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
  String lookForURL(String content) {
    // Debug: Print initial received content
    print("Initial content received: $content");

    // Check if the content starts with a double quote character
    if (content.startsWith('"')) {
      print("Content starts with a double quote, returning original content.");
      return '';
    }

    // Extract the URL from the shared content string
    print("Extracting URL from content...");
    final regex = RegExp(r'(https?://\S+)');
    final match = regex.firstMatch(content);
    if (match != null) {
      final url = match.group(1);
      print("URL extracted: $url");
      // Debug: Print the extracted URL
      if (isValidUrl(url!)) {
        print("Valid URL found: $url");
        // Debug: Print updated content
        return url;
      } else {
        print("Extracted URL is invalid, trimming and re-evaluating...");
        // Debug: Print invalid URL notice
        // Try to extract the URL after removing any leading/trailing whitespace
        final trimmedContent = content.trim();
        print("Trimmed content: $trimmedContent");
        // Debug: Print trimmed content
        final trimmedMatch = regex.firstMatch(trimmedContent);
        if (trimmedMatch != null) {
          final trimmedUrl = trimmedMatch.group(1);
          print("Trimmed URL extracted: $trimmedUrl");
          // Debug: Print the trimmed URL
          if (isValidUrl(trimmedUrl!)) {
            print("Valid trimmed URL found: $trimmedUrl");
            // Debug: Print updated content
            return trimmedUrl;
          } else {
            print("Trimmed URL is still invalid, returning empty string.");
            // Debug: Print empty update
            return '';
          }
        } else {
          print(
              "No URL could be extracted from trimmed content, returning empty string.");
          // Debug: Print empty update
          return '';
        }
      }
    } else {
      print("No URL found in initial content, returning empty string.");
      // Debug: Print empty update
      return '';
    }
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
