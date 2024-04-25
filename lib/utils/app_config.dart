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
  static Uri get createFirestoreDocumentUrl =>
      baseUrl.resolve('createFirestoreDocument');
  static Uri get generateTitleUrl => baseUrl.resolve('generateTitle');
  static Uri get processRawIntentUrl => baseUrl.resolve('processRawIntent');
  static Uri get submitFeedbackUrl => baseUrl.resolve('submitFeedback');
  static Uri get exchangeAuthCodeUrl => baseUrl.resolve('exchangeAuthCode');

  //static Uri checkTTSUrl(String fileId) => baseUrl.resolve('checkTTS/$fileId');
  static Uri checkTTSUrl(String fileId) {
    // Construct the base URL for the checkTTS endpoint
    Uri endpoint = baseUrl.resolve('checkTTS');
    // Return the URL with fileId as a query parameter
    return Uri.parse('$endpoint').replace(queryParameters: {'fileId': fileId});
  }
}
