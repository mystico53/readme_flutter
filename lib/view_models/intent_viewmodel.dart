import 'dart:async';

import 'package:flutter/material.dart';
import '../services/intent_service.dart'; // Adjust the import path based on your project structure
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class IntentViewModel with ChangeNotifier {
  final IntentService _intentService = IntentService();
  late StreamSubscription<List<SharedMediaFile>> _intentSub;
  List<SharedMediaFile> _sharedFiles = [];

  List<SharedMediaFile> get sharedFiles => _sharedFiles;

  void startListeningForIntents() {
    _intentSub = _intentService.getSharedFilesStream().listen((files) {
      _sharedFiles = files;
      notifyListeners();
    }, onError: (err) {
      print("Error listening for intents: $err");
    });
  }

  Future<void> loadInitialSharedFiles() async {
    _sharedFiles = await _intentService.getInitialSharedFiles();
    notifyListeners();
  }

  void resetIntent() {
    _intentService.resetIntent();
  }

  @override
  void dispose() {
    _intentSub.cancel();
    super.dispose();
  }
}
