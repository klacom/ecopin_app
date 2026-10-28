import 'package:flutter/material.dart';

const reportPriorityReasons = {
  'community_event': 'Community Event/Liga',
  'school_hospital_zone': 'School/Hospital Zone',
  'severe_obstruction': 'Severe Obstruction',
  'public_health_hazard': 'Public Health Hazard',
};

class ReportPriorityPicker extends StatelessWidget {
  const ReportPriorityPicker({
    super.key,
    required this.urgent,
    required this.reason,
    required this.explanationController,
    required this.onUrgentChanged,
    required this.onReasonChanged,
    this.urgentEnabled = true,
  });

  final bool urgent;
  final String? reason;
  final TextEditingController explanationController;
  final ValueChanged<bool> onUrgentChanged;
  final ValueChanged<String> onReasonChanged;
  final bool urgentEnabled;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Priority', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          ChoiceChip(
            label: const Text('Non-urgent'),
            selected: !urgent,
            onSelected: (_) => onUrgentChanged(false),
          ),
          ChoiceChip(
            label: const Text('Urgent'),
            selected: urgent,
            onSelected: urgentEnabled ? (_) => onUrgentChanged(true) : null,
          ),
        ],
      ),
      if (urgent) ...[
        const SizedBox(height: 12),
        const Text('Reason for urgent review *'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in reportPriorityReasons.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: reason == entry.key,
                onSelected: (_) => onReasonChanged(entry.key),
              ),
          ],
        ),
        if (reason == null) const Text('Choose one reason to continue.'),
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
        const SizedBox(height: 8),
        const Text(
          'Urgent requests need officer verification. Response timing depends on review.',
        ),
      ],
    ],
  );
}
