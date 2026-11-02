import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/features/field_crew/presentation/controllers/fc_route_presentation.dart';

/// Turn guidance at the top of the map: the next turn large, then where the
/// crew is heading and how the directions are being supplied. White text on
/// civic blue, per the contract.
class FcRouteNavBanner extends StatelessWidget {
  const FcRouteNavBanner({
    super.key,
    required this.instruction,
    required this.turnIcon,
    required this.destinationTitle,
    required this.routeSummary,
    required this.status,
    this.distanceToTurn,
  });

  /// “Turn left onto Caruncho Avenue”, or the saved-path note.
  final String instruction;
  final IconData turnIcon;

  /// Straight-line distance to the next turn, when turn guidance is running.
  final String? distanceToTurn;
  final String destinationTitle;

  /// “1.2 km · about 6 min”, or a sentence saying they are unavailable.
  final String routeSummary;

  /// Whether these directions are live from the internet or a saved copy.
  final CrewDirectionsStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 3,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        side: BorderSide(color: theme.dividerTheme.color ?? theme.dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: true,
            label: distanceToTurn == null
                ? instruction
                : 'In $distanceToTurn. $instruction',
            child: ExcludeSemantics(
              child: Container(
                color: AppColors.primaryDark,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(turnIcon, color: Colors.white, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (distanceToTurn != null)
                            Text(
                              'In $distanceToTurn',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          Text(
                            instruction,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
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
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Going to: ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: destinationTitle,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  routeSummary,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                _SourceRow(status: status),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One bold line naming where the directions come from (online or saved on
/// this phone), then a sentence on what that means. The icon backs up the
/// words and never replaces them.
class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.status});

  final CrewDirectionsStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: '${status.title}. ${status.detail}',
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppColors.radiusCard / 2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(status.icon, size: 20, color: theme.colorScheme.onSurface),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      status.detail,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
