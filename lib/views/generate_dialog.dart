import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/voice_model.dart';
import '../view_models/generate_dialog_viewmodel.dart';
import '../view_models/intent_viewmodel.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import '../view_models/user_id_viewmodel.dart';
import '../widgets/voice_selection_widget.dart';

class GenerateDialog extends StatefulWidget {
  const GenerateDialog({super.key});

  @override
  GenerateDialogState createState() => GenerateDialogState();
}

class GenerateDialogState extends State<GenerateDialog> {
  // Add your state variables here if needed
  //VoiceModel? _currentSelectedVoice;
  final textController = TextEditingController();
  final scrollController = ScrollController();
  String audioUrl = '';
  String rawIntent = '';

  @override
  void initState() {
    super.initState();

    // Accessing IntentViewModel from the dialog's build context
    final intentViewModel =
        Provider.of<IntentViewModel>(context, listen: false);
    intentViewModel.addListener(() {
      // This ensures we're not calling setState during the build phase.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            textController.text =
                //intentViewModel.sharedFiles.map((file) => file.path).join(", ");
                intentViewModel.sharedFiles.map((file) => file.path).join("\n");
          });
        }
      });
    });

    textController.addListener(() {
      // Update the character count in the view model
      Provider.of<GenerateDialogViewModel>(context, listen: false)
          .updateCharacterCount(textController.text.length);
    });

    // Immediately check if there are any shared files
    if (intentViewModel.sharedFiles.isNotEmpty) {
      // If there are shared files, update the dialog's state accordingly

      // For example, you might want to prepopulate some UI elements with this data
      // This is just an example, replace it with your actual logic
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            // Assuming you have a TextEditingController for displaying the file paths
            textController.text =
                //intentViewModel.sharedFiles.map((file) => file.path).join(", ");
                intentViewModel.sharedFiles.map((file) => file.path).join("\n");
          });
        }
      });
    } else {
      print("No shared files are available.");
      // Handle the case where no shared files are available
    }
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  Future<String> _getUserId(BuildContext context) async {
    final userIdViewModel =
        Provider.of<UserIdViewModel>(context, listen: false);
    return userIdViewModel.userId;
  }

  @override
  Widget build(BuildContext context) {
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
                    child: const Icon(Icons.paste),
                  ),
                  const SizedBox(width: 10), // Spacing between buttons
                  OutlinedButton(
                    onPressed: () {
                      textController.clear();
                    },
                    child: const Icon(Icons.clear),
                  ),
                  const SizedBox(width: 10), // Spacing between buttons
                  Consumer<GenerateDialogViewModel>(
                    builder: (context, viewModel, child) => ElevatedButton(
                      onPressed: () async {
                        String userId = await _getUserId(context);
                        // Initiate the audio generation process
                        viewModel.generateAndCheckAudio(
                          textController.text,
                          viewModel.currentSelectedVoice,
                          userId,
                        );
                        // Close the dialog immediately
                        Navigator.pop(context);
                      },
                      child: const Text('Generate Audio'),
                    ),
                  ),
                ],
              ),
            ),

            VoiceSelectionWidget(
              onSelectedVoiceChanged: (VoiceModel voice) {
                // Use Provider to access the ViewModel and call updateSelectedVoice
                print("Updating selected voice to: ${voice.name}");
                Provider.of<GenerateDialogViewModel>(context, listen: false)
                    .updateSelectedVoice(voice);
              },
            ),

            const SizedBox(width: 10), // Spacing between buttons
            SwitchListTile(
              title: Text("Clean with AI"),
              value: Provider.of<GenerateDialogViewModel>(context)
                  .isCleanAIToggled,
              onChanged: (bool value) {
                Provider.of<GenerateDialogViewModel>(context, listen: false)
                    .toggleCleanAI(value);
              },
            )
          ],
        ),
      ),
    );
  }
}
