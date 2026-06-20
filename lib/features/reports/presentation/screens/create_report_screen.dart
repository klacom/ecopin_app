import 'dart:io';
import 'dart:async';
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

import 'package:image_picker/image_picker.dart';

class CreateReportScreen extends ConsumerStatefulWidget {
  final LatLng? initialLocation;
  const CreateReportScreen({super.key, this.initialLocation});

  @override
  ConsumerState<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends ConsumerState<CreateReportScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  String? _selectedIssueType;
  final MapController _mapController = MapController();
  late LatLng _selectedLocation = widget.initialLocation ?? pasigInitialCenter;
  bool _isLoading = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final CameraService _cameraService = CameraService();
  List<File> _capturedImages = [];
  bool _isUploadingImage = false;

  static const List<String> _funFacts = [
    "Did you know? A single tree can absorb up to 48 lbs of CO2 per year!",
    "Fun fact: Recycling one glass bottle saves enough energy to power a 100W bulb for 4 hours!",
    "Every year, over 8 million tons of plastic ends up in our oceans.",
    "A plastic bottle can take up to 450 years to decompose!",
    "Planting native species helps local wildlife thrive!",
    "Turning off tap while brushing teeth saves up to 200 gallons/month!",
  ];

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

  static const int REPORT_MIN_PHOTOS = 1;
  static const int REPORT_MAX_PHOTOS = 5;
  static const int REPORT_TOTAL_PHOTOS_SIZE = 10 * 1024 * 1024; // 10MB

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final List<XFile>? images = await _picker.pickMultiImage();
        if (images != null && images.isNotEmpty) {
          for (final XFile xFile in images) {
            final File file = File(xFile.path);
            if (!_capturedImages.any((img) => img.path == file.path)) {
              // Check if adding this would exceed max photos
              if (_capturedImages.length >= REPORT_MAX_PHOTOS) {
                if (mounted) {
                  _showError('Maximum $REPORT_MAX_PHOTOS photos allowed');
                }
                break;
              }
              // Check total size
              final currentTotalSize = _capturedImages.fold<int>(
                0,
                (sum, img) => sum + img.lengthSync(),
              );
              final newFileSize = await file.length();
              if (currentTotalSize + newFileSize > REPORT_TOTAL_PHOTOS_SIZE) {
                if (mounted) {
                  _showError('Total photo size exceeds 10MB limit');
                }
                break;
              }
              setState(() {
                _capturedImages.add(file);
              });
            }
          }
        }
      } else {
        final XFile? image = await _picker.pickImage(source: source);
        if (image != null) {
          final File file = File(image.path);
          if (!_capturedImages.any((img) => img.path == file.path)) {
            if (_capturedImages.length >= REPORT_MAX_PHOTOS) {
              if (mounted) {
                _showError('Maximum $REPORT_MAX_PHOTOS photos allowed');
              }
              return;
            }
            final currentTotalSize = _capturedImages.fold<int>(
              0,
              (sum, img) => sum + img.lengthSync(),
            );
            final newFileSize = await file.length();
            if (currentTotalSize + newFileSize > REPORT_TOTAL_PHOTOS_SIZE) {
              if (mounted) {
                _showError('Total photo size exceeds 10MB limit');
              }
              return;
            }
            setState(() {
              _selectedImage = file;
              _capturedImages.add(file);
            });
          }
        }
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
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
    if (_capturedImages.length < REPORT_MIN_PHOTOS) {
      _showError('Please provide at least $REPORT_MIN_PHOTOS photo(s)');
      return;
    }
    if (_capturedImages.length > REPORT_MAX_PHOTOS) {
      _showError('Maximum $REPORT_MAX_PHOTOS photos allowed');
      return;
    }
    // Check total size again
    final totalSize = _capturedImages.fold<int>(
      0,
      (sum, img) => sum + img.lengthSync(),
    );
    if (totalSize > REPORT_TOTAL_PHOTOS_SIZE) {
      _showError('Total photo size exceeds 10MB limit');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Submission'),
        content: const Text(
          'Are you sure about your report details? The image will be analyzed by AI for validity.',
        ),
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

    // Remove focus from text fields
    _titleFocusNode.unfocus();
    _descriptionFocusNode.unfocus();

    // Show loading dialog with cycling fun facts
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _LoadingDialog(funFacts: _funFacts),
    );

    try {
      final apiClient = ref.read(apiClientProvider);

      // Use the first image for initial report creation and AI validation
      final mainImage =
          _selectedImage ??
          (_capturedImages.isNotEmpty ? _capturedImages.first : null);

      final response = await apiClient.createReport(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        issueType: _selectedIssueType!,
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
        imagePath: mainImage?.path,
      );

      final reportId = response.data['report']['id'];
      final aiScore = response.data['ai_score'] as num?;
      final status = response.data['report']?['validation_status'];

      // Upload remaining images as evidence if any
      if (_capturedImages.length > 1) {
        final remainingImages = _capturedImages
            .where((img) => img.path != mainImage?.path)
            .toList();
        for (final img in remainingImages) {
          await apiClient.uploadEvidence(
            reportId: reportId,
            imageFile: img,
            latitude: _selectedLocation.latitude,
            longitude: _selectedLocation.longitude,
          );
        }
      }

      if (mounted) {
        // Close loading dialog
        Navigator.pop(context);
        String message = 'Report submitted successfully!';
        if (status == 'automatically_valid') {
          message += ' AI Validated (Score: ${aiScore?.toStringAsFixed(1)}%)';
        } else if (status == 'manual_review') {
          message +=
              ' Pending manual review (Score: ${aiScore?.toStringAsFixed(1)}%)';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: status == 'automatically_valid'
                ? Colors.green
                : Colors.orange,
          ),
        );
        context.pop(); // Go back after success
      }
    } on DioException catch (e) {
      print('caught e: $e');
      if (mounted) Navigator.pop(context); // Close loading dialog
      String message = 'Failed to submit report';
      if (e.response?.data != null && e.response?.data['message'] != null) {
        message = e.response?.data['message'];
        if (e.response?.data['ai_score'] != null) {
          message +=
              ' (AI Score: ${e.response?.data['ai_score']?.toStringAsFixed(1)}%)';
        }
      }
      _showError(message);
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading dialog
      _showError('An unexpected error occurred: $e');
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
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
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
                child: Stack(
                  children: [
                    FlutterMap(
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
                        onPositionChanged:
                            (MapCamera camera, bool hasGesture) {
                              setState(() {
                                _selectedLocation = camera.center;
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
                      ],
                    ),
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 40.0),
                        child: Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
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
                'Drag the map to set the location',
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
              focusNode: _titleFocusNode,
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
              focusNode: _descriptionFocusNode,
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
            if (_capturedImages.isNotEmpty) ...[
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _capturedImages.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return Stack(
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
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                _buildPhotoOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                const SizedBox(width: 16),
                _buildPhotoOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
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
              Icon(
                icon,
                size: 32,
                color: onTap == null
                    ? Colors.grey.shade300
                    : Colors.grey.shade400,
              ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: onTap == null
                    ? Colors.grey.shade300
                    : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingDialog extends StatefulWidget {
  final List<String> funFacts;

  const _LoadingDialog({required this.funFacts});

  @override
  State<_LoadingDialog> createState() => _LoadingDialogState();
}

class _LoadingDialogState extends State<_LoadingDialog> {
  int _currentFactIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _currentFactIndex = (_currentFactIndex + 1) % widget.funFacts.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            const Text(
              "Submitting your report...",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Text(
                widget.funFacts[_currentFactIndex],
                key: ValueKey(_currentFactIndex),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
