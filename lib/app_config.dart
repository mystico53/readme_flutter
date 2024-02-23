class AppConfig {
  static const bool isProduction = false; // Local
  //static const bool isProduction = true; // Prod

  static Uri get baseUrl {
    return isProduction
        ? Uri.parse(
            'https://us-central1-firebase-readme-123.cloudfunctions.net/')
        // For local development, adjust as needed (e.g., if using the Android emulator):
        : Uri.parse('http://10.0.2.2:5001/firebase-readme-123/us-central1/');
  }

  static Uri get ttsUrl => baseUrl.resolve('textToSpeech');
  static Uri get generateAiTextUrl => baseUrl.resolve('cleanText');
  static Uri checkTTSUrl(String fileId) => baseUrl.resolve('checkTTS/$fileId');
}
