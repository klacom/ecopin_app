import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/features/field_crew/presentation/controllers/fc_dashboard_presentation.dart';
import 'package:ecopin_app/features/field_crew/presentation/controllers/fc_route_order.dart';
import 'package:ecopin_app/features/field_crew/presentation/controllers/fc_route_presentation.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_offline_ui.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';

/// The Route screen's bottom card: the next job, the Priority | Nearest switch
/// directly above **Start next job**, and a way to the full stop list. It can
/// be minimized to one row so the map is not covered.
class FcRouteNextCard extends StatelessWidget {
  const FcRouteNextCard({
    super.key,
    required this.next,
    required this.order,
    required this.stopCount,
    required this.collapsed,
    required this.starting,
    required this.onOrderChanged,
    required this.onStart,
    required this.onToggle,
    required this.onSeeStops,
  });
  final CrewNextStop next;
  final CrewRouteOrder order;
  final int stopCount;
  final bool collapsed, starting;
  final ValueChanged<CrewRouteOrder> onOrderChanged;
  final VoidCallback onStart, onToggle, onSeeStops;

  String get _detail => switch (order) {
    CrewRouteOrder.priority => 'Stop ${next.waypoint.sequenceOrder}',
    CrewRouteOrder.nearest =>
      next.distanceMeters != null
          ? '${crewFormatDistance(next.distanceMeters)} straight-line'
          : 'Waiting for GPS, showing priority order',
  };

  /// One row: the job and a Start button. At large text the button drops
  /// below the title so neither is squeezed.
  Widget _collapsed(BuildContext context, Widget number, String title) {
    final theme = Theme.of(context);
    final stacked = MediaQuery.textScalerOf(context).scale(16) > 20;
    final summary = Semantics(
      liveRegion: true,
      label: 'Next job: $title, $_detail',
      child: ExcludeSemantics(
        child: Column(
          // Without this the column fills the card's maximum height and the
          // minimized row grows to cover most of the map.
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Next job',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              title,
              maxLines: stacked ? 3 : 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
    final toggle = IconButton(
      tooltip: 'Show next job',
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      icon: const Icon(Icons.keyboard_arrow_up),
      onPressed: onToggle,
    );
    final start = Tooltip(
      message: 'Start next job',
      child: AppButton(
        text: 'Start',
        width: stacked ? double.infinity : 96,
        height: 48,
        isLoading: starting,
        onPressed: onStart,
      ),
    );
    if (!stacked) {
      return Row(
        children: [
          ExcludeSemantics(child: number),
          const SizedBox(width: 12),
          Expanded(child: summary),
          const SizedBox(width: 8),
          start,
          toggle,
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(child: number),
            const SizedBox(width: 12),
            Expanded(child: summary),
            toggle,
          ],
        ),
        Padding(padding: const EdgeInsets.only(right: 8), child: start),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = next.task.title;
    final number = Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fcAccent(context).withValues(alpha: .15),
        shape: BoxShape.circle,
      ),
      child: Text(
        '${next.waypoint.sequenceOrder}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: fcAccent(context),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    return Material(
      color: theme.colorScheme.surface,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        side: BorderSide(color: theme.dividerTheme.color ?? theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
        child: collapsed
            ? _collapsed(context, number, title)
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            'Next job',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Minimize',
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down),
                        onPressed: onToggle,
                      ),
                    ],
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Semantics(
                              liveRegion: true,
                              label: 'Next job: $title, $_detail',
                              child: ExcludeSemantics(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    number,
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: theme.textTheme.titleMedium,
                                          ),
                                          Text(
                                            crewTaskPlaceLine(next.task),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                          Text(
                                            _detail,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 12, 8, 0),
                            child: Semantics(
                              container: true,
                              label: 'Route order',
                              child: SegmentedButton<CrewRouteOrder>(
                                showSelectedIcon: false,
                                style: ButtonStyle(
                                  minimumSize: const WidgetStatePropertyAll(
                                    Size(48, 48),
                                  ),
                                ),
                                segments: [
                                  for (final value in CrewRouteOrder.values)
                                    ButtonSegment(
                                      value: value,
                                      label: Text(
                                        value.label,
                                        textAlign: TextAlign.center,
                                      ),
                                      tooltip: switch (value) {
                                        CrewRouteOrder.priority =>
                                          'Most urgent job first, following the published route',
                                        CrewRouteOrder.nearest =>
                                          'Closest job to you first',
                                      },
                                    ),
                                ],
                                selected: {order},
                                onSelectionChanged: (selection) =>
                                    onOrderChanged(selection.single),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 8, 0),
                    child: AppButton(
                      text: starting ? 'Loading directions…' : 'Start next job',
                      icon: Icons.near_me_outlined,
                      isLoading: starting,
                      onPressed: onStart,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      onPressed: onSeeStops,
                      icon: const Icon(Icons.expand_less),
                      iconAlignment: IconAlignment.end,
                      label: Text(
                        'See all $stopCount ${stopCount == 1 ? 'stop' : 'stops'}',
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
