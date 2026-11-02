import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import '../controllers/fc_dashboard_presentation.dart';
import 'fc_offline_ui.dart';

/// “All types” is the empty string, so a dismissed sheet (null) is told apart
/// from choosing to clear the filter.
const fcAllReportTypes = '';

/// One question, one tap: choosing a type applies it and closes the sheet.
Future<String?> showFcReportTypeSheet(
  BuildContext context, {
  required List<String> types,
  required String? selected,
}) => showModalBottomSheet<String>(
  context: context,
  useRootNavigator: true,
  useSafeArea: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (sheet) {
    final theme = Theme.of(sheet);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: RadioGroup<String>(
          groupValue: selected ?? fcAllReportTypes,
          onChanged: (value) {
            if (value != null) Navigator.pop(sheet, value);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text('Type', style: theme.textTheme.titleMedium),
              ),
              const SizedBox(height: 8),
              RadioListTile<String>(
                value: fcAllReportTypes,
                contentPadding: EdgeInsets.zero,
                activeColor: fcAccent(sheet),
                title: const Text('All types'),
              ),
              for (final type in types)
                RadioListTile<String>(
                  value: type,
                  contentPadding: EdgeInsets.zero,
                  activeColor: fcAccent(sheet),
                  title: Text(crewTaskLabel(type)),
                ),
            ],
          ),
        ),
      ),
    );
  },
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(AppColors.radiusDialog),
    ),
  ),
);
