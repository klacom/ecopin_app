import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'fc_offline_ui.dart';

enum FcStatusTone { accent, success, warning, error }

/// The card at the top of a crew screen that answers “what do I do now?”: an
/// icon, one bold sentence, one sentence of detail, and at most one button.
/// Colour backs up the words and never carries the state alone. Shared by
/// Send your work and Download your jobs.
class FcStatusCard extends StatelessWidget {
  const FcStatusCard({
    super.key,
    required this.tone,
    required this.icon,
    required this.title,
    required this.detail,
    this.showProgress = false,
    this.progress,
    this.actionLabel,
    this.actionIcon,
    this.primary = false,
    this.onAction,
    this.footnote,
  });

  final FcStatusTone tone;
  final IconData icon;
  final String title;
  final String detail;

  /// Shows a bar; [progress] null means it runs without a known end.
  final bool showProgress;
  final double? progress;
  final String? actionLabel;
  final IconData? actionIcon;
  final bool primary;
  final VoidCallback? onAction;

  /// A quiet line under the button, for what the state does not cover.
  final String? footnote;

  Color _color(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppStatusColors>();
    return switch (tone) {
      FcStatusTone.success => colors?.success ?? theme.colorScheme.onSurface,
      FcStatusTone.warning => colors?.warning ?? theme.colorScheme.onSurface,
      FcStatusTone.error => colors?.error ?? theme.colorScheme.error,
      FcStatusTone.accent => fcAccent(context),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _color(context);
    return FcOfflineCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: true,
            container: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          detail,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showProgress) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: progress, semanticsLabel: title),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            AppButton(
              text: actionLabel!,
              icon: actionIcon,
              variant: primary
                  ? ButtonVariant.primary
                  : ButtonVariant.secondary,
              onPressed: onAction,
            ),
          ],
          if (footnote != null) ...[
            const SizedBox(height: 12),
            Text(footnote!, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
