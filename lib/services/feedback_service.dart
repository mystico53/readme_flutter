import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';

class FeedbackService {
  static Future<void> submitFeedback(String text, List<int> screenshot) async {
    try {
      final screenshotBase64 = base64Encode(screenshot);

      final response = await http.post(
        AppConfig.submitFeedbackUrl,
        body: {
          'text': text,
          'screenshot': screenshotBase64,
        },
      );

      if (response.statusCode == 200) {
        print('Feedback submitted successfully');
      } else {
        print('Failed to submit feedback');
        throw Exception('Failed to submit feedback');
      }
    } catch (error) {
      print('Error submitting feedback: $error');
      throw error;
    }
  }
}
