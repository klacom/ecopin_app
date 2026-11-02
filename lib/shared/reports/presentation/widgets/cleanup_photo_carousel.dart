import 'package:flutter/material.dart';
import 'cleanup_proof_photo.dart';

/// Edge-to-edge gallery for one cleanup slot ("Before" or "After"). One photo
/// shows plainly; several swipe, with a "2 of 3" label and page dots so the
/// citizen can tell there is more. Tapping a photo opens the zoom viewer.
class CleanupPhotoCarousel extends StatefulWidget {
  const CleanupPhotoCarousel({
    super.key,
    required this.label,
    required this.urls,
    required this.onOpen,
    this.ownerOnly = false,
  });

  /// Short slot name shown on the photo, for example "Before".
  final String label;
  final List<String> urls;
  final ValueChanged<int> onOpen;
  final bool ownerOnly;

  @override
  State<CleanupPhotoCarousel> createState() => _CleanupPhotoCarouselState();
}

class _CleanupPhotoCarouselState extends State<CleanupPhotoCarousel> {
  final _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.urls.length;
    final theme = Theme.of(context);
    final tag = count > 1
        ? '${widget.label} · ${_page + 1} of $count'
        : widget.label;
    return Semantics(
      container: true,
      label: count > 1
          ? '${widget.label} cleanup photos, $count. Swipe to see more.'
          : '${widget.label} cleanup photo',
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _pages,
                itemCount: count,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (context, index) => CleanupProofPhoto(
                  cover: true,
                  ownerOnly: widget.ownerOnly,
                  url: widget.urls[index],
                  label: count > 1
                      ? '${widget.label} cleanup, photo ${index + 1} of $count'
                      : '${widget.label} cleanup',
                  onOpen: () => widget.onOpen(index),
                ),
              ),
              Positioned(
                left: 10,
                top: 10,
                child: ExcludeSemantics(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      child: Text(
                        tag,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (count > 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 10,
                  child: ExcludeSemantics(
                    child: IgnorePointer(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < count; i++)
                            Container(
                              width: i == _page ? 18 : 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(
                                  alpha: i == _page ? 1 : .6,
                                ),
                                borderRadius: BorderRadius.circular(3),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black38,
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
