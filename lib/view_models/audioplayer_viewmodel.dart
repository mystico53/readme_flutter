import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioPlayerViewModel extends ChangeNotifier {
  late Duration _maxReportedPosition = Duration.zero;
  double _lastProgressPercentage = 0.0;
  Timer? _periodicTimer;
  Timer? _timePlayedTimer; // Timer for incrementing total time played
  String? _currentFileId;
  bool _isPlaying = false; // Flag to track if the audio is playing
  String? get currentFileId => _currentFileId;
  double get lastProgressPercentage => _lastProgressPercentage;
  Duration get maxReportedPosition => _maxReportedPosition ?? Duration.zero;
  int _totalTimePlayed = 0;
  int get totalTimePlayed => _totalTimePlayed;

  // Added SharedPreferences instance
  SharedPreferences? _prefs;

  AudioPlayerViewModel() {
    _loadPrefs();
  }

  // Asynchronously load the SharedPreferences instance
  Future<void> _loadPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _totalTimePlayed = _prefs!.getInt('totaltimeplayed') ?? 0;
    print("SharedPreferences loaded. Total time played: $_totalTimePlayed");
  }

  void startTotalTimePlayedTimer() {
    _timePlayedTimer?.cancel(); // Cancel any existing timer
    _timePlayedTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (_isPlaying) {
        _totalTimePlayed += 1;
        await _prefs!.setInt('totaltimeplayed', _totalTimePlayed);
        notifyListeners();
      }
    });
  }

  Future<void> updateTotalTimePlayed(int seconds) async {
    _totalTimePlayed += seconds;
    print("Total time played updated: $_totalTimePlayed");
    await _prefs!.setInt('totaltimeplayed', _totalTimePlayed);
    notifyListeners();
  }

  void startPeriodicUpdate(Duration totalDuration, String fileId) {
    _currentFileId = fileId;
    _periodicTimer?.cancel();
    print("Starting periodic update for file ID: $fileId");

    // Load the saved progress from SharedPreferences
    _loadSavedProgress(fileId).then((savedPosition) {
      // Initialize _maxReportedPosition if it hasn't been initialized yet
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

  void setPlaying(bool isPlaying) {
    _isPlaying = isPlaying;
    if (isPlaying) {
      startTotalTimePlayedTimer();
    } else {
      _timePlayedTimer?.cancel();
    }
    notifyListeners();
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
    _timePlayedTimer
        ?.cancel(); // Cancel the timer when the ViewModel is disposed
    print("Disposing AudioPlayerViewModel and canceling timer.");
    super.dispose();
  }

  String formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final hoursStr = hours > 0 ? '${hours}h ' : '';
    final minutesStr = minutes > 0 ? '${minutes}m ' : '';
    final secondsStr = seconds > 0 ? '${seconds}s' : '';

    return '${hoursStr}${minutesStr}${secondsStr}'.trim();
  }
}
