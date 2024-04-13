import 'dart:async';
import 'package:flutter/material.dart';

import '../services/intent_service.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class IntentViewModel with ChangeNotifier {
  final IntentService _intentService = IntentService();
  late StreamSubscription<List<SharedMediaFile>> _intentSub;
  List<SharedMediaFile> _sharedFiles = [];
  String _sharedContent = '';
  String rawIntent = '';

  List<SharedMediaFile> get sharedFiles => _sharedFiles;
  String get sharedContent => _sharedContent;

  void startListeningForIntents(BuildContext context) {
    _intentSub = _intentService.getSharedFilesStream().listen((files) {
      // Debug message to log the files received
      print("Received shared files: ${files.length} files");
      _sharedFiles = files;
      notifyListeners();
    }, onError: (err) {
      print("Error listening for intents: $err");
    });
  }

  Future<void> loadInitialSharedFiles() async {
    _sharedFiles = await _intentService.getInitialSharedFiles();

    // Debug message after loading the files to indicate success and how many files were loaded
    print("Loaded initial shared files: ${_sharedFiles.length} files");

    notifyListeners();
  }

  // Method to update shared content
  void updateSharedContent(String newContent) {
    _sharedContent = newContent;
    notifyListeners(); // Notify any listeners that the shared content has been updated
  }

  void resetIntent() {
    _intentService.resetIntent();
    print("Resetting intent service");
  }

  @override
  void dispose() {
    _intentSub.cancel();
    super.dispose();
  }

  bool isValidUrl(String url) {
    try {
      return Uri.parse(url).isAbsolute &&
          (url.startsWith('http://') || url.startsWith('https://'));
    } catch (e) {
      // Log the error or handle it appropriately if needed
      print('Not a URL format: $e');
      return false;
    }
  }
}
