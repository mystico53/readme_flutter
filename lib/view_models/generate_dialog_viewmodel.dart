import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/voice_model.dart';
import '../services/clean_text.dart';
import '../services/create_firestore_document_service.dart';
import '../services/text_to_googleTTS.dart';
import '../utils/id_manager.dart';

class OperationStatus {
  final String fileId;
  String status;

  OperationStatus({required this.fileId, required this.status});
}

class GenerateDialogViewModel with ChangeNotifier {
  GenerateDialogViewModel() {
    listenToFirestoreChanges();
  }

  String userId = '';
  String _response = '';
  int characterCount = 0;
  String get response => _response;

  VoiceModel? get currentSelectedVoice => _currentSelectedVoice;
  VoiceModel? _currentSelectedVoice;

  // Generate Button
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

  // Clean AI Switch Toggle
  bool get isCleanAIToggled => _isCleanAIToggled;
  bool _isCleanAIToggled = true;

  void toggleCleanAI(bool value) {
    _isCleanAIToggled = value;
    notifyListeners();
  }

  // Add a new property to track operations and their statuses
  List<OperationStatus> operations = [];

  Future<void> generateAndCheckAudio(
      String text, String userId, VoiceModel? selectedVoice) async {
    _isGenerateButtonEnabled =
        false; // Disable the button when the process starts
    final fileId =
        "${IdManager.generateAudioId()}.wav"; // Generate fileId immediately
    final operationStatus =
        OperationStatus(fileId: fileId, status: "File ID created");
    operations.add(operationStatus); // Add the operation to the list
    notifyListeners();
    try {
      await FirestoreService().createFirestoreDocument(fileId);
      operationStatus.status = "Firestore document created";
      notifyListeners();

      if (_isCleanAIToggled) {
        text = await CleanTextService.cleanText(text);
      }

      operationStatus.status = "Cleaned Text";
      notifyListeners(); // Update status

      var sendResult = await TextToGoogleTTS.sendTextToServer(
          text, userId, selectedVoice, fileId);
      if (sendResult['success']) {
        operationStatus.status = "Google TTS Started";
        notifyListeners();
        var checkResult = await TextToGoogleTTS.checkTTSStatus(fileId);
        if (checkResult['success']) {
          operationStatus.status = "TTS File generated";
          _response = checkResult['response'];
        } else {
          operationStatus.status = "Error: ${checkResult['error']}";
          _response = checkResult['error'];
        }
      } else {
        operationStatus.status = "Error: ${sendResult['error']}";
        _response = sendResult['error'] ?? 'Failed to send text to server.';
      }
    } catch (e) {
      operationStatus.status = "Error: $e";
      _response = 'Error during text-to-speech processing: $e';
    } finally {
      _isGenerateButtonEnabled =
          true; // Re-enable the button after the process completes or fails
      notifyListeners(); // Notify listeners to update the UI based on the new state
    }
  }

  void updateSelectedVoice(VoiceModel voice) {
    _currentSelectedVoice = voice;
    print("Updating voice to: ${_currentSelectedVoice?.name}");
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

  void listenToFirestoreChanges() {
    final firestoreService = FirestoreService();
    firestoreService.listenToAudioFileChanges((documentSnapshot) {
      // Rebuild the UI to reflect the changes in Firestore documents
      notifyListeners();
    });
  }
}
