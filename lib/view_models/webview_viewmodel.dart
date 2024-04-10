import 'package:flutter/material.dart';

class WebViewViewModel with ChangeNotifier {
  String _url = '';

  String get url => _url;

  void setUrl(String newUrl) {
    _url = newUrl;
    notifyListeners();
  }
}
