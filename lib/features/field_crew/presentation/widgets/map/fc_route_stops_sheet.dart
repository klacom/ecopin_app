import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/features/field_crew/presentation/controllers/fc_route_presentation.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_offline_ui.dart';

/// The whole route as a text list, so the stops are readable without map
/// tiles and without searching for pins. Tapping a stop centers the map on it.
Future<void> showFcRouteStopsSheet(
  BuildContext context, {
  required List<CrewStopRow> rows,
  required String? totals,
  required ValueChanged<CrewStopRow> onSelect,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final status = theme.extension<AppStatusColors>();
      return SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * .8,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        'Route · ${rows.length} ${rows.length == 1 ? 'stop' : 'stops'}',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close stop list',
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text(
                totals == null
                    ? 'Distance and time are not available for this route.'
                    : '$totals, from the published route',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              if (rows.isEmpty)
                Text(
                  'No stops with jobs are saved on this phone for this route.',
                  style: theme.textTheme.bodyMedium,
                ),
              for (final row in rows) ...[
                Material(
                  color: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.radiusCard),
                    side: BorderSide(
                      color: row.state == CrewStopState.next
                          ? fcAccent(sheetContext)
                          : theme.dividerTheme.color ?? theme.dividerColor,
                      width: row.state == CrewStopState.next ? 1.5 : 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppColors.radiusCard),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      onSelect(row);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ExcludeSemantics(
                            child: Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color:
                                    (row.finished
                                            ? status?.success ??
                                                  theme.colorScheme.onSurface
                                            : fcAccent(sheetContext))
                                        .withValues(alpha: .15),
                                shape: BoxShape.circle,
                              ),
                              child: row.finished
                                  ? Icon(
                                      Icons.check,
                                      size: 18,
                                      color:
                                          status?.success ??
                                          theme.colorScheme.onSurface,
                                    )
                                  : Text(
                                      '${row.number}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: fcAccent(sheetContext),
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  row.task.title,
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  row.place,
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Stop ${row.number} · ${row.label}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: row.state == CrewStopState.next
                                        ? fcAccent(sheetContext)
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const ExcludeSemantics(
                            child: Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      );
    },
  );
}
