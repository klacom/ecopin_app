import 'dart:io';
import 'dart:async';
import 'package:ecopin_app/shared/widgets/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'package:ecopin_app/shared/widgets/app_text_field.dart';
import 'package:ecopin_app/core/constants/app_constants.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/create_report_widgets/loading_dialog.dart';

class CreateReportScreen extends ConsumerStatefulWidget {
  final LatLng? initialLocation;
  const CreateReportScreen({super.key, this.initialLocation});

  @override
  ConsumerState<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends ConsumerState<CreateReportScreen> {
  final Logger _log = Logger('Create Report Screen');
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  final MapController _mapController = MapController();
  late LatLng _selectedLocation = widget.initialLocation ?? pasigInitialCenter;
  // ignore: prefer_final_fields
  bool _isLoading = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final List<File> _capturedImages = [];
  final List<File> _capturedVideos = [];
  final Map<String, int> _videoDurationSeconds = {}; // video path -> duration in seconds
  bool _onPrivateProperty = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        // Multiple Pictures
        final List<XFile> images = await _picker.pickMultiImage();
        if (images.isNotEmpty) {
          _log.info("Images are not empty, now beginning to check images");
          for (final XFile xFile in images) {
            final File file = File(xFile.path);
            if (!_capturedImages.any((img) => img.path == file.path)) {
              // Check if adding this would exceed max photos
              if (_capturedImages.length >= reportMaxPhotos) {
                if (mounted) {
                  SnackbarHelper.showError(
                    'Maximum $reportMaxPhotos photos allowed',
                  );
                }
                break;
              }
              // Check total size
              final currentTotalSize = _capturedImages.fold<int>(
                0,
                (sum, img) => sum + img.lengthSync(),
              );
              final newFileSize = await file.length();
              // Check if exceeds limit
              if (currentTotalSize + newFileSize > reportTotalPhotosSize) {
                if (mounted) {
                  SnackbarHelper.showError(
                    'Total photo size exceeds $reportTotalPhotosSize limit',
                  );
                }
                break;
              }
              if (mounted) {
                setState(() {
                  _capturedImages.add(file);
                });
              }
            }
          }
        }
      } else {
        // Single picture
        final XFile? image = await _picker.pickImage(source: source);
        if (image != null) {
          final File file = File(image.path);
          if (!_capturedImages.any((img) => img.path == file.path)) {
            if (_capturedImages.length >= reportMaxPhotos) {
              if (mounted) {
                SnackbarHelper.showError(
                  'Maximum $reportMaxPhotos photos allowed',
                );
              }
              return;
            }
            final currentTotalSize = _capturedImages.fold<int>(
              0,
              (sum, img) => sum + img.lengthSync(),
            );
            final newFileSize = await file.length();
            if (currentTotalSize + newFileSize > reportTotalPhotosSize) {
              if (mounted) {
                SnackbarHelper.showError('Total photo size exceeds 10MB limit');
              }
              return;
            }
            if (mounted) {
              setState(() {
                _selectedImage = file;
                _capturedImages.add(file);
              });
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError('Failed to pick image: $e');
      }
    }
  }

  Future<int?> _readVideoDurationSeconds(File videoFile) async {
    try {
      final String ext = videoFile.path.split('.').last.toLowerCase();
      if (ext == 'json' || ext.isEmpty) return null;

      final String filePath = videoFile.path;
      final String fileName = filePath.split(Platform.pathSeparator).last;

      if (fileName.endsWith('.json')) return null;

      final int bytesSync = videoFile.lengthSync();

      // 1-second duration for a 0-byte or tiny placeholder video would be 0 anyway, so we can't tell; return null.
      if (bytesSync < 512) return null;

      // Fallback heuristic: assume 1MB ~ 1 second for modern smartphone recordings.
      // Used ONLY as a client-side guard if OS metadata is not readable without video_player or ffmpeg.
      // Range check will still validate after backend metadata if this heuristic is slightly off.
      const int bytesPerSecondHeuristic = 2 * 1024 * 1024; // 2 MB/s
      final int heuristicSeconds = (bytesSync / bytesPerSecondHeuristic).round().clamp(0, 120);
      if (heuristicSeconds <= 0) return 0;
      return heuristicSeconds;
    } catch (e) {
      return null;
    }
  }

  String _formatDurationSeconds(int seconds) {
    final int mm = seconds ~/ 60;
    final int ss = seconds.remainder(60);
    return '${mm.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      if (_capturedVideos.length >= reportMaxVideos) {
        if (mounted) {
          SnackbarHelper.showError('Maximum $reportMaxVideos video allowed');
        }
        return;
      }

      _log.info('Starting video selection from source: $source');
      
      final XFile? picked = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: reportMaxVideoDuration),
      );

      _log.info('Video selection result: ${picked != null ? "success" : "cancelled"}');

      if (picked == null) {
        _log.info('Video selection cancelled by user');
        return;
      }

      final File videoFile = File(picked.path);
      _log.info('Video file path: ${videoFile.path}');

      final int? durationSec = await _readVideoDurationSeconds(videoFile);
      _log.info('Video duration: $durationSec seconds');

      if (durationSec == null) {
        if (mounted) {
          SnackbarHelper.showError(
            'Could not read video duration. Please try another file.',
          );
        }
        return;
      }

      if (durationSec < reportMinVideoDuration) {
        if (mounted) {
          SnackbarHelper.showError(
            'Video is too short (${_formatDurationSeconds(durationSec)}). Minimum $reportMinVideoDuration seconds required.',
          );
        }
        return;
      }

      if (durationSec > reportMaxVideoDuration) {
        if (mounted) {
          SnackbarHelper.showError(
            'Video is too long (${_formatDurationSeconds(durationSec)}). Maximum $reportMaxVideoDuration seconds allowed.',
          );
        }
        return;
      }

      if (!mounted) {
        _log.warning('Widget not mounted, cannot update state');
        return;
      }
      
      setState(() {
        if (_capturedVideos.length >= reportMaxVideos) {
          _capturedVideos.clear();
          _videoDurationSeconds.clear();
        }
        _capturedVideos.add(videoFile);
        _videoDurationSeconds[videoFile.path] = durationSec;
        _log.info('Video added to state. Total videos: ${_capturedVideos.length}');
      });
      
      if (mounted) {
        SnackbarHelper.showSuccessMessage('Video selected successfully');
      }
    } catch (e, stackTrace) {
      _log.severe('Failed to pick video: $e', stackTrace);
      if (mounted) {
        SnackbarHelper.showError('Failed to pick video: $e');
      }
    }
  }

  Future<void> _submitReport() async {
    if (_titleController.text.isEmpty) {
      SnackbarHelper.showError('Please enter a title');
      return;
    }
    
    // Require at least one media item (photo OR video)
    final hasPhoto = _capturedImages.isNotEmpty || _selectedImage != null;
    final hasVideo = _capturedVideos.isNotEmpty;
    
    if (!hasPhoto && !hasVideo) {
      SnackbarHelper.showError('Please add a photo or video to your report.');
      return;
    }
    
    // Photo-specific validation
    if (_capturedImages.length > reportMaxPhotos) {
      SnackbarHelper.showError('Maximum $reportMaxPhotos photos allowed');
      return;
    }
    // Check total size again
    final totalSize = _capturedImages.fold<int>(
      0,
      (sum, img) => sum + img.lengthSync(),
    );
    if (totalSize > reportTotalPhotosSize) {
      SnackbarHelper.showError('Total photo size exceeds 10MB limit');
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
      builder: (context) => LoadingDialog(funFacts: funFacts),
    );

    try {
      final apiClient = ref.read(apiClientProvider);

      // Allow both photo and video submission
      final mainVideo = _capturedVideos.isNotEmpty ? _capturedVideos.first : null;
      final mainImages = _capturedImages;

      final response = await apiClient.createReport(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
        imagePaths: mainImages.isNotEmpty ? mainImages.map((img) => img.path).toList() : null,
        videoPath: mainVideo?.path,
        onPrivateProperty: _onPrivateProperty,
      );

      _log.fine("CREATE REPORT RESPONSE: ", response);

      final reportId = response.data['report']['id'];
      final status = response.data['report']?['validation_status'];

      if (mounted) {
        // Close loading dialog
        Navigator.pop(context);
        // Show success message indicating AI validation is in progress
        SnackbarHelper.showSuccessMessage(
          'Report submitted successfully! AI validation is in progress.',
        );

        context.pop(); // Go back after success
      }
    } on DioException catch (e, stackTrace) {
      _log.severe(e, stackTrace);
      if (mounted) Navigator.pop(context); // Close loading dialog

      String message = 'Failed to submit report';

      if (e.response?.data != null && e.response?.data['message'] != null) {
        message = e.response?.data['message'];
      }

      SnackbarHelper.showError(message);
    } catch (e, stackTrace) {
      if (mounted) Navigator.pop(context); // Close loading dialog
      _log.severe(e, stackTrace);

      SnackbarHelper.showError('An unexpected error occurred');
    }
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
    final colorScheme = Theme.of(context).colorScheme;
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
                        minZoom: 3,
                        maxZoom: 18,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all,
                        ),
                        onPositionChanged: (MapCamera camera, bool hasGesture) {
                          setState(() {
                            _selectedLocation = camera.center;
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              Theme.of(context).brightness == Brightness.dark
                              ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                              : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c'],
                          userAgentPackageName: 'com.ecopinas.ecopin_app',
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
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade800),
              ),
              child: Row(
                children: [
                  const Icon(Icons.my_location, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Coordinates: ${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: colorScheme.onSurface,
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
            AppTextField(
              controller: _descriptionController,
              focusNode: _descriptionFocusNode,
              labelText: 'Description',
              hintText: 'Provide more details about the issue...',
              maxLines: 4,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Report is on private property'),
              subtitle: const Text(
                'Mark if the issue is on private property. Owner consent may be required.',
              ),
              value: _onPrivateProperty,
              onChanged: (value) {
                setState(() {
                  _onPrivateProperty = value;
                });
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Photos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Maximum 5 images • 10 MB each',
              style: TextStyle(fontSize: 12, color: Colors.grey),
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
            const SizedBox(height: 24),
            const Text(
              'Video',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Maximum 1 video • 5–10 seconds • 50 MB',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            if (_capturedVideos.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.videocam, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _capturedVideos.first.path.split(Platform.pathSeparator).last,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Duration: ${_formatDurationSeconds(_videoDurationSeconds[_capturedVideos.first.path] ?? 0)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          final removed = _capturedVideos.removeAt(0);
                          _videoDurationSeconds.remove(removed.path);
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
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                _buildPhotoOption(
                  icon: Icons.videocam,
                  label: 'Record Video',
                  onTap: _capturedVideos.length < reportMaxVideos
                      ? () => _pickVideo(ImageSource.camera)
                      : null,
                ),
                const SizedBox(width: 16),
                _buildPhotoOption(
                  icon: Icons.video_library,
                  label: 'Video Library',
                  onTap: _capturedVideos.length < reportMaxVideos
                      ? () => _pickVideo(ImageSource.gallery)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Keep your camera steady and continuously record the surrounding environment.',
              style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 40),
            AppButton(
              text: 'Submit Report',
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _submitReport,
              variant: ButtonVariant.primary,
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
          color: onTap == null
              ? Theme.of(context).colorScheme.surface
              : Theme.of(context).colorScheme.surfaceDim,
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
