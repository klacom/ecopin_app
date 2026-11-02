import 'package:flutter/material.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';

/// Bottom sheet shown when a pin is tapped. The primary action opens the
/// existing detail screen; navigation, when offered, is secondary. Opening
/// details never starts or completes anything.
Future<void> showFcRoutePreview(
  BuildContext context, {
  required List<Widget> badges,
  required String title,
  required String primaryLabel,
  required VoidCallback onPrimary,
  String? place,
  String? placeDetail,
  String? description,
  String? details,
  String? secondaryLabel,
  VoidCallback? onSecondary,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final colors = theme.colorScheme;
      return SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * .8,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: badges,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close preview',
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ),
                if (place != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ExcludeSemantics(
                        child: Icon(Icons.location_on_outlined, size: 24),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(place, style: theme.textTheme.bodyMedium),
                            if (placeDetail != null)
                              Text(
                                placeDetail,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                if (details != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    details,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
                if (description != null && description.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(description, style: theme.textTheme.bodyMedium),
                ],
                const SizedBox(height: 24),
                AppButton(
                  text: primaryLabel,
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    onPrimary();
                  },
                ),
                if (secondaryLabel != null && onSecondary != null) ...[
                  const SizedBox(height: 12),
                  AppButton(
                    text: secondaryLabel,
                    icon: Icons.near_me_outlined,
                    variant: ButtonVariant.secondary,
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      onSecondary();
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}
