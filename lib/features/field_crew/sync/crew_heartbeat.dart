import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/shared/profile/providers/profile_provider.dart';
import 'fc_sync_gate.dart';

final crewHeartbeatProvider = Provider.autoDispose<CrewHeartbeat?>((ref) {
  final profile = ref.watch(profileProvider).asData?.value;
  final owner = profile?['id'] as String?;
  if (profile?['role'] != 'field_crew' || owner == null) return null;
  final api = ref.watch(apiClientProvider);
  if (api.currentUserId != owner) return null;
  final gate = ref.watch(fcSyncGateProvider);
  CancelToken? pending;
  final heartbeat = CrewHeartbeat(
    send: () async {
      final policy = await gate.checkAutoSync();
      if (!ref.mounted || !policy.allowed) return;
      final token = CancelToken();
      pending = token;
      final timeout = Timer(
        const Duration(seconds: 8),
        () => token.cancel('Presence request timed out'),
      );
      try {
        await api.dioClient.post(
          '/api/fc/presence',
          data: <String, dynamic>{},
          cancelToken: token,
          options: Options(
            receiveTimeout: const Duration(seconds: 6),
            sendTimeout: const Duration(seconds: 6),
            extra: {'expectedUserId': owner, 'requiresSession': true},
          ),
        );
      } finally {
        timeout.cancel();
        if (identical(pending, token)) pending = null;
      }
    },
  );
  ref.onDispose(() {
    heartbeat.dispose();
    pending?.cancel('Crew session ended');
  });
  heartbeat.start();
  return heartbeat;
});

// Presence is a foreground contact hint, never an offline write or physical-presence claim.
class CrewHeartbeat with WidgetsBindingObserver {
  CrewHeartbeat({
    required this.send,
    this.interval = const Duration(seconds: 30),
  });
  final Future<void> Function() send;
  final Duration interval;
  Timer? _timer;
  bool _started = false, _disposed = false, _sending = false;
  bool get _foreground =>
      WidgetsBinding.instance.lifecycleState == null ||
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  void start() {
    if (_started || _disposed) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _resume();
  }

  void _resume() {
    if (_disposed || !_foreground) return;
    _timer?.cancel();
    unawaited(_ping());
    _timer = Timer.periodic(interval, (_) => unawaited(_ping()));
  }

  Future<void> _ping() async {
    if (_disposed || !_foreground || _sending) return;
    _sending = true;
    try {
      await send();
    } catch (_) {
      /* Retry on the next foreground tick; do not queue stale contact. */
    } finally {
      _sending = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _timer?.cancel();
    if (state == AppLifecycleState.resumed) _resume();
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}
