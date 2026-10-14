import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';

typedef LocalVideoControllerFactory = VideoPlayerController Function(File file);

Future<void> _releaseVideo(VideoPlayerController controller) async {
  try {
    await controller.dispose().timeout(const Duration(seconds: 2));
  } catch (_) {
    // A failed platform initialization may also fail during cleanup.
  }
}

Future<Duration?> readLocalVideoDuration(
  File file, {
  LocalVideoControllerFactory? createController,
}) async {
  final controller = (createController ?? VideoPlayerController.file)(file);
  try {
    await controller.initialize().timeout(const Duration(seconds: 10));
    return controller.value.isInitialized && !controller.value.hasError
        ? controller.value.duration
        : null;
  } catch (_) {
    return null;
  } finally {
    await _releaseVideo(controller);
  }
}

String mediaDurationLabel(Duration duration) {
  final seconds = duration.inSeconds;
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

class LocalPhotoPreview extends StatefulWidget {
  const LocalPhotoPreview({
    super.key,
    required this.photos,
    required this.initialIndex,
  });
  final List<File> photos;
  final int initialIndex;
  @override
  State<LocalPhotoPreview> createState() => _LocalPhotoPreviewState();
}

class _LocalPhotoPreviewState extends State<LocalPhotoPreview> {
  late int _index = widget.initialIndex;
  late final PageController _pages = PageController(initialPage: _index);
  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _changePhoto(int index) => _pages.animateToPage(
    index,
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 200),
    curve: Curves.easeOut,
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight:
          MediaQuery.textScalerOf(
                context,
              ).clamp(maxScaleFactor: 1.3).scale(24) *
              2 +
          16,
      title: Text('Photo ${_index + 1} of ${widget.photos.length}'),
    ),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pages,
              itemCount: widget.photos.length,
              onPageChanged: (index) => setState(() => _index = index),
              itemBuilder: (context, index) => InteractiveViewer(
                key: ValueKey(index),
                minScale: 1,
                maxScale: 5,
                child: Center(
                  child: Image.file(
                    widget.photos[index],
                    fit: BoxFit.contain,
                    semanticLabel: 'Selected report photo ${index + 1}',
                    errorBuilder: (context, error, stack) => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'This photo could not be opened. Return to your report to remove it or choose another photo.',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Pinch to zoom. These photos have not been sent yet.',
              textAlign: TextAlign.center,
            ),
          ),
          if (widget.photos.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Previous',
                      variant: ButtonVariant.secondary,
                      onPressed: _index > 0
                          ? () => _changePhoto(_index - 1)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      text: 'Next',
                      variant: ButtonVariant.secondary,
                      onPressed: _index + 1 < widget.photos.length
                          ? () => _changePhoto(_index + 1)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class LocalVideoPreview extends StatefulWidget {
  const LocalVideoPreview({
    super.key,
    required this.file,
    this.createController,
  });
  final File file;
  final LocalVideoControllerFactory? createController;
  @override
  State<LocalVideoPreview> createState() => _LocalVideoPreviewState();
}

class _LocalVideoPreviewState extends State<LocalVideoPreview> {
  VideoPlayerController? _controller;
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    final controller = _controller;
    if (controller != null) unawaited(_releaseVideo(controller));
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final old = _controller;
    if (old != null) await _releaseVideo(old);
    if (!mounted) return;
    final controller = (widget.createController ?? VideoPlayerController.file)(
      widget.file,
    );
    _controller = controller;
    try {
      await controller.initialize().timeout(const Duration(seconds: 10));
      if (!controller.value.isInitialized || controller.value.hasError) {
        throw StateError('Video unavailable');
      }
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error =
              'This video could not be opened. Retry, or return to your report and choose another video.';
        });
      }
    }
  }

  Future<void> _togglePlayback() async {
    final controller = _controller!;
    try {
      if (controller.value.isPlaying) {
        await controller.pause();
      } else {
        if (controller.value.position >= controller.value.duration) {
          await controller.seekTo(Duration.zero);
        }
        await controller.play();
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Playback is unavailable. Retry, or choose another video in your report.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight:
          MediaQuery.textScalerOf(
                context,
              ).clamp(maxScaleFactor: 1.3).scale(24) *
              2 +
          16,
      title: const Text('Preview video'),
    ),
    body: SafeArea(
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Opening selected video',
              ),
            )
          : _error != null
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: Text(_error!, textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: 24),
                    AppButton(text: 'Retry video', onPressed: _load),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: _controller!.value.size.width,
                        height: _controller!.value.size.height,
                        child: VideoPlayer(_controller!),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ValueListenableBuilder<VideoPlayerValue>(
                    valueListenable: _controller!,
                    builder: (context, value, child) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Semantics(
                          label: 'Video position',
                          child: SizedBox(
                            height: 48,
                            child: VideoProgressIndicator(
                              _controller!,
                              allowScrubbing: true,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                            ),
                          ),
                        ),
                        Text(
                          '${mediaDurationLabel(value.position)} / ${mediaDurationLabel(value.duration)}',
                        ),
                        const SizedBox(height: 8),
                        AppButton(
                          text: value.isPlaying ? 'Pause video' : 'Play video',
                          icon: value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          onPressed: _togglePlayback,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This video has not been sent yet.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    ),
  );
}
