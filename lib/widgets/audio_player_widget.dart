import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:readme_app/view_models/audioplayer_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final String audioTitle;
  final String fileId;

  Duration get maxReportedPosition => viewModel.maxReportedPosition;

  final AudioPlayerViewModel viewModel;

  AudioPlayerWidget({
    Key? key,
    required this.audioUrl,
    required this.audioTitle,
    required this.fileId,
    required this.viewModel,
  }) : super(key: key);

  @override
  AudioPlayerWidgetState createState() => AudioPlayerWidgetState();
}

class AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isBuffering = false;
  bool _isAudioLoaded = false;
  String _errorMessage = '';
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudio();
  }

  @override
  void didUpdateWidget(AudioPlayerWidget oldWidget) {
    if (oldWidget.audioUrl != widget.audioUrl) {
      _audioPlayer.dispose();
      _audioPlayer = AudioPlayer();
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

      //send viewmodel fileid and duration
      widget.viewModel.startPeriodicUpdate(_totalDuration, widget.fileId);

      _audioPlayer.positionStream.listen((position) {
        setState(() {
          _currentPosition = position;
        });
        widget.viewModel.updatePosition(position);
      });

      setState(() {
        _isAudioLoaded = true;
        _errorMessage = '';
      });

      _audioPlayer.playerStateStream.listen((state) {
        setState(() {
          _isPlaying = state.playing;
          _isBuffering = state.processingState == ProcessingState.buffering;
        });
        print("state: ${state.playing}");
      });

      await _audioPlayer.play();

      _audioPlayer.processingStateStream.listen((state) {
        setState(() {
          _isBuffering = state == ProcessingState.buffering;
        });
      });

      _audioPlayer.playingStream.listen((playing) {
        if (playing) {
          _startTime = DateTime.now();
        } else {
          if (_startTime != null) {
            Duration playedDuration = DateTime.now().difference(_startTime!);
            widget.viewModel.updateTotalTimePlayed(playedDuration.inSeconds);
            _startTime = null;
          }
        }
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
    final seekPosition = Duration(milliseconds: value.toInt());
    _audioPlayer.seek(seekPosition);
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

  void _jumpToMaxReportedPosition() {
    final maxReportedPosition = widget.viewModel.maxReportedPosition;
    _seekAudio(maxReportedPosition.inMilliseconds.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    String totalDurationString = _formatDuration(_totalDuration);
    String currentPositionString = _formatDuration(_currentPosition);

    double currentPositionValue = _currentPosition.inMilliseconds.toDouble();
    double totalDurationValue = _totalDuration.inMilliseconds.toDouble();
    currentPositionValue = currentPositionValue.clamp(0.0, totalDurationValue);

    //this can be used to get the saved progress and visualize it in the slider
    final maxReportedPositionValue =
        widget.maxReportedPosition.inMilliseconds.toDouble();
    final maxReportedPositionPercentage = totalDurationValue > 0
        ? maxReportedPositionValue / totalDurationValue
        : 0.0;

    return Container(
      color: Color(0xFF4B473D),
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isAudioLoaded)
            Text(
              _errorMessage,
              style: TextStyle(color: Color(0xFFFFEFC3)),
            )
          else
            SizedBox.shrink(),
          SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isBuffering && _isAudioLoaded)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFFFEFC3)),
                  ),
                )
              else
                SizedBox(width: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.audioTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFFFFEFC3),
                  ),
                  softWrap: true,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          _isAudioLoaded
              ? Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        currentPositionString,
                        style: TextStyle(color: Color(0xFFFFEFC3)),
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbColor: Color(0xFFFFEFC3),
                          activeTrackColor: Color(0xFFFFEFC3),
                          inactiveTrackColor: Colors.transparent,
                        ),
                        child: Slider(
                          value: currentPositionValue,
                          min: 0.0,
                          max: totalDurationValue,
                          onChanged: _seekAudio,
                        ),
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
              GestureDetector(
                onLongPress: () async {
                  await _audioPlayer.stop();
                  await _audioPlayer.seek(Duration.zero);
                  setState(() {
                    _currentPosition = Duration.zero;
                  });
                  await widget.viewModel.resetProgress(widget.fileId);
                },
                child: IconButton(
                  onPressed: () async {
                    await _audioPlayer.stop();
                    await _audioPlayer.seek(Duration.zero);
                    setState(() {
                      _currentPosition = Duration.zero;
                    });
                  },
                  icon: Icon(Icons.stop, color: Color(0xFFFFEFC3)),
                ),
              ),
              SizedBox(width: 10),
              IconButton(
                onPressed: _jumpBackward,
                icon: Icon(Icons.replay_10, color: Color(0xFFFFEFC3)),
              ),
              SizedBox(width: 10),
              GestureDetector(
                onLongPress: () async {
                  await _audioPlayer.seek(_currentPosition);
                  setState(() {
                    _isPlaying = true;
                  });
                  await _audioPlayer.play();
                },
                child: IconButton(
                  onPressed: () async {
                    if (_isPlaying) {
                      await _audioPlayer.pause();
                    } else {
                      if (_currentPosition >= _totalDuration) {
                        await _audioPlayer.seek(Duration.zero);
                        setState(() {
                          _currentPosition = Duration.zero;
                        });
                      }
                      await _audioPlayer.play();
                    }
                  },
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Color(0xFFFFEFC3),
                  ),
                ),
              ),
              SizedBox(width: 10),
              IconButton(
                onPressed: _jumpForward,
                icon: Icon(Icons.forward_10, color: Color(0xFFFFEFC3)),
              ),
              SizedBox(width: 10),
              IconButton(
                onPressed: _jumpToMaxReportedPosition,
                icon: Icon(Icons.skip_next, color: Color(0xFFFFEFC3)),
              ),
              SizedBox(width: 10),
            ],
          ),
        ],
      ),
    );
  }
}
