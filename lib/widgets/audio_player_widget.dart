import 'dart:async';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;

  AudioPlayerWidget({Key? key, required this.audioUrl}) : super(key: key);

  @override
  _AudioPlayerWidgetState createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer audioPlayer;
  Duration totalDuration = Duration();
  Duration currentPosition = Duration();
  Timer? timer;

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

  void initAudio() async {
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
      audioPlayer.onPositionChanged.listen((position) {
        setState(() {
          currentPosition = position;
        });
      });
      timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
        if (!mounted) return;
        setState(() {});
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
    audioPlayer.dispose();
    timer?.cancel();
    super.dispose();
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}h ${twoDigitMinutes}m ${twoDigitSeconds}s";
  }

  @override
  Widget build(BuildContext context) {
    // Format the total duration and current position for display
    String totalDurationString = formatDuration(totalDuration);
    String currentPositionString = formatDuration(currentPosition);

    print("debug: Building audio player widget");

    // Modify the logic to allow the UI to load even when total duration is zero
    // Instead of returning an error message immediately, we'll provide a default UI
    bool isAudioLoaded = totalDuration != Duration.zero;

    // Debug message to indicate whether the audio is considered loaded
    print("debug: isAudioLoaded - $isAudioLoaded");

    return Container(
      color: Colors.grey[200], // Set the background color to light grey
      padding: EdgeInsets.all(16.0), // Add padding for better spacing
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Received Audio: '),
              // Display the current position and total duration
              // If the audio is not loaded, indicate that to the user
              Text(isAudioLoaded
                  ? '${currentPositionString} / ${totalDurationString}'
                  : 'Loading...'),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  print("debug: Stopping audio");
                  await audioPlayer.stop();
                },
                child: Text('Stop'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () async {
                  print("debug: Pausing audio");
                  await audioPlayer.pause();
                },
                child: Text('Pause'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () async {
                  print("debug: Attempting to play audio");
                  // Attempt to play the audio. If totalDuration is zero because the audio is not fully loaded,
                  // this action can force a load or indicate an error to the user based on the audio player's behavior.
                  await audioPlayer.resume();
                },
                child: Text('Play'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
