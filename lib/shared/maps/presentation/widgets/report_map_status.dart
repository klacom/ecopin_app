import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/shared/reports/data/datasources/public_report_map_datasource.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReportMapStatus extends StatelessWidget {
  final AsyncValue<ReportMapPage> value;
  final VoidCallback onRetry;
  final bool hasPreviousReports;
  final bool compact;
  const ReportMapStatus({
    super.key,
    required this.value,
    required this.onRetry,
    this.hasPreviousReports = false,
    this.compact = false,
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
    final displayMessage =
        value.hasError && (value.hasValue || hasPreviousReports)
        ? '$message Showing the last loaded reports.'
        : message;
    final compactMessage = value.when(
      skipLoadingOnRefresh: false,
      data: (page) => page.hasMore
          ? 'Newest 200 · Zoom in'
          : '${page.reports.length} report${page.reports.length == 1 ? '' : 's'}',
      loading: () => 'Loading…',
      error: (_, _) => hasPreviousReports || value.hasValue
          ? 'Refresh failed · Previous reports'
          : 'Reports could not load.',
    );
    return Semantics(
      liveRegion: true,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: compact ? EdgeInsets.zero : const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5, right: 8),
                    child: SizedBox(
                      width: 8,
                      height: 8,
                      child: value.isLoading
                          ? CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.primary,
                              value: MediaQuery.disableAnimationsOf(context)
                                  ? .75
                                  : null,
                            )
                          : DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: value.hasError
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).brightness ==
                                          Brightness.dark
                                    ? AppColors.environmentalDark
                                    : AppColors.environmentalLight,
                              ),
                            ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      compact ? compactMessage : displayMessage,
                      semanticsLabel: displayMessage,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              if (value.hasError)
                TextButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      ),
    );
  }
}
