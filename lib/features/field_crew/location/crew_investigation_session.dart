import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../data/models/cleanup_task_model.dart';
import '../presentation/controllers/fc_task_detail_presentation.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'crew_investigation.dart';

class InvestigationTarget {
  InvestigationTarget(this.id, this.label, this.point, this.claimGeneration);
  final String id, label;
  final LatLng? point;
  final int claimGeneration;
  String get signature =>
      '$id:${point?.latitude}:${point?.longitude}:$claimGeneration';
}

List<InvestigationTarget> investigationTargets(
  CleanupTask task,
  List<ReportModel> reports,
) {
  final ids = taskReportIds(task);
  if (ids.isEmpty) {
    return [InvestigationTarget(task.id, task.title, taskPoint(task), 0)];
  }
  final byId = {for (final r in reports) r.id: r};
  return [
    for (final id in ids)
      InvestigationTarget(
        id,
        byId[id]?.title ?? 'Incident unavailable',
        byId[id] == null ||
                (byId[id]!.cleanupTaskId != null &&
                    byId[id]!.cleanupTaskId != task.id)
            ? null
            : _validPoint(byId[id]!.location),
        (byId[id]?.reportClaimGeneration ?? 0) > 0
            ? byId[id]!.reportClaimGeneration
            : task.reportClaimGenerations[id] ?? 0,
      ),
  ];
}

LatLng? _validPoint(LatLng p) =>
    p.latitude.isFinite &&
        p.longitude.isFinite &&
        p.latitude.abs() <= 90 &&
        p.longitude.abs() <= 180 &&
        (p.latitude != 0 || p.longitude != 0)
    ? p
    : null;

