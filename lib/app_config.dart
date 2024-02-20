class AppConfig {
  static const bool isProduction = false; // Toggle this for production

  static Uri get baseUrl {
    return isProduction
        ? Uri.parse(
            'https://us-central1-firebase-readme-123.cloudfunctions.net/')
        // For local development, adjust as needed (e.g., if using the Android emulator):
        : Uri.parse('http://10.0.2.2:5001/firebase-readme-123/us-central1/');
  }

  static Uri get ttsUrl => baseUrl.resolve('textToSpeech');
  static Uri checkAudioStatusUrl(String fileName) =>
      baseUrl.resolve('check_audio_status/$fileName');

  // Update the function URL to match the new Cloud Function name
  static Uri get generateAiTextUrl => baseUrl.resolve('cleanText');
}

/* old flask 
class AppConfig {
  static const bool isProduction = false; // Set to true for production

  static Uri get baseUrl {
    return isProduction
        ? Uri.parse('https://readmebackend-e4ad7505dabd.herokuapp.com')
        //: Uri.parse('http://10.0.2.2:5000');
        : Uri.parse('http://10.0.2.2:5000');
  }

  static Uri get ttsUrl => baseUrl.resolve('/tts');
  static Uri checkAudioStatusUrl(String fileName) =>
      baseUrl.resolve('/check_audio_status/$fileName');

  static Uri get generateAiTextUrl => baseUrl.resolve('/generate_ai_text');
}
*/