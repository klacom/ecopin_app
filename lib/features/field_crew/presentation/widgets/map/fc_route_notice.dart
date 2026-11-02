import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';

/// Small pill at the top of the map: “5 stops · 2.4 km · about 35 min”.
class FcRouteChip extends StatelessWidget {
  const FcRouteChip({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        elevation: 2,
        color: theme.colorScheme.surface,
        shape: StadiumBorder(
          side: BorderSide(
            color: theme.dividerTheme.color ?? theme.dividerColor,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// A persistent notice over the map (location, signal). It stays until the
/// situation changes, unlike a snackbar.
class FcRouteNotice extends StatelessWidget {
  const FcRouteNotice({
    super.key,
    required this.icon,
    required this.message,
    this.actions = const [],
    this.busy = false,
  });
  final IconData icon;
  final String message;
  final List<Widget> actions;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Material(
        elevation: 2,
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusCard),
          side: BorderSide(
            color: theme.dividerTheme.color ?? theme.dividerColor,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: busy
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : Icon(icon),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(message, style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
              if (actions.isNotEmpty) Wrap(spacing: 8, children: actions),
            ],
          ),
        ),
      ),
    );
  }
}
