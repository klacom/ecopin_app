import 'package:ecopin_app/shared/reports/presentation/widgets/report_status_presentation.dart';
import 'package:ecopin_app/shared/widgets/private_media_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Placeholder glyph for the leading tile when a report has no photo; the trash
/// glyph covers waste and any unknown concern.
IconData reportConcernIcon(String? issueType) => switch (reportStatusKey(
  issueType ?? '',
)) {
  'flooding' || 'clogged_drain' || 'clogged_drainage' => Icons.water_outlined,
  'pollution' ||
  'burning_waste' ||
  'open_burning' => Icons.local_fire_department_outlined,
  'infrastructure' => Icons.construction_outlined,
  'illegal_logging' => Icons.park_outlined,
  _ => Icons.delete_outline,
};

/// Recency label for the list a report belongs under.
String reportRecencyGroup(DateTime date, DateTime now) {
  final days = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(date.year, date.month, date.day)).inDays;
  if (days <= 0) return 'Today';
  if (days < 7) return 'This week';
  if (date.year == now.year && date.month == now.month) {
    return 'Earlier this month';
  }
  return DateFormat.yMMMM().format(date);
}

/// Newest-first [items] interleaved with a recency label whenever it changes.
List<Object> groupReportsByRecency<T>(
  List<T> items,
  DateTime Function(T item) createdAt,
  DateTime now,
) {
  final entries = <Object>[];
  String? previous;
  for (final item in items) {
    final label = reportRecencyGroup(createdAt(item).toLocal(), now);
    if (label != previous) entries.add(label);
    previous = label;
    entries.add(item as Object);
  }
  return entries;
}

class ReportGroupHeader extends StatelessWidget {
  const ReportGroupHeader({
    super.key,
    required this.label,
    this.first = false,
    this.trailing,
  });
  final String label;
  final bool first;

  /// Optional action at the end of the header line (for example Mark all as read).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = Text(
      label,
      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
    );
    // The action drops under the label when enlarged text would squeeze both.
    final stacked =
        trailing != null && MediaQuery.textScalerOf(context).scale(14) > 18.2;
    return Semantics(
      header: true,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, first ? 16 : 24, 12, 4),
        child: stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [title, ?trailing],
              )
            : Row(
                children: [
                  Expanded(child: title),
                  if (trailing != null) Flexible(child: trailing!),
                ],
              ),
      ),
    );
  }
}

class ReportRowLine {
  const ReportRowLine(
    this.text, {
    this.color,
    this.emphasis = false,
    this.maxLines = 2,
  });
  final String text;
  final Color? color;
  final bool emphasis;
  final int maxLines;
}

/// Divider row shared by the citizen public List and My Reports: a 68dp tile
/// (private photo when there is one, otherwise a tinted concern icon) with a
/// status pip, a medium title and up to three quiet text lines.
class ReportRow extends StatelessWidget {
  const ReportRow({
    super.key,
    required this.title,
    required this.lines,
    required this.icon,
    required this.tone,
    required this.pip,
    required this.semanticLabel,
    required this.onTap,
    this.photoUrl,
  });
  final String title;
  final List<ReportRowLine> lines;
  final IconData icon;

  /// Status color tinting the placeholder tile and its glyph.
  final Color tone;

  /// Color of the pip at the tile's corner (status or overdue).
  final Color pip;
  final String semanticLabel;
  final VoidCallback onTap;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        color: tone.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(child: Icon(icon, size: 28, color: tone)),
    );
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: onTap,
      // The list gives rows 4dp side padding; the 12dp inside keeps content on
      // the 16dp grid while the pressed highlight is a soft rounded panel.
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => scheme.primary.withValues(
            alpha: states.contains(WidgetState.focused)
                ? .12
                : states.contains(WidgetState.pressed)
                ? .08
                : states.contains(WidgetState.hovered)
                ? .04
                : 0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerTheme.color ?? scheme.outlineVariant,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                children: [
                  SizedBox(
                    width: 68,
                    height: 68,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: photoUrl == null
                              ? fallback
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: PrivateMediaImage(
                                    photoUrl!,
                                    width: 68,
                                    height: 68,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stack) =>
                                        fallback,
                                  ),
                                ),
                        ),
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: pip,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: scheme.surface,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        for (final line in lines) ...[
                          const SizedBox(height: 6),
                          Text(
                            line.text,
                            maxLines: line.maxLines,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: line.color ?? scheme.onSurfaceVariant,
                              fontWeight: line.emphasis
                                  ? FontWeight.w500
                                  : null,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
