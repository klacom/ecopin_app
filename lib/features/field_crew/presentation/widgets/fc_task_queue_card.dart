import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import '../controllers/fc_dashboard_presentation.dart';
import '../controllers/fc_sync_ui_providers.dart';
import 'fc_current_objective_card.dart';
import 'fc_offline_ui.dart';
import 'fc_task_status_badge.dart';

/// The one job card used on Home and on the Jobs tab.
class FcTaskQueueCard extends ConsumerWidget {
  const FcTaskQueueCard({
    super.key,
    required this.task,
    this.position,
    this.done = false,
    this.emphasized = false,
    this.deviceNote,
    this.footer,
  });
  final CleanupTask task;

  /// Place in the crew's order of work (the current job is 1). Omitted for
  /// device-record lists, where order is not meaningful.
  final int? position;

  /// Shows a check mark instead of a number for finished work.
  final bool done;

  /// Draws the card with a blue border (the job being worked on).
  final bool emphasized;

  /// Written note for work held only on this phone, such as “Marked done on
  /// this phone”. Local state is never presented as a server result.
  final String? deviceNote;

  /// Extra content below the chips, such as the response deadline line. It
  /// brings its own top spacing so an empty footer adds no gap.
  final Widget? footer;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final status = theme.extension<AppStatusColors>();
    final lead = done
        ? Icon(
            Icons.check_circle_outline,
            size: 28,
            color: status?.success ?? theme.colorScheme.onSurface,
          )
        : position == null
        ? null
        : Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fcAccent(context).withValues(alpha: .15),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$position',
              style: theme.textTheme.bodySmall?.copyWith(
                color: fcAccent(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          );
    return Semantics(
      button: true,
      label: position == null ? null : 'Job $position in your order',
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusCard),
          side: BorderSide(
            color: emphasized
                ? fcAccent(context)
                : theme.dividerTheme.color ?? theme.dividerColor,
            width: emphasized ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppColors.radiusCard),
          onTap: () async {
            await context.push(crewTaskPath(task.id));
            if (context.mounted) ref.invalidate(fcPendingSummaryProvider);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (lead != null) ...[
                  ExcludeSemantics(child: lead),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(task.title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        crewTaskPlaceLine(task),
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          FcTaskStatusBadge(status: task.status),
                          if (!done) FcPriorityChip(priority: task.priority),
                          if (deviceNote != null)
                            _DeviceNoteChip(text: deviceNote!),
                        ],
                      ),
                      ?footer,
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const ExcludeSemantics(
                  child: Icon(Icons.chevron_right, size: 24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeviceNoteChip extends StatelessWidget {
  const _DeviceNoteChip({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        theme.extension<AppStatusColors>()?.warning ??
        theme.colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        border: Border.all(color: color.withValues(alpha: .35)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Icon(Icons.smartphone_outlined, size: 16, color: color),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
