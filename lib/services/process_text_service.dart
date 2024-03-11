import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:readme_app/utils/app_config.dart';

class ProcessTextService {
  static Future<String> processRawIntent(String text) async {
    print("process raw intent text $text");
    try {
      final url = AppConfig.processRawIntentUrl;
      final response = await http.post(
        url as Uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'text': text}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final processedText = responseData['text'];
        print('Processed Raw Intent received from server:');
        print(processedText);
        return processedText;
      } else {
        print(
            'Error sending raw intent to server. Status code: ${response.statusCode}');
        throw Exception('Failed to process raw intent');
      }
    } catch (e) {
      print('Error processing raw intent: $e');
      throw Exception('Failed to process raw intent');
    }
  }
}
