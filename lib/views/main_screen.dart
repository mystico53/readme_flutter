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
import '../view_models/text_cleaner_viewmodel.dart';
import '../view_models/text_to_googleTTS_viewmodel.dart';
import '../widgets/audio_files_list.dart';
import '../widgets/audio_player_widget.dart';
import '../widgets/voice_selection_widget.dart';

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

  @override
  void dispose() {
    textController.removeListener(_updateCharacterCount);
    textController.dispose();
    _pollingTimer?.cancel();
    _intentSub.cancel();
    super.dispose();
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
                  Consumer<TextToGoogleTTSViewModel>(
                    builder: (context, viewModel, child) => ElevatedButton(
                      onPressed: viewModel.isGenerateButtonEnabled
                          ? () async {
                              // Assuming you have `textController`, `userId`, and `selectedVoice` available
                              await viewModel.generateAndCheckAudio(
                                  textController.text,
                                  userId,
                                  _currentSelectedVoice);
                            }
                          : null,
                      child: const Text('Generate Audio'),
                    ),
                  ),
                ],
              ),
            ),
            VoiceSelectionWidget(onSelectedVoiceChanged: _updateSelectedVoice),
            const SizedBox(width: 10), // Spacing between buttons
            // Using Consumer to rebuild the button based on ButtonState
            Consumer<TextCleanerViewModel>(
              builder: (context, viewModel, child) => ElevatedButton(
                onPressed: viewModel.isCleanButtonEnabled
                    ? () async {
                        // Directly call the cleanText method from your ViewModel
                        await viewModel.cleanText(
                            textController.text, textController);
                      }
                    : null,
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
