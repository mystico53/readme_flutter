import 'package:flutter/foundation.dart';
import '../utils/id_manager.dart';

class UserIdViewModel with ChangeNotifier {
  String _userId = '';

  String get userId => _userId;

  // Fetches or creates a new user ID
  Future<void> initUserId() async {
    _userId = await IdManager.getOrCreateUserId();
    notifyListeners(); // Notify listeners about the change
  }

  // Other methods related to the user can be added here
}
