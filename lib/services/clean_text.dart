import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../utils/app_config.dart'; // Assuming you have this setup

class CleanTextService {
  static Future<String> cleanText(String text) async {
    try {
      String cleanedText = await sendTextToAI(text);
      return cleanedText;
    } catch (e) {
      print("Error during text cleaning: $e");
      return text; // Return the original text or an error message
    }
  }

  static Future<String> sendTextToAI(String text) async {
    final response = await http.post(
      AppConfig.generateAiTextUrl,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'text': text,
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      String generatedText = jsonResponse['generated_text'];
      generatedText = generatedText.replaceAll('\n', ' ');
      return generatedText;
    } else {
      print('Failed to generate AI text');
      return text; // Consider throwing an exception or returning a specific error message
    }
  }
}
