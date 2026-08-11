import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';

class FcOfflineSyncBanner extends StatefulWidget {
  const FcOfflineSyncBanner({super.key});

  @override
  State<FcOfflineSyncBanner> createState() => _FcOfflineSyncBannerState();
}

class _FcOfflineSyncBannerState extends State<FcOfflineSyncBanner> {
  // Simulated States for high fidelity UX prototyping
  bool _isOnline = true;
  bool _isMobileData = false;
  int _pendingCount = 4;
  bool _isSyncing = false;
  double _syncProgress = 0.0;

  void _simulateSync() {
    setState(() {
      _isSyncing = true;
      _syncProgress = 0.0;
    });

    Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!mounted) return;
      setState(() {
        _syncProgress += 0.1;
        if (_syncProgress >= 1.0) {
          _isSyncing = false;
          _pendingCount = 0;
          timer.cancel();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Data successfully synced to officer!'),
                ],
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
    });
  }

  void _handleSyncPress() {
    if (!_isOnline) return;

    if (_isMobileData) {
      // Show high-fidelity data usage warning dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            icon: const Icon(
              Icons.network_cell_rounded,
              size: 40,
              color: AppColors.warning,
            ),
            title: const Text('Mobile Data Warning'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'You are connected via Mobile Data.',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Syncing $_pendingCount reports will consume approximately 320 KB of data.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _simulateSync();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: const Text('Sync Anyway'),
              ),
            ],
          );
        },
      );
    } else {
      _simulateSync();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme alignment colors based on offline/online state
    final Color bannerBg = !_isOnline
        ? (isDark
              ? const Color(0xFF3E2723)
              : const Color(0xFFFFF8E1)) // Warn amber/brown
        : (isDark
              ? const Color(0xFF1B5E20).withValues(alpha: 0.2)
              : const Color(0xFFF1F8E9)); // Success green tint

    final Color borderColor = !_isOnline
        ? AppColors.warning.withValues(alpha: 0.5)
        : AppColors.success.withValues(alpha: 0.4);

    final Color iconColor = !_isOnline ? AppColors.warning : AppColors.success;

    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSecondary = textPrimary.withValues(alpha: 0.7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Simulation controls for testing UX ──
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppColors.spaceMD,
            vertical: AppColors.spaceXS,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ChoiceChip(
                    label: const Text(
                      'Offline',
                      style: TextStyle(fontSize: 10),
                    ),
                    selected: !_isOnline,
                    onSelected: (val) => setState(() => _isOnline = !val),
                  ),
                  const SizedBox(width: 4),
                  ChoiceChip(
                    label: const Text('Wi-Fi', style: TextStyle(fontSize: 10)),
                    selected: _isOnline && !_isMobileData,
                    onSelected: (val) => setState(() {
                      if (val) {
                        _isOnline = true;
                        _isMobileData = false;
                      }
                    }),
                  ),
                  const SizedBox(width: 4),
                  ChoiceChip(
                    label: const Text(
                      'Mobile Data',
                      style: TextStyle(fontSize: 10),
                    ),
                    selected: _isOnline && _isMobileData,
                    onSelected: (val) => setState(() {
                      if (val) {
                        _isOnline = true;
                        _isMobileData = true;
                      }
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Main Offline Sync Banner Card ──
        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppColors.spaceMD,
            vertical: AppColors.spaceSM,
          ),
          decoration: BoxDecoration(
            color: bannerBg,
            borderRadius: BorderRadius.circular(AppColors.radiusCard),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowCard,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppColors.radiusCard),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppColors.spaceMD),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          !_isOnline
                              ? Icons.cloud_off_rounded
                              : (_isMobileData
                                    ? Icons.network_cell_rounded
                                    : Icons.cloud_done_rounded),
                          color: iconColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppColors.spaceMD),
                      // Text Description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              !_isOnline
                                  ? 'Offline Mode Active'
                                  : 'Progress Safe & Connected',
                              style: AppTypography.body.copyWith(
                                color: textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              !_isOnline
                                  ? 'Your progress is being saved offline. We will re-sync automatically when you regain internet.'
                                  : 'Everything is securely saved. You have $_pendingCount reports pending manual or automatic sync.',
                              style: AppTypography.bodySmall.copyWith(
                                color: textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            if (_pendingCount > 0 && _isOnline) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: iconColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(
                                    AppColors.radiusChip,
                                  ),
                                ),
                                child: Text(
                                  '$_pendingCount files waiting to sync',
                                  style: AppTypography.caption.copyWith(
                                    color: iconColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Linear Progress bar during sync simulation
                if (_isSyncing)
                  LinearProgressIndicator(
                    value: _syncProgress,
                    backgroundColor: iconColor.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                    minHeight: 3,
                  ),

                // Button Bar Footer
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppColors.spaceMD,
                    vertical: AppColors.spaceSM,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.03),
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? AppColors.dividerDark
                            : AppColors.dividerLight,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Active network label
                      Row(
                        children: [
                          Icon(
                            !_isOnline
                                ? Icons.signal_wifi_off_rounded
                                : (_isMobileData
                                      ? Icons.signal_cellular_alt_rounded
                                      : Icons.wifi_rounded),
                            size: 14,
                            color: textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            !_isOnline
                                ? 'No Connection'
                                : (_isMobileData
                                      ? 'Mobile Data Active'
                                      : 'Wi-Fi Connected'),
                            style: AppTypography.caption.copyWith(
                              color: textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Sync button
                      Tooltip(
                        message: !_isOnline
                            ? 'Please connect to the internet to sync'
                            : 'Sync data now',
                        child: ElevatedButton.icon(
                          onPressed:
                              (_isOnline && _pendingCount > 0 && !_isSyncing)
                              ? _handleSyncPress
                              : null,
                          icon: _isSyncing
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.sync_rounded, size: 16),
                          label: Text(
                            _isSyncing ? 'Syncing...' : 'Sync Now',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            backgroundColor: iconColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.08),
                            disabledForegroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.3)
                                : Colors.black.withValues(alpha: 0.35),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
