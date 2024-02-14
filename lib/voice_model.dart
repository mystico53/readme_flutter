class VoiceModel {
  final String name;
  final String languageCode;
  final String voiceName;
  final double speakingRate; // Add this line

  VoiceModel({
    required this.name,
    required this.languageCode,
    required this.voiceName,
    this.speakingRate = 1.0, // Add a default value for speakingRate
  });
}
