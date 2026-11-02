import 'package:ecopin_app/shared/reports/presentation/widgets/create_report_widgets/choice_tile_grid.dart';
import 'package:ecopin_app/shared/widgets/sliding_switch.dart';
import 'package:flutter/material.dart';

const reportPriorityReasons = {
  'community_event': 'Community Event/Liga',
  'school_hospital_zone': 'School/Hospital Zone',
  'severe_obstruction': 'Severe Obstruction',
  'public_health_hazard': 'Public Health Hazard',
};

/// Priority card: a Non-urgent/Urgent switch, the trust note that explains a
/// locked Urgent, and (when Urgent is chosen) the required reason and details.
class ReportPriorityPicker extends StatelessWidget {
  const ReportPriorityPicker({
    super.key,
    required this.urgent,
    required this.reason,
    required this.explanationController,
    required this.onUrgentChanged,
    required this.onReasonChanged,
    this.urgentEnabled = true,
    this.trustNote,
  });

  final bool urgent;
  final String? reason;
  final TextEditingController explanationController;
  final ValueChanged<bool> onUrgentChanged;
  final ValueChanged<String> onReasonChanged;
  final bool urgentEnabled;

  /// Server-reported trust status shown under the switch.
  final Widget? trustNote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.dividerTheme.color ?? scheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Priority',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SlidingSwitch(
              selectedIndex: urgent ? 1 : 0,
              onChanged: (index) => onUrgentChanged(index == 1),
              options: [
                const SlidingSwitchOption(label: 'Non-urgent'),
                SlidingSwitchOption(
                  label: 'Urgent',
                  enabled: urgentEnabled,
                  icon: urgentEnabled ? null : Icons.lock_outline,
                  semanticsLabel: urgentEnabled ? 'Urgent' : 'Urgent, locked',
                ),
              ],
            ),
            if (trustNote != null) ...[const SizedBox(height: 8), trustNote!],
            if (urgent) ...[
              const SizedBox(height: 16),
              Text(
                'Reason for urgent review *',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ChoiceTileGrid(
                options: [
                  for (final entry in reportPriorityReasons.entries)
                    ChoiceTileOption(entry.key, entry.value),
                ],
                selected: reason,
                onSelected: onReasonChanged,
              ),
              if (reason == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Choose one reason to continue.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: explanationController,
                maxLength: 1000,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Additional explanation (optional)',
                  hintText: 'Anything else officers should know?',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Urgent requests need officer verification. Response timing depends on review.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
