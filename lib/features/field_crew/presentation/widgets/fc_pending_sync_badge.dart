import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/features/field_crew/providers/fc_local_repository_provider.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_trigger.dart';
import '../../sync/fc_sync_settings.dart';

/// AppBar chip shown while a task or report has unsynced local work.
/// Shared by the task and report detail screens ([entityId] is the task or report id).
class FcPendingSyncBadge extends ConsumerWidget {
  const FcPendingSyncBadge({super.key, required this.entityId});
  final String entityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(fcSyncStateProvider);
    ref.watch(fcPendingWritesProvider);
    final automatic = ref.watch(fcSyncSettingsProvider).autoSyncEnabled;
    final localRepo = ref.watch(fcLocalRepositoryProvider);

    return FutureBuilder<bool>(
      key: ValueKey(syncState.lastSyncAt),
      future: _hasPending(localRepo, ref),
      builder: (context, snap) {
        if (snap.data != true) return const SizedBox.shrink();
        return FcSyncChip(phase: syncState.phase, automatic: automatic);
      },
    );
  }

  Future<bool> _hasPending(dynamic localRepo, WidgetRef ref) async {
    final items = await localRepo.getPendingOutboxItems();
    if (items.any((i) => i.entityId == entityId)) return true;
    final photos = ref.read(fcLocalPhotoRepositoryProvider);
    final uploads = await photos.getPendingUploads();
    final deletes = await photos.getPendingDeletes();
    return [...uploads, ...deletes].any((p) => p.entityId == entityId);
  }
}

/// Small status chip with a written state and an icon, 12sp or larger. Colors
/// come from the theme's status colors, so both themes keep their contrast.
class FcSyncChip extends StatelessWidget {
  const FcSyncChip({super.key, required this.phase, required this.automatic});
  final FcSyncPhase phase;
  final bool automatic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = theme.extension<AppStatusColors>();
    final (label, icon, color) = switch (phase) {
      FcSyncPhase.syncing => (
        'Sending',
        Icons.sync,
        status?.info ?? theme.colorScheme.primary,
      ),
      FcSyncPhase.error || FcSyncPhase.partialFailure => (
        'Did not send',
        Icons.sync_problem,
        status?.error ?? theme.colorScheme.error,
      ),
      _ => (
        automatic ? 'Waiting to send' : 'Saved on this phone',
        Icons.schedule,
        status?.warning ?? theme.colorScheme.onSurface,
      ),
    };
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          border: Border.all(color: color.withValues(alpha: .4)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(child: Icon(icon, size: 16, color: color)),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
