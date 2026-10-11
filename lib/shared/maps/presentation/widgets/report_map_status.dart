import 'package:ecopin_app/shared/reports/data/datasources/public_report_map_datasource.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReportMapStatus extends StatelessWidget {
  final AsyncValue<ReportMapPage> value;
  final VoidCallback onRetry;
  const ReportMapStatus({
    super.key,
    required this.value,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final message = value.when(
      skipLoadingOnRefresh: false,
      data: (page) => page.hasMore
          ? 'Showing the newest 200 reports in this area. Zoom in to see more.'
          : '${page.reports.length} public report${page.reports.length == 1 ? '' : 's'} in this area',
      loading: () => 'Loading reports in this area…',
      error: (error, stack) => 'Reports could not load.',
    );
    return Semantics(
      liveRegion: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(message)),
              if (value.hasError)
                TextButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      ),
    );
  }
}
