import 'package:flutter/material.dart';
import '../services/clean_text.dart';

class TextCleanerViewModel with ChangeNotifier {
  bool _isCleanButtonEnabled = true;

  bool get isCleanButtonEnabled => _isCleanButtonEnabled;

  void disableCleanButton() {
    _isCleanButtonEnabled = false;
    notifyListeners();
  }

  void enableCleanButton() {
    _isCleanButtonEnabled = true;
    notifyListeners();
  }

  Future<void> cleanText(
      String text, TextEditingController textController) async {
    disableCleanButton();
    try {
      String cleanedText = await CleanTextService.cleanText(text);
      textController.text = cleanedText;
    } catch (e) {
      print("Error during text cleaning: $e");
      // Optionally handle the error more gracefully here
    }
    enableCleanButton();
  }
}
