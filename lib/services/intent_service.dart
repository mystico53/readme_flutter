import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:async';

class IntentService {
  StreamSubscription? _intentSub;

  Future<List<SharedMediaFile>> getInitialSharedFiles() async {
    print("IntentService: Getting initial shared files");
    final files = await ReceiveSharingIntent.instance.getInitialMedia();
    print("IntentService: Received ${files.length} initial shared files");
    return files;
  }

  Stream<List<SharedMediaFile>> getSharedFilesStream() {
    print("IntentService: Getting shared files stream");
    return ReceiveSharingIntent.instance.getMediaStream();
  }

  void resetIntent() {
    // No need to reset in the new version, as the library handles it internally
  }

  void startListening() {
    print("IntentService: Starting to listen for shared files");
    _intentSub = getSharedFilesStream().listen((List<SharedMediaFile> files) {
      print("IntentService: Received ${files.length} shared files");
      // Handle received files
    });
  }

  void dispose() {
    _intentSub?.cancel();
  }
}
