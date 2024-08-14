import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:readme_app/view_models/audioplayer_viewmodel.dart';

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  late AudioPlayerViewModel _viewModel;

  MyAudioHandler() {
    _player.playbackEventStream.listen(_broadcastState);
  }

  void setViewModel(AudioPlayerViewModel viewModel) {
    _viewModel = viewModel;
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

  Future<void> setAudioSource(String url, String fileId) async {
    await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));

    final duration = await _player.duration;

    mediaItem.add(MediaItem(
      id: fileId, // Use fileId instead of url
      album: "Unknown Album",
      title: "Audio Track",
      artist: "Unknown Artist",
      duration: duration,
    ));

    _viewModel.setCurrentFileId(fileId);
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
