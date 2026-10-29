import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Foreground, sampled GPS evidence. This is not server-attested physical presence.
class CrewInvestigation {
  CrewInvestigation(this.target);
  static const radiusMetres = 5.0;
  static const requiredDwell = Duration(minutes: 5);
  static const maximumGap = Duration(seconds: 15);
  final LatLng target;
  Duration dwell = Duration.zero;
  bool inside = false;
  bool complete = false;
  double? distanceMetres;
  double? accuracyMetres;
  String message = 'Waiting for precise GPS';
  Duration? _started, _lastElapsed;
  DateTime? _lastTimestamp;
  DateTime? completedAt, arrivedAt;
  int sampleCount = 0;
  double maximumAccuracy = 0;

  void observe(
    Position fix, {
    required Duration elapsed,
    required DateTime now,
  }) {
    final age = now.difference(fix.timestamp);
    final delta = _lastTimestamp == null
        ? null
        : fix.timestamp.difference(_lastTimestamp!);
    final monotonicDelta = _lastElapsed == null
        ? null
        : elapsed - _lastElapsed!;
    accuracyMetres = fix.accuracy;
    if (!fix.latitude.isFinite ||
        !fix.longitude.isFinite ||
        fix.latitude.abs() > 90 ||
        fix.longitude.abs() > 180 ||
        fix.isMocked ||
        !fix.accuracy.isFinite ||
        fix.accuracy <= 0 ||
        fix.accuracy > radiusMetres ||
        age > const Duration(seconds: 10) ||
        age < const Duration(seconds: -2) ||
        (delta != null && delta <= Duration.zero)) {
      interrupt('GPS unreliable or stale. Investigation timer reset.');
      return;
    }
    distanceMetres = const Distance(roundResult: false)(
      target,
      LatLng(fix.latitude, fix.longitude),
    );
    if (!distanceMetres!.isFinite || distanceMetres! > radiusMetres) {
      interrupt('Move within 5 m of this incident.');
      return;
    }
    if (monotonicDelta != null &&
        (monotonicDelta > maximumGap ||
            monotonicDelta <= Duration.zero ||
            delta! > maximumGap ||
            (delta - monotonicDelta).abs() > const Duration(seconds: 2))) {
      interrupt('GPS continuity lost. Investigation timer reset.');
    }
    inside = true;
    _started ??= elapsed;
    _lastElapsed = elapsed;
    _lastTimestamp = fix.timestamp;
    if (!complete) {
      arrivedAt ??= fix.timestamp.toUtc();
      sampleCount++;
      if (fix.accuracy > maximumAccuracy) maximumAccuracy = fix.accuracy;
      dwell = elapsed - _started!;
      if (dwell >= requiredDwell) {
        dwell = requiredDwell;
        complete = true;
        completedAt = now.toUtc();
      }
    }
    message = complete
        ? 'Investigation recorded on this device'
        : 'On site — investigation in progress';
  }

  bool canRecord(Duration elapsed) =>
      complete &&
      inside &&
      _lastElapsed != null &&
      elapsed >= _lastElapsed! &&
      elapsed - _lastElapsed! <= maximumGap;

  void expire(Duration elapsed) {
    if (_lastElapsed != null && elapsed - _lastElapsed! > maximumGap) {
      interrupt('GPS updates stopped. Investigation timer reset.');
    }
  }

  void interrupt([
    String reason =
        'Investigation paused. Stay on this screen with GPS enabled.',
  ]) {
    inside = false;
    _started = null;
    _lastElapsed = null;
    // Keep the sensor watermark: a replayed fix must not restart a dwell.
    if (!complete) {
      dwell = Duration.zero;
      arrivedAt = null;
      sampleCount = 0;
      maximumAccuracy = 0;
    }
    message = reason;
  }

  /// Restore only completed evidence; current presence always needs a fresh fix.
  void restore(Map<String, dynamic> saved) {
    final at = DateTime.tryParse(saved['completed_at']?.toString() ?? '');
    final arrived = DateTime.tryParse(saved['arrived_at']?.toString() ?? '');
    final count = saved['sample_count'];
    final accuracy = saved['maximum_accuracy_m'];
    if (complete ||
        at == null ||
        arrived == null ||
        at.isBefore(arrived) ||
        saved['target_latitude'] != target.latitude ||
        saved['target_longitude'] != target.longitude ||
        saved['observed_dwell_seconds'] != requiredDwell.inSeconds ||
        saved['radius_m'] != radiusMetres ||
        count is! int ||
        count < 21 ||
        accuracy is! num ||
        !accuracy.isFinite ||
        accuracy <= 0 ||
        accuracy > radiusMetres) {
      return;
    }
    complete = true;
    dwell = requiredDwell;
    completedAt = at;
    arrivedAt = arrived;
    sampleCount = count;
    maximumAccuracy = accuracy.toDouble();
    inside = false;
    message = 'Investigation recorded. Waiting for fresh GPS.';
  }

  Map<String, dynamic> receipt() => {
    'target_latitude': target.latitude,
    'target_longitude': target.longitude,
    'radius_m': radiusMetres,
    'required_dwell_seconds': requiredDwell.inSeconds,
    'completed_at': completedAt?.toIso8601String(),
    'arrived_at': arrivedAt?.toIso8601String(),
    'observed_dwell_seconds': dwell.inSeconds,
    'sample_count': sampleCount,
    'maximum_accuracy_m': maximumAccuracy,
    'verification': 'device_gps',
  };
}
