import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

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
  final bool isCustom;
  final List<String>? reportIds;

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
    this.isCustom = false,
    this.reportIds,
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
      isCustom: json['is_custom'] as bool? ?? false,
      reportIds: json['report_ids'] != null
          ? (json['report_ids'] as List).map((e) => e.toString()).toList()
          : null,
    );
  }
}

class TaskReport {
  final String id;
  final String? title;
  final String? description;
  final String? issueType;
  final String? status;
  final String? stage;
  final String? validationStatus;
  final double? latitude;
  final double? longitude;
  final String? beforePhotoUrl;
  final String? afterPhotoUrl;

  TaskReport({
    required this.id,
    this.title,
    this.description,
    this.issueType,
    this.status,
    this.stage,
    this.validationStatus,
    this.latitude,
    this.longitude,
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
      stage: json['stage'] as String? ?? json['lifecycle_stage'] as String?,
      validationStatus: json['validation_status'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      beforePhotoUrl: json['before_photo_url'] as String?,
      afterPhotoUrl: json['after_photo_url'] as String?,
    );
  }
}

class LguCleanupTaskDetailsScreen extends ConsumerStatefulWidget {
  final String taskId;

  const LguCleanupTaskDetailsScreen({super.key, required this.taskId});

  @override
  ConsumerState<LguCleanupTaskDetailsScreen> createState() =>
      _LguCleanupTaskDetailsScreenState();
}

class _LguCleanupTaskDetailsScreenState
    extends ConsumerState<LguCleanupTaskDetailsScreen> {
  CleanupTaskDetail? _task;
  List<TaskReport> _reports = [];
  bool _isLoading = true;
  bool _isMarkingComplete = false;
  final Map<String, bool> _isUploadingPhotos = {}; // key: "$reportId-$photoType"
  final Map<String, bool> _isDeletingPhotos = {}; // key: "$reportId-$photoType"
  final Set<String> _expandedReports = {};
  final ImagePicker _picker = ImagePicker();

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

      // Load reports
      if (_task?.isCustom == true && _task?.reportIds?.isNotEmpty == true) {
        // Load reports by ids
        final reportsResponse = await apiClient.getReportsByIds(_task!.reportIds!);
        final List<dynamic> data = reportsResponse.data is List
            ? reportsResponse.data as List<dynamic>
            : [];
        final reports = data
            .map((json) => TaskReport.fromJson(json as Map<String, dynamic>))
            .toList();
        setState(() {
          _reports = reports;
        });
      } else if (_task?.clusterId != null) {
        // Load reports by cluster id
        final reportsResponse = await apiClient.getReportsByClusterId(
          _task!.clusterId!,
        );
        final List<dynamic> data = reportsResponse.data is List
            ? reportsResponse.data as List<dynamic>
            : [];
        final reports = data
            .map((json) => TaskReport.fromJson(json as Map<String, dynamic>))
            .toList();
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
    // Check if all reports are resolved (lifecycle stage)
    if (_reports.isNotEmpty) {
      final unresolvedReports = _reports.where((r) => r.stage != 'resolved');
      if (unresolvedReports.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task can only be complete when all reports are resolved'),
          ),
        );
        return;
      }
    }

