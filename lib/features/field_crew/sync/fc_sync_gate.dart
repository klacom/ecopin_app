import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/fc_local_photo_repository.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/fc_local_repository.dart';
import 'package:ecopin_app/features/field_crew/providers/fc_local_repository_provider.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Network type
// ─────────────────────────────────────────────────────────────────────────────

enum FcNetworkType { wifi, mobile, none }

extension FcNetworkTypeLabel on FcNetworkType {
  String get label => switch (this) {
        FcNetworkType.wifi   => 'Wi-Fi',
        FcNetworkType.mobile => 'Mobile Data',
        FcNetworkType.none   => 'Offline',
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Pending summary
// ─────────────────────────────────────────────────────────────────────────────

class FcPendingSummary {
  final int mutationCount;
  final int photoCount;
  final int failedPhotoCount;
  final int pendingDeleteCount;
  final int estimatedBytes;

  const FcPendingSummary({
    required this.mutationCount,
    required this.photoCount,
    required this.failedPhotoCount,
    required this.pendingDeleteCount,
    required this.estimatedBytes,
  });

  bool get isEmpty => mutationCount == 0 && photoCount == 0 && pendingDeleteCount == 0;

  String get formattedSize {
    if (estimatedBytes <= 0) return '';
    if (estimatedBytes < 1024) return '${estimatedBytes} B';
    if (estimatedBytes < 1024 * 1024) {
      return '${(estimatedBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(estimatedBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get summaryLine {
    final parts = <String>[];
    if (mutationCount > 0) {
      parts.add('$mutationCount ${mutationCount == 1 ? "change" : "changes"}');
    }
    final activePhotos = photoCount - failedPhotoCount;
    if (activePhotos > 0) {
      parts.add('$activePhotos ${activePhotos == 1 ? "photo" : "photos"}');
    }
    if (failedPhotoCount > 0) {
      parts.add('$failedPhotoCount failed');
    }
    final size = formattedSize;
    if (size.isNotEmpty) parts.add(size);
    return parts.isEmpty ? 'Nothing pending' : parts.join(' · ');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gate decision
// ─────────────────────────────────────────────────────────────────────────────

class FcGateDecision {
  final bool allowed;

  /// True when allowed but we should show a mobile-data confirmation dialog.
  final bool requiresConfirmation;

  /// Human-readable reason when blocked (null when allowed).
  final String? reason;

  final FcNetworkType networkType;

  const FcGateDecision({
    required this.allowed,
    required this.networkType,
    this.requiresConfirmation = false,
    this.reason,
  });

  factory FcGateDecision.block(FcNetworkType type, String reason) =>
      FcGateDecision(allowed: false, networkType: type, reason: reason);

  factory FcGateDecision.allow(FcNetworkType type,
          {bool confirm = false}) =>
      FcGateDecision(
          allowed: true, networkType: type, requiresConfirmation: confirm);
}

// ─────────────────────────────────────────────────────────────────────────────
// Gate
// ─────────────────────────────────────────────────────────────────────────────

/// Decides whether a sync run is permitted given the current [FcSyncSettings]
/// and network type.
///
/// This is a plain Dart class — not a [Notifier]. The Riverpod provider
/// reconstructs it whenever [FcSyncSettings] changes.
class FcSyncGate {
  final FcSyncSettings settings;
  final FcLocalRepository _localRepo;
  final FcLocalPhotoRepository _photoRepo;

  const FcSyncGate(this.settings, this._localRepo, this._photoRepo);

  // ── Network detection ──────────────────────────────────────────────────────

  Future<FcNetworkType> _networkType() async {
    final results = await Connectivity().checkConnectivity();
    if (results.contains(ConnectivityResult.wifi)) return FcNetworkType.wifi;
    if (results.contains(ConnectivityResult.mobile)) return FcNetworkType.mobile;
    return FcNetworkType.none;
  }

  // ── Auto-sync gate ─────────────────────────────────────────────────────────

  /// Called before each automatic (periodic / connectivity-restore) sync.
  Future<FcGateDecision> checkAutoSync() async {
    if (settings.syncBlocked) {
      return FcGateDecision.block(FcNetworkType.none, 'Offline Only mode is enabled');
    }
    if (!settings.autoSyncEnabled) {
      return FcGateDecision.block(FcNetworkType.none,
          'Manual Commit mode — tap "Commit Changes" to upload');
    }

    final type = await _networkType();
    return _evaluateNetwork(type, forManualCommit: false);
  }

  // ── Manual-commit gate ─────────────────────────────────────────────────────

  /// Called when the user taps "Commit Changes".
  ///
  /// Offline Only and no-network still block.  Manual Commit mode is allowed
  /// (that is the whole point of the button).
  Future<FcGateDecision> checkManualCommit() async {
    if (settings.syncBlocked) {
      return FcGateDecision.block(FcNetworkType.none, 'Offline Only mode is enabled');
    }
    final type = await _networkType();
    return _evaluateNetwork(type, forManualCommit: true);
  }

  FcGateDecision _evaluateNetwork(FcNetworkType type,
      {required bool forManualCommit}) {
    switch (type) {
      case FcNetworkType.none:
        return FcGateDecision.block(type, 'No network connection');

      case FcNetworkType.wifi:
        if (!settings.syncOverWifi) {
          return FcGateDecision.block(
              type, 'Wi-Fi sync is disabled in settings');
        }
        return FcGateDecision.allow(type);

      case FcNetworkType.mobile:
        if (!settings.syncOverMobileData) {
          return FcGateDecision.block(
              type, 'Mobile data sync is disabled in settings');
        }
        // Mobile data is allowed but show confirmation on manual commits.
        return FcGateDecision.allow(type,
            confirm: forManualCommit);
    }
  }

  // ── Pending summary ────────────────────────────────────────────────────────

  /// Returns pending mutation count, photo count, and estimated upload size.
  Future<FcPendingSummary> getPendingSummary() async {
    final mutations      = await _localRepo.getPendingOutboxItems();
    final pendingUploads = await _photoRepo.getPendingUploads();
    final pendingDeletes = await _photoRepo.getPendingDeletes();

    int estimatedBytes = 0;
    int failedPhotos = 0;
    for (final p in pendingUploads) {
      estimatedBytes += p.fileSize;
      if (p.retryCount >= 5) failedPhotos++;
    }

    return FcPendingSummary(
      mutationCount:    mutations.length,
      photoCount:       pendingUploads.length,
      failedPhotoCount: failedPhotos,
      pendingDeleteCount: pendingDeletes.length,
      estimatedBytes:   estimatedBytes,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final fcSyncGateProvider = Provider<FcSyncGate>((ref) {
  final settings   = ref.watch(fcSyncSettingsProvider);
  final localRepo  = ref.watch(fcLocalRepositoryProvider);
  final photoRepo  = ref.watch(fcLocalPhotoRepositoryProvider);
  return FcSyncGate(settings, localRepo, photoRepo);
});
