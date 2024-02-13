class AppConfig {
  static const bool isProduction = false; // Set to true for production

  static Uri get baseUrl {
    return isProduction
        ? Uri.parse('https://readmebackend-e4ad7505dabd.herokuapp.com')
        : Uri.parse('http://10.0.2.2:5000');
  }

  static Uri get ttsUrl => baseUrl.resolve('/tts');
  static Uri checkAudioStatusUrl(String fileName) =>
      baseUrl.resolve('/check_audio_status/$fileName');

  static Uri get generateAiTextUrl => baseUrl.resolve('/generate_ai_text');
}
