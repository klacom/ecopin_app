import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ReportVideoPlayer extends StatefulWidget {
  final String videoUrl;

  final VideoPlayerController Function(Uri source)? createController;
  final double extent;
  const ReportVideoPlayer({
    super.key,
    required this.videoUrl,
    this.createController,
    this.extent = 200,
  });

  @override
  State<ReportVideoPlayer> createState() => ReportVideoPlayerState();
}

class ReportVideoPlayerState extends State<ReportVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      final controller =
          (widget.createController ?? VideoPlayerController.networkUrl)(
            Uri.parse(widget.videoUrl),
          );
      _controller = controller;
      await controller.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        controller.addListener(() {
          if (mounted) {
            setState(() {
              _isPlaying = controller.value.isPlaying;
            });
          }
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isInitialized = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    final controller = _controller;
    if (controller == null) return;

    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
        _isPlaying = false;
      } else {
        controller.play();
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        width: widget.extent,
        height: widget.extent,
        color: Colors.grey.shade300,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final controller = _controller;
    if (_hasError || controller == null) {
      return Container(
        width: widget.extent,
        height: widget.extent,
        color: Colors.grey.shade300,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 32, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Video load failed',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: _togglePlayPause,
          child: SizedBox(
            width: widget.extent,
            height: widget.extent,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: _isPlaying ? 'Pause report video' : 'Play report video',
          onPressed: _togglePlayPause,
          iconSize: 64,
          style: IconButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.black54,
          ),
          icon: Icon(
            _isPlaying ? Icons.pause_circle_outline : Icons.play_circle_outline,
          ),
        ),
      ],
    );
  }
}
