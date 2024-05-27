import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/voice_model.dart';
import '../view_models/generate_dialog_viewmodel.dart';
import '../view_models/intent_viewmodel.dart';
import 'dart:async';
import '../view_models/user_id_viewmodel.dart';
import '../widgets/voice_selection_widget.dart';

class GenerateDialog extends StatefulWidget {
  const GenerateDialog({super.key});

  @override
  GenerateDialogState createState() => GenerateDialogState();
}

class GenerateDialogState extends State<GenerateDialog> {
  final textController = TextEditingController();
  final scrollController = ScrollController();
  String audioUrl = '';
  String rawIntent = '';

  @override
  void initState() {
    super.initState();

    final intentViewModel =
        Provider.of<IntentViewModel>(context, listen: false);
    intentViewModel.addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            textController.text =
                intentViewModel.sharedFiles.map((file) => file.path).join("\n");
          });
        }
      });
    });

    textController.addListener(() {
      Provider.of<GenerateDialogViewModel>(context, listen: false)
          .updateCharacterCount(textController.text.length);
    });

    if (intentViewModel.sharedFiles.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            textController.text =
                intentViewModel.sharedFiles.map((file) => file.path).join("\n");
          });
        }
      });
    } else {
      print("No shared files are available.");
    }

    // Ensure toggles are on by default
    Provider.of<GenerateDialogViewModel>(context, listen: false)
        .toggleCleanAI(true);
    Provider.of<GenerateDialogViewModel>(context, listen: false)
        .toggleCleanText(true);
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
      backgroundColor: Color(0xFFFFEFC3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Stack(
                children: [
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Create your Lisme',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4B473D),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      color: const Color(0xFF4B473D),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                constraints: BoxConstraints(
                  minHeight: 50.0, // Minimum height for the TextField
                  maxHeight: 200.0, // Maximum height for the TextField
                ),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Color(0xFF4B473D),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.zero,
                ),
                child: TextField(
                  controller: textController,
                  scrollController: scrollController,
                  style: const TextStyle(color: Color(0xFF4B473D)),
                  decoration: const InputDecoration(
                    labelText: 'Selected text:',
                    labelStyle: TextStyle(color: Color(0xFF4B473D)),
                    border: InputBorder.none,
                  ),
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(1.0),
                child: Consumer<GenerateDialogViewModel>(
                  builder: (context, viewModel, child) {
                    return Text(
                      'Character Count: ${viewModel.characterCount}',
                      style: const TextStyle(color: Color(0xFF4B473D)),
                    );
                  },
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Expanded Voice Selection Widget
                    VoiceSelectionWidget(
                      onSelectedVoiceChanged: (VoiceModel voice) {
                        print("Updating selected voice to: ${voice.name}");
                        Provider.of<GenerateDialogViewModel>(context,
                                listen: false)
                            .updateSelectedVoice(voice);
                      },
                    ),
                    const SizedBox(height: 16.0),
                    /*
                    Row(
                      children: [
                        const Text(
                          "Summarize with AI",
                          style: TextStyle(color: Color(0xFF4B473D)),
                        ),
                        const Spacer(),
                        Checkbox(
                          value: Provider.of<GenerateDialogViewModel>(context)
                              .isCleanAIToggled,
                          onChanged: (bool? value) {
                            Provider.of<GenerateDialogViewModel>(context,
                                    listen: false)
                                .toggleCleanAI(value ?? false);
                          },
                          activeColor: const Color(0xFF4B473D),
                          checkColor: const Color(0xFFFFEFC3),
                          side: const BorderSide(
                            color: Color(0xFF4B473D),
                            width: 2.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        const Text(
                          "Clean Text",
                          style: TextStyle(color: Color(0xFF4B473D)),
                        ),
                        const Spacer(),
                        Checkbox(
                          value: Provider.of<GenerateDialogViewModel>(context)
                              .iscleanTextToggled,
                          onChanged: (bool? value) {
                            Provider.of<GenerateDialogViewModel>(context,
                                    listen: false)
                                .toggleCleanText(value ?? false);
                          },
                          activeColor: const Color(0xFF4B473D),
                          checkColor: const Color(0xFFFFEFC3),
                          side: const BorderSide(
                            color: Color(0xFF4B473D),
                            width: 2.0,
                          ),
                        ),
                      ],
                    ),
                    */
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Consumer<GenerateDialogViewModel>(
                builder: (context, viewModel, child) => ElevatedButton(
                  onPressed: () async {
                    String userId = await _getUserId(context);
                    viewModel.generateAndCheckAudio(
                      textController.text,
                      viewModel.currentSelectedVoice,
                      userId,
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: const Color(0xFFFFEFC3),
                    backgroundColor: const Color(0xFF4B473D),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero),
                  ),
                  child: const Text('Create'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
