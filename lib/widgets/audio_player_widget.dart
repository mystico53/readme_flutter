import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

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
  late AudioPlayer audioPlayer;
  Duration totalDuration = Duration();
  Duration currentPosition = Duration();
  bool isPlaying = false;
  bool isSeeking = false;
  Timer? seekDebounceTimer;
  bool isAudioInitialized = false;
  StreamSubscription<Duration>? _positionSubscription;
  bool isBuffering = false;

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    initAudio();
  }

  @override
  void didUpdateWidget(AudioPlayerWidget oldWidget) {
    if (oldWidget.audioUrl != widget.audioUrl) {
      initAudio(); // Re-initialize audio if the URL changes
    }
    super.didUpdateWidget(oldWidget);
  }

  Future<void> initAudio() async {
    if (widget.audioUrl.isEmpty) {
      // If the audio URL is empty, set the total duration to zero
      setState(() {
        totalDuration = Duration.zero;
      });
      return;
    }

    try {
      await audioPlayer.setSource(UrlSource(widget.audioUrl));
      audioPlayer.onDurationChanged.listen((duration) {
        setState(() {
          totalDuration = duration;
        });
      });

      // Cancel any previous position subscription
      _positionSubscription?.cancel();

      // Subscribe to position changes
      _positionSubscription = audioPlayer.onPositionChanged.listen((position) {
        setState(() {
          currentPosition = position;
        });
      });

      audioPlayer.onPlayerStateChanged.listen((state) {
        if (state == PlayerState.stopped) {
          setState(() {
            isPlaying = false;
            currentPosition = Duration.zero;
          });
        } else if (state == PlayerState.playing) {
          setState(() {
            isPlaying = true;
          });
        } else if (state == PlayerState.paused) {
          setState(() {
            isPlaying = false;
          });
        } else if (state == PlayerState.completed) {
          setState(() {
            isPlaying = false;
            currentPosition = totalDuration;
          });
        }
      });
      setState(() {
        isAudioInitialized = true;
      });
    } catch (e) {
      print('Error setting audio source: ${e.toString()}');
      // Set the total duration to zero if an error occurs
      setState(() {
        totalDuration = Duration.zero;
      });
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    audioPlayer.dispose();
    super.dispose();
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}h ${twoDigitMinutes}m ${twoDigitSeconds}s";
  }

  void seekAudio(double value) async {
    await audioPlayer.pause();
    await audioPlayer.seek(Duration(milliseconds: value.toInt()));
    await audioPlayer.resume();
    setState(() {
      currentPosition = Duration(milliseconds: value.toInt());
    });
  }

  void jumpBackward() {
    final newPosition = currentPosition - Duration(seconds: 10);
    if (newPosition < Duration.zero) {
      seekAudio(0);
    } else {
      seekAudio(newPosition.inMilliseconds.toDouble());
    }
  }

  void jumpForward() {
    final newPosition = currentPosition + Duration(seconds: 10);
    if (newPosition > totalDuration) {
      seekAudio(totalDuration.inMilliseconds.toDouble());
    } else {
      seekAudio(newPosition.inMilliseconds.toDouble());
    }
  }

  @override
  Widget build(BuildContext context) {
    String totalDurationString = formatDuration(totalDuration);
    String currentPositionString = formatDuration(currentPosition);
    bool isAudioLoaded = totalDuration != Duration.zero;

    return Container(
      color: Colors.grey[200],
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (isBuffering) CircularProgressIndicator() else SizedBox.shrink(),
          SizedBox(height: 10),
          Text(
            widget.audioTitle,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 10),
          isAudioLoaded
              ? Row(
                  children: [
                    Text(currentPositionString),
                    Expanded(
                      child: Slider(
                        value: currentPosition.inMilliseconds.toDouble(),
                        min: 0.0,
                        max: totalDuration.inMilliseconds.toDouble(),
                        onChanged: (double value) {
                          seekAudio(value);
                        },
                      ),
                    ),
                    Text(totalDurationString),
                  ],
                )
              : Container(),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () async {
                  try {
                    await audioPlayer.stop();
                    await audioPlayer.release();
                    setState(() {
                      isPlaying = false;
                      currentPosition = Duration.zero;
                      isAudioInitialized = false;
                    });
                    await initAudio(); // Reinitialize the audio player
                  } catch (e) {
                    print('Error stopping audio: ${e.toString()}');
                    // Handle the error and show an appropriate message to the user
                  }
                },
                icon: Icon(Icons.stop),
              ),
              SizedBox(width: 10),
              IconButton(
                onPressed: jumpBackward,
                icon: Icon(Icons.replay_10),
              ),
              SizedBox(width: 10),
              IconButton(
                onPressed: () async {
                  try {
                    if (isPlaying) {
                      await audioPlayer.pause();
                      setState(() {
                        isPlaying = false;
                      });
                    } else {
                      if (!isAudioInitialized) {
                        await initAudio();
                      }
                      await audioPlayer.resume();
                      setState(() {
                        isPlaying = true;
                      });
                    }
                  } catch (e) {
                    print('Error playing/pausing audio: ${e.toString()}');
                    // Handle the error and show an appropriate message to the user
                  }
                },
                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              ),
              SizedBox(width: 10),
              IconButton(
                onPressed: jumpForward,
                icon: Icon(Icons.forward_10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
