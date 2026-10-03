import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/shared/notifications/presentation/widgets/notification_badge_action.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:ecopin_app/features/officer/presentation/widgets/officer_reports_filter_bar.dart';

class LguReport {
  final String id;
  final String? title;
  final String? description;
  final String? issueType;
  final String? status;
  final DateTime? createdAt;
  final String? validationStatus;
  final bool? isOverdue;
  final String? lifecycleStage;
  final String? rejectionReason;
  final DateTime? rejectedAt;

  LguReport({
    required this.id,
    this.title,
    this.description,
    this.issueType,
    this.status,
    this.createdAt,
    this.validationStatus,
    this.isOverdue,
    this.lifecycleStage,
    this.rejectionReason,
    this.rejectedAt,
  });

  factory LguReport.fromJson(Map<String, dynamic> json) {
    return LguReport(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String?,
      description: json['description'] as String?,
      issueType: json['issue_type'] as String?,
      status: json['status'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      validationStatus: json['validation_status'] as String?,
      isOverdue: json['is_overdue'] as bool?,
      lifecycleStage: json['lifecycle_stage'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      rejectedAt: json['rejected_at'] != null
          ? DateTime.tryParse(json['rejected_at'])
          : null,
    );
  }
}

class LguReportsNotifier extends ChangeNotifier {
  final ApiClient _apiClient;
  AsyncValue<List<LguReport>> _reports = const AsyncValue.loading();

  LguReportsNotifier(this._apiClient) {
    loadReports();
  }

  AsyncValue<List<LguReport>> get reports => _reports;

  Future<void> loadReports() async {
    _reports = const AsyncValue.loading();
    notifyListeners();
    try {
      final response = await _apiClient.getPublicReports();
      final List<dynamic> data = response.data is List
          ? response.data as List<dynamic>
          : [];
      final reports = data
          .map((json) => LguReport.fromJson(json as Map<String, dynamic>))
          // Filter out rejected reports entirely for LGU
          .where(
            (report) => report.validationStatus?.toLowerCase() != 'rejected',
          )
          .toList();
      _reports = AsyncValue.data(reports);
      notifyListeners();
    } catch (e, stackTrace) {
      _reports = AsyncValue.error(e, stackTrace);
      notifyListeners();
    }
  }

  Future<void> updateReportStatus(String reportId, String status) async {
    try {
      await _apiClient.updateReportStatus(reportId, status);
      await loadReports();
    } catch (e) {
      // Handle error
    }
  }
}

final officerReportsProvider = ChangeNotifierProvider<LguReportsNotifier>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LguReportsNotifier(apiClient);
});

class OfficerReportsScreen extends ConsumerStatefulWidget {
  const OfficerReportsScreen({super.key});

  @override
  ConsumerState<OfficerReportsScreen> createState() => _OfficerReportsScreenState();
}

