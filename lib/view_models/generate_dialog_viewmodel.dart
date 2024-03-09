import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/voice_model.dart';
import '../services/clean_text.dart';
import '../services/create_firestore_document_service.dart';
import '../services/generate_title_service.dart';
import '../services/process_text_service.dart';
import '../services/text_to_googleTTS.dart';
import '../utils/id_manager.dart';

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

  // Clean AI Switch Toggle
  bool get isCleanAIToggled => _isCleanAIToggled;
  bool _isCleanAIToggled = true;

  void toggleCleanAI(bool value) {
    _isCleanAIToggled = value;
    notifyListeners();
  }

  Future<void> generateAndCheckAudio(
      String text, String userId, VoiceModel? selectedVoice) async {
    final fileId =
        "${IdManager.generateAudioId()}.wav"; // Generate fileId immediately

    try {
      await FirestoreService().createFirestoreDocument(fileId, 'pending');

      await GenerateTitleService.generateTitle(text, fileId);

      if (_isCleanAIToggled) {
        await FirestoreService()
            .updateFirestoreDocumentStatus(fileId, 'cleaning');
        text = await CleanTextService.cleanText(text);
        await FirestoreService()
            .updateFirestoreDocumentStatus(fileId, 'cleaned');
      }

      print('Sending text to server:');
      print('  Text: $text');
      print('  User ID: $userId');
      print('  Selected Voice: ${selectedVoice?.name ?? 'Default'}');
      print('  File ID: $fileId');

      var sendResult = await TextToGoogleTTS.sendTextToServer(
          text, userId, selectedVoice, fileId);

      print('Send result: $sendResult');
      if (!sendResult['success']) {
        print(' Server responded with an error');
        _response = sendResult['error'] ?? 'Failed to send text to server.';
        await FirestoreService()
            .updateFirestoreDocumentStatus(fileId, 'error, no text sent');
      }
      if (sendResult['success']) {
        var checkResult = await TextToGoogleTTS.checkTTSStatus(fileId);
        if (checkResult['success']) {
          _response = checkResult['response'];
        } else {
          _response = checkResult['error'];
          await FirestoreService()
              .updateFirestoreDocumentStatus(fileId, 'error');
        }
      }
    } catch (e) {
      _response = 'Error during text-to-speech processing: $e';
      await FirestoreService().updateFirestoreDocumentStatus(fileId, 'error');
    } finally {
      notifyListeners(); // Notify listeners to update the UI based on the new state
    }
  }

  Future<void> sendTextToServer(String text) async {
    try {
      await ProcessTextService.rawIntentToServer(text);
      // Handle the success case
      print('Raw Intent sent to server successfully');
    } catch (e) {
      // Handle the error case
      print('Error sending text to server: $e');
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
    return totalCost.toStringAsFixed(4); // Format to 4 decimal places
  }

  void listenToFirestoreChanges() {
    final firestoreService = FirestoreService();
    firestoreService.listenToAudioFileChanges((documentSnapshot) {
      // Rebuild the UI to reflect the changes in Firestore documents
      notifyListeners();
    });
  }
}
