import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/features/field_crew/data/models/agency_response_model.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/field_crew_report_repository.dart';
import 'package:ecopin_app/features/field_crew/providers/field_crew_reports_provider.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';

/// Holds all screen state for a single report detail view.
class FcReportDetailState {
  final ReportModel? report;
  final List<AgencyResponse> notes;
  final List<dynamic> evidence;
  final bool isLoading;
  final String? errorMessage;

  const FcReportDetailState({
    this.report,
    this.notes = const [],
    this.evidence = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  FcReportDetailState copyWith({
    ReportModel? report,
    List<AgencyResponse>? notes,
    List<dynamic>? evidence,
    bool? isLoading,
    String? errorMessage,
  }) {
    return FcReportDetailState(
      report: report ?? this.report,
      notes: notes ?? this.notes,
      evidence: evidence ?? this.evidence,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier for a single report detail screen.
///
/// Mutations write to the local DB first and update [state] synchronously,
/// so the UI reflects changes immediately whether online or offline.
class FcReportDetailNotifier extends Notifier<FcReportDetailState> {
  final String reportId;

  FcReportDetailNotifier(this.reportId);

  late FieldCrewReportRepository _repo;

  @override
  FcReportDetailState build() {
    _repo = ref.watch(fieldCrewReportRepositoryProvider);
    Future.microtask(_load);
    return const FcReportDetailState(isLoading: true);
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final report = await _repo.fetchReportById(reportId);
      final results = await Future.wait([
        _repo.fetchAgencyResponses(reportId),
        _repo.fetchReportEvidence(reportId),
      ]);
      state = FcReportDetailState(
        report: report,
        notes: results[0] as List<AgencyResponse>,
        evidence: results[1],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Re-fetches from network / local cache (pull-to-refresh).
  Future<void> refresh() => _load();

  /// Optimistically updates report status in local state.
  Future<void> updateStatus(String newStatus) async {
    final current = state.report;
    if (current == null) return;
    state =
        state.copyWith(report: _patchReport(current, {'status': newStatus}));
    await _repo.updateReportStatus(reportId, newStatus);
  }

  /// Optimistically updates lifecycle stage.
  Future<void> updateLifecycleStage(String stage) async {
    final current = state.report;
    if (current == null) return;
    state = state.copyWith(
        report: _patchReport(current, {'lifecycle_stage': stage}));
    await _repo.updateLifecycleStage(reportId, stage);
  }

  /// Optimistically updates validation status.
  Future<void> updateValidation(String validationStatus) async {
    final current = state.report;
    if (current == null) return;
    state = state.copyWith(
        report:
            _patchReport(current, {'validation_status': validationStatus}));
    await _repo.updateReportValidation(reportId, validationStatus);
  }

  /// Optimistically updates editable details.
  Future<void> updateDetails(Map<String, dynamic> body) async {
    final current = state.report;
    if (current == null) return;
    state = state.copyWith(report: _patchReport(current, body));
    await _repo.updateReportDetails(reportId, body);
  }

  /// Adds a note locally and prepends it to the notes list immediately.
  Future<void> addNote(String noteText) async {
    final synthetic = await _repo.logAgencyResponse(reportId, {
      'action': noteText,
      'action_type': 'manual_note',
    });
    state = state.copyWith(notes: [synthetic, ...state.notes]);
  }

  /// Applies a shallow patch to a [ReportModel] by round-tripping through JSON.
  ReportModel _patchReport(ReportModel r, Map<String, dynamic> patch) {
    final json = r.toJson();
    json['id'] = r.id;
    json['user_id'] = r.userId;
    json['status'] = r.status;
    json['validation_status'] = r.validationStatus;
    json['cluster_id'] = r.clusterId;
    json['created_at'] = r.createdAt.toIso8601String();
    json['updated_at'] = r.updatedAt.toIso8601String();
    json['before_photo_url'] = r.beforePhotoUrl;
    json['after_photo_url'] = r.afterPhotoUrl;
    json['is_overdue'] = r.isOverdue;
    json.addAll(patch);
    return ReportModel.fromJson(json);
  }
}

/// Family provider — one notifier per reportId.
final fcReportDetailNotifierProvider =
    NotifierProvider.family<FcReportDetailNotifier, FcReportDetailState,
        String>(
  (reportId) => FcReportDetailNotifier(reportId),
);
