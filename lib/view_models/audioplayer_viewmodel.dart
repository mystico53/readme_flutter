import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioPlayerViewModel extends ChangeNotifier {
  late Duration _maxReportedPosition;
  double _lastProgressPercentage = 0.0;
  Timer? _periodicTimer;
  String? _currentFileId;
  String? get currentFileId => _currentFileId;
  double get lastProgressPercentage => _lastProgressPercentage;

  // Added SharedPreferences instance
  SharedPreferences? _prefs;

  AudioPlayerViewModel() {
    _loadPrefs();
  }

  // Asynchronously load the SharedPreferences instance
  Future<void> _loadPrefs() async {
    print("Loading SharedPreferences...");
    _prefs = await SharedPreferences.getInstance();
    print("SharedPreferences loaded.");
  }

  void startPeriodicUpdate(Duration totalDuration, String fileId) {
    _currentFileId = fileId;
    _periodicTimer?.cancel();
    print("Starting periodic update for file ID: $fileId");

    // Load the saved progress from SharedPreferences
    _loadSavedProgress(fileId).then((savedPosition) {
      _maxReportedPosition = savedPosition ?? Duration.zero;
      print(
          "Loaded saved progress: $_maxReportedPosition ms for file ID: $fileId");

      _periodicTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
        if (totalDuration.inSeconds > 0 && _maxReportedPosition.inSeconds > 0) {
          final double progressPercentage =
              (_maxReportedPosition.inSeconds / totalDuration.inSeconds) * 100;
          String formattedPercentage = progressPercentage.toStringAsFixed(1);
          if (progressPercentage != _lastProgressPercentage) {
            _lastProgressPercentage = progressPercentage;
            print(
                'Progress percentage: $formattedPercentage% for file ID: $_currentFileId');
            // Save to SharedPreferences
            await saveProgress(_currentFileId!, _maxReportedPosition);
            notifyListeners();
          }
        }
      });
    });
  }

  Future<Duration?> _loadSavedProgress(String fileId) async {
    if (_prefs == null) {
      print("SharedPreferences not initialized, cannot load saved progress.");
      return null;
    }

    String? savedProgressString = _prefs!.getString('$fileId');
    if (savedProgressString != null) {
      int savedMilliseconds = int.parse(savedProgressString);
      return Duration(milliseconds: savedMilliseconds);
    }
    return null;
  }

  void updatePosition(Duration currentPosition) {
    if (currentPosition > _maxReportedPosition) {
      _maxReportedPosition = currentPosition;
    }
  }

  Future<void> saveProgress(String fileId, Duration position) async {
    if (_prefs == null) {
      print("SharedPreferences not initialized, cannot save progress.");
      return;
    }

    await _prefs!.setString('$fileId', position.inMilliseconds.toString());
    print("Saved progress: $position ms for file ID: $fileId.");
  }

  Future<void> resetProgress(String fileId) async {
    _maxReportedPosition = Duration.zero;
    await saveProgress(fileId, Duration.zero);
    notifyListeners();
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    print("Disposing AudioPlayerViewModel and canceling timer.");
    super.dispose();
  }
}
