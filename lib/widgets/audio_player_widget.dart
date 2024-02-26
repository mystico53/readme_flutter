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
    await audioPlayer.setSource(DeviceFileSource(widget.audioUrl));
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
    String totalDurationString = formatDuration(totalDuration);
    String currentPositionString = formatDuration(currentPosition);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Received Audio: '),
            Text('${currentPositionString} / ${totalDurationString}'),
          ],
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                await audioPlayer.stop();
              },
              child: Text('Stop'),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: () async {
                await audioPlayer.pause();
              },
              child: Text('Pause'),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: () async {
                // Set the audio source again before resuming playback
                await audioPlayer.setSource(DeviceFileSource(widget.audioUrl));
                await audioPlayer.resume();
              },
              child: Text('Play'),
            ),
          ],
        ),
      ],
    );
  }
}
