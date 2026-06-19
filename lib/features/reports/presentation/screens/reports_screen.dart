import 'package:ecopin_app/features/reports/data/models/report_model.dart';
import 'package:ecopin_app/features/reports/providers/report_provider.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = [
    'All',
    'unresolved',
    'in progress',
    'resolved',
  ];

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
              itemCount: _filters.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
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
          final filteredReports = _selectedFilter == 'All'
              ? reports
              : reports
                    .where(
                      (r) =>
                          r.status.toLowerCase() ==
                          _selectedFilter.toLowerCase(),
                    )
                    .toList();

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
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _StatusBadge(status: report.status),
          const SizedBox(height: 4),
          _ValidationBadge(status: report.validationStatus),
        ],
      ),
    );
  }
}

class _ValidationBadge extends StatelessWidget {
  final String status;

  const _ValidationBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'validated':
        color = Colors.green;
        label = 'AI OK';
        break;
      case 'manual_review':
        color = Colors.orange;
        label = 'REVIEW';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'INVALID';
        break;
      default:
        color = Colors.grey;
        label = 'PENDING';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'resolved':
        color = Colors.green;
        break;
      case 'in progress':
        color = Colors.orange;
        break;
      case 'unresolved':
      default:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
