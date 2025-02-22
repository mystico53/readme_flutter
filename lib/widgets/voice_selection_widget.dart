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
    // English voices
    VoiceModel(
        name: "🇺🇸 Franky's Voice (HD)",
        languageCode: "en-US",
        voiceName: "en-US-Studio-Q",
        speakingRate: 0.9),
    VoiceModel(
        name: "🇺🇸 Serene's Voice (HD)",
        languageCode: "en-US",
        voiceName: "en-US-Studio-O",
        speakingRate: 0.85),
    VoiceModel(
        name: "🇺🇸 Craig's Voice (News)",
        languageCode: "en-US",
        voiceName: "en-US-Standard-D",
        speakingRate: 0.85),
    VoiceModel(
        name: "🇺🇸 Gordon's Voice (Low)",
        languageCode: "en-US",
        voiceName: "en-US-Neural2-J",
        speakingRate: 0.9),
    VoiceModel(
        name: "🇺🇸 Malcolm's Voice (Poly)",
        languageCode: "en-US",
        voiceName: "en-US-Polyglot-1",
        speakingRate: 0.85),
    VoiceModel(
        name: "🇬🇧 Bishop's Voice (Low)",
        languageCode: "en-GB",
        voiceName: "en-GB-Neural2-D",
        speakingRate: 0.85),
    // German voices
    VoiceModel(
        name: "🇩🇪 Stefan's Voice (HD)",
        languageCode: "de-DE",
        voiceName: "de-DE-Studio-B",
        speakingRate: 1.0),
    VoiceModel(
        name: "🇩🇪 Jutta's Voice (HD)",
        languageCode: "de-DE",
        voiceName: "de-DE-Studio-C",
        speakingRate: 1.0),
    VoiceModel(
        name: "🇩🇪 Sabine's Voice (Low)",
        languageCode: "de-DE",
        voiceName: "de-DE-Neural2-C",
        speakingRate: 1.0),
    VoiceModel(
        name: "🇩🇪 Rüdiger's Voice (Poly)",
        languageCode: "de-DE",
        voiceName: "de-DE-Polyglot-1",
        speakingRate: 1.0),
  ];

  VoiceModel? selectedVoice;

  @override
  void initState() {
    super.initState();
    // Initialize selectedVoice with Franky's VoiceModel
    selectedVoice = voices.firstWhere(
        (voice) => voice.name == "🇺🇸 Franky's Voice (Elite)",
        orElse: () => voices.first);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Color(0xFFFFEFC3),
      ),
      child: Container(
        width: 200,
        child: DropdownButton<VoiceModel>(
          value: selectedVoice,
          hint: Text(
            "Select a voice",
            style: TextStyle(color: Color(0xFF4B473D), fontSize: 16),
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
          style: TextStyle(color: Color(0xFFFFEFC3), fontSize: 16),
          underline: SizedBox(),
          isDense: true,
          isExpanded: true,
        ),
      ),
    );
  }
}
