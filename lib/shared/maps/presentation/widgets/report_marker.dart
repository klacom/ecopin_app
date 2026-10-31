import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/report_status_presentation.dart';

class ReportMarkerStyle {
  const ReportMarkerStyle(this.label, this.fill, this.icon);
  final String label;
  final Color fill;
  final IconData icon;
  Color get foreground {
    final luminance = fill.computeLuminance();
    return (luminance + .05) / .05 >= 1.05 / (luminance + .05)
        ? Colors.black
        : Colors.white;
  }

  factory ReportMarkerStyle.forStatus(BuildContext context, String status) {
    final colors =
        Theme.of(context).extension<AppStatusColors>() ??
        AppStatusColors(
          success: AppColors.success,
          warning: const Color(0xFFB45309),
          error: Theme.of(context).colorScheme.error,
          info: AppColors.info,
          feedback: const Color(0xFF6D28D9),
        );
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final (fill, icon) = switch (reportStatusKey(status)) {
      'unresolved' ||
      'submitted' ||
      'pending' ||
      'rejected' => (colors.error, Icons.error_outline),
      'in_progress' || 'acknowledged' => (colors.info, Icons.schedule),
      'resolved' => (colors.success, Icons.check),
      'waiting_for_feedback' => (colors.feedback, Icons.chat_bubble_outline),
      'pending_owner_consent' => (colors.info, Icons.lock_outline),
      'closed' => (muted, Icons.done_all),
      _ => (muted, Icons.help_outline),
    };
    return ReportMarkerStyle(reportStatusLabel(status), fill, icon);
  }
}

class ReportMarker extends StatelessWidget {
  const ReportMarker({
    super.key,
    required this.status,
    this.title = 'Report',
    this.issueType,
    this.selected = false,
    this.onTap,
  });
  final String status, title;
  final String? issueType;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = ReportMarkerStyle.forStatus(context, status);
    final concernIcon = switch (reportStatusKey(issueType ?? '')) {
      'illegal_dumping' => Icons.delete_outline,
      'littering' => Icons.delete_sweep_outlined,
      'uncollected_garbage' ||
      'uncollected_waste' => Icons.local_shipping_outlined,
      'clogged_drain' || 'clogged_drainage' => Icons.water_outlined,
      'burning_waste' || 'open_burning' => Icons.local_fire_department_outlined,
      _ => Icons.location_on_outlined,
    };
    final pin = ReportPinFrame(
      color: style.fill,
      selected: selected,
      badge: Icon(style.icon, color: style.foreground, size: 14),
      child: Icon(concernIcon, color: style.fill, size: 25),
    );
    if (onTap == null) {
      return Semantics(
        label: '$title, ${style.label}',
        selected: selected,
        child: pin,
      );
    }
    return SizedBox(
      width: ReportPinFrame.width,
      height: ReportPinFrame.height,
      child: Semantics(
        selected: selected,
        child: IconButton(
          tooltip: '$title, ${style.label}',
          constraints: const BoxConstraints.tightFor(
            width: ReportPinFrame.width,
            height: ReportPinFrame.height,
          ),
          padding: EdgeInsets.zero,
          onPressed: onTap,
          icon: pin,
        ),
      ),
    );
  }
}

/// Shared pointed silhouette; map callers anchor its bottom tip to the coordinate.
class ReportPinFrame extends StatelessWidget {
  const ReportPinFrame({
    super.key,
    required this.color,
    required this.child,
    required this.badge,
    this.selected = false,
    this.layered = false,
  });
  static const double width = 56, height = 64;
  final Color color;
  final Widget child, badge;
  final bool selected, layered;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ring = scheme.brightness == Brightness.dark
        ? AppColors.linkDark
        : AppColors.accent;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (layered)
            Positioned(
              top: 1,
              left: 0,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.surfaceContainerHighest,
                  border: Border.all(color: color, width: 2),
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            left: 22,
            child: CustomPaint(
              size: const Size(12, 10),
              painter: _PinTip(color),
            ),
          ),
          Positioned(
            top: 6,
            left: 3,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.alphaBlend(
                  color.withValues(alpha: .10),
                  scheme.surface,
                ),
                border: Border.all(color: color, width: 3),
                boxShadow: [
                  BoxShadow(color: Colors.white, spreadRadius: 2),
                  if (selected) BoxShadow(color: ring, spreadRadius: 4),
                  if (selected)
                    BoxShadow(
                      color: ring.withValues(alpha: .2),
                      spreadRadius: 7,
                    ),
                  const BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 12,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Center(child: child),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: badge,
            ),
          ),
        ],
      ),
    );
  }
}

class _PinTip extends CustomPainter {
  const _PinTip(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_PinTip oldDelegate) => oldDelegate.color != color;
}
