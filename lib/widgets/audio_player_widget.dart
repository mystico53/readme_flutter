import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:readme_app/services/audio_handler.dart';
import 'package:readme_app/view_models/audioplayer_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audio_service/audio_service.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final String audioTitle;
  final String fileId;
  final String? artist;
  final String? album;

  Duration get maxReportedPosition => viewModel.maxReportedPosition;

  final AudioPlayerViewModel viewModel;

  AudioPlayerWidget({
    Key? key,
    required this.audioUrl,
    required this.audioTitle,
    required this.fileId,
    this.artist,
    this.album,
    required this.viewModel,
  }) : super(key: key);

  @override
  AudioPlayerWidgetState createState() => AudioPlayerWidgetState();
}

class AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioHandler _audioHandler;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isBuffering = false;
  bool _isAudioLoaded = false;
  String _errorMessage = '';
  DateTime? _startTime;
  double _playbackSpeed = 1.0; // Playback speed state
  Timer? _positionUpdateTimer;
  StreamSubscription? _playbackStateSubscription;
  StreamSubscription? _mediaItemSubscription;

  @override
  @override
  void initState() {
    super.initState();
    _audioHandler = Provider.of<AudioHandler>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.setTrackInfo(
        title: widget.audioTitle,
        artist: widget.artist,
        album: widget.album,
      );
      _initAudio();
    });
  }

  void _listenToAudioHandlerState() {
    _playbackStateSubscription = _audioHandler.playbackState.listen((state) {
      setState(() {
        _isPlaying = state.playing;
        _currentPosition = state.position;
        _isBuffering = state.processingState == AudioProcessingState.buffering;
      });
      widget.viewModel.setPlaying(state.playing);
      widget.viewModel.updatePosition(state.position);
    });

    _mediaItemSubscription =
        (_audioHandler as MyAudioHandler).currentMediaItem.listen((mediaItem) {
      if (mediaItem != null) {
        setState(() {
          _totalDuration = mediaItem.duration ?? Duration.zero;
        });
      }
    });
  }

  void _startPositionUpdateTimer() {
    _positionUpdateTimer?.cancel();
    _positionUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPlaying && !_isBuffering) {
        widget.viewModel.updatePosition(_currentPosition);
      }
    });
  }

  @override
  void didUpdateWidget(AudioPlayerWidget oldWidget) {
    if (oldWidget.audioUrl != widget.audioUrl) {
      // We don't need to dispose of the AudioHandler as it's managed externally
      // Instead, we'll reinitialize the audio with the new URL
      _initAudio();
    }
    super.didUpdateWidget(oldWidget);
  }

  Future<void> _initAudio() async {
    setState(() {
      _isBuffering = true;
      _errorMessage = '';
    });

    if (widget.audioUrl.isEmpty) {
      setState(() {
        _totalDuration = Duration.zero;
        _isAudioLoaded = false;
        _isBuffering = false;
        _errorMessage = 'Select or create a Lisme';
      });
      Future.microtask(() {
        widget.viewModel.setPlaying(false);
      });
      return;
    }

    try {
      await (_audioHandler as MyAudioHandler).setAudioSource(
        widget.audioUrl,
        widget.fileId,
        title: widget.audioTitle,
        artist: widget.artist,
        album: widget.album,
      );
      widget.viewModel.setCurrentFileId(widget.fileId);

      _totalDuration = await (_audioHandler as MyAudioHandler).getDuration() ??
          Duration.zero;
      await _audioHandler.setSpeed(_playbackSpeed);

      Duration? storedPosition =
          await widget.viewModel.getStoredPosition(widget.fileId);
      if (storedPosition != null) {
        await _audioHandler.seek(storedPosition);
        _currentPosition = storedPosition;
      }

      widget.viewModel.startPeriodicUpdate(_totalDuration, widget.fileId);

      _listenToAudioHandlerState();
      _startPositionUpdateTimer();

      setState(() {
        _isAudioLoaded = true;
        _isBuffering = false;
        _errorMessage = '';
      });

      // We're not auto-playing, so we set playing to false
      Future.microtask(() {
        widget.viewModel.setPlaying(false);
      });
    } catch (e) {
      _handleError('Failed to load audio: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    _positionUpdateTimer?.cancel();
    _playbackStateSubscription?.cancel();
    _mediaItemSubscription?.cancel();
    super.dispose();
  }

  void _handleError(String message) {
    print('AudioPlayer Error: $message');
    setState(() {
      _totalDuration = Duration.zero;
      _currentPosition = Duration.zero;
      _isAudioLoaded = false;
      _isBuffering = false;
      _errorMessage = message;
    });
    widget.viewModel.setPlaying(false);
    // Optionally, you could notify a global error handling service here
    // errorHandlingService.reportError(message);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:${twoDigitMinutes}:${twoDigitSeconds}";
  }

  void _seekAudio(double value) {
    final seekPosition = Duration(milliseconds: value.toInt());
    _audioHandler.seek(seekPosition);
  }

  void _jumpBackward() {
    final newPosition = _currentPosition - const Duration(seconds: 10);
    _seekAudio(newPosition < Duration.zero
        ? 0
        : newPosition.inMilliseconds.toDouble());
  }

  void _jumpForward() {
    final newPosition = _currentPosition + const Duration(seconds: 10);
    _seekAudio(newPosition > _totalDuration
        ? _totalDuration.inMilliseconds.toDouble()
        : newPosition.inMilliseconds.toDouble());
  }

  void _jumpToMaxReportedPosition() {
    final maxReportedPosition = widget.viewModel.maxReportedPosition;
    _seekAudio(maxReportedPosition.inMilliseconds.toDouble());
  }

  void _updatePlaybackSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
    });
    _audioHandler.setSpeed(speed);
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

    bool isAudioAvailable = widget.audioUrl.isNotEmpty;

    return Container(
      color: const Color(0xFF4B473D),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isAudioLoaded)
            Text(
              _errorMessage,
              style: const TextStyle(color: Color(0xFFFFEFC3)),
            )
          else
            const SizedBox.shrink(),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isBuffering && _isAudioLoaded)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFFFEFC3)),
                  ),
                )
              else
                const SizedBox(width: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${widget.viewModel.title} - ${widget.viewModel.artist}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFFFFEFC3),
                  ),
                  softWrap: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _isAudioLoaded
              ? Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        currentPositionString,
                        style: const TextStyle(color: Color(0xFFFFEFC3)),
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 2,
                              thumbColor: Colors.transparent,
                              activeTrackColor: const Color(0xFFFFEFC3),
                              inactiveTrackColor: Colors.transparent,
                              overlayColor: Colors.transparent,
                            ),
                            child: Slider(
                              value: widget
                                  .viewModel.maxReportedPosition.inMilliseconds
                                  .toDouble()
                                  .clamp(0.0, totalDurationValue),
                              min: 0.0,
                              max: totalDurationValue,
                              onChanged:
                                  null, // Make this slider non-interactive
                            ),
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4,
                              thumbColor: const Color(0xFFFFEFC3),
                              activeTrackColor: const Color(0xFFFFEFC3),
                              inactiveTrackColor: Colors.transparent,
                            ),
                            child: Slider(
                              value: currentPositionValue.clamp(
                                  0.0, totalDurationValue),
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
                      style: const TextStyle(color: Color(0xFFFFEFC3)),
                    ),
                  ],
                )
              : Container(),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Speed control dropdown
              DropdownButton<double>(
                value: _playbackSpeed,
                dropdownColor: const Color(0xFF4B473D),
                style: const TextStyle(color: Color(0xFFFFEFC3)),
                items: List.generate(11, (index) {
                  double value = 0.7 + (index * 0.1);
                  return DropdownMenuItem(
                    value: value,
                    child: Text(
                      value.toStringAsFixed(1),
                      style: const TextStyle(color: Color(0xFFFFEFC3)),
                    ),
                  );
                }),
                onChanged: isAudioAvailable
                    ? (value) {
                        if (value != null) {
                          _updatePlaybackSpeed(value);
                        }
                      }
                    : null,
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onLongPress: () async {
                  await _audioHandler.stop();
                  await _audioHandler.seek(Duration.zero);
                  setState(() {
                    _currentPosition = Duration.zero;
                  });
                  await widget.viewModel.resetProgress(widget.fileId);
                },
                child: IconButton(
                  onPressed: isAudioAvailable
                      ? () async {
                          await _audioHandler.stop();
                          await _audioHandler.seek(Duration.zero);
                          setState(() {
                            _currentPosition = Duration.zero;
                          });
                        }
                      : null,
                  icon: Icon(Icons.stop,
                      color: isAudioAvailable
                          ? const Color(0xFFFFEFC3)
                          : const Color(0xFF8B8778)),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: isAudioAvailable ? _jumpBackward : null,
                icon: Icon(Icons.replay_10,
                    color: isAudioAvailable
                        ? const Color(0xFFFFEFC3)
                        : const Color(0xFF8B8778)),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: isAudioAvailable
                    ? () async {
                        if (_isPlaying) {
                          await _audioHandler.pause();
                        } else {
                          if (_currentPosition >= _totalDuration) {
                            await _audioHandler.seek(Duration.zero);
                          }
                          await _audioHandler.play();
                        }
                      }
                    : null,
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: isAudioAvailable
                      ? const Color(0xFFFFEFC3)
                      : const Color(0xFF8B8778),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: isAudioAvailable ? _jumpForward : null,
                icon: Icon(Icons.forward_10,
                    color: isAudioAvailable
                        ? const Color(0xFFFFEFC3)
                        : const Color(0xFF8B8778)),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: isAudioAvailable ? _jumpToMaxReportedPosition : null,
                icon: Icon(Icons.skip_next,
                    color: isAudioAvailable
                        ? const Color(0xFFFFEFC3)
                        : const Color(0xFF8B8778)),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ],
      ),
    );
  }
}
