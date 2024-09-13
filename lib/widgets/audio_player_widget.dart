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

class CustomSliderTrackShape extends SliderTrackShape {
  final double maxReportedPositionValue;
  final double totalDurationValue;
  final Color totalTrackColor;
  final Color maxReportedTrackColor;
  final Color currentTrackColor;

  CustomSliderTrackShape({
    required this.maxReportedPositionValue,
    required this.totalDurationValue,
    required this.totalTrackColor,
    required this.maxReportedTrackColor,
    required this.currentTrackColor,
  });

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    required RenderBox parentBox,
    Offset? secondaryOffset,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required Offset thumbCenter,
  }) {
    if (sliderTheme.trackHeight == null || sliderTheme.trackHeight! <= 0) {
      return;
    }

    final double trackHeight = sliderTheme.trackHeight!;
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      sliderTheme: sliderTheme,
      offset: offset,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    // Define the border color
    final Color borderColor = const Color(0xFFFFEFC3);

    // Create the Paint for the total track (background)
    final Paint totalTrackPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Adjust the trackRect to ensure the stroke is drawn inside
    final Rect adjustedTrackRect = trackRect.deflate(0.5);

    // Draw the total track (background) as transparent with border
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(
        adjustedTrackRect,
        Radius.circular(trackHeight / 2),
      ),
      totalTrackPaint,
    );

    // Calculate percentages
    final double maxReportedPercent =
        (maxReportedPositionValue / totalDurationValue).clamp(0.0, 1.0);

    final double currentPercent =
        ((thumbCenter.dx - trackRect.left) / trackRect.width).clamp(0.0, 1.0);

    // Draw the max reported position track
    final Rect maxReportedTrackRect = Rect.fromLTWH(
      trackRect.left,
      trackRect.top,
      trackRect.width * maxReportedPercent,
      trackHeight,
    );

    final Paint maxReportedTrackPaint = Paint()
      ..color = maxReportedTrackColor
      ..style = PaintingStyle.fill;

    context.canvas.drawRRect(
      RRect.fromRectAndRadius(
        maxReportedTrackRect,
        Radius.circular(trackHeight / 2),
      ),
      maxReportedTrackPaint,
    );

    // Draw the current position track
    final Rect currentTrackRect = Rect.fromLTWH(
      trackRect.left,
      trackRect.top,
      trackRect.width * currentPercent,
      trackHeight,
    );

    final Paint currentTrackPaint = Paint()
      ..color = currentTrackColor
      ..style = PaintingStyle.fill;

    context.canvas.drawRRect(
      RRect.fromRectAndRadius(
        currentTrackRect,
        Radius.circular(trackHeight / 2),
      ),
      currentTrackPaint,
    );
  }

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    Offset offset = Offset.zero,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double thumbRadius =
        sliderTheme.thumbShape!.getPreferredSize(isEnabled, isDiscrete).width /
            2.0;
    final double trackHeight = sliderTheme.trackHeight ?? 4.0;

    // Define the total padding you want to apply to the track
    final double trackPadding = 40.0; // Adjust this value as needed

    // Calculate the adjusted trackLeft and trackWidth
    final double trackLeft = offset.dx + thumbRadius + trackPadding / 2;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth =
        parentBox.size.width - 2 * thumbRadius - trackPadding;

    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
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
  StreamSubscription<Duration>? _positionStreamSubscription;

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
      _initPositionListener();
    });
  }

  void _initPositionListener() {
    _positionStreamSubscription =
        (_audioHandler as MyAudioHandler).positionStream.listen((position) {
      setState(() {
        _currentPosition = position;
      });
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
    _positionStreamSubscription
        ?.cancel(); // Cancel the position stream subscription
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
                      width: 60,
                      child: Text(
                        currentPositionString,
                        style: const TextStyle(color: Color(0xFFFFEFC3)),
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 6,
                          thumbColor: const Color(0xFFFFEFC3),
                          activeTrackColor: Colors.transparent,
                          inactiveTrackColor: Colors.transparent,
                          overlayColor: Colors.transparent,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8.0),
                          trackShape: CustomSliderTrackShape(
                            maxReportedPositionValue: maxReportedPositionValue,
                            totalDurationValue: totalDurationValue,
                            totalTrackColor: Colors.grey[800]!,
                            maxReportedTrackColor: Colors.grey[500]!,
                            currentTrackColor: const Color(0xFFFFEFC3),
                          ),
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
