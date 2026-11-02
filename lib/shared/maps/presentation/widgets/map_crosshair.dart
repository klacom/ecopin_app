import 'package:flutter/material.dart';

/// A thin horizontal and vertical line meeting at the middle of the map view,
/// so a citizen can see exactly where "Use this map center" will land. It is
/// decorative: it ignores touches and is hidden from screen readers.
class MapCrosshair extends StatelessWidget {
  const MapCrosshair({super.key});

  /// How strongly the marks show. Kept low so they read as a guide, not a mark.
  static const double opacity = .5;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: CustomPaint(
          painter: _CrosshairPainter(
            line: (dark ? Colors.white : Theme.of(context).colorScheme.primary)
                .withValues(alpha: opacity),
            halo: (dark ? Colors.black : Colors.white).withValues(
              alpha: opacity * .6,
            ),
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  _CrosshairPainter({required this.line, required this.halo});
  final Color line, halo;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final horizontal = [Offset(0, c.dy), Offset(size.width, c.dy)];
    final vertical = [Offset(c.dx, 0), Offset(c.dx, size.height)];
    final haloPaint = Paint()
      ..color = halo
      ..strokeWidth = 3;
    final linePaint = Paint()
      ..color = line
      ..strokeWidth = 1;
    for (final points in [horizontal, vertical]) {
      canvas.drawLine(points[0], points[1], haloPaint);
    }
    for (final points in [horizontal, vertical]) {
      canvas.drawLine(points[0], points[1], linePaint);
    }
    canvas.drawCircle(
      c,
      6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = halo,
    );
    canvas.drawCircle(
      c,
      6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = line,
    );
  }

  @override
  bool shouldRepaint(_CrosshairPainter old) =>
      old.line != line || old.halo != halo;
}
