// ─────────────────────────────────────────────────────────────────────────────
// Phase 5 data model for sync results
// ─────────────────────────────────────────────────────────────────────────────

/// Describes why a mutation was merged or rejected, echoed from the server.
///
/// Present on [FcOpResult] when `status` is `merged` or `conflict`.
/// Null for `success`, `duplicate`, `failed`, and `invalid`.
class FcConflictDetail {
  /// The rule that was applied.
  ///   'first_accepted_wins'  — status/lifecycle/validation ops
  ///   'field_authority'      — update_details ops
  final String rule;

  /// Fields that were applied to the server entity (only set for 'merged').
  final List<String> appliedFields;

  /// Fields that were NOT applied because another role owns them.
  final List<String> rejectedFields;

  /// The server's fc_version at the time of processing.
  final int serverVersion;

  /// The fc_version the client believed the entity was at.
  final int clientBaseVersion;

  const FcConflictDetail({
    required this.rule,
    this.appliedFields = const [],
    this.rejectedFields = const [],
    required this.serverVersion,
    required this.clientBaseVersion,
  });

  factory FcConflictDetail.fromJson(Map<String, dynamic> json) {
    return FcConflictDetail(
      rule: json['rule'] as String? ?? 'unknown',
      appliedFields: _parseStringList(json['applied_fields']),
      rejectedFields: _parseStringList(json['rejected_fields']),
      serverVersion: _parseInt(json['server_version']),
      clientBaseVersion: _parseInt(json['client_base_version']),
    );
  }

  static List<String> _parseStringList(dynamic v) {
    if (v is List) return v.whereType<String>().toList();
    return const [];
  }

  static int _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  @override
  String toString() =>
      'FcConflictDetail(rule=$rule, applied=$appliedFields, '
      'rejected=$rejectedFields, srv=$serverVersion, cli=$clientBaseVersion)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Per-operation result
// ─────────────────────────────────────────────────────────────────────────────

/// Per-operation result returned by the backend batch sync endpoint.
///
/// JSON shape:
/// ```json
/// {
///   "operation_id"   : "...",
///   "status"         : "success"|"merged"|"conflict"|"duplicate"|"failed"|"invalid",
///   "server_record"  : { ... } | null,
///   "error_message"  : "..." | null,
///   "conflict_detail": { "rule": "...", ... } | null
/// }
/// ```
class FcOpResult {
  final String operationId;
  final FcOpStatus status;
  final Map<String, dynamic>? serverRecord;
  final String? errorMessage;

  /// Non-null when `status` is `merged` or `conflict`.
  final FcConflictDetail? conflictDetail;

  const FcOpResult({
    required this.operationId,
    required this.status,
    this.serverRecord,
    this.errorMessage,
    this.conflictDetail,
  });

  factory FcOpResult.fromJson(Map<String, dynamic> json) {
    final rawDetail = json['conflict_detail'];
    return FcOpResult(
      operationId: json['operation_id'] as String? ?? '',
      status: _parseStatus(json['status'] as String? ?? 'failed'),
      serverRecord: json['server_record'] as Map<String, dynamic>?,
      errorMessage: json['error_message'] as String?,
      conflictDetail: rawDetail is Map<String, dynamic>
          ? FcConflictDetail.fromJson(rawDetail)
          : null,
    );
  }

  static FcOpStatus _parseStatus(String raw) {
    switch (raw) {
      case 'success':   return FcOpStatus.success;
      case 'merged':    return FcOpStatus.merged;
      case 'conflict':  return FcOpStatus.conflict;
      case 'duplicate': return FcOpStatus.duplicate;
      case 'invalid':   return FcOpStatus.invalid;
      default:          return FcOpStatus.failed;
    }
  }

  bool get isTerminalSuccess =>
      status == FcOpStatus.success ||
      status == FcOpStatus.merged ||
      status == FcOpStatus.duplicate;

  bool get isTerminalFailure =>
      status == FcOpStatus.conflict || status == FcOpStatus.invalid;

  bool get isRetryable => status == FcOpStatus.failed;

  @override
  String toString() =>
      'FcOpResult($operationId, $status, detail=$conflictDetail, err=$errorMessage)';
}

enum FcOpStatus { success, merged, conflict, duplicate, failed, invalid }

// ─────────────────────────────────────────────────────────────────────────────
// Aggregated run result
// ─────────────────────────────────────────────────────────────────────────────

/// Human-facing summary of one conflict event — used by [FcConflictSummary].
class FcConflictEvent {
  final String operationId;
  final FcOpStatus status;

  /// Human-readable description of what happened, ready to show in the UI.
  final String message;

  const FcConflictEvent({
    required this.operationId,
    required this.status,
    required this.message,
  });
}

/// Aggregated outcome of one sync run.
class FcSyncRunResult {
  final int total;
  final int succeeded;
  final int merged;
  final int conflicted;
  final int retryable;
  final int permanent;
  final List<FcOpResult> results;

  const FcSyncRunResult({
    required this.total,
    required this.succeeded,
    required this.merged,
    required this.conflicted,
    required this.retryable,
    required this.permanent,
    required this.results,
  });

  bool get allSucceeded =>
      retryable == 0 && permanent == 0 && conflicted == 0;

  /// Returns human-readable conflict events for the UI banner.
  /// Only includes merged and conflict outcomes (not retryable failures,
  /// which the user doesn't need to act on).
  List<FcConflictEvent> get conflictEvents {
    final events = <FcConflictEvent>[];
    for (final r in results) {
      if (r.status == FcOpStatus.merged) {
        final detail = r.conflictDetail;
        if (detail != null && detail.rejectedFields.isNotEmpty) {
          events.add(FcConflictEvent(
            operationId: r.operationId,
            status: r.status,
            message:
                'Some changes were merged. '
                '${detail.rejectedFields.length} field(s) updated by another '
                'crew member were kept.',
          ));
        } else {
          events.add(FcConflictEvent(
            operationId: r.operationId,
            status: r.status,
            message: 'Your change was merged with another crew member\'s update.',
          ));
        }
      } else if (r.status == FcOpStatus.conflict) {
        events.add(FcConflictEvent(
          operationId: r.operationId,
          status: r.status,
          message:
              'One change was not applied — another crew member\'s update '
              'was accepted first.',
        ));
      }
    }
    return events;
  }

  @override
  String toString() =>
      'FcSyncRunResult(total=$total succeeded=$succeeded merged=$merged '
      'conflicted=$conflicted retryable=$retryable permanent=$permanent)';
}
