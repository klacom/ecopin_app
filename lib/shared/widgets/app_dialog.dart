import 'package:ecopin_app/core/theme/colors.dart';
import 'package:flutter/material.dart';

/// One frame for confirmation and form dialogs (log out, change password,
/// delete account): 24dp corners, optional tinted icon, a 20dp bold title, an
/// optional message and body, and actions that sit in a row or stack at full
/// width. Content scrolls so large text and the keyboard never clip actions.
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    required this.actions,
    this.icon,
    this.iconColor,
    this.message,
    this.child,
    this.centered = false,
    this.stackActions = false,
  });

  final String title;
  final IconData? icon;
  final Color? iconColor;
  final String? message;
  final Widget? child;

  /// Centers the icon, title and message (confirmations); forms stay start-aligned.
  final bool centered;
  final List<Widget> actions;

  /// Full-width stacked actions (narrow content or a destructive primary).
  final bool stackActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = iconColor ?? theme.colorScheme.primary;
    final align = centered
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusDialog),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Content scrolls; the actions stay pinned so they are always reachable.
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: align,
                  children: [
                    if (icon != null) ...[
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: tone.withValues(alpha: .12),
                          shape: BoxShape.circle,
                        ),
                        child: ExcludeSemantics(
                          child: Icon(icon, color: tone, size: 28),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        textAlign: centered
                            ? TextAlign.center
                            : TextAlign.start,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        message!,
                        textAlign: centered
                            ? TextAlign.center
                            : TextAlign.start,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (child != null) ...[const SizedBox(height: 16), child!],
                  ],
                ),
              ),
            ),
            Padding(padding: const EdgeInsets.all(24), child: _actions()),
          ],
        ),
      ),
    );
  }

  Widget _actions() {
    if (stackActions) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            actions[i],
          ],
        ],
      );
    }
    if (centered) {
      return Row(
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: actions[i]),
          ],
        ],
      );
    }
    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        children: actions,
      ),
    );
  }
}
