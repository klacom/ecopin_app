import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import 'package:ecopin_app/features/field_crew/providers/fc_task_detail_notifier.dart';
import 'package:ecopin_app/features/field_crew/providers/cleanup_tasks_provider.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_report_table.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_photo_gallery_card.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_photo_upload_section.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_task_sidebar_card.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_progress_bar.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_mark_complete_button.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_shimmer_card.dart';
import 'package:ecopin_app/features/field_crew/providers/fc_local_repository_provider.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/fc_local_photo_repository.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_conflict_summary.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_trigger.dart';
import 'package:ecopin_app/core/database/app_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FieldCrewTaskDetailScreen extends ConsumerWidget {
  final String taskId;

  const FieldCrewTaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fcTaskDetailNotifierProvider(taskId));
    final notifier = ref.read(fcTaskDetailNotifierProvider(taskId).notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back, color: AppColors.textPrimaryDark),
          onPressed: () => context.pop(),
        ),
        title: Text('Task Details',
            style:
                AppTypography.h5.copyWith(color: AppColors.textPrimaryDark)),
        actions: [
          if (state.task != null) _PendingSyncBadge(taskId: taskId),
        ],
      ),
      body: _buildBody(context, ref, state, notifier),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    FcTaskDetailState state,
    FcTaskDetailNotifier notifier,
  ) {
    if (state.isLoading && state.task == null) {
      return const _TaskDetailSkeleton();
    }

    if (state.errorMessage != null && state.task == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Could not load task.',
                  style: AppTypography.h5
                      .copyWith(color: AppColors.textPrimaryDark)),
              const SizedBox(height: 8),
              Text(state.errorMessage!,
                  style:
                      AppTypography.caption.copyWith(color: AppColors.error),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: notifier.refresh,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final task = state.task!;
    final reports = state.reports;
    final currentUserId =
        Supabase.instance.client.auth.currentUser?.id;
    final isAssigned = currentUserId != null &&
        task.assignedCrewIds.contains(currentUserId);

    // Resolved count computed from local state.
    int resolvedCount = 0;
    for (final r in reports) {
      final isScouting =
          r.issueType == 'scouting' || r.issueType == 'acknowledge_only';
      final isResolved = r.status.toLowerCase() == 'resolved' ||
          r.status.toLowerCase() == 'closed';
      if (isScouting) {
        if (r.validationStatus.toLowerCase() == 'validated' || isResolved) {
          resolvedCount++;
        }
      } else {
        if (isResolved) resolvedCount++;
      }
    }

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      color: AppColors.primaryDark,
      backgroundColor: AppColors.surfaceDark,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(
              left: AppColors.spaceLG,
              right: AppColors.spaceLG,
              top: AppColors.spaceLG,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Phase 5: conflict summary banner
                  const FcConflictSummary(),

                  FcTaskSidebarCard(task: task),
                  const SizedBox(height: AppColors.spaceLG),

                  // Progress bar
                  Container(
                    padding: const EdgeInsets.all(AppColors.spaceLG),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(AppColors.radiusCard),
                      border: Border.all(color: AppColors.dividerDark),
                    ),
                    child: FcProgressBar(
                      current: resolvedCount,
                      total: reports.length,
                      label: 'Cluster Progress',
                    ),
                  ),
                  const SizedBox(height: AppColors.spaceLG),

                  // Task-level Before/After photos (offline-first)
                  _TaskPhotoSection(
                    task: task,
                    isAssigned: isAssigned,
                    onUpload: (file, type) async {
                      final repo =
                          ref.read(cleanupTaskRepositoryProvider);
                      await repo.uploadTaskPhoto(task.id, file, type);
                      await notifier.refresh();
                    },
                    onDelete: (slot, type) async {
                      final repo =
                          ref.read(cleanupTaskRepositoryProvider);
                      await repo.deleteTaskPhoto(task.id, type);
                      await notifier.refresh();
                    },
                  ),
                  const SizedBox(height: AppColors.spaceLG),

                  // Mark Complete — uses local state, completes immediately
                  FcMarkCompleteButton(
                    task: task,
                    reports: reports,
                    onComplete: () async {
                      await notifier.markComplete();
                      ref
                          .read(completedTasksProvider.notifier)
                          .addCompletedTask(taskId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Task marked as complete!'),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: AppColors.spaceXL),

                  // Photo gallery
                  FcPhotoGalleryCard(reports: reports),
                  const SizedBox(height: AppColors.spaceXL),

                  Text(task.isOutlier ? 'Optimized Route Waypoints' : 'Reports in this Task',
                      style: AppTypography.h4
                          .copyWith(color: AppColors.textPrimaryDark)),
                  const SizedBox(height: AppColors.spaceMD),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppColors.spaceLG),
            sliver: FcReportTable(reports: reports, taskId: taskId),
          ),
          const SliverPadding(
            padding: EdgeInsets.only(bottom: AppColors.spaceXL),
          ),
        ],
      ),
    );
  }
}

