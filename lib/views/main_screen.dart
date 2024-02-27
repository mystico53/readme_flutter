import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:http/http.dart' as http;

import '../models/voice_model.dart';
import '../utils/app_config.dart';
import '../utils/id_manager.dart';
import '../widgets/audio_files_list.dart';
import '../widgets/audio_player_widget.dart';
import '../widgets/voice_selection_widget.dart';
import '../providers/button_state.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String userId = '';
  late StreamSubscription _intentSub;
  final _sharedFiles = <SharedMediaFile>[];
  VoiceModel? _currentSelectedVoice;
  String _response = 'No data';

  final textController = TextEditingController();
  final scrollController = ScrollController();
  String audioUrl = '';
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _initUser();
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
      });
    }, onError: (err) {
      print("getIntentDataStream error: $err");
    });
    ReceiveSharingIntent.getInitialMedia().then((value) {
      setState(() {
        _sharedFiles.clear();
        _sharedFiles.addAll(value);
        String filesString =
            _sharedFiles.map((f) => f.toMap().toString()).join(", ");
        textController.text = filesString;

        // Tell the library that we are done processing the intent.
        ReceiveSharingIntent.reset();
      });
    });
  }

  void _initUser() async {
    userId = await IdManager.getOrCreateUserId();
    setState(() {});
    print("UserId: $userId");
    // Now you can use the userId for fetching or uploading data to Firestore
  }

  void _updateSelectedVoice(VoiceModel voice) {
    setState(() {
      _currentSelectedVoice = voice;
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
    final fileId = '${IdManager.generateAudioId()}.wav';
    print("fileID: $fileId");

    // Modify this part to include selectedVoice's parameters
    final languageCode = _currentSelectedVoice?.languageCode ??
        'en-US'; // Default to 'en-US' if null
    final voiceName = _currentSelectedVoice?.voiceName ??
        'en-US-Neural2-J'; // Default voice if null
    final speakingRate =
        _currentSelectedVoice?.speakingRate ?? 1.0; // Default voice if null

    var request = http.Request('POST', AppConfig.ttsUrl);
    request.headers.addAll({'Content-Type': 'application/json'});
    request.body = jsonEncode({
      'text': text,
      'fileId': fileId,
      'languageCode': languageCode, // Include language code
      'voiceName': voiceName, // Include voice name
      'speakingRate': speakingRate,
      'userId': userId,
    });

    var streamedResponse =
        await request.send().timeout(const Duration(seconds: 30));

    if (streamedResponse.statusCode == 200) {
      print("Text sent successfully, starting status check.");
      callcheckTTS(fileId); // Now, just start checking status
    } else {
      print('Server responded with error: ${streamedResponse.statusCode}');
    }
  }

  // Function to call the Cloud Function
  Future<void> callcheckTTS(String fileId) async {
    var url = AppConfig.checkTTSUrl(fileId);
    print("url= $url");

    try {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          _response = response.body; // Store the entire response
          // send to audioplayer
          audioUrl = responseData[
              'gcsUri']; // Store just the gcsUri part in the audioUrl state variable
        });
        print(_response);

        // Pass the gcsUri to streamAudioFromUrl
        //streamAudioFromUrl(responseData['gcsUri']);
      } else {
        setState(() {
          _response = 'Error: ${response.reasonPhrase}';
        });
      }
    } catch (e) {
      setState(() {
        _response = 'Error calling cloud function: $e';
      });
    }
  }

  @override
  void dispose() {
    textController.removeListener(_updateCharacterCount);
    textController.dispose();
    _pollingTimer?.cancel();
    _intentSub.cancel();
    super.dispose();
  }

  void cleanWithAI() async {
    print("Disabling button");
    Provider.of<ButtonState>(context, listen: false).disableButton();
    String text = textController.text;

    try {
      String cleanedText = await sendTextToAI(text);
      if (mounted) {
        setState(() {
          textController.text = cleanedText;
        });
        print("Enabling button");
        Provider.of<ButtonState>(context, listen: false).enableButton();
      }
    } catch (e) {
      print("Error during text cleaning: $e");
      if (mounted) {
        Provider.of<ButtonState>(context, listen: false).enableButton();
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lisme - listen to my text'),
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
            VoiceSelectionWidget(onSelectedVoiceChanged: _updateSelectedVoice),
            const SizedBox(width: 10), // Spacing between buttons
            // Using Consumer to rebuild the button based on ButtonState
            Consumer<ButtonState>(
              builder: (context, buttonState, child) => ElevatedButton(
                onPressed: buttonState.isEnabled ? () => cleanWithAI() : null,
                child: const Text('Clean with AI'),
              ),
            ),
            Expanded(
              child: AudioFilesList(
                onAudioSelected: (String url) {
                  setState(() {
                    audioUrl =
                        url; // This will update the audioUrl in MainScreenState and rebuild the widget.
                  });
                },
              ),
            ),
            SizedBox(height: 20),
            if (audioUrl.isNotEmpty) AudioPlayerWidget(audioUrl: audioUrl),
          ],
        ),
      ),
    );
  }
}
