import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
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

  void sendTextToServer() async {
    final serverUrl =
        AppConfig.serverUrl; // Use AppConfig to get the server URL
    final text = textController.text;

    try {
      final response = await http
          .post(
            Uri.parse(serverUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(seconds: 30)); // Set a 30-second timeout

      if (response.statusCode == 200) {
        final audioData = response.bodyBytes;
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/audio.mp3';
        final audioFile = File(filePath);

        await audioFile.writeAsBytes(audioData);
        setState(() {
          audioUrl = audioFile.path;
        });
      } else {
        // Handle the case when the server responds with an error
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
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Read me app'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: textController,
              decoration: const InputDecoration(labelText: 'Enter Text'),
              keyboardType:
                  TextInputType.multiline, // Set keyboard type to multiline
              maxLines: 7, // Set the maximum number of lines
              minLines: 4, // Set the minimum number of lines
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                sendTextToServer();
              },
              child: const Text('Send'),
            ),
            SizedBox(height: 20),
            if (audioUrl.isNotEmpty) AudioPlayerWidget(audioUrl: audioUrl),
          ],
        ),
      ),
    );
  }
}

class AudioPlayerWidget extends StatelessWidget {
  final String audioUrl;

  AudioPlayerWidget({required this.audioUrl});

  @override
  Widget build(BuildContext context) {
    final audioPlayer = AudioPlayer();

    return Column(
      children: [
        Text('Received Audio:'),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () async {
            await audioPlayer.setSource(DeviceFileSource(audioUrl));
            await audioPlayer.resume(); // Play the audio
          },
          child: Text('Play Audio'),
        ),
      ],
    );
  }
}
