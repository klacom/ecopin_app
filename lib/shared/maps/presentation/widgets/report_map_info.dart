import 'package:flutter/material.dart';
import 'report_marker.dart';
import 'my_marker_cluster_layer.dart';

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
        const Row(
          children: [
            ExcludeSemantics(
              child: ReportClusterBadge(count: 3, onActivate: null),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Report cluster\nThe number shows how many reports are grouped nearby. Tap a cluster on the map to zoom in or spread its reports in a circle. This is an example.',
              ),
            ),
          ],
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
                    width: ReportPinFrame.width,
                    height: ReportPinFrame.height,
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
        const Text(
          'Heatmap shading summarizes nearby reports and their current response status.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Some public pins show an approximate area. The report preview identifies approximate locations.',
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () =>
              openSource(Uri.parse('https://www.openstreetmap.org/copyright')),
          child: const Text(
            '© OpenStreetMap contributors',
            textAlign: TextAlign.center,
          ),
        ),
        TextButton(
          onPressed: () =>
              openSource(Uri.parse('https://carto.com/attributions')),
          child: const Text(
            'CARTO basemap credits',
            textAlign: TextAlign.center,
          ),
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
