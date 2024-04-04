import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final String audioTitle;
  final String fileId;
  final Function(int) onProgressChanged;

  AudioPlayerWidget({
    Key? key,
    required this.audioUrl,
    required this.audioTitle,
    required this.fileId,
    required this.onProgressChanged,
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
  Duration _furthestPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudio();
  }

  @override
  void didUpdateWidget(AudioPlayerWidget oldWidget) {
    if (oldWidget.audioUrl != widget.audioUrl) {
      _saveProgress();
      _initAudio(); // Re-initialize audio if the URL changes
      print("init audio triggered");
    }
    super.didUpdateWidget(oldWidget);
    print("did update, playing: $_isPlaying");
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
          if (position > _furthestPosition) {
            _furthestPosition = position;
            if (_totalDuration.inMilliseconds > 0) {
              double progress = (_furthestPosition.inMilliseconds /
                      _totalDuration.inMilliseconds) *
                  100;
              widget.onProgressChanged(progress.toInt());
            }
          }
        });
      });

      setState(() {
        _isAudioLoaded = true;
        _errorMessage = '';
        _isPlaying = true;
      });

      print(
          "inside init audio: audio loaded $_isAudioLoaded, playing: $_isPlaying");

      // Retrieve the stored progress from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final storedProgress = prefs.getInt('${widget.fileId}_progress') ?? 0;
      _furthestPosition = Duration(milliseconds: storedProgress);

      // Jump to the furthest position
      await _audioPlayer.seek(_furthestPosition);
      setState(() {
        _currentPosition = _furthestPosition;
      });
      if (_isPlaying) {
        await _audioPlayer.play();
        print(
            "init audio starting audioplayer, is playing (should be true): $_isPlaying");
      }

      // Autoplay the audio if it's not already playing
      if (!_isPlaying) {
        await _audioPlayer.play();
      }

      _audioPlayer.playerStateStream.listen((state) {
        setState(() {
          _isPlaying = state.playing;
          _isBuffering = state.processingState == ProcessingState.buffering;
          print(
              "getting playerstate stream, isplaying: $_isPlaying, is buffering: $_isBuffering ");
        });

        if (!state.playing) {
          _saveProgress(); // Save progress when the audio is paused or finished
          widget.onProgressChanged((_currentPosition.inMilliseconds /
                  _totalDuration.inMilliseconds *
                  100)
              .toInt());
        }
      });

      _audioPlayer.processingStateStream.listen((state) {
        print("Debug: Processing state changed to $state");
        setState(() {
          _isBuffering = state == ProcessingState.buffering;
        });
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

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final currentProgress = _currentPosition.inMilliseconds;

    if (currentProgress > _furthestPosition.inMilliseconds) {
      _furthestPosition = Duration(milliseconds: currentProgress);
      await prefs.setInt('${widget.fileId}_progress', currentProgress);
    } else if (_furthestPosition == Duration.zero) {
      await prefs.remove('${widget.fileId}_progress');
    }
  }

  @override
  void dispose() {
    _saveProgress();
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

    setState(() {
      _currentPosition = seekPosition;
    });

    if (seekPosition > _furthestPosition) {
      setState(() {
        _furthestPosition = seekPosition;
      });
      _saveProgress();
    }
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

    double furthestPositionValue = _furthestPosition.inMilliseconds.toDouble();
    furthestPositionValue =
        furthestPositionValue.clamp(0.0, totalDurationValue);

    double progress = _totalDuration.inMilliseconds > 0
        ? (_furthestPosition.inMilliseconds / _totalDuration.inMilliseconds) *
            100
        : 0;

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
          Text(
            'Progress: ${progress.toStringAsFixed(1)}%',
            style: TextStyle(color: Color(0xFFFFEFC3)),
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
                      child: Stack(
                        children: [
                          //Furthest position
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4,
                              thumbShape: RoundSliderThumbShape(
                                enabledThumbRadius: 3,
                              ),
                              activeTrackColor: Color(0xFFFFEFC3),
                              inactiveTrackColor: Color(0xFFFFEFC3),
                            ),
                            child: Slider(
                              value: furthestPositionValue,
                              min: 0.0,
                              max: totalDurationValue,
                              onChanged: null,
                            ),
                          ),
                          SliderTheme(
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
                        ],
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
                    _isPlaying = false;
                    _currentPosition = Duration.zero;
                    _furthestPosition = Duration.zero;
                  });
                  await _saveProgress();
                },
                child: IconButton(
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
              ),
              SizedBox(width: 10),
              IconButton(
                onPressed: _jumpBackward,
                icon: Icon(Icons.replay_10, color: Color(0xFFFFEFC3)),
              ),
              SizedBox(width: 10),
              GestureDetector(
                onLongPress: () async {
                  await _audioPlayer.seek(_furthestPosition);
                  setState(() {
                    _currentPosition = _furthestPosition;
                    _isPlaying = true;
                  });
                  await _audioPlayer.play();
                },
                child: IconButton(
                  onPressed: () async {
                    if (_isPlaying) {
                      await _audioPlayer.pause();
                      setState(() {
                        _isPlaying = false;
                      });
                    } else {
                      if (_currentPosition >= _totalDuration) {
                        await _audioPlayer.seek(Duration.zero);
                        setState(() {
                          _currentPosition = Duration.zero;
                        });
                      }
                      await _audioPlayer.play();
                      setState(() {
                        _isPlaying = true;
                      });
                    }
                    print(
                        "play press: playing: $_isPlaying, audioloaded: $_isAudioLoaded");
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
            ],
          ),
        ],
      ),
    );
  }
}
