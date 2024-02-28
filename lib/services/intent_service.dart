import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class IntentService {
  Future<List<SharedMediaFile>> getInitialSharedFiles() async {
    try {
      final files = await ReceiveSharingIntent.getInitialMedia();
      return files;
    } catch (e) {
      print("Error getting initial shared files: $e");
      return [];
    }
  }

  Stream<List<SharedMediaFile>> getSharedFilesStream() {
    return ReceiveSharingIntent.getMediaStream();
  }

  void resetIntent() {
    ReceiveSharingIntent.reset();
  }
}
