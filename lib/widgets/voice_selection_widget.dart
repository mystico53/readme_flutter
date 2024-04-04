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
        name: "🇺🇸 Craig (News)",
        languageCode: "en-US",
        voiceName: "en-US-News-N",
        speakingRate: 0.85),
    VoiceModel(
        name: "🇺🇸 Gordon",
        languageCode: "en-US",
        voiceName: "en-US-Neural2-J",
        speakingRate: 0.9),
    VoiceModel(
        name: "🇺🇸 Malcolm (Poly)",
        languageCode: "en-US",
        voiceName: "en-US-Polyglot-1",
        speakingRate: 0.85),
    VoiceModel(
        name: "🇺🇸 Serene (Elite)",
        languageCode: "en-US",
        voiceName: "en-US-Studio-O",
        speakingRate: 0.85),
    VoiceModel(
        name: "🇺🇸 Franky (Elite)",
        languageCode: "en-US",
        voiceName: "en-US-Studio-Q",
        speakingRate: 0.9),
    VoiceModel(
        name: "🇬🇧 Bishop",
        languageCode: "en-GB",
        voiceName: "en-GB-Neural2-D",
        speakingRate: 0.85),
    VoiceModel(
        name: "🇩🇪 Sabine",
        languageCode: "de-DE",
        voiceName: "de-DE-Neural2-C",
        speakingRate: 1.0),
    VoiceModel(
        name: "🇩🇪 Rüdiger (Poly)",
        languageCode: "de-DE",
        voiceName: "de-DE-Polyglot-1",
        speakingRate: 1.0),
    VoiceModel(
        name: "🇩🇪 Stefan (Elite)",
        languageCode: "de-DE",
        voiceName: "de-DE-Studio-B",
        speakingRate: 1.0),
    VoiceModel(
        name: "🇩🇪 Jutta (Elite)",
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
    selectedVoice = voices.firstWhere(
        (voice) => voice.name == "🇺🇸 Craig (News)",
        orElse: () => voices.first);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Color(0xFFFFEFC3),
      ),
      child: Container(
        width: 200, // Set your desired width here
        child: DropdownButton<VoiceModel>(
          value: selectedVoice,
          hint: Text(
            "Select a voice",
            style: TextStyle(color: Color(0xFF4B473D)),
          ),
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
              child: Text(
                voice.name,
                style: TextStyle(color: Color(0xFF4B473D)),
              ),
            );
          }).toList(),
          iconEnabledColor: Color(0xFF4B473D),
          style: TextStyle(color: Color(0xFF4B473D)),
          underline: SizedBox(),
          isDense: true,
          isExpanded:
              true, // Ensure the dropdown expands to fill the container width
        ),
      ),
    );
  }
}
