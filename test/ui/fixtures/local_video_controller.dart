import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class SyntheticVideoController extends VideoPlayerController {
  SyntheticVideoController(
    super.file, {
    this.duration = const Duration(seconds: 7),
    this.fail = false,
  }) : super.file();
  final Duration duration;
  final bool fail;
  bool released = false;
  @override
  Future<void> initialize() async {
    if (fail) throw PlatformException(code: 'VideoError');
    value = value.copyWith(
      duration: duration,
      isInitialized: true,
      size: const Size(1920, 1080),
    );
  }

  @override
  Future<void> play() async {
    value = value.copyWith(isPlaying: true);
  }

  @override
  Future<void> pause() async {
    value = value.copyWith(isPlaying: false);
  }

  @override
  Future<void> seekTo(Duration position) async {
    value = value.copyWith(position: position);
  }

  @override
  Future<void> dispose() async {
    released = true;
    await super.dispose();
  }
}
