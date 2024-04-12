import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:readme_app/views/webview.dart';
import '../services/intent_service.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../view_models/user_id_viewmodel.dart';

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
      if (_sharedFiles.isNotEmpty) {
        String firstLine = _sharedFiles[0].path;
        if (isValidUrl(firstLine)) {
          print("url found in first line");
          Future.delayed(const Duration(milliseconds: 500), () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChangeNotifierProvider(
                  create: (context) => UserIdViewModel()..initUserId(),
                  child: WebViewPage(url: firstLine),
                ),
              ),
            );
          });
        } else {
          notifyListeners();
        }
      }
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
    return Uri.parse(url).isAbsolute;
  }
}
