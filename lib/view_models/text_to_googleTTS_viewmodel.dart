import 'package:flutter/material.dart';
import 'package:readme_app/models/voice_model.dart';
import 'package:readme_app/services/text_to_googleTTS.dart';

class TextToGoogleTTSViewModel with ChangeNotifier {
  String _response = '';
  String? _audioUrl;

  // Getter methods for UI components to bind to
  String get response => _response;
  String? get audioUrl => _audioUrl;

  bool _isGenerateButtonEnabled = true;

  bool get isGenerateButtonEnabled => _isGenerateButtonEnabled;

  void disableGenerateButton() {
    _isGenerateButtonEnabled = false;
    notifyListeners();
  }

  void enableGenerateButton() {
    _isGenerateButtonEnabled = true;
    notifyListeners();
  }

  Future<void> generateAndCheckAudio(
      String text, String userId, VoiceModel? selectedVoice) async {
    disableGenerateButton(); // Disable the button when the process starts
    try {
      var sendResult =
          await TextToGoogleTTS.sendTextToServer(text, userId, selectedVoice);
      if (sendResult['success']) {
        var fileId = sendResult['fileId'] as String; // Casting is necessary
        var checkResult = await TextToGoogleTTS.checkTTSStatus(fileId);
        if (checkResult['success']) {
          _audioUrl = checkResult['audioUrl'];
          _response = checkResult['response'];
        } else {
          _response = checkResult['error'];
        }
      } else {
        _response = sendResult['error'] ?? 'Failed to send text to server.';
      }
    } catch (e) {
      _response = 'Error during text-to-speech processing: $e';
    } finally {
      enableGenerateButton(); // Re-enable the button after the process completes or fails
      notifyListeners(); // Notify listeners to update the UI based on the new state
    }
  }
}
