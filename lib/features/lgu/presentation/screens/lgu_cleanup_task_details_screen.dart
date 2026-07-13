import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:go_router/go_router.dart';

class CleanupTaskDetail {
  final String id;
  final String? clusterId;
  final String? title;
  final String? description;
  final String? status;
  final DateTime? createdAt;
  final String? beforePhotoUrl;
  final String? afterPhotoUrl;
  final Map<String, dynamic>? cluster;

  CleanupTaskDetail({
    required this.id,
    this.clusterId,
    this.title,
    this.description,
    this.status,
    this.createdAt,
    this.beforePhotoUrl,
    this.afterPhotoUrl,
    this.cluster,
  });

  factory CleanupTaskDetail.fromJson(Map<String, dynamic> json) {
    return CleanupTaskDetail(
      id: json['id']?.toString() ?? '',
      clusterId: json['cluster_id']?.toString(),
      title: json['title'] as String?,
      description: json['description'] as String?,
      status: json['status'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      beforePhotoUrl: json['before_photo_url'] as String?,
      afterPhotoUrl: json['after_photo_url'] as String?,
      cluster: json['clusters'] as Map<String, dynamic>?,
    );
  }
}

class TaskReport {
  final String id;
  final String? title;
  final String? description;
  final String? issueType;
  final String? status;
  final String? beforePhotoUrl;
  final String? afterPhotoUrl;

  TaskReport({
    required this.id,
    this.title,
    this.description,
    this.issueType,
    this.status,
    this.beforePhotoUrl,
    this.afterPhotoUrl,
  });

  factory TaskReport.fromJson(Map<String, dynamic> json) {
    return TaskReport(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String?,
      description: json['description'] as String?,
      issueType: json['issue_type'] as String?,
      status: json['status'] as String?,
      beforePhotoUrl: json['before_photo_url'] as String?,
      afterPhotoUrl: json['after_photo_url'] as String?,
    );
  }
}

class LguCleanupTaskDetailsScreen extends ConsumerStatefulWidget {
  final String taskId;

  const LguCleanupTaskDetailsScreen({super.key, required this.taskId});

  @override
  ConsumerState<LguCleanupTaskDetailsScreen> createState() => _LguCleanupTaskDetailsScreenState();
}

class _LguCleanupTaskDetailsScreenState extends ConsumerState<LguCleanupTaskDetailsScreen> {
  CleanupTaskDetail? _task;
  List<TaskReport> _reports = [];
  bool _isLoading = true;
  bool _isMarkingComplete = false;
  final Set<String> _expandedReports = {};

  @override
  void initState() {
    super.initState();
    _loadTaskDetails();
  }

  Future<void> _loadTaskDetails() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.getCleanupTaskById(widget.taskId);
      setState(() {
        _task = CleanupTaskDetail.fromJson(response.data);
        _isLoading = false;
      });

      // Load reports in the cluster
      if (_task?.clusterId != null) {
        final reportsResponse = await apiClient.getReportsByClusterId(_task!.clusterId!);
        final List<dynamic> data = reportsResponse.data is List
            ? reportsResponse.data as List<dynamic>
            : [];
        final reports = data.map((json) => TaskReport.fromJson(json as Map<String, dynamic>)).toList();
        setState(() {
          _reports = reports;
        });
      }
    } catch (e) {
      print('Error loading task details: $e');
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  void _toggleReportExpansion(String reportId) {
    setState(() {
      if (_expandedReports.contains(reportId)) {
        _expandedReports.remove(reportId);
      } else {
        _expandedReports.add(reportId);
      }
    });
  }

  Future<void> _markTaskComplete() async {
    setState(() => _isMarkingComplete = true);
    try {
      // TODO: Implement mark task complete API call
      setState(() => _isMarkingComplete = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task marked as complete')),
      );
    } catch (e) {
      setState(() => _isMarkingComplete = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to mark task complete')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task #${widget.taskId}'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _task == null
              ? const Center(child: Text('Task not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTaskSummary(),
                      const SizedBox(height: 24),
                      _buildReportsSection(),
                      const SizedBox(height: 24),
                      _buildPhotoGallery(),
                      const SizedBox(height: 24),
                      if (_task?.status != 'completed')
                        _buildMarkCompleteButton(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildTaskSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _task?.title ?? 'Untitled Task',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _task?.description ?? 'No description',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_task?.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _task?.status?.toUpperCase() ?? 'N/A',
                    style: TextStyle(
                      color: _getStatusColor(_task?.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      _task?.createdAt != null
                          ? 'Created: ${_task!.createdAt!.day}/${_task!.createdAt!.month}/${_task!.createdAt!.year}'
                          : 'N/A',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                if (_task?.clusterId != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.group_work, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Cluster: ${_task!.clusterId}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsSection() {
    final completedCount = _reports.where((r) => r.status == 'resolved').length;
    final totalCount = _reports.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Reports in this Cluster',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$completedCount / $totalCount completed',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (totalCount > 0)
              LinearProgressIndicator(
                value: totalCount > 0 ? completedCount / totalCount : 0,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            const SizedBox(height: 16),
            if (_reports.isEmpty)
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

  Widget _buildReportCard(TaskReport report) {
    final isExpanded = _expandedReports.contains(report.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: _getStatusColor(report.status),
          width: report.status == 'resolved' ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
        children: [
          InkWell(
            onTap: () => _toggleReportExpansion(report.id),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.title ?? 'Untitled Report',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          report.description ?? 'No description',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                report.issueType ?? 'Unknown',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(report.status).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                report.status?.replaceAll('_', ' ').toUpperCase() ?? 'N/A',
                                style: TextStyle(
                                  color: _getStatusColor(report.status),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                    ),
                    onPressed: () => _toggleReportExpansion(report.id),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Before & After Photos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPhotoSection('Before', report.beforePhotoUrl),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPhotoSection('After', report.afterPhotoUrl),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection(String label, String? photoUrl) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          if (photoUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                photoUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 120,
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.broken_image)),
                  );
                },
              ),
            )
          else
            Container(
              height: 120,
              color: Colors.grey[200],
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate, size: 32),
                    SizedBox(height: 8),
                    Text('Upload photo', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Task Photo Gallery',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPhotoSection('Before', _task?.beforePhotoUrl),
            const SizedBox(height: 12),
            _buildPhotoSection('After', _task?.afterPhotoUrl),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkCompleteButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isMarkingComplete ? null : _markTaskComplete,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isMarkingComplete
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Mark Task as Complete',
                style: TextStyle(fontSize: 16),
              ),
      ),
    );
  }
}