/// One foreground task session, shared by Task and task-scoped Report Details.
class CrewInvestigationSession extends ChangeNotifier
    with WidgetsBindingObserver {
  CrewInvestigationSession({
    required this.actorId,
    required this.positions,
    this.observeLifecycle = true,
    this.elapsedOverride,
    this.wallNow = DateTime.now,
    this.onCompleted,
    this.loadSaved,
  }) {
    if (observeLifecycle) WidgetsBinding.instance.addObserver(this);
  }
  final String? Function() actorId;
  final Stream<Position> Function() positions;
  final bool observeLifecycle;
  final Duration Function()? elapsedOverride;
  final DateTime Function() wallNow;
  final Future<void> Function(Map<String, dynamic>)? onCompleted;
  final Future<Map<String, dynamic>?> Function(String)? loadSaved;
  Duration get elapsed => elapsedOverride?.call() ?? clock.elapsed;
  final Stopwatch clock = Stopwatch()..start();
  final Map<String, CrewInvestigation> gates = {};
  List<InvestigationTarget> targets = [];
  String? error;
  String? _scope;
  CleanupTask? _task;
  List<ReportModel> _reports = [];
  String? _owner;
  StreamSubscription<Position>? _subscription;
  Timer? _watchdog;
  int _attempt = 0;
  bool _disposed = false, _starting = false, _foreground = true;

  bool configure(CleanupTask task, List<ReportModel> reports) {
    final owner = actorId();
    final next = investigationTargets(task, reports)
      ..sort((a, b) => a.id.compareTo(b.id));
    final scope = '$owner:${task.id}:${task.assignmentGeneration}';
    final changed =
        scope != _scope ||
        next.map((t) => t.signature).join('|') !=
            targets.map((t) => t.signature).join('|');
    _task = task;
    _reports = reports;
    if (changed) {
      // A reassignment, account, incident pin or claim change starts a new session.
      _stop();
      gates.clear();
      targets = next;
      _scope = scope;
      _owner = owner;
      for (final target in targets) {
        if (target.point != null) {
          gates[target.id] = CrewInvestigation(target.point!);
        }
      }
    }
    if (!_authorized) {
      _stop();
      error = 'Investigation is available only for your active assigned task.';
    } else if (_subscription == null && !_starting && _foreground) {
      unawaited(retry());
    }
    if (changed && loadSaved != null) {
      unawaited(
        loadSaved!(_scope!).then((saved) {
          if (!_disposed && saved != null) restore(saved);
        }),
      );
    }
    notifyListeners();
    return changed;
  }

  void refreshActor() {
    if (_task != null) configure(_task!, _reports);
  }

  bool get _authorized =>
      !_disposed &&
      _owner != null &&
      actorId() == _owner &&
      _task != null &&
      _task!.assignedCrewIds.contains(_owner) &&
      !{
        'completed',
        'cancelled',
        'closed',
      }.contains(_task!.status.toLowerCase());
  bool get allComplete =>
      _authorized &&
      targets.isNotEmpty &&
      targets.every((t) => gates[t.id]?.complete == true);
  bool get canCompleteTask =>
      allComplete && (taskReportIds(_task!).isNotEmpty || canRecord(_task!.id));
  bool canRecord(String id) =>
      _authorized && _foreground && gates[id]?.canRecord(elapsed) == true;

  void requireIncident(String id) {
    if (!canRecord(id)) {
      throw StateError(
        'Stay within 5 m of this incident for 5 continuous minutes with precise GPS before recording its outcome.',
      );
    }
  }

  void requireTask() {
    if (!canCompleteTask) {
      throw StateError(
        'Complete the 5-minute on-site investigation at every incident before completing this task.',
      );
    }
  }

  Map<String, dynamic> receipt(String id) {
    requireIncident(id);
    return _receipt(id);
  }

  List<Map<String, dynamic>> get taskReceipts {
    requireTask();
    return [for (final t in targets) _receipt(t.id)];
  }

  Map<String, dynamic> _receipt(String id) => {
    'crew_id': _owner,
    'task_id': _task!.id,
    'incident_id': id,
    'assignment_generation': _task!.assignmentGeneration,
    'report_claim_generation': targets
        .firstWhere((t) => t.id == id)
        .claimGeneration,
    ...gates[id]!.receipt(),
  };

  String? get cacheScope => _scope;
  Map<String, dynamic> get snapshot => {
    'scope': _scope,
    'targets': targets.map((t) => t.signature).toList(),
    'receipts': {
      for (final t in targets)
        if (gates[t.id]?.complete == true) t.id: gates[t.id]!.receipt(),
    },
  };
  void restore(Map<String, dynamic> saved) {
    final savedTargets = saved['targets'];
    if (!_authorized ||
        saved['scope'] != _scope ||
        savedTargets is! List ||
        !listEquals(savedTargets, targets.map((t) => t.signature).toList()) ||
        saved['receipts'] is! Map) {
      return;
    }
    for (final entry in (saved['receipts'] as Map).entries) {
      if (entry.value is Map && gates[entry.key] != null) {
        gates[entry.key]!.restore(
          Map<String, dynamic>.from(entry.value as Map),
        );
      }
    }
    notifyListeners();
  }

  Future<void> retry() async {
    _stop();
    if (!_authorized || !_foreground) return;
    final attempt = ++_attempt;
    _starting = true;
    error = null;
    notifyListeners();
    // The production source checks permission; tests supply a deterministic stream.
    try {
      final stream = positions();
      _subscription = stream.listen(
        (fix) {
          if (_disposed || attempt != _attempt || !_foreground) return;
          if (!_authorized) {
            _stop();
            gates.clear();
            notifyListeners();
            return;
          }
          var earned = false;
          for (final gate in gates.values) {
            final wasComplete = gate.complete;
            gate.observe(fix, elapsed: elapsed, now: wallNow());
            earned = earned || (!wasComplete && gate.complete);
          }
          if (earned && onCompleted != null) {
            unawaited(
              onCompleted!(snapshot).catchError((Object _) {
                if (!_disposed) {
                  error =
                      'Investigation recorded in this session, but device storage failed. Save the outcome before leaving this task.';
                  notifyListeners();
                }
              }),
            );
          }
          notifyListeners();
        },
        onError: (Object _) {
          if (!_disposed && attempt == _attempt) _failed();
        },
        onDone: () {
          if (!_disposed && attempt == _attempt) _failed();
        },
      );
      _watchdog = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!_authorized) {
          _stop();
          gates.clear();
        }
        for (final gate in gates.values) {
          gate.expire(elapsed);
        }
        notifyListeners();
      });
    } catch (_) {
      _failed();
    }
    if (!_disposed && attempt == _attempt) _starting = false;
  }

  void _failed() {
    _stop();
    error =
        'Precise location unavailable. Enable location permission and GPS, then retry.';
    notifyListeners();
  }

  void _stop() {
    _attempt++;
    _starting = false;
    unawaited(_subscription?.cancel());
    _subscription = null;
    _watchdog?.cancel();
    _watchdog = null;
    for (final gate in gates.values) {
      gate.interrupt();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _stop();
      notifyListeners();
    } else if (_authorized) {
      unawaited(retry());
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _stop();
    clock.stop();
    if (observeLifecycle) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

Stream<Position> preciseInvestigationPositions() async* {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw StateError('GPS disabled');
  }
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw StateError('Location permission required');
  }
  // No last-known fallback: a stationary device still needs recurring fresh fixes.
  yield* Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
      timeLimit: Duration(seconds: 15),
    ),
  );
}
