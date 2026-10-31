import 'package:ecopin_app/core/constants/app_constants.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:flutter/material.dart';

String reportStatusKey(String value) =>
    value.trim().toLowerCase().replaceAll(' ', '_');
String reportStatusLabel(String value) {
  final key = reportStatusKey(value);
  return reportStatusLabels[key] ??
      (key.isEmpty
          ? 'Status unavailable'
          : key
                .split('_')
                .where((word) => word.isNotEmpty)
                .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
                .join(' '));
}

Color reportStatusColor(BuildContext context, String value) {
  final theme = Theme.of(context);
  final colors = theme.extension<AppStatusColors>();
  final dark = theme.brightness == Brightness.dark;
  // Canonical matrix (mirrors ecopin-web statusHelpers.js REPORT_STATUS_COLORS):
  // unresolved=red, in_progress=blue, waiting_for_feedback=purple, resolved=green, closed=grey.
  return switch (reportStatusKey(value)) {
    'resolved' =>
      colors?.success ??
          (dark ? AppColors.environmentalDark : AppColors.success),
    'in_progress' || 'acknowledged' || 'pending_owner_consent' =>
      colors?.info ?? (dark ? AppColors.linkDark : AppColors.accent),
    'waiting_for_feedback' =>
      colors?.feedback ??
          (dark ? const Color(0xFFC4B5FD) : const Color(0xFF6D28D9)),
    'unresolved' || 'pending' || 'submitted' || 'rejected' =>
      colors?.error ?? theme.colorScheme.error,
    _ => theme.colorScheme.onSurfaceVariant, // closed + unknown
  };
}
