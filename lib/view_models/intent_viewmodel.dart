import 'dart:async';

import 'package:flutter/material.dart';
import '../services/intent_service.dart'; // Adjust the import path based on your project structure
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class IntentViewModel with ChangeNotifier {
  final IntentService _intentService = IntentService();
  late StreamSubscription<List<SharedMediaFile>> _intentSub;
  List<SharedMediaFile> _sharedFiles = [];
  String _sharedContent = '';

  List<SharedMediaFile> get sharedFiles => _sharedFiles;
  String get sharedContent => _sharedContent;

  void startListeningForIntents() {
    // Debug message to indicate that the listening for intents has started
    print("Starting to listen for shared intents...");

    _intentSub = _intentService.getSharedFilesStream().listen((files) {
      // Debug message to log the files received
      print("Received shared files: ${files.length} files");

      _sharedFiles = files;
      notifyListeners();

      // Debug message after notifying listeners about the new files
      print("Listeners notified of new shared files.");
    }, onError: (err) {
      // Existing error message
      print("Error listening for intents: $err");
    });

    // Debug message to confirm the subscription has been created
    print("Subscription to shared files stream created.");
  }

  Future<void> loadInitialSharedFiles() async {
    // Debug message before loading initial shared files
    print("Loading initial shared files...");

    _sharedFiles = await _intentService.getInitialSharedFiles();

    // Debug message after loading the files to indicate success and how many files were loaded
    print("Loaded initial shared files: ${_sharedFiles.length} files");

    notifyListeners();

    // Debug message after notifying listeners about the loaded files
    print("Listeners notified of initially loaded shared files.");
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
}
