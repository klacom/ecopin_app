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
  return switch (reportStatusKey(value)) {
    'resolved' || 'closed' =>
      colors?.success ??
          (dark ? AppColors.environmentalDark : AppColors.success),
    'in_progress' || 'acknowledged' || 'pending_owner_consent' =>
      colors?.info ?? (dark ? AppColors.linkDark : AppColors.accent),
    'waiting_for_feedback' || 'unresolved' || 'pending' =>
      colors?.warning ??
          (dark ? const Color(0xFFE5B55E) : const Color(0xFF9C6500)),
    'rejected' => colors?.error ?? theme.colorScheme.error,
    _ => theme.colorScheme.onSurfaceVariant,
  };
}
