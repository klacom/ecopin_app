import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:logging/logging.dart';

class LguReportDetail {
  final String id;
  final String? title;
  final String? issue;
  final String? description;
  final String? location;
  final String? status;
  final String? stage;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? reporterId;
  final String? reporterName;
  final String? reporterEmail;
  final bool? discloseIdentity;
  final bool? dataConsent;
  final List<EvidencePhoto>? evidencePhotos;
  final String? beforePhotoUrl;
  final String? afterPhotoUrl;
  final List<ResponseLog>? responseLogs;
  final String? validationStatus;

  LguReportDetail({
    required this.id,
    this.title,
    this.issue,
    this.description,
    this.location,
    this.status,
    this.stage,
    this.createdAt,
    this.updatedAt,
    this.reporterId,
    this.reporterName,
    this.reporterEmail,
    this.discloseIdentity,
    this.dataConsent,
    this.evidencePhotos,
    this.beforePhotoUrl,
    this.afterPhotoUrl,
    this.responseLogs,
    this.validationStatus,
  });

  factory LguReportDetail.fromJson(Map<String, dynamic> json) {
    return LguReportDetail(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String?,
      issue: json['issue_type'] as String?,
      description: json['description'] as String?,
      location: json['location'] as String?,
      status: json['status'] as String?,
      stage: json['stage'] as String? ?? json['lifecycle_stage'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      reporterId: json['user_id']?.toString(),
      reporterName:
          json['profiles']?['full_name'] as String? ??
          json['user_full_name'] as String?,
      reporterEmail: null,
      discloseIdentity: json['disclose_identity'] as bool?,
      dataConsent: json['profiles']?['data_consent'] as bool?,
      evidencePhotos: null,
      beforePhotoUrl: json['before_photo_url'] as String?,
      afterPhotoUrl: json['after_photo_url'] as String?,
      responseLogs: json['response_logs'] != null
          ? (json['response_logs'] as List)
                .map((e) => ResponseLog.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      validationStatus: json['validation_status'] as String?,
    );
  }
}

class EvidencePhoto {
  final String url;
  final String name;
  final int? size;
  final DateTime? createdAt;

  EvidencePhoto({
    required this.url,
    required this.name,
    this.size,
    this.createdAt,
  });

  factory EvidencePhoto.fromJson(Map<String, dynamic> json) {
    return EvidencePhoto(
      url: json['url'] as String,
      name: json['name'] as String,
      size: json['size'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}

class ResponseLog {
  final String id;
  final String? actionType;
  final String? actionDetails;
  final DateTime? createdAt;
  final String? userId;
  final String? userName;

  ResponseLog({
    required this.id,
    this.actionType,
    this.actionDetails,
    this.createdAt,
    this.userId,
    this.userName,
  });

  factory ResponseLog.fromJson(Map<String, dynamic> json) {
    return ResponseLog(
      id: json['id']?.toString() ?? '',
      actionType: json['action_type'] as String?,
      actionDetails: json['action_details'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      userId: json['user_id']?.toString(),
      userName: json['profiles']?['full_name'] as String?,
    );
  }
}

class LguReportDetailsScreen extends ConsumerStatefulWidget {
  final String reportId;

  const LguReportDetailsScreen({super.key, required this.reportId});

  @override
  ConsumerState<LguReportDetailsScreen> createState() =>
      _LguReportDetailsScreenState();
}

class _LguReportDetailsScreenState
    extends ConsumerState<LguReportDetailsScreen> {
  LguReportDetail? _report;
  List<EvidencePhoto> _evidencePhotos = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _isUpdating = false;
  bool _isUploading = false;
  bool _isDeleting = false;
  final TextEditingController _notesController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final Logger log = Logger("LGU Report Details Screen");

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
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });
    try {
      final apiClient = ref.read(apiClientProvider);

      final response = await apiClient.getReportById(widget.reportId);

      List<EvidencePhoto> evidenceList = [];
      try {
        final evidenceResponse = await apiClient.getReportEvidence(
          widget.reportId,
        );
        if (evidenceResponse.data is List) {
          evidenceList = (evidenceResponse.data as List)
              .map((e) => EvidencePhoto.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      } catch (e) {
        log.severe('Error loading evidence: $e');
      }

      setState(() {
        if (mounted) {
          _report = LguReportDetail.fromJson(
            response.data is Map<String, dynamic>
                ? response.data as Map<String, dynamic>
                : {},
          );
          _evidencePhotos = evidenceList;
          _isLoading = false;
        }
      });
    } catch (e, stackTrace) {
      log.severe('Error loading report details: $e');
      log.severe('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _updateLifecycleStage(String stage) async {
    setState(() => _isUpdating = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.updateReportLifecycleStage(widget.reportId, stage);
      await _loadReportDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lifecycle stage updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update lifecycle stage')),
        );
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _saveNotes() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.logAgencyResponse(widget.reportId, _notesController.text);
      _notesController.clear();
      await _loadReportDetails();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Notes saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to save notes')));
      }
    }
  }

  Future<void> _uploadPhoto(bool isBefore) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxHeight: 1920,
        maxWidth: 1080,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      final apiClient = ref.read(apiClientProvider);
      await apiClient.uploadReportPhoto(
        widget.reportId,
        File(image.path),
        isBefore ? 'before' : 'after',
      );

      await _loadReportDetails();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo uploaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to upload photo')));
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteReportPhoto(bool isBefore) async {
    setState(() => _isDeleting = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.deleteReportPhoto(
        widget.reportId,
        isBefore ? 'before' : 'after',
      );
      await _loadReportDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to delete photo')));
      }
    } finally {
      setState(() => _isDeleting = false);
    }
  }

  Future<void> _updateValidationStatus(String status) async {
    setState(() => _isUpdating = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.updateReportValidation(widget.reportId, status);
      await _loadReportDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Validation status updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update validation status')),
        );
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'resolved':
      case 'waiting_for_feedback':
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
    final items = <DropdownMenuItem<String>>[];
    final currentStage = _report?.stage;
    final validStages = ['submitted', 'acknowledged', 'responded', 'resolved'];

    // Always add the current stage first (disabled if it's the final stage)
    if (currentStage != null && !validStages.contains(currentStage)) {
      items.add(
        DropdownMenuItem(
          value: currentStage,
          enabled: false,
          child: Text(currentStage.replaceAll('_', ' ')),
        ),
      );
    }

    // Add submitted if needed
    if (currentStage == null ||
        currentStage == 'submitted' ||
        !validStages.contains(currentStage)) {
      items.add(
        const DropdownMenuItem(
          value: 'submitted',
          enabled: false,
          child: Text('Submitted'),
        ),
      );
    }

    // Add the rest of the stages
    items.addAll(const [
      DropdownMenuItem(value: 'acknowledged', child: Text('Acknowledged')),
      DropdownMenuItem(value: 'responded', child: Text('Responded')),
      DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
    ]);

    // Ensure no duplicate values
    final seenValues = <String>{};
    return items.where((item) {
      if (seenValues.contains(item.value)) return false;
      seenValues.add(item.value!);
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Details'), elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Error loading report',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_errorMessage ?? 'Unknown error'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadReportDetails,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
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
                  if (_report?.discloseIdentity == true ||
                      _report?.dataConsent == true)
                    _buildReporterSection(),
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
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      if (_report?.validationStatus != null)
                        Wrap(
                          spacing: 4,
                          children: [
                            Text(
                              'Validation: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getValidationColor(
                                  _report?.validationStatus,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _report?.validationStatus
                                        ?.replaceAll('_', ' ')
                                        .toUpperCase() ??
                                    'N/A',
                                style: TextStyle(
                                  color: _getValidationColor(
                                    _report?.validationStatus,
                                  ),
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
                SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        _report?.status,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _report?.status?.replaceAll('_', ' ').toUpperCase() ??
                          'N/A',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _getStatusColor(_report?.status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
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
          ],
        ),
      ),
    );
  }

  Color _getValidationColor(String? status) {
    switch (status) {
      case 'automatically_valid':
        return Colors.green;
      case 'manual_review':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.grey;
    }
  }

  Widget _buildActionsSection() {
    // Get valid lifecycle items first
    final lifecycleItems = _getLifecycleStageItems();
    final validLifecycleValues = lifecycleItems
        .map((item) => item.value)
        .toSet();
    // Ensure current stage is in the list, fallback to null or first valid value
    String? currentLifecycleValue = _report?.stage;
    if (currentLifecycleValue != null &&
        !validLifecycleValues.contains(currentLifecycleValue)) {
      currentLifecycleValue = null;
    }

    // Handle validation status similarly
    const validValidationValues = {
      'pending',
      'automatically_valid',
      'manual_review',
      'rejected',
    };
    String? currentValidationValue = _report?.validationStatus;
    if (currentValidationValue != null &&
        !validValidationValues.contains(currentValidationValue)) {
      currentValidationValue = null;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: currentLifecycleValue,
              decoration: const InputDecoration(
                labelText: 'Update Lifecycle Stage',
                border: OutlineInputBorder(),
              ),
              items: lifecycleItems,
              onChanged: _isUpdating || _report?.stage == 'resolved'
                  ? null
                  : (value) {
                      if (value != null) {
                        _updateLifecycleStage(value);
                      }
                    },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: currentValidationValue,
              decoration: const InputDecoration(
                labelText: 'Update Validation Status',
                border: OutlineInputBorder(),
              ),
              items: [
                // Add current validation status if it's not in the list
                if (currentValidationValue != null &&
                    !validValidationValues.contains(currentValidationValue))
                  DropdownMenuItem(
                    value: currentValidationValue,
                    enabled: false,
                    child: Text(currentValidationValue.replaceAll('_', ' ')),
                  ),
                const DropdownMenuItem(
                  value: 'pending',
                  child: Text('Pending'),
                ),
                const DropdownMenuItem(
                  value: 'automatically_valid',
                  child: Text('Automatically Valid'),
                ),
                const DropdownMenuItem(
                  value: 'manual_review',
                  child: Text('Manual Review'),
                ),
                const DropdownMenuItem(
                  value: 'rejected',
                  child: Text('Rejected'),
                ),
              ],
              onChanged: _isUpdating
                  ? null
                  : (value) {
                      if (value != null) {
                        _updateValidationStatus(value);
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildLifecycleStep('Submitted', true, _report?.stage == null),
            _buildLifecycleStep(
              'Acknowledged',
              _report?.stage == 'acknowledged' ||
                  _report?.stage == 'responded' ||
                  _report?.stage == 'resolved',
              _report?.stage == 'acknowledged',
            ),
            _buildLifecycleStep(
              'Responded',
              _report?.stage == 'responded' || _report?.stage == 'resolved',
              _report?.stage == 'responded',
            ),
            _buildLifecycleStep(
              'Resolved',
              _report?.stage == 'resolved',
              _report?.stage == 'resolved',
            ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reporter Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Reporter Name', _report?.reporterName),
            _buildInfoRow('Reporter ID', _report?.reporterId),
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
            if (_evidencePhotos.isNotEmpty) ...[
              const Text(
                'Reporter\'s Evidence Photos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildPhotoGrid(_evidencePhotos.map((e) => e.url).toList()),
              const SizedBox(height: 24),
            ],
            if (_report?.beforePhotoUrl != null)
              _buildPhotoWithRemove(
                'LGU Before Photo',
                _report!.beforePhotoUrl!,
                true,
              ),
            const SizedBox(height: 16),
            _buildLguPhotoSection('Upload Before Photo', true),
            const SizedBox(height: 16),
            if (_report?.afterPhotoUrl != null)
              _buildPhotoWithRemove(
                'LGU After Photo',
                _report!.afterPhotoUrl!,
                false,
              ),
            const SizedBox(height: 16),
            _buildLguPhotoSection('Upload After Photo', false),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid(List<String> photoUrls) {
    return GridView.builder(
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
    );
  }

  Widget _buildPhotoWithRemove(String label, String photoUrl, bool isBefore) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                photoUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    height: 200,
                    width: double.infinity,
                    child: const Center(child: Icon(Icons.broken_image)),
                  );
                },
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: _isDeleting
                    ? null
                    : () => _deleteReportPhoto(isBefore),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLguPhotoSection(String label, bool isBefore) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isUploading ? null : () => _uploadPhoto(isBefore),
        icon: const Icon(Icons.upload, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 40),
        ),
      ),
    );
  }

  Widget _buildLguNotesSection() {
    final manualNotes =
        _report?.responseLogs
            ?.where((log) => log.actionType == 'manual_note')
            .toList() ??
        [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LGU Notes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (manualNotes.isNotEmpty)
              ...manualNotes.map((note) => _buildNoteItem(note)),
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

  Widget _buildNoteItem(ResponseLog note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(note.actionDetails ?? '', style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            '${note.userName ?? 'Unknown'} • ${_formatDateTime(note.createdAt)}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_report?.responseLogs != null &&
                _report!.responseLogs!.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _report!.responseLogs!.length,
                itemBuilder: (context, index) {
                  final log = _report!.responseLogs![index];
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

  Widget _buildActivityLogItem(ResponseLog log) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                log.actionType?.toUpperCase() ?? 'UNKNOWN',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              if (log.createdAt != null)
                Text(
                  _formatDateTime(log.createdAt!),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 4),
          if (log.actionDetails != null && log.actionDetails!.isNotEmpty)
            Text(log.actionDetails!, style: const TextStyle(fontSize: 14)),
          if (log.userName != null) ...[
            const SizedBox(height: 4),
            Text(
              'By: ${log.userName}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
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

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
