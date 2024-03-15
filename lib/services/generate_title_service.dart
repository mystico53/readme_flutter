import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';

class GenerateTitleService {
  static Future<String> generateTitle(
      String text, String documentId, String userId) async {
    try {
      String generatedTitle = await sendTextToAI(text, documentId, userId);
      return generatedTitle;
    } catch (e) {
      print("Error during title generation: $e");
      return ""; // Return an empty string or an error message
    }
  }

  static Future<String> sendTextToAI(
      String text, String documentId, String userId) async {
    final response = await http.post(
      AppConfig.generateTitleUrl,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'text': text,
        'documentId': documentId,
        'userId': userId,
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      String generatedTitle = jsonResponse['title'];
      return generatedTitle;
    } else {
      print('Failed to generate title');
      return ""; // Consider throwing an exception or returning a specific error message
    }
  }
}