    setState(() => _isMarkingComplete = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.markCleanupTaskComplete(widget.taskId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cleanup task marked as complete successfully!')),
      );
      await _loadTaskDetails();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark task complete: $e')),
      );
    } finally {
      if (mounted) setState(() => _isMarkingComplete = false);
    }
  }

  Future<void> _uploadReportPhoto(String reportId, String photoType) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile == null) return;

    final key = "$reportId-$photoType";
    setState(() => _isUploadingPhotos[key] = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final file = File(pickedFile.path);
      await apiClient.uploadReportPhoto(
        reportId,
        file,
        photoType,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo uploaded successfully')),
      );
      await _loadTaskDetails();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload photo: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploadingPhotos.remove(key));
    }
  }

  Future<void> _deleteReportPhoto(String reportId, String photoType) async {
    final key = "$reportId-$photoType";
    setState(() => _isDeletingPhotos[key] = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.deleteReportPhoto(
        reportId,
        photoType,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo deleted successfully')),
      );
      await _loadTaskDetails();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete photo: $e')),
      );
    } finally {
      if (mounted) setState(() => _isDeletingPhotos.remove(key));
    }
  }

  Future<void> _uploadTaskPhoto(String photoType) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile == null) return;

    final key = "task-$photoType";
    setState(() => _isUploadingPhotos[key] = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final file = File(pickedFile.path);
      await apiClient.uploadCleanupPhoto(
        taskId: widget.taskId,
        photoType: photoType,
        image: file,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo uploaded successfully')),
      );
      await _loadTaskDetails();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload photo: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploadingPhotos.remove(key));
    }
  }

  Future<void> _deleteTaskPhoto(String photoType) async {
    final key = "task-$photoType";
    setState(() => _isDeletingPhotos[key] = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.deleteCleanupPhoto(
        taskId: widget.taskId,
        photoType: photoType,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo deleted successfully')),
      );
      await _loadTaskDetails();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete photo: $e')),
      );
    } finally {
      if (mounted) setState(() => _isDeletingPhotos.remove(key));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Task #${widget.taskId}'), elevation: 0),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _task == null
            ? const Center(child: Text('Task not found'))
            : SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 24,
                ),
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
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          Text(
                            _task?.title ?? 'Untitled Task',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_task?.isCustom == true)
                            Chip(
                              label: const Text('Custom'),
                              labelStyle: const TextStyle(fontSize: 10),
                              padding: const EdgeInsets.all(0),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _task?.description ?? 'No description',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      _task?.status,
                    ).withValues(alpha: 0.1),
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
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey[600],
                    ),
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
                      Flexible(
                        child: Text(
                          'Cluster: ${_truncateClusterId(_task!.clusterId!)}',
                          style: TextStyle(color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
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
                Text(
                  _task?.isCustom == true ? 'Linked Reports' : 'Reports in this Cluster',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Flexible(
                  child: Text(
                    '$completedCount / $totalCount',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    overflow: TextOverflow.ellipsis,
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
              Text(_task?.isCustom == true ? 'No linked reports' : 'No reports found in this cluster')
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  report.issueType ?? 'Unknown',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              Container(
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
                                  report.status
                                          ?.replaceAll('_', ' ')
                                          .toUpperCase() ??
                                      'N/A',
                                  style: TextStyle(
                                    color: _getStatusColor(report.status),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (report.stage != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.blue),
                                  ),
                                  child: Text(
                                    report.stage!
                                            .replaceAll('_', ' ')
                                            .toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.blue,
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
                    _buildReportInfoSection(report),
                    const SizedBox(height: 16),
                    
                    // Before & After Photos Section
                    const Text(
                      'Before & After Photos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildReportPhotoUploadSection(report, 'before'),
                    const SizedBox(height: 12),
                    _buildReportPhotoUploadSection(report, 'after'),
                    
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.go('/lgu/reports/${report.id}');
                        },
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('View Full Report Details'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportPhotoUploadSection(TaskReport report, String photoType) {
    final key = "${report.id}-$photoType";
    final photoUrl = photoType == 'before' ? report.beforePhotoUrl : report.afterPhotoUrl;
    final label = photoType == 'before' ? 'Before Photo' : 'After Photo';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        if (photoUrl != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  photoUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.broken_image)),
                    );
                  },
                ),
              ),
              if (_task?.status != 'completed')
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton.filled(
                    onPressed: (_isDeletingPhotos[key] ?? false)
                        ? null
                        : () => _deleteReportPhoto(report.id, photoType),
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ),
            ],
          )
        else
          SizedBox(
            width: double.infinity,
            height: 200,
            child: ElevatedButton.icon(
              onPressed: (_isUploadingPhotos[key] ?? false)
                  ? null
                  : () => _uploadReportPhoto(report.id, photoType),
              icon: const Icon(Icons.add_a_photo),
              label: Text('Upload $label'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReportInfoSection(TaskReport report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Report Information',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildInfoRow('Report ID', report.id),
        _buildInfoRow('Title', report.title ?? 'N/A'),
        _buildInfoRow('Description', report.description ?? 'N/A'),
        _buildInfoRow('Issue Type', report.issueType ?? 'N/A'),
        _buildInfoRow(
          'Status',
          report.status?.replaceAll('_', ' ').toUpperCase() ?? 'N/A',
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery() {
    // Collect all before and after photos
    final List<Map<String, dynamic>> beforePhotos = [];
    final List<Map<String, dynamic>> afterPhotos = [];

    // Add task-level photos first
    if (_task?.beforePhotoUrl != null) {
      beforePhotos.add({
        'url': _task!.beforePhotoUrl,
        'label': 'Task Before',
        'isTask': true,
        'reportId': null,
      });
    }
    if (_task?.afterPhotoUrl != null) {
      afterPhotos.add({
        'url': _task!.afterPhotoUrl,
        'label': 'Task After',
        'isTask': true,
        'reportId': null,
      });
    }

    // Add report-level photos
    for (var report in _reports) {
      if (report.beforePhotoUrl != null) {
        beforePhotos.add({
          'url': report.beforePhotoUrl!,
          'label': report.title ?? 'Report ${report.id}',
          'isTask': false,
          'reportId': report.id,
        });
      }
      if (report.afterPhotoUrl != null) {
        afterPhotos.add({
          'url': report.afterPhotoUrl!,
          'label': report.title ?? 'Report ${report.id}',
          'isTask': false,
          'reportId': report.id,
        });
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Photo Gallery',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Before Photos Section
            _buildPhotoGroup('Before Photos', beforePhotos, 'before'),
            const SizedBox(height: 24),
            
            // After Photos Section
            _buildPhotoGroup('After Photos', afterPhotos, 'after'),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGroup(String label, List<Map<String, dynamic>> photos, String photoType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (photos.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              return _buildPhotoItem(photo, photoType);
            },
          )
        else
          Text(
            'No $label yet',
            style: TextStyle(color: Colors.grey[600]),
          ),
      ],
    );
  }

  Widget _buildPhotoItem(Map<String, dynamic> photo, String photoType) {
    final isTask = photo['isTask'] as bool;
    final reportId = photo['reportId'] as String?;
    final key = isTask ? "task-$photoType" : "$reportId-$photoType";

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              photo['url'] as String,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 32),
                  ),
                );
              },
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  photo['label'] as String,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (_task?.status != 'completed')
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filled(
                  onPressed: (_isDeletingPhotos[key] ?? false)
                      ? null
                      : () {
                          if (isTask) {
                            _deleteTaskPhoto(photoType);
                          } else if (reportId != null) {
                            _deleteReportPhoto(reportId, photoType);
                          }
                        },
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid(String label, List<String> photoUrls) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: photoUrls.length,
          itemBuilder: (context, index) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                photoUrls[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.broken_image)),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 12),
      ],
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

  String _truncateClusterId(String clusterId) {
    if (clusterId.length <= 8) return clusterId;
    return '${clusterId.substring(0, 8)}...';
  }
}
