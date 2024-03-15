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
  GenerateDialogViewModel(this.userId) {
    listenToFirestoreChanges();
  }

  final String userId;
  String _response = '';
  int characterCount = 0;

  String get response => _response;
  VoiceModel? get currentSelectedVoice => _currentSelectedVoice;
  VoiceModel? _currentSelectedVoice;

  // Clean AI Switch Toggle
  bool get isCleanAIToggled => _isCleanAIToggled;
  bool _isCleanAIToggled = false;

  void toggleCleanAI(bool value) {
    _isCleanAIToggled = value;
    notifyListeners();
  }

  Future<void> generateAndCheckAudio(
    String text,
    VoiceModel? selectedVoice,
    String userId,
  ) async {
    final fileId = "${IdManager.generateAudioId()}.wav";

    try {
      await FirestoreService()
          .createFirestoreDocument(fileId, 'initiating', userId);
      text = await ProcessTextService.processRawIntent(text);
      print("Debug: Text from Process Text Service: $text");
      await GenerateTitleService.generateTitle(text, fileId, userId);

      if (_isCleanAIToggled) {
        await FirestoreService()
            .updateFirestoreDocumentStatus(fileId, 'cleaning', userId);
        text = await CleanTextService.cleanText(text);
        await FirestoreService()
            .updateFirestoreDocumentStatus(fileId, 'cleaned', userId);
      }

      print('Sending text to server:');
      print(' Text: $text');
      print(' User ID: $userId');
      print(' Selected Voice: ${selectedVoice?.name ?? 'Default'}');
      print(' File ID: $fileId');

      var sendResult = await TextToGoogleTTS.sendTextToServer(
        text,
        userId,
        selectedVoice,
        fileId,
      );
      print('Send result: $sendResult');

      if (!sendResult['success']) {
        print(' Server responded with an error');
        _response = sendResult['error'] ?? 'Failed to send text to server.';
        await FirestoreService().updateFirestoreDocumentStatus(
            fileId, 'error, no text sent', userId);
      }

      if (sendResult['success']) {
        var checkResult = await TextToGoogleTTS.checkTTSStatus(fileId, userId);
        if (checkResult['success']) {
          _response = checkResult['response'];
        } else {
          _response = checkResult['error'];
          await FirestoreService()
              .updateFirestoreDocumentStatus(fileId, 'error', userId);
        }
      }
    } catch (e) {
      _response = 'Error during text-to-speech processing: $e';
      await FirestoreService()
          .updateFirestoreDocumentStatus(fileId, 'error', userId);
    } finally {
      notifyListeners();
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
    return totalCost.toStringAsFixed(4);
  }

  void listenToFirestoreChanges() {
    final firestoreService = FirestoreService();
    firestoreService.listenToAudioFileChanges(userId, (documentSnapshot) {
      notifyListeners();
    });
  }
}