class _TaskDetailSkeleton extends StatelessWidget {
  const _TaskDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppColors.spaceLG),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: const [
                FcShimmerCard(height: 200),
                SizedBox(height: AppColors.spaceLG),
                FcShimmerCard(height: 100),
                SizedBox(height: AppColors.spaceLG),
                FcShimmerCard(height: 60),
                SizedBox(height: AppColors.spaceXL),
                FcShimmerCard(height: 300),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Small chip in the AppBar indicating pending sync.
class _PendingSyncBadge extends ConsumerWidget {
  final String taskId;
  const _PendingSyncBadge({required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(fcSyncStateProvider);
    final localRepo = ref.watch(fcLocalRepositoryProvider);

    if (syncState.phase == FcSyncPhase.success &&
        syncState.lastSyncAt != null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<bool>(
      key: ValueKey(syncState.lastSyncAt),
      future: _hasPending(localRepo, taskId),
      builder: (context, snap) {
        if (snap.data != true) return const SizedBox.shrink();
        return _SyncChip(phase: syncState.phase);
      },
    );
  }

  Future<bool> _hasPending(dynamic localRepo, String taskId) async {
    final items = await localRepo.getPendingOutboxItems();
    return items.any((i) => i.entityId == taskId);
  }
}

/// Small AppBar chip showing sync status.
class _SyncChip extends StatelessWidget {
  final FcSyncPhase phase;
  const _SyncChip({required this.phase});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (phase) {
      FcSyncPhase.syncing => ('Syncing…', AppColors.primaryDark),
      FcSyncPhase.error => ('Sync Error', AppColors.error),
      _ => ('Pending Sync', AppColors.warning),
    };
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Chip(
        label: Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.white)),
        backgroundColor: color,
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: -4),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Task-level photo section
// ─────────────────────────────────────────────────────────────────────────────

/// Resolves [FcLocalPhoto] rows for a task's before/after slots and renders
/// [FcPhotoUploadSection].
///
/// Mirrors the pattern used by [_ReportPhotoSection] in the report detail
/// screen so both entity types share identical offline-first UX.
class _TaskPhotoSection extends ConsumerStatefulWidget {
  final CleanupTask task;
  final bool isAssigned;
  final Future<void> Function(dynamic file, String type) onUpload;
  final Future<void> Function(FcPhotoSlot slot, String type) onDelete;

  const _TaskPhotoSection({
    required this.task,
    required this.isAssigned,
    required this.onUpload,
    required this.onDelete,
  });

  @override
  ConsumerState<_TaskPhotoSection> createState() => _TaskPhotoSectionState();
}

class _TaskPhotoSectionState extends ConsumerState<_TaskPhotoSection> {
  FcPhotoSlot? _beforeSlot;
  FcPhotoSlot? _afterSlot;

  @override
  void initState() {
    super.initState();
    _resolveSlots();
  }

  @override
  void didUpdateWidget(_TaskPhotoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id ||
        oldWidget.task.beforePhotoUrl != widget.task.beforePhotoUrl ||
        oldWidget.task.afterPhotoUrl != widget.task.afterPhotoUrl) {
      _resolveSlots();
    }
  }

  Future<void> _resolveSlots() async {
    final photoRepo = ref.read(fcLocalPhotoRepositoryProvider);
    final before =
        await photoRepo.getActivePhoto(widget.task.id, 'task', 'before');
    final after =
        await photoRepo.getActivePhoto(widget.task.id, 'task', 'after');

    if (!mounted) return;
    setState(() {
      _beforeSlot = _buildSlot(before, widget.task.beforePhotoUrl);
      _afterSlot = _buildSlot(after, widget.task.afterPhotoUrl);
    });
  }

  FcPhotoSlot? _buildSlot(FcLocalPhoto? localRow, String? remoteUrl) {
    if (localRow != null) {
      return FcPhotoSlot(
        localPhotoId: localRow.localPhotoId,
        localPath: localRow.localPath,
        remoteUrl: localRow.remoteUrl,
        syncStatus: localRow.syncStatus,
      );
    }
    if (remoteUrl != null && remoteUrl.isNotEmpty) {
      return FcPhotoSlot(remoteUrl: remoteUrl);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Only show the section if there are photos or the user is assigned.
    final hasContent = (_beforeSlot != null && _beforeSlot!.hasPhoto) ||
        (_afterSlot != null && _afterSlot!.hasPhoto) ||
        widget.isAssigned;

    if (!hasContent) return const SizedBox.shrink();

    return FcPhotoUploadSection(
      evidencePhotos: const [], // Tasks have no citizen evidence
      beforeSlot: _beforeSlot,
      afterSlot: _afterSlot,
      isAssigned: widget.isAssigned,
      onUpload: (file, type) async {
        await widget.onUpload(file, type);
        await _resolveSlots();
      },
      onDelete: (slot, type) async {
        await widget.onDelete(slot, type);
        await _resolveSlots();
      },
    );
  }
}
