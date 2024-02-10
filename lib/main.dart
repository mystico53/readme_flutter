import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'app_config.dart'; // Import AppConfig
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final textController = TextEditingController();
  String audioUrl = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    textController.addListener(
        _updateCharacterCount); // Add listener to the textController
  }

  void _updateCharacterCount() {
    setState(() {}); // Update UI whenever text changes
  }

  String _calculateEstimatedCost() {
    double costPerCharacter = 0.000016;
    int characterCount = textController.text.length;
    double totalCost = characterCount * costPerCharacter;
    return totalCost.toStringAsFixed(6); // Format to 2 decimal places
  }

  void sendTextToServer() async {
    final text = textController.text;
    final filename =
        'audio_${DateTime.now().millisecondsSinceEpoch}.wav'; // Generate filename

    try {
      print("trying");
      // Create the request
      var request = http.Request('POST', Uri.parse(AppConfig.ttsUrl))
        ..headers.addAll({'Content-Type': 'application/json'})
        ..body = jsonEncode({'text': text, 'filename': filename});

      // Send the request and await the streamed response
      var streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));

      if (streamedResponse.statusCode == 200) {
        // Get the path to save the file
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$filename'; // Unique file path
        final audioFile = File(filePath);

        startCheckingStatus(filename);

        // Stream the bytes to the file
        await streamedResponse.stream.pipe(audioFile.openWrite());

        setState(() {
          audioUrl = AppConfig.checkAudioStatusUrl(filename);
          print("audioUrl $audioUrl");
        });
      } else {
        // Handle the case when the server responds with an error
        print('Server responded with error: ${streamedResponse.statusCode}');
      }
    } on TimeoutException catch (e) {
      // Handle the timeout exception
      print('Request to server timed out: $e');
    } catch (e) {
      // Handle other exceptions
      print('An error occurred: $e');
    }
  }

  @override
  void dispose() {
    textController.removeListener(_updateCharacterCount);
    textController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> checkAudioStatus(String fileName) async {
    try {
      final url = AppConfig.checkAudioStatusUrl(fileName);
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("checked status for $fileName and received $data");
        stopCheckingStatus();
        return {
          'status': data['status'], // This is correct now
          'gcs_url': data['gcs_url'] ??
              '', // Providing a default value if gcs_url is not present
        };
      } else {
        print('Server error: ${response.statusCode} for $fileName');
        stopCheckingStatus();
        return {
          'status': 'Server error',
          'gcs_url': '',
        };
      }
    } catch (e) {
      print('An error occurred: $e for $fileName');
      stopCheckingStatus();
      return {
        'status': 'Error',
        'gcs_url': '',
      };
    }
  }

  void startCheckingStatus(String fileName) {
    const period = Duration(
        seconds: 1); // Adjusted to every 5 seconds as mentioned in the comment
    _timer = Timer.periodic(period, (timer) async {
      final result = await checkAudioStatus(fileName);
      final status = result['status'];
      final gcsUrl = result['gcs_url'];

      print("Status: $status");
      if (gcsUrl?.isNotEmpty == true) {
        print("GCS URL: $gcsUrl");
        timer.cancel();
      }

      if (status == "ready") {
        timer.cancel(); // Stop checking once the file is ready
        // Handle the ready status, e.g., downloading/streaming the file using gcsUrl
        // Example: downloadAudio(gcsUrl); or whatever your next step is
      } else if (status == "Server error" || status == "Error") {
        timer
            .cancel(); // Consider stopping the timer on errors too, or handle retries differently
        // Handle error
      }
      // If the status is not "ready" or an error, the timer will continue until it's stopped.
    });
  }

  void stopCheckingStatus() {
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading voice app'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: textController,
              decoration: const InputDecoration(labelText: 'Enter Text'),
              keyboardType: TextInputType.multiline,
              maxLines: 6,
              minLines: 6,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Character Count: ${textController.text.length}'),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                  'Estimated Costs: \$${_calculateEstimatedCost()}'), // Display estimated cost
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Clipboard.getData(Clipboard.kTextPlain).then((value) {
                        textController.text = value?.text ?? '';
                      });
                    },
                    child: const Text('Paste Text'),
                  ),
                  const SizedBox(width: 10), // Spacing between buttons
                  OutlinedButton(
                    onPressed: () {
                      textController.clear();
                    },
                    child: const Text('Clear Text'),
                  ),
                  const SizedBox(width: 10), // Spacing between buttons
                  ElevatedButton(
                    onPressed: () {
                      sendTextToServer();
                    },
                    child: const Text('Generate Audio'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            //if (audioUrl.isNotEmpty) AudioPlayerWidget(audioUrl: audioUrl),
          ],
        ),
      ),
    );
  }
}

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
