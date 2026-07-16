import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/routes/app_routes.dart';

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

final lguReportsProvider = ChangeNotifierProvider<LguReportsNotifier>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LguReportsNotifier(apiClient);
});

class LguReportsScreen extends ConsumerStatefulWidget {
  const LguReportsScreen({super.key});

  @override
  ConsumerState<LguReportsScreen> createState() => _LguReportsScreenState();
}

class _LguReportsScreenState extends ConsumerState<LguReportsScreen> {
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
    final reportsAsync = ref.watch(lguReportsProvider).reports;

    return Scaffold(
      appBar: AppBar(title: const Text('Reports'), elevation: 0),
      body: Column(
        children: [
          _buildFilters(),
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
                          ref.read(lguReportsProvider).loadReports(),
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
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search reports...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _currentPage = 1;
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Flexible(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _statusFilter,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(
                      value: 'unresolved',
                      child: Text('Unresolved'),
                    ),
                    DropdownMenuItem(
                      value: 'in_progress',
                      child: Text('In Progress'),
                    ),
                    DropdownMenuItem(
                      value: 'resolved',
                      child: Text('Resolved'),
                    ),
                    DropdownMenuItem(value: 'closed', child: Text('Closed')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _statusFilter = value ?? 'all';
                      _currentPage = 1;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _issueTypeFilter,
                  decoration: const InputDecoration(
                    labelText: 'Issue Type',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'Waste', child: Text('Waste')),
                    DropdownMenuItem(
                      value: 'Flooding',
                      child: Text('Flooding'),
                    ),
                    DropdownMenuItem(
                      value: 'Pollution',
                      child: Text('Pollution'),
                    ),
                    DropdownMenuItem(
                      value: 'Illegal Logging',
                      child: Text('Illegal Log.'),
                    ),
                    DropdownMenuItem(value: 'Others', child: Text('Others')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _issueTypeFilter = value ?? 'all';
                      _currentPage = 1;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Flexible(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _validationStatusFilter,
                  decoration: const InputDecoration(
                    labelText: 'Validation',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(
                      value: 'automatically_valid',
                      child: Text('Auto Valid'),
                    ),
                    DropdownMenuItem(
                      value: 'manual_review',
                      child: Text('Manual Review'),
                    ),
                    DropdownMenuItem(
                      value: 'rejected',
                      child: Text('Rejected'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _validationStatusFilter = value ?? 'all';
                      _currentPage = 1;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _lifecycleStageFilter,
                  decoration: const InputDecoration(
                    labelText: 'Lifecycle',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(
                      value: 'reported',
                      child: Text('Reported'),
                    ),
                    DropdownMenuItem(
                      value: 'acknowledged',
                      child: Text('Acknowledged'),
                    ),
                    DropdownMenuItem(
                      value: 'in_progress',
                      child: Text('In Progress'),
                    ),
                    DropdownMenuItem(
                      value: 'resolved',
                      child: Text('Resolved'),
                    ),
                    DropdownMenuItem(value: 'closed', child: Text('Closed')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _lifecycleStageFilter = value ?? 'all';
                      _currentPage = 1;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _sortBy,
            decoration: const InputDecoration(
              labelText: 'Sort By',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'newest', child: Text('Newest First')),
              DropdownMenuItem(value: 'oldest', child: Text('Oldest First')),
            ],
            onChanged: (value) {
              setState(() {
                _sortBy = value ?? 'newest';
                _currentPage = 1;
              });
            },
          ),
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
      padding: const EdgeInsets.all(16.0),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.go(LguAppRoutes.reportDetails.replaceAll(':id', report.id));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      report.title ?? 'Untitled Report',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
                        border: Border.all(color: Colors.red),
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
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.category, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    report.issueType ?? 'Unknown',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    report.createdAt != null
                        ? _formatDate(report.createdAt!)
                        : 'N/A',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (report.description != null && report.description!.isNotEmpty)
                Text(
                  report.description!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildStatusBadge(report.status),
                        _buildValidationBadge(report.validationStatus),
                        if (report.lifecycleStage != null)
                          _buildLifecycleBadge(report.lifecycleStage!),
                      ],
                    ),
                  ),
                ],
              ),
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
