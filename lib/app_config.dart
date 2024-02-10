class AppConfig {
  static const bool isProduction = false; // Set to true for production

  static String get baseUrl {
    return isProduction
        ? 'https://readmebackend-e4ad7505dabd.herokuapp.com'
        : 'http://10.0.2.2:5000';
  }

  static String get ttsUrl => '$baseUrl/tts';
  static String checkAudioStatusUrl(String fileName) =>
      '$baseUrl/check_audio_status/$fileName';
}
