import 'package:flutter/material.dart';
import 'report_marker.dart';

class ReportMapInfo extends StatelessWidget {
  const ReportMapInfo({super.key, required this.openSource});
  final void Function(Uri) openSource;
  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('Map legend and credits'),
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Choose a pin to preview a report. Numbered groups expand to show nearby reports. A ring highlights your selected report.',
        ),
        const SizedBox(height: 16),
        for (final status in [
          'unresolved',
          'in_progress',
          'pending_owner_consent',
          'waiting_for_feedback',
          'resolved',
          'closed',
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: ReportMarker(status: status),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ReportMarkerStyle.forStatus(context, status).label,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
      const Text('Heatmap shading summarizes nearby reports and their current response status.'),
      const SizedBox(height: 16),
        const Text(
          'Some public pins show an approximate area. The report preview identifies approximate locations.',
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () =>
              openSource(Uri.parse('https://www.openstreetmap.org/copyright')),
          child: const Text('© OpenStreetMap contributors'),
        ),
        TextButton(
          onPressed: () =>
              openSource(Uri.parse('https://carto.com/attributions')),
          child: const Text('CARTO basemap credits'),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Close'),
      ),
    ],
  );
}
