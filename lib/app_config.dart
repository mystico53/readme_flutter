class AppConfig {
  static const bool isProduction = false; // Set to true for production

  static String get serverUrl {
    if (isProduction) {
      return 'https://readmebackend-e4ad7505dabd.herokuapp.com/tts';
    } else {
      return 'http://10.0.2.2:5000/tts'; // Replace with your local server's port
    }
  }
}
