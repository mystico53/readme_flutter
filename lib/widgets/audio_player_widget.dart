import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final String audioTitle;

  AudioPlayerWidget(
      {Key? key, required this.audioUrl, required this.audioTitle})
      : super(key: key);

  @override
  _AudioPlayerWidgetState createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isBuffering = false;
  bool _isAudioLoaded = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudio();
  }

  @override
  void didUpdateWidget(AudioPlayerWidget oldWidget) {
    if (oldWidget.audioUrl != widget.audioUrl) {
      _initAudio(); // Re-initialize audio if the URL changes
    }
    super.didUpdateWidget(oldWidget);
  }

  Future<void> _initAudio() async {
    if (widget.audioUrl.isEmpty) {
      setState(() {
        _totalDuration = Duration.zero;
        _isAudioLoaded = false;
        _errorMessage = 'Select or create a Lisme';
      });
      return;
    }

    try {
      await _audioPlayer.setUrl(widget.audioUrl);
      _totalDuration = _audioPlayer.duration ?? Duration.zero;

      _audioPlayer.positionStream.listen((position) {
        setState(() {
          _currentPosition = position;
        });
      });

      _audioPlayer.playerStateStream.listen((state) {
        setState(() {
          _isPlaying = state.playing;
          _isBuffering = state.processingState == ProcessingState.buffering;
        });
      });

      _audioPlayer.processingStateStream.listen((state) {
        setState(() {
          _isBuffering = state == ProcessingState.buffering;
        });
      });

      setState(() {
        _isAudioLoaded = true;
        _errorMessage = '';
      });
    } catch (e) {
      print('Error setting audio source: ${e.toString()}');
      setState(() {
        _totalDuration = Duration.zero;
        _isAudioLoaded = false;
        _errorMessage = 'Failed to load audio';
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:${twoDigitMinutes}:${twoDigitSeconds}";
  }

  void _seekAudio(double value) {
    _audioPlayer.seek(Duration(milliseconds: value.toInt()));
  }

  void _jumpBackward() {
    final newPosition = _currentPosition - Duration(seconds: 10);
    _seekAudio(newPosition < Duration.zero
        ? 0
        : newPosition.inMilliseconds.toDouble());
  }

  void _jumpForward() {
    final newPosition = _currentPosition + Duration(seconds: 10);
    _seekAudio(newPosition > _totalDuration
        ? _totalDuration.inMilliseconds.toDouble()
        : newPosition.inMilliseconds.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    String totalDurationString = _formatDuration(_totalDuration);
    String currentPositionString = _formatDuration(_currentPosition);

    double currentPositionValue = _currentPosition.inMilliseconds.toDouble();
    double totalDurationValue = _totalDuration.inMilliseconds.toDouble();
    currentPositionValue = currentPositionValue.clamp(0.0, totalDurationValue);

    return Container(
      color: Color(0xFF4B473D),
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (_isBuffering)
            LinearProgressIndicator()
          else if (!_isAudioLoaded)
            Text(
              _errorMessage,
              style: TextStyle(color: Color(0xFFFFEFC3)),
            )
          else
            SizedBox.shrink(),
          SizedBox(height: 10),
          Text(
            widget.audioTitle,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFFFFEFC3),
            ),
          ),
          SizedBox(height: 10),
          _isAudioLoaded
              ? Row(
                  children: [
                    Text(
                      currentPositionString,
                      style: TextStyle(color: Color(0xFFFFEFC3)),
                    ),
                    Expanded(
                      child: Slider(
                        value: currentPositionValue,
                        min: 0.0,
                        max: totalDurationValue,
                        onChanged: _seekAudio,
                        activeColor: Color(0xFFFFEFC3),
                        inactiveColor: Color(0xFFFFEFC3).withOpacity(0.3),
                      ),
                    ),
                    Text(
                      totalDurationString,
                      style: TextStyle(color: Color(0xFFFFEFC3)),
                    ),
                  ],
                )
              : Container(),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () async {
                  await _audioPlayer.stop();
                  await _audioPlayer.seek(Duration.zero);
                  setState(() {
                    _isPlaying = false;
                    _currentPosition = Duration.zero;
                  });
                },
                icon: Icon(Icons.stop, color: Color(0xFFFFEFC3)),
              ),
              SizedBox(width: 10),
              IconButton(
                onPressed: _jumpBackward,
                icon: Icon(Icons.replay_10, color: Color(0xFFFFEFC3)),
              ),
              SizedBox(width: 10),
              IconButton(
                onPressed: () async {
                  if (_isPlaying) {
                    await _audioPlayer.pause();
                  } else {
                    try {
                      await _audioPlayer.play();
                    } catch (e) {
                      print('Error playing audio: ${e.toString()}');
                      // Handle the error and show an appropriate message to the user
                    }
                  }
                },
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Color(0xFFFFEFC3)),
              ),
              SizedBox(width: 10),
              IconButton(
                onPressed: _jumpForward,
                icon: Icon(Icons.forward_10, color: Color(0xFFFFEFC3)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
