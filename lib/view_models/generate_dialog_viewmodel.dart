import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:readme_app/view_models/audioplayer_viewmodel.dart';
import '../models/voice_model.dart';
import '../services/clean_text.dart';
import '../services/create_firestore_document_service.dart';
import '../services/generate_title_service.dart';
import '../services/process_text_service.dart';
import '../services/text_to_googleTTS.dart';
import '../utils/id_manager.dart';
import 'package:just_audio/just_audio.dart';

class GenerateDialogViewModel with ChangeNotifier {
  GenerateDialogViewModel(this.userId) {
    listenToFirestoreChanges();
    _audioPlayerViewModel = AudioPlayerViewModel();
  }

  final String userId;
  late final AudioPlayerViewModel _audioPlayerViewModel;
  String _response = '';
  int characterCount = 0;

  String get response => _response;
  VoiceModel? get currentSelectedVoice => _currentSelectedVoice;
  VoiceModel? _currentSelectedVoice;

  // Clean AI Switch Toggle
  bool get isCleanAIToggled => _isCleanAIToggled;
  bool _isCleanAIToggled = false;
  bool get iscleanTextToggled => _isCleanTextToggled;
  bool _isCleanTextToggled = true;

  void toggleCleanText(bool value) {
    _isCleanTextToggled = value;
    notifyListeners();
  }

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
          .createFirestoreDocument(fileId, 'initiating file', userId);

      if (_isCleanTextToggled) {
        await FirestoreService()
            .updateFirestoreDocumentStatus(fileId, 'processing text', userId);
        text = await ProcessTextService.processRawIntent(text);
      }

      await FirestoreService()
          .updateFirestoreDocumentStatus(fileId, 'generating title', userId);
      await GenerateTitleService.generateTitle(text, fileId, userId);

      if (_isCleanAIToggled) {
        await FirestoreService()
            .updateFirestoreDocumentStatus(fileId, 'summarizing', userId);
        text = await CleanTextService.cleanText(text);
      }

      print('Sending text to server:');
      print(' Text: $text');
      print(' User ID: $userId');
      print(' Selected Voice: ${selectedVoice?.name ?? 'Default'}');
      print(' File ID: $fileId');

      await FirestoreService()
          .updateFirestoreDocumentStatus(fileId, 'generating speech', userId);
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
            fileId, 'error, couldnt send text', userId);
      }

      if (sendResult['success']) {
        var checkResult = await TextToGoogleTTS.checkTTSStatus(fileId, userId);
        if (checkResult['success']) {
          await FirestoreService()
              .updateFirestoreDocumentStatus(fileId, 'ready', userId);
          _response = checkResult['response'];

          // Indicate the start of the process
          print('Starting to retrieve audio URL for fileId: $fileId');

          // Retrieve the audio URL from Firestore
          final audioUrl = await FirestoreService().getAudioUrl(fileId);

          if (audioUrl != null) {
            // Confirm that the audio URL was successfully retrieved
            print(
                'Audio URL retrieved successfully for fileId: $fileId, URL: $audioUrl');

            // Create an instance of AudioPlayer
            final player = AudioPlayer();
            print('AudioPlayer instance created.');

            try {
              // Attempt to load the audio URL
              print('Attempting to load audio from URL: $audioUrl');
              await player.setUrl(audioUrl);
              print('Audio loaded successfully.');

              // Retrieve the duration and print it
              final duration = await player.durationFuture;
              print('Audio duration: $duration');

              // When done, dispose of the player
              await player.dispose();
              print('AudioPlayer disposed.');

              // Update the Firestore document with the audio duration if it's not null
              if (duration != null) {
                await FirestoreService().updateFirestoreDocumentDuration(
                  fileId,
                  duration.inSeconds,
                  userId,
                );
                print('Succes: Audio duration written to firestore');

                // Call the _saveProgress function from AudioPlayerViewModel
                await _audioPlayerViewModel.saveProgress(fileId, Duration.zero);
              } else {
                print('Audio duration is null for fileId: $fileId');
              }
            } catch (e) {
              // If an error occurs, print it
              print('Error loading audio from URL: $audioUrl, Error: $e');
            }
          } else {
            // If the audio URL was not found, print an error message
            print('Audio URL not found for fileId: $fileId');
          }
        } else {
          _response = 'Google TTS Error: ${checkResult['error']}';
          await FirestoreService().updateFirestoreDocumentStatus(
              fileId, 'error: google tts', userId);
          print('Google TTS error: ${checkResult['error']}');
        }
      }
    } catch (e) {
      _response = 'Error during text-to-speech processing: $e';
      await FirestoreService().updateFirestoreDocumentStatus(
          fileId, 'Error during text-to-speech processing', userId);
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
