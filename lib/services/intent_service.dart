import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:async';

class IntentService {
  StreamSubscription? _intentSub;

  Future<List<SharedMediaFile>> getInitialSharedFiles() async {
    // Updated method to get initial media
    final files = await ReceiveSharingIntent.instance.getInitialMedia();
    return files;
  }

  Stream<List<SharedMediaFile>> getSharedFilesStream() {
    // Updated method to get media stream
    return ReceiveSharingIntent.instance.getMediaStream();
  }

  void resetIntent() {
    // No need to reset in the new version, as the library handles it internally
  }

  void startListening() {
    _intentSub = getSharedFilesStream().listen((List<SharedMediaFile> files) {
      // Handle received files
    });
  }

  void dispose() {
    _intentSub?.cancel();
  }
}
