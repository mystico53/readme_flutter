import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:readme_app/utils/app_config.dart';

class ProcessTextService {
  static Future<void> rawIntentToServer(String text) async {
    try {
      final url = AppConfig.processRawIntentUrl;

      final response = await http.post(
        url as Uri, // Use url directly as Uri
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'text': text}),
      );

      if (response.statusCode == 200) {
        print('Raw Intent sent to server successfully');
      } else {
        print(
            'Error sending text to server. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending text to server: $e');
    }
  }
}
