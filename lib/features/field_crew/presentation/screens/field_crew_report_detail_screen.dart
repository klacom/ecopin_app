import '../../sync/fc_sync_settings.dart';
import '../../providers/fc_investigation_provider.dart';
import '../../providers/fc_task_detail_notifier.dart';
import '../widgets/fc_investigation_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/core/database/app_database.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
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
import 'package:ecopin_app/features/field_crew/presentation/widgets/crew_urgency_form.dart';

class FieldCrewReportDetailScreen extends ConsumerWidget {
  final String reportId;
  final String? taskId;

  const FieldCrewReportDetailScreen({
    super.key,
    required this.reportId,
    this.taskId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(fcSyncStateProvider, (previous, next) {
      if (next.lastSyncAt != null && previous?.lastSyncAt != next.lastSyncAt) {
        ref.read(fcReportDetailNotifierProvider(reportId).notifier).refresh();
      }
    });
    final detailState = ref.watch(fcReportDetailNotifierProvider(reportId));
    final taskAsync = taskId != null
        ? ref.watch(cleanupTaskDetailProvider(taskId!))
        : null;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : Colors.black87;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Report Details',
          style: AppTypography.h5.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (detailState.report != null) _PendingSyncBadge(reportId: reportId),
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
              Text(
                'Could not load report.',
                style: AppTypography.h5.copyWith(
                  color: AppColors.textPrimaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                detailState.errorMessage!,
                style: AppTypography.caption.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref
                    .read(fcReportDetailNotifierProvider(reportId).notifier)
                    .refresh(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final report = detailState.report!;
    final observationTask = taskAsync?.value;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    Widget? taskBanner;
    bool isAssigned = currentUserId != null;

    if (taskAsync != null) {
      taskAsync.whenData((task) {
        isAssigned =
            currentUserId != null &&
            task.assignedCrewIds.contains(currentUserId);
        taskBanner = Container(
          padding: const EdgeInsets.all(AppColors.spaceMD),
          decoration: BoxDecoration(
            color: AppColors.primaryDark.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppColors.radiusCard),
            border: Border.all(
              color: AppColors.primaryDark.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.link, color: AppColors.primaryDark),
              const SizedBox(width: AppColors.spaceMD),
              Expanded(
                child: Text(
                  'Part of Task: ${taskAsync.value?.title ?? ""}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        );
      });
    }

    final notifier = ref.read(
      fcReportDetailNotifierProvider(reportId).notifier,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return RefreshIndicator(
      onRefresh: () async => notifier.refresh(),
      color: AppColors.primaryDark,
      backgroundColor: cardColor,
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

                  if (taskId != null && isAssigned) ...[
                    FcInvestigationCard(
                      session: ref.watch(
                        fcActiveInvestigationProvider(taskId!),
                      ),
                      reportId: reportId,
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Metadata
                  FcReportMetadataCard(report: report),
                  if (isAssigned &&
                      report.citizenPriority == 'urgent' &&
                      observationTask != null &&
                      currentUserId != null)
                    CrewUrgencyForm(
                      key: ValueKey(
                        '$reportId:${observationTask.id}:${observationTask.assignmentGeneration}:${report.reportClaimGeneration}',
                      ),
                      canSubmit:
                          report.cleanupTaskId == observationTask.id &&
                          const [
                            'created',
                            'pending',
                            'assigned',
                            'en_route',
                            'in_progress',
                            'partially_completed',
                          ].contains(observationTask.status) &&
                          observationTask.routeStatus == 'ready',
                      onSave: (result, conditions) =>
                          notifier.addUrgencyObservation(
                            taskId: observationTask.id,
                            observerId: currentUserId,
                            assignmentGeneration:
                                observationTask.assignmentGeneration,
                            reportClaimGeneration: report.reportClaimGeneration,
                            result: result,
                            conditions: conditions,
                          ),
                    ),
                  const SizedBox(height: AppColors.spaceXL),

                  // Photo Verification + Action Buttons right below Before & After photos
                  _ReportPhotoSection(
                    report: report,
                    isAssigned: isAssigned,
                    evidencePhotos: detailState.evidence,
                    evidenceError: detailState.evidenceError,
                    onViewOnMap: () => context.push('/field-crew/map'),
                    onStatusChange: (newStatus, hasBefore, hasAfter) async {
                      if (const {
                        'resolved',
                        'completed',
                        'closed',
                      }.contains(newStatus.toLowerCase())) {
                        try {
                          if (taskId == null) {
                            throw StateError(
                              'Open the assigned task before recording completion.',
                            );
                          }
                          ref
                              .read(fcInvestigationProvider(taskId!))
                              .requireIncident(reportId);
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.toString())),
                            );
                          }
                          return;
                        }
                      }
                      if (newStatus.toLowerCase() == 'resolved') {
                        final issueType = report.issueType?.toLowerCase() ?? '';
                        final isScouting =
                            issueType == 'scouting' ||
                            issueType == 'acknowledge_only';
                        if (!isScouting && (!hasBefore || !hasAfter)) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Before and after photos are required before completing cleanup.',
                                ),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                          return;
                        }
                      }

                      if (newStatus == 'acknowledged') {
                        await notifier.updateLifecycleStage('acknowledged');
                      } else {
                        await notifier.updateStatus(newStatus);
                      }
                      if (report.breachedAt != null &&
                          (newStatus.toLowerCase() == 'resolved' ||
                              newStatus.toLowerCase() == 'closed')) {
                        if (context.mounted &&
                            taskAsync != null &&
                            taskAsync.value != null) {
                          final task = taskAsync.value!;
                          final currentIndex =
                              task.reports?.indexWhere(
                                (r) => r.id == report.id,
                              ) ??
                              -1;

                          if (currentIndex != -1 && task.reports != null) {
                            // Find next unresolved report
                            try {
                              final nextReport = task.reports!
                                  .skip(currentIndex + 1)
                                  .firstWhere(
                                    (r) =>
                                        r.status.toLowerCase() != 'resolved' &&
                                        r.status.toLowerCase() != 'closed',
                                  );
                              context.pushReplacement(
                                '/field-crew/tasks/${task.id}/reports/${nextReport.id}',
                              );
                            } catch (_) {
                              // No next report found (all done or at end of list)
                              context.pop();
                            }
                          } else {
                            context.pop();
                          }
                        }
                      }
                    },
                    onUpload: (file, type) async {
                      try {
                        final repo = ref.read(
                          fieldCrewReportRepositoryProvider,
                        );
                        await repo.uploadReportPhoto(reportId, file, type);
                        await notifier.refresh();
                      } catch (e) {
                        rethrow;
                      }
                    },
                    onDelete: (slot, type) async {
                      try {
                        final repo = ref.read(
                          fieldCrewReportRepositoryProvider,
                        );
                        await repo.deleteReportPhoto(
                          reportId,
                          type,
                          photoId: slot.remoteId ?? slot.localPhotoId,
                        );
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
class _ReportPhotoSection extends ConsumerStatefulWidget {
  final ReportModel report;
  final bool isAssigned;
  final List<dynamic> evidencePhotos;
  final String? evidenceError;
  final VoidCallback onViewOnMap;
  final Future<void> Function(String newStatus, bool hasBefore, bool hasAfter)
  onStatusChange;
  final Future<void> Function(dynamic file, String type) onUpload;
  final Future<void> Function(FcPhotoSlot slot, String type) onDelete;

  const _ReportPhotoSection({
    required this.report,
    required this.isAssigned,
    required this.evidencePhotos,
    this.evidenceError,
    required this.onViewOnMap,
    required this.onStatusChange,
    required this.onUpload,
    required this.onDelete,
  });

  @override
  ConsumerState<_ReportPhotoSection> createState() =>
      _ReportPhotoSectionState();
}

class _ReportPhotoSectionState extends ConsumerState<_ReportPhotoSection> {
  FcPhotoSlot? _beforeSlot;
  List<FcPhotoSlot> _beforeSlots = [];
  FcPhotoSlot? _afterSlot;
  List<FcPhotoSlot> _afterSlots = [];

  @override
  void initState() {
    super.initState();
    _resolveSlots();
  }

  @override
  void didUpdateWidget(_ReportPhotoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.report.beforePhotos != widget.report.beforePhotos ||
        oldWidget.report.afterPhotos != widget.report.afterPhotos ||
        oldWidget.report.beforePhotoUrl != widget.report.beforePhotoUrl ||
        oldWidget.report.afterPhotoUrl != widget.report.afterPhotoUrl ||
        oldWidget.report.status != widget.report.status ||
        oldWidget.report.lifecycleStage != widget.report.lifecycleStage ||
        oldWidget.report.id != widget.report.id) {
      _resolveSlots();
    }
  }

  Future<void> _resolveSlots() async {
    final photoRepo = ref.read(fcLocalPhotoRepositoryProvider);
    final allRows = await photoRepo.getPhotosForEntity(
      widget.report.id,
      'report',
    );
    final pendingDeletes = await photoRepo.getPendingDeletes();

    List<FcPhotoSlot> buildSlotsForType(
      String photoType,
      List<Map<String, dynamic>> remoteCollection,
      String? legacyUrl,
    ) {
      final rows = allRows.where((p) => p.photoType == photoType).toList();
      final deletedIds = pendingDeletes
          .where(
            (p) =>
                p.entityId == widget.report.id &&
                p.entityType == 'report' &&
                p.photoType == photoType,
          )
          .map((p) => p.remoteId ?? p.localPhotoId)
          .toSet();
      final slots = rows.map((p) => _buildSlot(p, null)!).toList();
      final urls = slots.map((p) => p.remoteUrl).toSet();
      for (final photo in remoteCollection) {
        final url = photo['url'] as String?;
        if (url != null && !deletedIds.contains(photo['id']) && urls.add(url)) {
          slots.add(
            FcPhotoSlot(remoteUrl: url, remoteId: photo['id'] as String?),
          );
        }
      }
      if (slots.isEmpty &&
          remoteCollection.isEmpty &&
          !deletedIds.contains('legacy') &&
          legacyUrl?.isNotEmpty == true) {
        slots.add(FcPhotoSlot(remoteUrl: legacyUrl, remoteId: 'legacy'));
      }
      return slots;
    }

    final beforePhotos = buildSlotsForType(
      'before',
      widget.report.beforePhotos,
      widget.report.beforePhotoUrl,
    );
    final afterPhotos = buildSlotsForType(
      'after',
      widget.report.afterPhotos,
      widget.report.afterPhotoUrl,
    );

    if (!mounted) return;
    setState(() {
      _beforeSlots = beforePhotos;
      _beforeSlot = beforePhotos.isEmpty ? null : beforePhotos.first;
      _afterSlots = afterPhotos;
      _afterSlot = afterPhotos.isEmpty ? null : afterPhotos.first;
    });
  }

  /// Merges a local DB row with the remote URL fallback from [ReportModel].
  FcPhotoSlot? _buildSlot(FcLocalPhoto? localRow, String? remoteUrl) {
    if (localRow != null) {
      return FcPhotoSlot(
        localPhotoId: localRow.localPhotoId,
        remoteId: localRow.remoteId,
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
    final currentStatus = widget.report.status.toLowerCase();
    final bool isTerminal = const {
      'resolved',
      'completed',
      'closed',
      'rejected',
      'waiting_for_feedback',
    }.contains(currentStatus);

    final bool isAcknowledged = ![
      'unresolved',
      'submitted',
      'pending',
    ].contains(currentStatus);

    final currentLifecycle = widget.report.lifecycleStage?.toLowerCase();
    final bool isLifecycleAcknowledged =
        currentLifecycle != null &&
        ![
          'new',
          'pending',
          'under_review',
          'submitted',
        ].contains(currentLifecycle);

    final bool effectivelyAcknowledged =
        isAcknowledged || isLifecycleAcknowledged;

    // Allow uploading Before photos before or after acknowledging (until completed/terminal).
    final bool isBeforeEnabled = !isTerminal;
    // Allow uploading After photos once acknowledged (until completed/terminal).
    final bool isAfterEnabled = effectivelyAcknowledged && !isTerminal;

    final bool hasBefore =
        _beforeSlots.isNotEmpty ||
        widget.report.beforePhotos.isNotEmpty ||
        (widget.report.beforePhotoUrl != null &&
            widget.report.beforePhotoUrl!.isNotEmpty);
    final bool hasAfter =
        _afterSlots.isNotEmpty ||
        widget.report.afterPhotos.isNotEmpty ||
        (widget.report.afterPhotoUrl != null &&
            widget.report.afterPhotoUrl!.isNotEmpty);

    return FcPhotoUploadSection(
      evidencePhotos: widget.evidencePhotos,
      evidenceError: widget.evidenceError,
      beforeSlot: _beforeSlot,
      beforeSlots: _beforeSlots,
      afterSlot: _afterSlot,
      afterSlots: _afterSlots,
      isAssigned: widget.isAssigned,
      isBeforeEnabled: isBeforeEnabled,
      isAfterEnabled: isAfterEnabled,
      actionSection: FcReportActionButtons(
        report: widget.report,
        isAssigned: widget.isAssigned,
        hasBeforePhoto: hasBefore,
        hasAfterPhoto: hasAfter,
        onViewOnMap: widget.onViewOnMap,
        onStatusChange: (newStatus) =>
            widget.onStatusChange(newStatus, hasBefore, hasAfter),
      ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Pending sync badge
// ─────────────────────────────────────────────────────────────────────────────

class _PendingSyncBadge extends ConsumerWidget {
  final String reportId;
  const _PendingSyncBadge({required this.reportId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(fcSyncStateProvider);
    ref.watch(fcPendingWritesProvider);
    final automatic = ref.watch(fcSyncSettingsProvider).autoSyncEnabled;
    final localRepo = ref.watch(fcLocalRepositoryProvider);

    return FutureBuilder<bool>(
      key: ValueKey(syncState.lastSyncAt),
      future: _hasPending(localRepo, ref, reportId),
      builder: (context, snap) {
        if (snap.data != true) return const SizedBox.shrink();
        return _SyncChip(phase: syncState.phase, automatic: automatic);
      },
    );
  }

  Future<bool> _hasPending(
    dynamic localRepo,
    WidgetRef ref,
    String reportId,
  ) async {
    final items = await localRepo.getPendingOutboxItems();
    if (items.any((i) => i.entityId == reportId)) return true;
    final photos = ref.read(fcLocalPhotoRepositoryProvider);
    final uploads = await photos.getPendingUploads();
    final deletes = await photos.getPendingDeletes();
    return [...uploads, ...deletes].any((p) => p.entityId == reportId);
  }
}

/// Small AppBar chip showing sync status.
class _SyncChip extends StatelessWidget {
  final FcSyncPhase phase;
  final bool automatic;
  const _SyncChip({required this.phase, required this.automatic});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (phase) {
      FcSyncPhase.syncing => ('Syncing…', AppColors.primaryDark),
      FcSyncPhase.error => ('Sync Error', AppColors.error),
      FcSyncPhase.partialFailure => ('Sync attention', AppColors.error),
      _ => (automatic ? 'Sync queued' : 'Pending Sync', AppColors.warning),
    };
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Chip(
        label: Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white),
        ),
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
