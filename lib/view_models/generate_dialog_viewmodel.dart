import 'package:flutter/foundation.dart';
import '../models/voice_model.dart';

class GenerateDialogViewModel with ChangeNotifier {
  String userId = '';
  VoiceModel? _currentSelectedVoice;
  int characterCount = 0;

  VoiceModel? get currentSelectedVoice => _currentSelectedVoice;

  void updateSelectedVoice(VoiceModel voice) {
    _currentSelectedVoice = voice;
    notifyListeners();
  }

  void updateCharacterCount(int count) {
    characterCount = count;
    notifyListeners();
  }

  String calculateEstimatedCost() {
    double costPerCharacter = 0.000016;
    double totalCost = characterCount * costPerCharacter;
    return totalCost.toStringAsFixed(4); // Format to 2 decimal places
  }
}
