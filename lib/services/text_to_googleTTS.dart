import 'dart:convert';
import 'package:http/http.dart' as http;

import '../utils/app_config.dart';
//import '../utils/id_manager.dart'; // Assuming you have this for ID generation
import '../models/voice_model.dart';

class TextToGoogleTTS {
  static Future<Map<String, dynamic>> sendTextToServer(String text,
      String userId, VoiceModel? selectedVoice, String fileId) async {
    final languageCode = selectedVoice?.languageCode ?? 'en-US';
    final voiceName = selectedVoice?.voiceName ?? 'en-US-Neural2-J';
    final speakingRate = selectedVoice?.speakingRate ?? 1.0;
    print(
        "Debug: Prepared request parameters: languageCode=$languageCode, voiceName=$voiceName, speakingRate=$speakingRate");

    var request = http.Request('POST', AppConfig.ttsUrl);
    print("TTS URL: ${AppConfig.ttsUrl}");
    request.headers.addAll({'Content-Type': 'application/json'});
    request.body = jsonEncode({
      'text': text,
      'fileId': fileId,
      'languageCode': languageCode,
      'voiceName': voiceName,
      'speakingRate': speakingRate,
      'userId': userId,
    });

    print("Debug: Sending request to server with body: ${request.body}");

    try {
      var streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));
      print(
          "Debug: Received response from server with status code: ${streamedResponse.statusCode}");

      if (streamedResponse.statusCode == 200) {
        print("Debug: Request succeeded");
        return {'success': true, 'fileId': fileId};
      } else {
        print(
            "Debug: Request failed with status code: ${streamedResponse.statusCode}");
        return {
          'success': false,
          'error': 'Server responded with error: ${streamedResponse.statusCode}'
        };
      }
    } catch (e) {
      print("Debug: Exception caught while sending request: $e");
      return {'success': false, 'error': 'Exception during request: $e'};
    }
  }

  static Future<Map<String, dynamic>> checkTTSStatus(
      String fileId, String userId) async {
    var url = AppConfig.checkTTSUrl(fileId);
    print(
        "Debug: Checking TTS status for fileId: $fileId and userId: $userId with URL: $url");

    try {
      var response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'fileId': fileId,
          'userId': userId,
        }),
      );

      print(
          "Debug: Received status check response with status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print(
            "Debug: Status check succeeded with response data: ${response.body}");
        return {
          'success': true,
          'audioUrl': responseData['gcsUri'],
          'response': response.body,
        };
      } else {
        print(
            "Debug: Status check failed with reason: ${response.reasonPhrase}");
        return {
          'success': false,
          'error': 'Error: ${response.reasonPhrase}',
        };
      }
    } catch (e) {
      print("Debug: Exception caught while checking TTS status: $e");
      return {
        'success': false,
        'error': 'Error calling cloud function: $e',
      };
    }
  }
}
