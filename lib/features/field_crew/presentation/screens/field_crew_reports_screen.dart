import 'package:flutter/material.dart';
import 'package:ecopin_app/shared/reports/presentation/response_deadline.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/response_deadline_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import 'package:ecopin_app/features/field_crew/providers/field_crew_reports_provider.dart';
import 'package:ecopin_app/features/field_crew/providers/cleanup_tasks_provider.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_reports_filter_bar.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_shimmer_list.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_report_list_tile.dart';

class FieldCrewReportsScreen extends ConsumerStatefulWidget {
  const FieldCrewReportsScreen({super.key});

  @override
  ConsumerState<FieldCrewReportsScreen> createState() =>
      _FieldCrewReportsScreenState();
}

class _FieldCrewReportsScreenState
    extends ConsumerState<FieldCrewReportsScreen> {
  String _searchQuery = '';
  String _selectedStatus = 'All Status';
  String _selectedType = 'All Types';
  String _selectedValidation = 'All Validation';
  DeadlineState? _deadlineFilter;

  @override
  Widget build(BuildContext context) {
    final issueTypesAsync = ref.watch(issueTypesProvider);
    final assignedReportsAsync = ref.watch(assignedReportsProvider);
    final now =
        ref.watch(responseDeadlineClockProvider).value ?? DateTime.now();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : Colors.black87;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Reports',
          style: AppTypography.h5.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppColors.spaceLG,
              vertical: AppColors.spaceMD,
            ),
            child: FcReportsFilterBar(
              searchQuery: _searchQuery,
              selectedStatus: _selectedStatus,
              selectedType: _selectedType,
              selectedValidation: _selectedValidation,
              availableTypes: issueTypesAsync.value ?? [],
              onSearchChanged: (val) {
                setState(() => _searchQuery = val);
              },
              onStatusChanged: (val) {
                setState(() => _selectedStatus = val);
              },
              onTypeChanged: (val) {
                setState(() => _selectedType = val);
              },
              onValidationChanged: (val) {
                setState(() => _selectedValidation = val);
              },
              onReset: () {
                setState(() {
                  _searchQuery = '';
                  _selectedStatus = 'All Status';
                  _selectedType = 'All Types';
                  _selectedValidation = 'All Validation';
                  _deadlineFilter = null;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppColors.spaceLG),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in <DeadlineState?, String>{
                  null: 'All deadlines',
                  DeadlineState.atRisk: 'At risk',
                  DeadlineState.overdue: 'Overdue',
                }.entries)
                  ChoiceChip(
                    label: Text(entry.value),
                    selected: _deadlineFilter == entry.key,
                    onSelected: (_) =>
                        setState(() => _deadlineFilter = entry.key),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(fieldCrewReportsProvider);
                ref.invalidate(allCleanupTasksProvider);
                await ref.read(assignedReportsProvider.future);
              },
              color: AppColors.primaryDark,
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: assignedReportsAsync.when(
                data: (data) {
                  final filteredReports = data.reports.where((report) {
                    final searchMatch =
                        _searchQuery.isEmpty ||
                        report.title.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ||
                        (report.description?.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ) ??
                            false);

                    final displayStatus =
                        report.status == 'unresolved' &&
                            [
                              'acknowledged',
                              'responded',
                            ].contains(report.lifecycleStage)
                        ? report.lifecycleStage
                        : report.status;
                    final statusMatch =
                        _selectedStatus == 'All Status' ||
                        displayStatus == _selectedStatus;
                    final typeMatch =
                        _selectedType == 'All Types' ||
                        report.issueType == _selectedType;

                    bool validationMatch =
                        _selectedValidation == 'All Validation';
                    if (!validationMatch) {
                      if (_selectedValidation == 'pending') {
                        validationMatch =
                            report.validationStatus == 'pending' ||
                            report.validationStatus == 'manual_review' ||
                            report.validationStatus == 'Manual_Review';
                      } else {
                        validationMatch =
                            report.validationStatus == _selectedValidation;
                      }
                    }

                    return searchMatch &&
                        (_deadlineFilter == null ||
                            responseDeadline(report, now)?.state ==
                                _deadlineFilter) &&
                        statusMatch &&
                        typeMatch &&
                        validationMatch;
                  }).toList();

                  if (filteredReports.isEmpty) {
                    return ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: _buildEmptyState(),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppColors.spaceLG,
                      vertical: AppColors.spaceMD,
                    ),
                    itemCount: filteredReports.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppColors.spaceMD),
                    itemBuilder: (context, index) {
                      final report = filteredReports[index];
                      return FcReportListTile(
                        report: report,
                        onTap: () {
                          final taskId = data.reportTaskMap[report.id];
                          context.push(
                            '/field-crew/reports/${report.id}',
                            extra: taskId,
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => ListView(children: const [FcShimmerList()]),
                error: (error, stack) => ListView(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Center(
                        child: Text(
                          'Error loading reports: $error',
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 64,
            color: AppColors.primaryDark.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppColors.spaceLG),
          Text(
            'No reports found',
            style: AppTypography.h5.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: AppColors.spaceSM),
          Text(
            'Try adjusting your filters',
            style: AppTypography.body.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
