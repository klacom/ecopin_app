import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import '../controllers/fc_sync_center_presentation.dart';
import '../controllers/fc_sync_ui_providers.dart';

/// One item that did not send: what it is, a plain sentence about why, and the
/// server's own words under Details. The “Did not send” tag is text, so the
/// red border is never the only signal.
class FcSyncFailureCard extends StatelessWidget {
  const FcSyncFailureCard({super.key, required this.failure});
  final FcQueuedFailure failure;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error =
        theme.extension<AppStatusColors>()?.error ?? theme.colorScheme.error;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        side: BorderSide(color: error),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(failure.label, style: theme.textTheme.titleSmall),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: error.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Did not send',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              fcPlainFailure(failure.reason),
              style: theme.textTheme.bodyMedium,
            ),
            Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                title: Text('Details', style: theme.textTheme.bodyMedium),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What the server said: ${failure.reason}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Report or job ID: ${failure.entityId}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(failure.attemptLabel, style: theme.textTheme.bodySmall),
                  if (failure.retriesPaused) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Automatic tries are paused. Read the reason before you allow another try.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
