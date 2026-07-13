import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class LguReportDetail {
  final String id;
  final String? title;
  final String? issue;
  final String? description;
  final String? location;
  final String? status;
  final String? lifecycleStage;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? reporterId;
  final String? reporterName;
  final String? reporterEmail;
  final bool? discloseIdentity;
  final bool? dataConsent;
  final List<String>? evidencePhotos;
  final List<String>? lguBeforePhotos;
  final List<String>? lguAfterPhotos;
  final String? lguNotes;
  final List<ActivityLog>? activityLogs;

  LguReportDetail({
    required this.id,
    this.title,
    this.issue,
    this.description,
    this.location,
    this.status,
    this.lifecycleStage,
    this.createdAt,
    this.updatedAt,
    this.reporterId,
    this.reporterName,
    this.reporterEmail,
    this.discloseIdentity,
    this.dataConsent,
    this.evidencePhotos,
    this.lguBeforePhotos,
    this.lguAfterPhotos,
    this.lguNotes,
    this.activityLogs,
  });

  factory LguReportDetail.fromJson(Map<String, dynamic> json) {
    return LguReportDetail(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String?,
      issue: json['issue'] as String?,
      description: json['description'] as String?,
      location: json['location'] as String?,
      status: json['status'] as String?,
      lifecycleStage: json['lifecycle_stage'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      reporterId: json['reporter_id']?.toString(),
      reporterName: json['reporter_name'] as String?,
      reporterEmail: json['reporter_email'] as String?,
      discloseIdentity: json['disclose_identity'] as bool?,
      dataConsent: json['profiles'] != null && json['profiles']['data_consent'] != null
          ? json['profiles']['data_consent'] as bool
          : null,
      evidencePhotos: json['evidence_photos'] != null
          ? (json['evidence_photos'] as List).map((e) => e.toString()).toList()
          : null,
      lguBeforePhotos: json['lgu_before_photos'] != null
          ? (json['lgu_before_photos'] as List).map((e) => e.toString()).toList()
          : null,
      lguAfterPhotos: json['lgu_after_photos'] != null
          ? (json['lgu_after_photos'] as List).map((e) => e.toString()).toList()
          : null,
      lguNotes: json['lgu_notes'] as String?,
      activityLogs: json['activity_logs'] != null
          ? (json['activity_logs'] as List)
              .map((e) => ActivityLog.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
}

class ActivityLog {
  final String id;
  final String? action;
  final String? details;
  final DateTime? createdAt;
  final String? userId;
  final String? userName;

  ActivityLog({
    required this.id,
    this.action,
    this.details,
    this.createdAt,
    this.userId,
    this.userName,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id']?.toString() ?? '',
      action: json['action'] as String?,
      details: json['details'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      userId: json['user_id']?.toString(),
      userName: json['user_name'] as String?,
    );
  }
}

class LguReportDetailsScreen extends ConsumerStatefulWidget {
  final String reportId;

  const LguReportDetailsScreen({super.key, required this.reportId});

  @override
  ConsumerState<LguReportDetailsScreen> createState() => _LguReportDetailsScreenState();
}

class _LguReportDetailsScreenState extends ConsumerState<LguReportDetailsScreen> {
  LguReportDetail? _report;
  bool _isLoading = true;
  bool _isUpdating = false;
  bool _isUploading = false;
  final TextEditingController _notesController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadReportDetails();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadReportDetails() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.getReportById(widget.reportId);
      setState(() {
        _report = LguReportDetail.fromJson(response.data);
        _notesController.text = _report?.lguNotes ?? '';
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading report details: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateLifecycleStage(String stage) async {
    setState(() => _isUpdating = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.updateReportLifecycleStage(widget.reportId, stage);
      await _loadReportDetails();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lifecycle stage updated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update lifecycle stage')),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _saveNotes() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.updateReportNotes(widget.reportId, _notesController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notes saved')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save notes')),
      );
    }
  }

  Future<void> _uploadPhotos(bool isBefore) async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxHeight: 1920,
        maxWidth: 1080,
      );

      if (images.isEmpty) return;

      if (images.length > 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 5 photos allowed')),
        );
        return;
      }

      setState(() => _isUploading = true);

      final files = images.map((xFile) => File(xFile.path)).toList();

      final response = isBefore
          ? await ref.read(apiClientProvider).uploadReportBeforePhotos(widget.reportId, files)
          : await ref.read(apiClientProvider).uploadReportAfterPhotos(widget.reportId, files);

      await _loadReportDetails();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photos uploaded successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload photos')),
      );
    } finally {
      setState(() => _isUploading = false);
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

  List<DropdownMenuItem<String>> _getLifecycleStageItems() {
    final currentStage = _report?.lifecycleStage;
    final items = <DropdownMenuItem<String>>[];

    // Only show the next available stage based on current stage
    switch (currentStage) {
      case null:
        // Can move to acknowledged
        items.add(const DropdownMenuItem(value: 'acknowledged', child: Text('Acknowledged')));
        break;
      case 'acknowledged':
        // Can move to responded
        items.add(const DropdownMenuItem(value: 'acknowledged', child: Text('Acknowledged')));
        items.add(const DropdownMenuItem(value: 'responded', child: Text('Responded')));
        break;
      case 'responded':
        // Can move to resolved
        items.add(const DropdownMenuItem(value: 'acknowledged', child: Text('Acknowledged')));
        items.add(const DropdownMenuItem(value: 'responded', child: Text('Responded')));
        items.add(const DropdownMenuItem(value: 'resolved', child: Text('Resolved')));
        break;
      case 'resolved':
        // No further stages
        items.add(const DropdownMenuItem(value: 'acknowledged', child: Text('Acknowledged')));
        items.add(const DropdownMenuItem(value: 'responded', child: Text('Responded')));
        items.add(const DropdownMenuItem(value: 'resolved', child: Text('Resolved')));
        break;
      default:
        items.add(const DropdownMenuItem(value: 'acknowledged', child: Text('Acknowledged')));
        items.add(const DropdownMenuItem(value: 'responded', child: Text('Responded')));
        items.add(const DropdownMenuItem(value: 'resolved', child: Text('Resolved')));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _report == null
              ? const Center(child: Text('Report not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReportDetailsSection(),
                      const SizedBox(height: 24),
                      _buildActionsSection(),
                      const SizedBox(height: 24),
                      _buildLifecycleSection(),
                      const SizedBox(height: 24),
                      if (_report?.discloseIdentity == true) _buildReporterSection(),
                      const SizedBox(height: 24),
                      _buildEvidencePhotosSection(),
                      const SizedBox(height: 24),
                      _buildLguNotesSection(),
                      const SizedBox(height: 24),
                      _buildActivityLogSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildReportDetailsSection() {
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
                  'Report Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_report?.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _report?.status?.replaceAll('_', ' ').toUpperCase() ?? 'N/A',
                    style: TextStyle(
                      color: _getStatusColor(_report?.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Report ID', _report?.id ?? 'N/A'),
            _buildInfoRow('Created Date', _formatDate(_report?.createdAt)),
            _buildInfoRow('Last Updated', _formatDate(_report?.updatedAt)),
            _buildInfoRow('Title', _report?.title ?? 'N/A'),
            _buildInfoRow('Issue', _report?.issue ?? 'N/A'),
            _buildInfoRow('Description', _report?.description ?? 'N/A'),
            _buildInfoRow('Location', _report?.location ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _report?.lifecycleStage,
              decoration: const InputDecoration(
                labelText: 'Update Lifecycle Stage',
                border: OutlineInputBorder(),
              ),
              items: _getLifecycleStageItems(),
              onChanged: _isUpdating || _report?.lifecycleStage == 'resolved'
                  ? null
                  : (value) {
                      if (value != null) {
                        _updateLifecycleStage(value);
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLifecycleSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report Lifecycle',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildLifecycleStep('Submitted', true, _report?.lifecycleStage == null),
            _buildLifecycleStep('Acknowledged', _report?.lifecycleStage == 'acknowledged', _report?.lifecycleStage == 'acknowledged'),
            _buildLifecycleStep('Responded', _report?.lifecycleStage == 'responded' || _report?.lifecycleStage == 'resolved', _report?.lifecycleStage == 'responded'),
            _buildLifecycleStep('Resolved', _report?.lifecycleStage == 'resolved', _report?.lifecycleStage == 'resolved'),
          ],
        ),
      ),
    );
  }

  Widget _buildLifecycleStep(String label, bool isCompleted, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? Colors.green : Colors.grey[300],
            ),
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.green : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReporterSection() {
    if (_report?.dataConsent != true) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reporter Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Reporter Name', _report?.reporterName),
            _buildInfoRow('Reporter ID', _report?.reporterId),
            _buildInfoRow('Reporter Email', _report?.reporterEmail),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidencePhotosSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Evidence Photos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_report?.evidencePhotos != null && _report!.evidencePhotos!.isNotEmpty)
              _buildPhotoGrid('Reporter Evidence', _report!.evidencePhotos!),
            const SizedBox(height: 16),
            _buildLguPhotoSection('LGU Before Photos', _report?.lguBeforePhotos, true),
            const SizedBox(height: 16),
            _buildLguPhotoSection('LGU After Photos', _report?.lguAfterPhotos, false),
            if (_report?.evidencePhotos == null || _report!.evidencePhotos!.isEmpty)
              const Text('No evidence photos available'),
          ],
        ),
      ),
    );
  }

  Widget _buildLguPhotoSection(String label, List<String>? photos, bool isBefore) {
    return Column(
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
        if (photos != null && photos.isNotEmpty)
          _buildPhotoGrid(label, photos),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => _uploadPhotos(isBefore),
          icon: const Icon(Icons.upload, size: 18),
          label: Text('Upload ${isBefore ? 'Before' : 'After'} Photos'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 40),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoGrid(String label, List<String> photoUrls) {
    return Column(
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
      ],
    );
  }

  Widget _buildLguNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LGU Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_report?.lguNotes != null && _report!.lguNotes!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _report!.lguNotes!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _notesController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Add notes about this report...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveNotes,
                child: const Text('Save Notes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLogSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity Log',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_report?.activityLogs != null && _report!.activityLogs!.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _report!.activityLogs!.length,
                itemBuilder: (context, index) {
                  final log = _report!.activityLogs![index];
                  return _buildActivityLogItem(log);
                },
              )
            else
              const Text('No activity logs available'),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLogItem(ActivityLog log) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                log.action?.toUpperCase() ?? 'UNKNOWN',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              if (log.createdAt != null)
                Text(
                  _formatDateTime(log.createdAt!),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          if (log.details != null && log.details!.isNotEmpty)
            Text(
              log.details!,
              style: const TextStyle(fontSize: 14),
            ),
          if (log.userName != null) ...[
            const SizedBox(height: 4),
            Text(
              'By: ${log.userName}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
