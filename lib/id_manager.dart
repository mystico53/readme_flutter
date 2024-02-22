// user_manager.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class IdManager {
  // Method to get or create a user ID prefixed with "user+"
  static Future<String> getOrCreateUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    if (userId == null) {
      final uuid = Uuid();
      userId = 'user+${uuid.v4()}'; // Generates a new UUID with "user+" prefix
      await prefs.setString('userId', userId);
    }
    return userId;
  }

  // Method to generate a unique ID for audio files prefixed with "audio+"
  static String generateAudioId() {
    final uuid = Uuid();
    return 'audio+${uuid.v4()}'; // Generates a new UUID with "audio+" prefix
  }
}
