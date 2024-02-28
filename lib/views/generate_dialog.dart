import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/voice_model.dart';
import '../view_models/generate_dialog_viewmodel.dart';
import '../view_models/intent_viewmodel.dart';
import 'dart:async';
import 'package:flutter/services.dart';

import '../view_models/text_cleaner_viewmodel.dart';
import '../view_models/text_to_googleTTS_viewmodel.dart';
import '../view_models/user_id_viewmodel.dart';
import '../widgets/voice_selection_widget.dart';

class GenerateDialog extends StatefulWidget {
  const GenerateDialog({super.key});

  @override
  GenerateDialogState createState() => GenerateDialogState();
}

class GenerateDialogState extends State<GenerateDialog> {
  // Add your state variables here if needed
  VoiceModel? _currentSelectedVoice;
  final textController = TextEditingController();
  final scrollController = ScrollController();
  String audioUrl = '';

  @override
  void initState() {
    super.initState();
    final intentViewModel =
        Provider.of<IntentViewModel>(context, listen: false);
    // Listen for changes in the ViewModel
    textController.addListener(() {
      // Get the current text length
      int currentTextLength = textController.text.length;
      // Update the ViewModel
      Provider.of<GenerateDialogViewModel>(context, listen: false)
          .updateCharacterCount(currentTextLength);
    });
    intentViewModel.addListener(() {
      // This ensures we're not calling setState during the build phase.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            textController.text =
                intentViewModel.sharedFiles.map((file) => file.path).join(", ");
          });
        }
      });
    });
    intentViewModel.loadInitialSharedFiles();
    intentViewModel.startListeningForIntents();
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<UserIdViewModel>(context).userId;
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Center(
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
              child: Consumer<GenerateDialogViewModel>(
                builder: (context, viewModel, child) {
                  return Text('Character Count: ${viewModel.characterCount}');
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Consumer<GenerateDialogViewModel>(
                builder: (context, viewModel, child) {
                  return Text(
                      'Estimated Costs: \$${viewModel.calculateEstimatedCost()}');
                },
              ),
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
                        Future.delayed(const Duration(milliseconds: 100), () {
                          scrollController.animateTo(
                            scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 200),
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

            VoiceSelectionWidget(
              onSelectedVoiceChanged: (VoiceModel voice) {
                // Use Provider to access the ViewModel and call updateSelectedVoice
                Provider.of<GenerateDialogViewModel>(context, listen: false)
                    .updateSelectedVoice(voice);
              },
            ),

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
          ],
        ),
      ),
    );
  }
}
