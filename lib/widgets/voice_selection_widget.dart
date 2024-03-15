import 'package:flutter/material.dart';

import '/models/voice_model.dart';

class VoiceSelectionWidget extends StatefulWidget {
  final Function(VoiceModel) onSelectedVoiceChanged;
  VoiceSelectionWidget({required this.onSelectedVoiceChanged});
  @override
  _VoiceSelectionWidgetState createState() => _VoiceSelectionWidgetState();
}

class _VoiceSelectionWidgetState extends State<VoiceSelectionWidget> {
  List<VoiceModel> voices = [
    VoiceModel(
        name: "US - Craig",
        languageCode: "en-US",
        voiceName: "en-US-Neural2-J",
        speakingRate: 0.85),
    VoiceModel(
        name: "US - Gordon (Casual)",
        languageCode: "en-US",
        voiceName: "en-US-Casual-K",
        speakingRate: 0.9),
    VoiceModel(
        name: "US - Malcolm (Poly)",
        languageCode: "en-US",
        voiceName: "en-US-Polyglot-1",
        speakingRate: 0.85),
    VoiceModel(
        name: "US - Serene (Elite)",
        languageCode: "en-US",
        voiceName: "en-US-Studio-O",
        speakingRate: 0.85),
    VoiceModel(
        name: "US - Franky (Elite)",
        languageCode: "en-US",
        voiceName: "en-US-Studio-Q",
        speakingRate: 0.9),
    VoiceModel(
        name: "GB - Bishop",
        languageCode: "en-GB",
        voiceName: "en-GB-Neural2-D",
        speakingRate: 0.85),
    VoiceModel(
        name: "DE - Sabine",
        languageCode: "de-DE",
        voiceName: "de-DE-Neural2-C",
        speakingRate: 1.0),
    VoiceModel(
        name: "DE - Rüdiger (Poly)",
        languageCode: "de-DE",
        voiceName: "de-DE-Polyglot-1",
        speakingRate: 1.0),
    VoiceModel(
        name: "DE - Stefan (Elite)",
        languageCode: "de-DE",
        voiceName: "de-DE-Studio-B",
        speakingRate: 1.0),
    VoiceModel(
        name: "DE- Jutta (Elite)",
        languageCode: "de-DE",
        voiceName: "de-DE-Studio-C",
        speakingRate: 1.0)
    // Add more voice options as needed
  ];

  VoiceModel? selectedVoice;

  @override
  void initState() {
    super.initState();
    // Initialize selectedVoice with Craig's VoiceModel
    selectedVoice = voices.firstWhere((voice) => voice.name == "Craig",
        orElse: () => voices.first);
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<VoiceModel>(
      value: selectedVoice,
      hint: Text("Select a voice"),
      onChanged: (VoiceModel? newValue) {
        if (newValue != null) {
          setState(() {
            selectedVoice = newValue;
          });
          widget.onSelectedVoiceChanged(newValue);
        }
      },
      items: voices.map<DropdownMenuItem<VoiceModel>>((VoiceModel voice) {
        return DropdownMenuItem<VoiceModel>(
          value: voice,
          child: Text(voice.name),
        );
      }).toList(),
    );
  }
}
