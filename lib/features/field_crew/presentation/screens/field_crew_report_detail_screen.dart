import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/core/database/app_database.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/fc_local_photo_repository.dart';
import 'package:ecopin_app/features/field_crew/providers/fc_report_detail_notifier.dart';
import 'package:ecopin_app/features/field_crew/providers/cleanup_task_detail_provider.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_report_metadata_card.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_photo_upload_section.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_lgu_notes_section.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_activity_log.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_report_action_buttons.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_shimmer_card.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_conflict_summary.dart';
import 'package:ecopin_app/features/field_crew/providers/fc_local_repository_provider.dart';
import 'package:ecopin_app/features/field_crew/providers/field_crew_reports_provider.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_trigger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';

class FieldCrewReportDetailScreen extends ConsumerWidget {
  final String reportId;
  final String? taskId;

  const FieldCrewReportDetailScreen(
      {super.key, required this.reportId, this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(fcReportDetailNotifierProvider(reportId));
    final taskAsync =
        taskId != null ? ref.watch(cleanupTaskDetailProvider(taskId!)) : null;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimaryDark),
          onPressed: () => context.pop(),
        ),
        title: Text('Report Details',
            style:
                AppTypography.h5.copyWith(color: AppColors.textPrimaryDark)),
        actions: [
          if (detailState.report != null)
            _PendingSyncBadge(reportId: reportId),
        ],
      ),
      body: _buildBody(context, ref, detailState, taskAsync),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    FcReportDetailState detailState,
    AsyncValue? taskAsync,
  ) {
    if (detailState.isLoading && detailState.report == null) {
      return const _ReportDetailSkeleton();
    }

    if (detailState.errorMessage != null && detailState.report == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Could not load report.',
                  style: AppTypography.h5
                      .copyWith(color: AppColors.textPrimaryDark)),
              const SizedBox(height: 8),
              Text(detailState.errorMessage!,
                  style:
                      AppTypography.caption.copyWith(color: AppColors.error),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref
                    .read(fcReportDetailNotifierProvider(reportId).notifier)
                    .refresh(),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final report = detailState.report!;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    Widget? taskBanner;
    bool isAssigned = currentUserId != null;

    if (taskAsync != null) {
      taskAsync.whenData((task) {
        isAssigned = currentUserId != null &&
            task.assignedCrewIds.contains(currentUserId);
        taskBanner = Container(
          padding: const EdgeInsets.all(AppColors.spaceMD),
          decoration: BoxDecoration(
            color: AppColors.primaryDark.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppColors.radiusCard),
            border:
                Border.all(color: AppColors.primaryDark.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.link, color: AppColors.primaryDark),
              const SizedBox(width: AppColors.spaceMD),
              Expanded(
                child: Text(
                  'Part of Task: ${taskAsync.value?.title ?? ""}',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.primaryDark),
                ),
              ),
            ],
          ),
        );
      });
    }

    final notifier =
        ref.read(fcReportDetailNotifierProvider(reportId).notifier);

    return RefreshIndicator(
      onRefresh: () async => notifier.refresh(),
      color: AppColors.primaryDark,
      backgroundColor: AppColors.surfaceDark,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(AppColors.spaceLG),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (taskBanner != null) ...[
                    taskBanner!,
                    const SizedBox(height: AppColors.spaceLG),
                  ],

                  // Phase 5: conflict summary banner (auto-dismisses after 12 s)
                  const FcConflictSummary(),

                  // Metadata
                  FcReportMetadataCard(report: report),
                  const SizedBox(height: AppColors.spaceLG),

                  // Action buttons (status transitions)
                  FcReportActionButtons(
                    report: report,
                    isAssigned: isAssigned,
                    hasBeforePhoto: report.beforePhotoUrl != null,
                    hasAfterPhoto: report.afterPhotoUrl != null,
                    onViewOnMap: () => context.push('/field-crew/map'),
                    onStatusChange: (newStatus) async {
                      await notifier.updateStatus(newStatus);
                    },
                  ),
                  const SizedBox(height: AppColors.spaceXL),

                  // Photo Verification — offline-first with local photo slots
                  _ReportPhotoSection(
                    report: report,
                    isAssigned: isAssigned,
                    evidencePhotos: detailState.evidence,
                    onUpload: (file, type) async {
                      try {
                        final repo =
                            ref.read(fieldCrewReportRepositoryProvider);
                        await repo.uploadReportPhoto(reportId, file, type);
                        await notifier.refresh();
                      } catch (e) {
                        rethrow;
                      }
                    },
                    onDelete: (slot, type) async {
                      try {
                        final repo =
                            ref.read(fieldCrewReportRepositoryProvider);
                        await repo.deleteReportPhoto(reportId, type);
                        await notifier.refresh();
                      } catch (e) {
                        rethrow;
                      }
                    },
                  ),
                  const SizedBox(height: AppColors.spaceXL),

                  // Notes input — local-first
                  FcLguNotesSection(
                    isAssigned: isAssigned,
                    onSubmit: (note) async {
                      await notifier.addNote(note);
                    },
                  ),
                  const SizedBox(height: AppColors.spaceXL),

                  // Activity log from local + remote state
                  FcActivityLog(responses: detailState.notes),
                  const SizedBox(height: AppColors.spaceXL),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Photo section — resolves FcLocalPhoto rows then renders FcPhotoUploadSection
// ─────────────────────────────────────────────────────────────────────────────

/// Queries [FcLocalPhotos] for local pending rows, then merges with the remote
/// URL fallback from [ReportModel] to produce [FcPhotoSlot] objects.
///
/// Using a [ConsumerStatefulWidget] here means the slot resolution is a one-
/// shot async load that re-runs whenever the parent calls [notifier.refresh()]
/// (which rebuilds this widget because the parent passes new [remoteBeforeUrl]/
/// [remoteAfterUrl] values).
class _ReportPhotoSection extends ConsumerStatefulWidget {
  final ReportModel report;
  final bool isAssigned;
  final List<dynamic> evidencePhotos;
  final Future<void> Function(dynamic file, String type) onUpload;
  final Future<void> Function(FcPhotoSlot slot, String type) onDelete;

  const _ReportPhotoSection({
    required this.report,
    required this.isAssigned,
    required this.evidencePhotos,
    required this.onUpload,
    required this.onDelete,
  });

  @override
  ConsumerState<_ReportPhotoSection> createState() =>
      _ReportPhotoSectionState();
}

class _ReportPhotoSectionState extends ConsumerState<_ReportPhotoSection> {
  FcPhotoSlot? _beforeSlot;
  FcPhotoSlot? _afterSlot;

  @override
  void initState() {
    super.initState();
    _resolveSlots();
  }

  @override
  void didUpdateWidget(_ReportPhotoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-resolve when parent refreshes (remote URL may have changed or new
    // local row may have been inserted).
    if (oldWidget.report.beforePhotoUrl != widget.report.beforePhotoUrl ||
        oldWidget.report.afterPhotoUrl != widget.report.afterPhotoUrl ||
        oldWidget.report.id != widget.report.id) {
      _resolveSlots();
    }
  }

  Future<void> _resolveSlots() async {
    final photoRepo = ref.read(fcLocalPhotoRepositoryProvider);
    final before = await photoRepo.getActivePhoto(
      widget.report.id,
      'report',
      'before',
    );
    final after = await photoRepo.getActivePhoto(
      widget.report.id,
      'report',
      'after',
    );

    if (!mounted) return;
    setState(() {
      _beforeSlot = _buildSlot(before, widget.report.beforePhotoUrl);
      _afterSlot = _buildSlot(after, widget.report.afterPhotoUrl);
    });
  }

  /// Merges a local DB row with the remote URL fallback from [ReportModel].
  ///
  /// Priority:
  ///   1. If a local [FcLocalPhoto] row exists, it drives the slot entirely
  ///      (its remoteUrl field will be set once synced).
  ///   2. If only a remote URL exists (pre-Phase-3 legacy data), wrap it in
  ///      a synced-looking slot so the widget can display it.
  FcPhotoSlot? _buildSlot(FcLocalPhoto? localRow, String? remoteUrl) {
    if (localRow != null) {
      return FcPhotoSlot(
        localPhotoId: localRow.localPhotoId,
        localPath: localRow.localPath,
        remoteUrl: localRow.remoteUrl,
        syncStatus: localRow.syncStatus,
      );
    }
    // No local row — fall back to legacy remote URL if available.
    if (remoteUrl != null && remoteUrl.isNotEmpty) {
      return FcPhotoSlot(
        remoteUrl: remoteUrl,
        // syncStatus is null → widget shows no badge (already synced legacy photo)
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final currentStatus = widget.report.status.toLowerCase();
    final bool isAcknowledged = !['unresolved', 'submitted', 'pending'].contains(currentStatus);
    
    final currentLifecycle = widget.report.lifecycleStage?.toLowerCase();
    final bool isLifecycleAcknowledged = currentLifecycle != null && !['new', 'pending', 'under_review'].contains(currentLifecycle);
    
    final bool effectivelyAcknowledged = isAcknowledged || isLifecycleAcknowledged;
    
    final bool isBeforeEnabled = effectivelyAcknowledged;
    final bool isAfterEnabled = effectivelyAcknowledged && (_beforeSlot?.hasPhoto == true);

    return FcPhotoUploadSection(
      evidencePhotos: widget.evidencePhotos,
      beforeSlot: _beforeSlot,
      afterSlot: _afterSlot,
      isAssigned: widget.isAssigned,
      isBeforeEnabled: isBeforeEnabled,
      isAfterEnabled: isAfterEnabled,
      onUpload: (file, type) async {
        await widget.onUpload(file, type);
        // Re-resolve slots after upload so new local row is visible immediately.
        await _resolveSlots();
      },
      onDelete: (slot, type) async {
        await widget.onDelete(slot, type);
        await _resolveSlots();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pending sync badge
// ─────────────────────────────────────────────────────────────────────────────

class _PendingSyncBadge extends ConsumerWidget {
  final String reportId;
  const _PendingSyncBadge({required this.reportId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch fcSyncStateProvider — rebuilds whenever a sync run completes.
    // Fall back to a direct DB check via FutureBuilder on first load (before
    // any sync has run and the notifier is still idle).
    final syncState = ref.watch(fcSyncStateProvider);
    final localRepo = ref.watch(fcLocalRepositoryProvider);

    // If a sync just completed and everything succeeded, hide the badge
    // immediately without a DB round-trip.
    if (syncState.phase == FcSyncPhase.success &&
        syncState.lastSyncAt != null) {
      return const SizedBox.shrink();
    }

    // Otherwise check the DB — this covers the initial load and partial-
    // failure states where some items for THIS report may still be pending.
    return FutureBuilder<bool>(
      // Re-run the future every time syncState changes so the badge
      // disappears as soon as this report's items drain.
      key: ValueKey(syncState.lastSyncAt),
      future: _hasPending(localRepo, reportId),
      builder: (context, snap) {
        if (snap.data != true) return const SizedBox.shrink();
        return _SyncChip(phase: syncState.phase);
      },
    );
  }

  Future<bool> _hasPending(dynamic localRepo, String reportId) async {
    final items = await localRepo.getPendingOutboxItems();
    return items.any((i) => i.entityId == reportId);
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
// Loading skeleton
// ─────────────────────────────────────────────────────────────────────────────

class _ReportDetailSkeleton extends StatelessWidget {
  const _ReportDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppColors.spaceLG),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: const [
                FcShimmerCard(height: 80),
                SizedBox(height: AppColors.spaceLG),
                FcShimmerCard(height: 180),
                SizedBox(height: AppColors.spaceLG),
                FcShimmerCard(height: 100),
                SizedBox(height: AppColors.spaceXL),
                FcShimmerCard(height: 250),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
