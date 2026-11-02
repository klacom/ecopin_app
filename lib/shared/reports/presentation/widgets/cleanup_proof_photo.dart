import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class CleanupProofPhoto extends StatefulWidget {
  const CleanupProofPhoto({
    super.key,
    required this.url,
    required this.label,
    this.onOpen,
    this.fullSize = false,
    this.ownerOnly = false,
    this.cover = false,
  });
  final String url, label;
  final VoidCallback? onOpen;
  final bool fullSize;
  final bool ownerOnly;

  /// Fill the parent's box edge to edge (cropping) instead of showing the whole
  /// photo on a quiet panel; the parent supplies the size and rounded clip.
  final bool cover;
  @override
  State<CleanupProofPhoto> createState() => _CleanupProofPhotoState();
}

class _CleanupProofPhotoState extends State<CleanupProofPhoto> {
  int _attempt = 0;
  ApiClient? _client;
  late Future<Uint8List>? _bytes = widget.ownerOnly ? _load() : null;

  Future<Uint8List> _load() async {
    final response = await (_client ??= ApiClient()).dioClient.get<List<int>>(
      widget.url,
      options: Options(
        responseType: ResponseType.bytes,
        extra: {'requiresSession': true},
      ),
    );
    return Uint8List.fromList(response.data!);
  }

  @override
  void didUpdateWidget(covariant CleanupProofPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.ownerOnly != widget.ownerOnly) {
      _bytes = widget.ownerOnly ? _load() : null;
    }
  }

  @override
  void dispose() {
    _client?.dioClient.close(force: true);
    super.dispose();
  }

  Future<void> _retry() async {
    if (widget.ownerOnly) {
      setState(() => _bytes = _load());
      return;
    }
    await NetworkImage(widget.url).evict();
    if (mounted) setState(() => _attempt++);
  }

  @override
  Widget build(BuildContext context) {
    final publicImage = Image.network(
      widget.url,
      key: ValueKey('${widget.url}/$_attempt'),
      fit: widget.cover ? BoxFit.cover : BoxFit.contain,
      semanticLabel: '${widget.label}, checked by SWMO for sharing',
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes == null
                    ? null
                    : progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!,
              ),
            ),
      errorBuilder: (_, _, _) => _error(),
    );
    final image = widget.ownerOnly
        ? FutureBuilder<Uint8List>(
            future: _bytes,
            builder: (context, snapshot) {
              if (snapshot.hasError) return _error();
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return Image.memory(
                snapshot.data!,
                fit: widget.cover ? BoxFit.cover : BoxFit.contain,
                semanticLabel: '${widget.label}, for the report owner',
                errorBuilder: (_, _, _) => _error(),
              );
            },
          )
        : publicImage;
    if (widget.fullSize) {
      return InteractiveViewer(minScale: 1, maxScale: 5, child: image);
    }
    if (widget.cover) {
      return Material(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.quietSurfaceDark
            : AppColors.quietSurfaceLight,
        child: InkWell(
          onTap: widget.onOpen,
          child: SizedBox.expand(child: image),
        ),
      );
    }
    return Material(
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColors.quietSurfaceDark
          : AppColors.quietSurfaceLight,
      borderRadius: BorderRadius.circular(AppColors.radiusInput),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onOpen,
        child: SizedBox(height: 180, width: double.infinity, child: image),
      ),
    );
  }

  Widget _error() => Center(
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.image_not_supported_outlined),
          const SizedBox(height: 8),
          const Text('This photo couldn’t load.', textAlign: TextAlign.center),
          TextButton(onPressed: _retry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

class CleanupProofPhotoViewer extends StatefulWidget {
  const CleanupProofPhotoViewer({
    super.key,
    required this.photos,
    required this.initialIndex,
    this.ownerOnly = false,
  });
  final List<({String label, String url})> photos;
  final int initialIndex;
  final bool ownerOnly;
  @override
  State<CleanupProofPhotoViewer> createState() =>
      _CleanupProofPhotoViewerState();
}

class _CleanupProofPhotoViewerState extends State<CleanupProofPhotoViewer> {
  late final _pages = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;
  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.photos[_index].label)),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pages,
              itemCount: widget.photos.length,
              onPageChanged: (index) => setState(() => _index = index),
              itemBuilder: (_, index) => Center(
                child: CleanupProofPhoto(
                  ownerOnly: widget.ownerOnly,
                  url: widget.photos[index].url,
                  label: widget.photos[index].label,
                  fullSize: true,
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Previous photo',
                onPressed: _index == 0
                    ? null
                    : () => _pages.jumpToPage(_index - 1),
                icon: const Icon(Icons.chevron_left),
              ),
              Flexible(
                child: Semantics(
                  liveRegion: true,
                  child: Text('${_index + 1} of ${widget.photos.length}'),
                ),
              ),
              IconButton(
                tooltip: 'Next photo',
                onPressed: _index == widget.photos.length - 1
                    ? null
                    : () => _pages.jumpToPage(_index + 1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
