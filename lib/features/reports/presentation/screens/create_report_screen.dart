import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'package:ecopin_app/shared/widgets/app_text_field.dart';
import 'package:ecopin_app/core/constants/app_constants.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/core/services/camera_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

class CreateReportScreen extends ConsumerStatefulWidget {
  final LatLng? initialLocation;
  const CreateReportScreen({super.key, this.initialLocation});

  @override
  ConsumerState<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends ConsumerState<CreateReportScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedIssueType;
  final MapController _mapController = MapController();
  late LatLng _selectedLocation = widget.initialLocation ?? pasigInitialCenter;
  bool _isLoading = false;
  final CameraService _cameraService = CameraService();
  List<File> _capturedImages = [];
  bool _isUploadingImage = false;

  final List<String> _issueTypes = [
    'Waste',
    'Flooding',
    'Pollution',
    'Illegal Logging',
    'Others',
  ];

  Future<void> _captureImage() async {
    try {
      setState(() => _isUploadingImage = true);
      
      final imageData = await _cameraService.captureImage();
      if (imageData != null) {
        setState(() {
          _capturedImages.add(imageData['file'] as File);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image captured successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to capture image: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _uploadEvidence(String reportId) async {
    if (_capturedImages.isEmpty) return;

    final apiClient = ref.read(apiClientProvider);
    
    for (final image in _capturedImages) {
      try {
        print('Uploading evidence for report $reportId');
        final response = await apiClient.uploadEvidence(
          reportId: reportId,
          imageFile: image,
          latitude: _selectedLocation.latitude,
          longitude: _selectedLocation.longitude,
        );
        print('Evidence upload response: ${response.data}');
      } catch (e) {
        print('Failed to upload evidence: $e');
      }
    }
  }

  Future<void> _submitReport() async {
    if (_titleController.text.isEmpty) {
      _showError('Please enter a title');
      return;
    }
    if (_selectedIssueType == null) {
      _showError('Please select an issue type');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Submission'),
        content: const Text('Are you sure about your report details?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.createReport(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        issueType: _selectedIssueType!,
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
      );

      final reportId = response.data['report']['id'];

      // Upload evidence if any images were captured
      if (_capturedImages.isNotEmpty) {
        await _uploadEvidence(reportId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted successfully!')),
        );
        context.pop(); // Go back after success
      }
    } on DioException catch (e) {
      String message = 'Failed to submit report';
      if (e.response?.data != null && e.response?.data['message'] != null) {
        message = e.response?.data['message'];
      }
      _showError(message);
    } catch (e) {
      _showError('An unexpected error occurred: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Report')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pin Location',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLocation,
                    initialZoom: 15.0,
                    minZoom: 12,
                    maxZoom: 18,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                    cameraConstraint: CameraConstraint.contain(
                      bounds: pasigBounds,
                    ),
                    onTap: (tapPosition, point) {
                      setState(() {
                        _selectedLocation = point;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.ecopinas.ecopin_app',
                      tileBounds: pasigBounds,
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLocation,
                          width: 80,
                          height: 80,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.my_location, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Coordinates: ${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Tap the map to fine-tune the location',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _titleController,
              labelText: 'Title',
              hintText: 'Brief summary of the issue',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedIssueType,
              decoration: const InputDecoration(
                labelText: 'Issue Type',
                border: OutlineInputBorder(),
              ),
              items: _issueTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedIssueType = value;
                });
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _descriptionController,
              labelText: 'Description',
              hintText: 'Provide more details about the issue...',
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            const Text(
              'Photos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildPhotoOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: _isUploadingImage ? null : _captureImage,
                  isLoading: _isUploadingImage,
                ),
              ],
            ),
            if (_capturedImages.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _capturedImages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _capturedImages[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _capturedImages.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 40),
            AppButton(
              text: 'Submit Report',
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _submitReport,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoOption({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: onTap == null ? Colors.grey.shade200 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(icon, size: 32, color: onTap == null ? Colors.grey.shade300 : Colors.grey.shade400),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: onTap == null ? Colors.grey.shade300 : Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}
