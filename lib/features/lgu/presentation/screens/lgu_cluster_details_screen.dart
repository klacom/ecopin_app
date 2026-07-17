import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:logging/logging.dart';

class ClusterDetail {
  final String id;
  final String? issueType;
  final String? severity;
  final int? reportCount;
  final String? status;
  final double? centerLat;
  final double? centerLng;

  ClusterDetail({
    required this.id,
    this.issueType,
    this.severity,
    this.reportCount,
    this.status,
    this.centerLat,
    this.centerLng,
  });

  factory ClusterDetail.fromJson(Map<String, dynamic> json) {
    return ClusterDetail(
      id: json['id']?.toString() ?? '',
      issueType: json['issue_type'] as String?,
      severity: json['severity'] as String?,
      reportCount: json['report_count'] as int?,
      status: json['status'] as String?,
      centerLat: json['center_lat'] as double?,
      centerLng: json['center_lng'] as double?,
    );
  }
}

class Report {
  final String id;
  final String? title;
  final String? description;
  final String? issueType;
  final String? status;
  final DateTime? createdAt;

  Report({
    required this.id,
    this.title,
    this.description,
    this.issueType,
    this.status,
    this.createdAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String?,
      description: json['description'] as String?,
      issueType: json['issue_type'] as String?,
      status: json['status'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }
}

class LguClusterDetailsScreen extends ConsumerStatefulWidget {
  final String clusterId;

  const LguClusterDetailsScreen({super.key, required this.clusterId});

  @override
  ConsumerState<LguClusterDetailsScreen> createState() =>
      _LguClusterDetailsScreenState();
}

class _LguClusterDetailsScreenState
    extends ConsumerState<LguClusterDetailsScreen> {
  final Logger log = Logger('Lgu Cluster Details Screen');
  ClusterDetail? _cluster;
  List<Report> _reports = [];
  bool _isLoading = true;
  bool _isLoadingReports = true;

  @override
  void initState() {
    super.initState();
    _loadClusterDetails();
    _loadClusterReports();
  }

  Future<void> _loadClusterDetails() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.getClusterById(widget.clusterId);
      setState(() {
        _cluster = ClusterDetail.fromJson(response.data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadClusterReports() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.getReportsByClusterId(widget.clusterId);
      final List<dynamic> data = response.data is List
          ? response.data as List<dynamic>
          : [];
      final reports = data
          .map((json) => Report.fromJson(json as Map<String, dynamic>))
          .toList();
      setState(() {
        _reports = reports;
        _isLoadingReports = false;
      });
    } catch (e) {
      log.severe('Error loading cluster reports: $e');
      setState(() => _isLoadingReports = false);
    }
  }

  Color _getSeverityColor(String? severity) {
    switch (severity) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'resolved':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'closed':
        return Colors.grey;
      case 'unresolved':
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cluster #${widget.clusterId}'), elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cluster == null
          ? const Center(child: Text('Cluster not found'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildClusterSummary(),
                  const SizedBox(height: 16),
                  _buildReportsSection(),
                  const SizedBox(height: 96),
                ],
              ),
            ),
    );
  }

  Widget _buildClusterSummary() {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Cluster Summary',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Pass all report IDs in this cluster
                    final reportIds = _reports.map((r) => r.id).toList();
                    context.push(
                      LguAppRoutes.clusterCreateTask.replaceAll(
                        ':id',
                        widget.clusterId,
                      ),
                      extra: {'reportIds': reportIds},
                    );
                  },
                  icon: const Icon(Icons.add_task, size: 20),
                  label: const Text('Create Task'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildStatCard(
                  'Total Reports',
                  _cluster?.reportCount?.toString() ?? '0',
                  Icons.description,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Severity',
                  _cluster?.severity?.toUpperCase() ?? 'N/A',
                  Icons.warning,
                  _getSeverityColor(_cluster?.severity),
                ),
                _buildStatCard(
                  'Issue Type',
                  _cluster?.issueType ?? 'N/A',
                  Icons.category,
                  Colors.purple,
                ),
                _buildStatCard(
                  'Location',
                  _cluster?.centerLat != null && _cluster?.centerLng != null
                      ? '${_cluster!.centerLat!.toStringAsFixed(4)}, ${_cluster!.centerLng!.toStringAsFixed(4)}'
                      : 'N/A',
                  Icons.location_on,
                  Colors.teal,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsSection() {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reports in this Cluster',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16, width: double.infinity),
            if (_isLoadingReports)
              const Center(child: CircularProgressIndicator())
            else if (_reports.isEmpty)
              const Text('No reports found in this cluster')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _reports.length,
                itemBuilder: (context, index) {
                  final report = _reports[index];
                  return _buildReportCard(report);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(Report report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.go('/lgu/reports/${report.id}');
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
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          report.status,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        report.status?.replaceAll('_', ' ').toUpperCase() ??
                            'N/A',
                        style: TextStyle(
                          color: _getStatusColor(report.status),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
                        ? '${report.createdAt!.day}/${report.createdAt!.month}/${report.createdAt!.year}'
                        : 'N/A',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
