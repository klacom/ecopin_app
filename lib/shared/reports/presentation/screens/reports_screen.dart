import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/reports_screen_widgets/status_badge.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/reports_screen_widgets/validation_badge.dart';
import 'package:ecopin_app/shared/reports/providers/report_provider.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ecopin_app/core/constants/app_constants.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _selectedFilter = 'All';

  // Helper to check if a rejected report is still visible (within 24 hours)
  bool _isReportVisible(ReportModel report) {
    if (report.validationStatus.toLowerCase() != 'rejected') {
      return true;
    }
    if (report.rejectedAt == null) {
      return true;
    }
    final now = DateTime.now();
    final difference = now.difference(report.rejectedAt!);
    return difference.inHours < 24;
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(myReportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: reportFilters.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = reportFilters[index];
                final isSelected = _selectedFilter == filter;
                return ChoiceChip(
                  label: Text(filter[0].toUpperCase() + filter.substring(1)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedFilter = filter);
                    }
                  },
                );
              },
            ),
          ),
        ),
      ),
      body: reportsAsync.when(
        data: (reports) {
          // First filter out rejected reports older than 24 hours
          final visibleReports = reports.where(_isReportVisible).toList();

          final filteredReports = _selectedFilter == 'All'
              ? visibleReports
              : visibleReports.where((r) {
                  if (_selectedFilter.toLowerCase() == 'rejected') {
                    return r.validationStatus.toLowerCase() == 'rejected';
                  }
                  return r.status.toLowerCase() ==
                      _selectedFilter.toLowerCase();
                }).toList();

          if (filteredReports.isEmpty) {
            return const Center(child: Text('No reports found.'));
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(myReportsProvider.future),
            child: ListView.builder(
              itemCount: filteredReports.length,
              itemBuilder: (context, index) {
                final report = filteredReports[index];
                return _ReportListItem(report: report);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _ReportListItem extends StatelessWidget {
  final ReportModel report;

  const _ReportListItem({required this.report});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM dd, yyyy').format(report.createdAt);

    return ListTile(
      onTap: () => context.push('${ProtectedAppRoutes.reports}/${report.id}'),
      title: Text(
        report.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(report.issueType ?? 'General'),
          Text(
            dateStr,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (report.validationStatus.toLowerCase() == 'rejected' &&
              report.rejectionReason != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                'Rejection Reason: ${report.rejectionReason}',
                style: TextStyle(fontSize: 12, color: Colors.red.shade700),
              ),
            ),
          ],
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          StatusBadge(status: report.status),
          const SizedBox(height: 4),
          ValidationBadge(status: report.validationStatus),
        ],
      ),
    );
  }
}