class _OfficerReportsScreenState extends ConsumerState<OfficerReportsScreen> {
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _issueTypeFilter = 'all';
  String _validationStatusFilter = 'all';
  String _lifecycleStageFilter = 'all';
  String _sortBy = 'newest'; // 'newest' or 'oldest'
  int _currentPage = 1;
  static const int _pageSize = 10;

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(officerReportsProvider).reports;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Reports',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: false,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: NotificationBadgeAction(),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: OfficerReportsFilterBar(
              searchQuery: _searchQuery,
              selectedStatus: _statusFilter,
              selectedType: _issueTypeFilter,
              selectedValidation: _validationStatusFilter,
              selectedLifecycle: _lifecycleStageFilter,
              selectedSort: _sortBy,
              availableTypes: const ['Waste', 'Flooding', 'Pollution', 'Illegal Logging', 'Others'],
              onSearchChanged: (val) {
                setState(() {
                  _searchQuery = val;
                  _currentPage = 1;
                });
              },
              onStatusChanged: (val) {
                setState(() {
                  _statusFilter = val;
                  _currentPage = 1;
                });
              },
              onTypeChanged: (val) {
                setState(() {
                  _issueTypeFilter = val;
                  _currentPage = 1;
                });
              },
              onValidationChanged: (val) {
                setState(() {
                  _validationStatusFilter = val;
                  _currentPage = 1;
                });
              },
              onLifecycleChanged: (val) {
                setState(() {
                  _lifecycleStageFilter = val;
                  _currentPage = 1;
                });
              },
              onSortChanged: (val) {
                setState(() {
                  _sortBy = val;
                  _currentPage = 1;
                });
              },
              onReset: () {
                setState(() {
                  _searchQuery = '';
                  _statusFilter = 'all';
                  _issueTypeFilter = 'all';
                  _validationStatusFilter = 'all';
                  _lifecycleStageFilter = 'all';
                  _sortBy = 'newest';
                  _currentPage = 1;
                });
              },
            ),
          ),
          Expanded(
            child: reportsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(officerReportsProvider).loadReports(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (reports) {
                final filteredReports = _filterReports(reports);
                final paginatedReports = _paginateReports(filteredReports);

                if (filteredReports.isEmpty) {
                  return const Center(child: Text('No reports found'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 80,
                  ),
                  itemCount: paginatedReports.length + 1,
                  itemBuilder: (context, index) {
                    if (index == paginatedReports.length) {
                      return _buildPaginationControls(filteredReports.length);
                    }
                    final report = paginatedReports[index];
                    return _buildReportCard(report);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }



  List<LguReport> _filterReports(List<LguReport> reports) {
    var filtered = reports.where((report) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          (report.title?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false) ||
          (report.description?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false);

      final matchesStatus =
          _statusFilter == 'all' || report.status == _statusFilter;

      final matchesIssueType =
          _issueTypeFilter == 'all' || report.issueType == _issueTypeFilter;

      final matchesValidationStatus =
          _validationStatusFilter == 'all' ||
          report.validationStatus == _validationStatusFilter;

      final matchesLifecycleStage =
          _lifecycleStageFilter == 'all' ||
          report.lifecycleStage == _lifecycleStageFilter;

      return matchesSearch &&
          matchesStatus &&
          matchesIssueType &&
          matchesValidationStatus &&
          matchesLifecycleStage;
    }).toList();

    // Sort by date
    filtered.sort((a, b) {
      if (a.createdAt == null || b.createdAt == null) return 0;
      return _sortBy == 'newest'
          ? b.createdAt!.compareTo(a.createdAt!)
          : a.createdAt!.compareTo(b.createdAt!);
    });

    return filtered;
  }

  List<LguReport> _paginateReports(List<LguReport> reports) {
    final start = (_currentPage - 1) * _pageSize;
    final end = start + _pageSize;
    if (start >= reports.length) return [];
    return reports.sublist(start, end > reports.length ? reports.length : end);
  }

  Widget _buildPaginationControls(int totalReports) {
    final totalPages = (totalReports / _pageSize).ceil();
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                  }
                : null,
            child: const Text('Previous'),
          ),
          const SizedBox(width: 16),
          Text('Page $_currentPage of $totalPages'),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _currentPage < totalPages
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                  }
                : null,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(LguReport report) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.go(OfficerAppRoutes.reportDetails.replaceAll(':id', report.id));
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          report.title ?? 'Untitled Report',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (report.isOverdue == true)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'OVERDUE',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        _buildValidationBadge(report.validationStatus),
                        if (report.lifecycleStage != null)
                          _buildLifecycleBadge(report.lifecycleStage!),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(report.status),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    report.createdAt != null
                        ? _formatDate(report.createdAt!)
                        : 'N/A',
                    style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                  if (report.issueType != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.category_outlined, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        report.issueType!,
                        style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              if (report.description != null && report.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                    ),
                  ),
                  child: Text(
                    report.description!,
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    Color color;
    switch (status) {
      case 'resolved':
        color = Colors.green;
        break;
      case 'in_progress':
        color = Colors.orange;
        break;
      case 'closed':
        color = Colors.grey;
        break;
      case 'unresolved':
      default:
        color = Colors.red;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status?.replaceAll('_', ' ').toUpperCase() ?? 'N/A',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildValidationBadge(String? validationStatus) {
    Color color;
    switch (validationStatus) {
      case 'automatically_valid':
        color = Colors.green;
        break;
      case 'manual_review':
        color = Colors.orange;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      case 'pending':
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        validationStatus?.replaceAll('_', ' ').toUpperCase() ?? 'N/A',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLifecycleBadge(String lifecycleStage) {
    Color color;
    switch (lifecycleStage) {
      case 'resolved':
      case 'closed':
        color = Colors.green;
        break;
      case 'in_progress':
        color = Colors.orange;
        break;
      case 'acknowledged':
        color = Colors.blue;
        break;
      case 'reported':
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        lifecycleStage.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

