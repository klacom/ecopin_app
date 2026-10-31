import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/core/theme/colors.dart';
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

/// Small status chip. Text is 12sp; warning (amber) uses dark text because white fails contrast on it.
class FcSyncChip extends StatelessWidget {
  const FcSyncChip({super.key, required this.phase, required this.automatic});
  final FcSyncPhase phase;
  final bool automatic;

  @override
  Widget build(BuildContext context) {
    final (label, color, textColor) = switch (phase) {
      FcSyncPhase.syncing => ('Syncing…', AppColors.primaryDark, Colors.white),
      FcSyncPhase.error => ('Sync Error', AppColors.error, Colors.white),
      FcSyncPhase.partialFailure => (
        'Sync attention',
        AppColors.error,
        Colors.white,
      ),
      _ => (
        automatic ? 'Sync queued' : 'Pending Sync',
        AppColors.warningFill,
        Colors.black87,
      ),
    };
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Chip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        backgroundColor: color,
        side: BorderSide.none,
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}
