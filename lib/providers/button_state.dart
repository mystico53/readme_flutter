import 'package:flutter/foundation.dart';

class ButtonState with ChangeNotifier {
  bool _isEnabled = true;

  bool get isEnabled => _isEnabled;

  void disableButton() {
    _isEnabled = false;
    notifyListeners();
  }

  void enableButton() {
    _isEnabled = true;
    notifyListeners();
  }
}
