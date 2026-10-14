import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
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

  factory ReportMarkerStyle.forStatus(BuildContext context, String status) =>
      ReportMarkerStyle(
        reportStatusLabel(status),
        reportStatusColor(context, status),
        switch (reportStatusKey(status)) {
          'closed' || 'resolved' => Icons.check,
          'in_progress' || 'acknowledged' => Icons.engineering_outlined,
          'waiting_for_feedback' => Icons.rate_review_outlined,
          'pending_owner_consent' => Icons.home_outlined,
          'unresolved' || 'pending' => Icons.priority_high,
          'rejected' => Icons.block,
          _ => Icons.location_on_outlined,
        },
      );
}

class ReportMarker extends StatelessWidget {
  const ReportMarker({
    super.key,
    required this.status,
    this.title = 'Report',
    this.selected = false,
    this.onTap,
  });
  final String status, title;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final style = ReportMarkerStyle.forStatus(context, status);
    final ring = Theme.of(context).brightness == Brightness.dark
        ? AppColors.linkDark
        : AppColors.accent;
    final pin = Center(
      child: Container(
        width: 44,
        height: 44,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: selected ? Border.all(color: ring, width: 2) : null,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: style.fill,
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.surface,
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Icon(style.icon, color: style.foreground, size: 20),
        ),
      ),
    );
    if (onTap == null) {
      return Semantics(label: '${style.label} report', child: pin);
    }
    return SizedBox(
      width: 48,
      height: 48,
      child: Semantics(
        selected: selected,
        child: IconButton(
          tooltip: '$title, ${style.label}',
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          padding: EdgeInsets.zero,
          onPressed: onTap,
          icon: pin,
        ),
      ),
    );
  }
}
