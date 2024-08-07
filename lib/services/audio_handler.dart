// lib/services/audio_handler.dart

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:readme_app/view_models/audioplayer_viewmodel.dart';

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final AudioPlayerViewModel _viewModel;

  MyAudioHandler(this._viewModel) {
    _player.playbackEventStream.listen(_broadcastState);
    _player.positionStream.listen((position) {
      _viewModel.updatePosition(position);
    });
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await playbackState.firstWhere(
        (state) => state.processingState == AudioProcessingState.idle);
  }

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  Future<void> setAudioSource(String url) async {
    await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));

    // Wait for the duration to be available
    final duration = await _player.duration;

    // Update the mediaItem
    mediaItem.add(MediaItem(
      id: url, // Using the URL as the ID, you might want to use a different ID system
      album:
          "Unknown Album", // You might want to pass these details from elsewhere
      title: "Audio Track",
      artist: "Unknown Artist",
      duration: duration,
      // artUri: Uri.parse('https://example.com/albumart.jpg'),  // If you have album art
    ));
  }

  Stream<MediaItem?> get currentMediaItem => mediaItem.stream;

  Future<Duration?> getDuration() async {
    return _player.duration;
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.rewind,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    ));
  }
}
