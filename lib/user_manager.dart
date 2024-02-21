// user_manager.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class UserManager {
  static Future<String> getOrCreateUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    if (userId == null) {
      final uuid = Uuid();
      userId = uuid.v4(); // Generates a new UUID
      await prefs.setString('userId', userId);
    }
    return userId;
  }
}
