import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:flutter/services.dart';
import 'app_config.dart'; // Import AppConfig

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
  late StreamSubscription _intentSub;
  final _sharedFiles = <SharedMediaFile>[];

  final textController = TextEditingController();
  final scrollController = ScrollController();
  String audioUrl = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    textController.addListener(_updateCharacterCount);

    // Listen for shared URLs/text when the app is already running
    _intentSub = ReceiveSharingIntent.getMediaStream().listen((value) {
      setState(() {
        _sharedFiles.clear();
        _sharedFiles.addAll(value);
        String filesString =
            _sharedFiles.map((f) => f.toMap().toString()).join(", ");
        textController.text = filesString;
        Future.delayed(Duration(milliseconds: 100), () {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        });
        //print(_sharedFiles.map((f) => f.toMap()));
      });
    }, onError: (err) {
      print("getIntentDataStream error: $err");
    });
  }

  void _updateCharacterCount() {
    setState(() {}); // Update UI whenever text changes
  }

  String _calculateEstimatedCost() {
    double costPerCharacter = 0.000016;
    int characterCount = textController.text.length;
    double totalCost = characterCount * costPerCharacter;
    return totalCost.toStringAsFixed(4); // Format to 2 decimal places
  }

  void sendTextToServer() async {
    final text = textController.text;
    final filename = 'audio_${DateTime.now().millisecondsSinceEpoch}.wav';

    var request = http.Request('POST', AppConfig.ttsUrl);
    request.headers.addAll({'Content-Type': 'application/json'});
    request.body = jsonEncode({'text': text, 'filename': filename});

    var streamedResponse =
        await request.send().timeout(const Duration(seconds: 30));

    if (streamedResponse.statusCode == 200) {
      print("Text sent successfully, starting status check.");
      handleProcessing(filename); // Now, just start checking status
    } else {
      print('Server responded with error: ${streamedResponse.statusCode}');
    }
  }

  @override
  void dispose() {
    textController.removeListener(_updateCharacterCount);
    textController.dispose();
    _intentSub.cancel();
    super.dispose();
  }

  Future<Map<String, String>> checkReadyStatus(String fileName) async {
    try {
      final url = AppConfig.checkAudioStatusUrl(fileName);
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("checked status for $fileName and received $data");
        return {
          'status': data['status'],
          'gcs_url': data['gcs_url'] ?? '',
        };
      } else {
        print('Server error: ${response.statusCode} for $fileName');
        return {'status': 'Server error', 'gcs_url': ''};
      }
    } catch (e) {
      print('An error occurred: $e for $fileName');
      return {'status': 'Error', 'gcs_url': ''};
    }
  }

  void handleProcessing(String fileName) {
    const period = Duration(seconds: 1);
    _timer = Timer.periodic(period, (timer) async {
      final result = await checkReadyStatus(fileName);
      if (result['status'] == 'ready' && result['gcs_url']!.isNotEmpty) {
        timer.cancel(); // Stop monitoring once the file is ready
        print("lets play it");
        String localFilePath = await prepareLocalFilePath(fileName);
        //await downloadAudioFile(result['gcs_url']!, localFilePath);
        // Optionally, play the audio file after download
        //playAudioFromFile(localFilePath);
        streamAudioFromUrl(result['gcs_url']!);
      }
    });
  }

  void cleanWithAI() async {
    String text = textController.text;
    String cleanedText = await sendTextToAI(text);
    setState(() {
      textController.text = cleanedText;
    });
  }

  Future<String> sendTextToAI(String text) async {
    final response = await http.post(
      AppConfig.generateAiTextUrl,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'text': text,
      }),
    );

    if (response.statusCode == 200) {
      // Assuming the response is a JSON object with a key 'generated_text'
      final jsonResponse = jsonDecode(response.body);
      String generatedText = jsonResponse['generated_text'];

      // Replace '\n' with spaces
      generatedText = generatedText.replaceAll('\n', ' ');

      return generatedText;
    } else {
      // Handle error response
      print('Failed to generate AI text');
      return text; // Return the original text or handle accordingly
    }
  }

  Future<String> prepareLocalFilePath(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$filename';
  }

  void streamAudioFromUrl(String url) async {
    //final player = AudioPlayer();
    // Convert or ensure the URL is in the correct format
    final httpsUrl = convertGsUrlToHttps(url);
    setState(() {
      audioUrl = httpsUrl;
    });
    //await player.play(UrlSource(httpsUrl));
  }

  String convertGsUrlToHttps(String gsUrl) {
    // Implement conversion logic here, or return a directly accessible HTTPS URL
    return gsUrl.replaceFirst('gs://', 'https://storage.googleapis.com/');
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
              scrollController: scrollController,
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
                        // Get current text from the controller
                        String currentText = textController.text;
                        // Append the clipboard text to the current text
                        String newText = currentText + (value?.text ?? '');
                        // Update the controller with the new text
                        textController.text = newText;
                        // Set the cursor at the end of the new text
                        textController.selection = TextSelection.fromPosition(
                            TextPosition(offset: newText.length));

                        // Scroll to the bottom of the TextField
                        Future.delayed(Duration(milliseconds: 100), () {
                          scrollController.animateTo(
                            scrollController.position.maxScrollExtent,
                            duration: Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                          );
                        });
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
            const SizedBox(width: 10), // Spacing between buttons
            ElevatedButton(
              onPressed: () {
                cleanWithAI();
              },
              child: const Text('Clean with AI'),
            ),
            SizedBox(height: 20),
            if (audioUrl.isNotEmpty) AudioPlayerWidget(audioUrl: audioUrl),
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
