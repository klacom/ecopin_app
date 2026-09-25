import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:ecopin_app/shared/reports/data/models/report_prefill_data.dart';
import 'package:ecopin_app/shared/reports/providers/report_provider.dart';
import 'package:ecopin_app/shared/widgets/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
// Note: LoadingDialog import removed since we're using an inline overlay

class CreateReportScreen extends ConsumerStatefulWidget {
  final ReportPrefillData? prefillData;
  const CreateReportScreen({super.key, this.prefillData});

  @override
  ConsumerState<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends ConsumerState<CreateReportScreen> {
  final Logger _log = Logger('Create Report Screen');
  final PageController _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 4;
  bool _isSubmitting = false;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();

  late LatLng _reportLocation;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final List<File> _capturedImages = [];
  final List<File> _capturedVideos = [];
  final Map<String, int> _videoDurationSeconds = {};
  bool _onPrivateProperty = false;
  String _selectedScale = 'medium';
  String _selectedObstruction = 'none';

  static const List<String> _validImageExtensions = ['jpeg', 'jpg', 'png', 'webp'];
  static const List<String> _validVideoExtensions = ['mp4', 'mov', 'webm'];

  @override
  void initState() {
    super.initState();
    _reportLocation = widget.prefillData?.location ?? pasigInitialCenter;
    if (widget.prefillData?.title != null) {
      _titleController.text = widget.prefillData!.title!;
    }
    if (widget.prefillData?.description != null) {
      _descriptionController.text = widget.prefillData!.description!;
    }
    
    // Listen to title controller to update step 2 next button state
    _titleController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      // Validation per step
      if (_currentStep == 1 && _titleController.text.trim().isEmpty) return;
      if (_currentStep == 2 && _capturedImages.isEmpty && _selectedImage == null && _capturedVideos.isEmpty) return;
      
      _titleFocusNode.unfocus();
      _descriptionFocusNode.unfocus();
      
      setState(() => _currentStep++);
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _titleFocusNode.unfocus();
      _descriptionFocusNode.unfocus();
      setState(() => _currentStep--);
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  bool _isValidImageExtension(String ext) => _validImageExtensions.contains(ext.toLowerCase());
  bool _isValidVideoExtension(String ext) => _validVideoExtensions.contains(ext.toLowerCase());

  String _formatDurationSeconds(int seconds) {
    final int mm = seconds ~/ 60;
    final int ss = seconds.remainder(60);
    return '${mm.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
  }

  Future<int?> _readVideoDurationSeconds(File videoFile) async {
    try {
      final String ext = videoFile.path.split('.').last.toLowerCase();
      if (ext == 'json' || ext.isEmpty) return null;
      if (videoFile.path.split(Platform.pathSeparator).last.endsWith('.json')) return null;
      final int bytesSync = videoFile.lengthSync();
      if (bytesSync < 512) return null;
      const int bytesPerSecondHeuristic = 2 * 1024 * 1024;
      final int heuristicSeconds = (bytesSync / bytesPerSecondHeuristic).round().clamp(0, 120);
      if (heuristicSeconds <= 0) return 0;
      return heuristicSeconds;
    } catch (e) {
      return null;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final List<XFile> images = await _picker.pickMultiImage();
        if (images.isEmpty) return;
        for (final XFile xFile in images) {
          final ext = xFile.path.split('.').last;
          if (!_isValidImageExtension(ext)) {
            if (mounted) SnackbarHelper.showError('Unsupported file type "${ext.toUpperCase()}".');
            continue;
          }
          final File file = File(xFile.path);
          if (_capturedImages.any((img) => img.path == file.path)) continue;
          if (_capturedImages.length >= reportMaxPhotos) {
            if (mounted) SnackbarHelper.showError('Maximum $reportMaxPhotos photos allowed');
            break;
          }
          final currentTotalSize = _capturedImages.fold<int>(0, (sum, img) => sum + img.lengthSync());
          final newFileSize = await file.length();
          if (currentTotalSize + newFileSize > reportTotalPhotosSize) {
            if (mounted) SnackbarHelper.showError('Total photo size exceeds 10 MB limit');
            break;
          }
          if (mounted) setState(() => _capturedImages.add(file));
        }
      } else {
        final XFile? image = await _picker.pickImage(source: source);
        if (image == null) return;
        final ext = image.path.split('.').last;
        if (!_isValidImageExtension(ext)) {
          if (mounted) SnackbarHelper.showError('Unsupported file type "${ext.toUpperCase()}".');
          return;
        }
        final File file = File(image.path);
        if (_capturedImages.any((img) => img.path == file.path)) return;
        if (_capturedImages.length >= reportMaxPhotos) {
          if (mounted) SnackbarHelper.showError('Maximum $reportMaxPhotos photos allowed');
          return;
        }
        final currentTotalSize = _capturedImages.fold<int>(0, (sum, img) => sum + img.lengthSync());
        final newFileSize = await file.length();
        if (currentTotalSize + newFileSize > reportTotalPhotosSize) {
          if (mounted) SnackbarHelper.showError('Total photo size exceeds limit');
          return;
        }
        if (mounted) {
          setState(() {
            _selectedImage = file;
            _capturedImages.add(file);
          });
        }
      }
    } on Exception catch (e) {
      _log.warning('Image pick failed: $e');
      if (mounted) SnackbarHelper.showError('Failed to select image.');
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      if (_capturedVideos.length >= reportMaxVideos) {
        if (mounted) SnackbarHelper.showError('Maximum $reportMaxVideos video allowed');
        return;
      }
      final XFile? picked = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: reportMaxVideoDuration),
      );
      if (picked == null) return;
      final ext = picked.path.split('.').last;
      if (!_isValidVideoExtension(ext)) {
        if (mounted) SnackbarHelper.showError('Unsupported file type "${ext.toUpperCase()}".');
        return;
      }
      final File videoFile = File(picked.path);
      final int? durationSec = await _readVideoDurationSeconds(videoFile);
      if (durationSec == null) {
        if (mounted) SnackbarHelper.showError('Could not read video duration.');
        return;
      }
      if (durationSec < reportMinVideoDuration) {
        if (mounted) SnackbarHelper.showError('Video is too short (${_formatDurationSeconds(durationSec)}).');
        return;
      }
      if (durationSec > reportMaxVideoDuration) {
        if (mounted) SnackbarHelper.showError('Video is too long (${_formatDurationSeconds(durationSec)}).');
        return;
      }
      if (mounted) {
        setState(() {
          if (_capturedVideos.length >= reportMaxVideos) {
            _capturedVideos.clear();
            _videoDurationSeconds.clear();
          }
          _capturedVideos.add(videoFile);
          _videoDurationSeconds[videoFile.path] = durationSec;
        });
      }
    } on Exception catch (e) {
      _log.severe('Failed to pick video: $e');
      if (mounted) SnackbarHelper.showError('Failed to select video.');
    }
  }

  Future<void> _submitReport() async {
    setState(() => _isSubmitting = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final mainVideo = _capturedVideos.isNotEmpty ? _capturedVideos.first : null;
      await apiClient.createReport(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        latitude: _reportLocation.latitude,
        longitude: _reportLocation.longitude,
        imagePaths: _capturedImages.isNotEmpty ? _capturedImages.map((img) => img.path).toList() : null,
        videoPath: mainVideo?.path,
        onPrivateProperty: _onPrivateProperty,
        scaleLevel: _selectedScale,
        obstructionLevel: _selectedObstruction,
      );
      if (mounted) {
        ref.invalidate(myReportsProvider);
        SnackbarHelper.showMessage('Report submitted! AI validation is in progress.');
        context.pop(); // Pop back to dashboard
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        String message = e.response?.data?['message'] ?? 'Failed to submit report.';
        if (e.response?.statusCode == 413) message = 'File is too large.';
        SnackbarHelper.showError(message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        SnackbarHelper.showError('An unexpected error occurred.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isPrefilled = widget.prefillData?.title != null;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(isPrefilled ? 'Resubmit Report' : 'Create Report'),
            leading: _currentStep > 0
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _prevStep,
                  )
                : const BackButton(),
          ),
          body: Column(
            children: [
              LinearProgressIndicator(
                value: (_currentStep + 1) / _totalSteps,
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: const Color(0xFFCCFF00), // Neon Lime
                minHeight: 4,
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1Location(colorScheme),
                    _buildStep2Details(),
                    _buildStep3Media(colorScheme),
                    _buildStep4Review(colorScheme),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        if (_isSubmitting)
          Positioned.fill(
            child: Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFFCCFF00)),
                      const SizedBox(height: 32),
                      Text(
                        'Analyzing & Submitting...',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lightbulb_outline, color: Theme.of(context).brightness == Brightness.light ? Colors.black : Theme.of(context).colorScheme.primary, size: 18),
                          const SizedBox(width: 8),
                          const Text('Fun Fact:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        funFacts[Random().nextInt(funFacts.length)],
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ).padding(const EdgeInsets.symmetric(horizontal: 40)),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStep1Location(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Step 1: Location',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Verify the GPS coordinates of the issue.',
            style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 24),
          
          // Map FIRST
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 250,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _reportLocation,
                  initialZoom: 15.0,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://api.maptiler.com/maps/streets-v2-dark/{z}/{x}/{y}.png?key=${dotenv.env['MAPTILER_API_KEY'] ?? ''}',
                    userAgentPackageName: 'dev.ecopinas.ecopin_app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _reportLocation,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_pin, color: Color(0xFFCCFF00), size: 40),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Location text BELOW map
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.gps_fixed, color: colorScheme.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${_reportLocation.latitude.toStringAsFixed(6)}, ${_reportLocation.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 16, fontFamily: 'Outfit', fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          AppButton(text: 'Next: Details', onPressed: _nextStep),
        ],
      ),
    );
  }

  Widget _buildStep2Details() {
    final bool canProceed = _titleController.text.trim().isNotEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Step 2: Details',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          AppTextField(
            controller: _titleController,
            focusNode: _titleFocusNode,
            labelText: 'Report Title *',
            hintText: 'Brief summary of the issue',
          ),
          const SizedBox(height: 24),
          AppTextField(
            controller: _descriptionController,
            focusNode: _descriptionFocusNode,
            labelText: 'Description',
            hintText: 'Provide more details...',
            maxLines: 5,
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('On Private Property', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Check this if the issue is located on private property.'),
            value: _onPrivateProperty,
            contentPadding: EdgeInsets.zero,
            onChanged: (value) => setState(() => _onPrivateProperty = value),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            initialValue: _selectedScale,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Estimated Scale',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'small', child: Text('Small (e.g., localized litter, minor puddle)')),
              DropdownMenuItem(value: 'medium', child: Text('Medium (e.g., standard pile of waste)')),
              DropdownMenuItem(value: 'large', child: Text('Large (e.g., illegal dumpsite, extensive)')),
            ],
            onChanged: (val) => setState(() => _selectedScale = val ?? 'medium'),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            initialValue: _selectedObstruction,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Obstruction Level',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'none', child: Text('None (No interference with public ways)')),
              DropdownMenuItem(value: 'partial', child: Text('Partial (Partially blocking sidewalk/road)')),
              DropdownMenuItem(value: 'complete', child: Text('Complete (Fully blocking access)')),
            ],
            onChanged: (val) => setState(() => _selectedObstruction = val ?? 'none'),
          ),
          const SizedBox(height: 48),
          AppButton(
            text: 'Next: Attach Media',
            onPressed: canProceed ? _nextStep : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Media(ColorScheme colorScheme) {
    final hasMedia = _capturedImages.isNotEmpty || _capturedVideos.isNotEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Step 3: Media',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Add photos or a video. At least one is required.',
            style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 24),
          
          const Text('Photos (Max 5)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_capturedImages.isNotEmpty) ...[
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _capturedImages.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_capturedImages[index], width: 120, height: 120, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => setState(() => _capturedImages.removeAt(index)),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 16, color: Colors.white),
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
              Expanded(
                child: _buildMediaOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMediaOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          const Text('Video (Max 1)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_capturedVideos.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: colorScheme.surface,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.videocam, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Selected Video', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Duration: ${_formatDurationSeconds(_videoDurationSeconds[_capturedVideos.first.path] ?? 0)}', style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6))),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => setState(() {
                      final removed = _capturedVideos.removeAt(0);
                      _videoDurationSeconds.remove(removed.path);
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: _buildMediaOption(
                  icon: Icons.videocam,
                  label: 'Record Video',
                  onTap: _capturedVideos.isEmpty ? () => _pickVideo(ImageSource.camera) : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMediaOption(
                  icon: Icons.video_library,
                  label: 'Select Video',
                  onTap: _capturedVideos.isEmpty ? () => _pickVideo(ImageSource.gallery) : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          AppButton(
            text: 'Next: Review',
            onPressed: hasMedia ? _nextStep : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStep4Review(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Step 4: Review',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Almost done. Review your report before AI submission.',
            style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Title', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
                const SizedBox(height: 4),
                Text(_titleController.text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                Text('Location', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
                const SizedBox(height: 4),
                Text('${_reportLocation.latitude.toStringAsFixed(4)}, ${_reportLocation.longitude.toStringAsFixed(4)}', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                
                Text('Media', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
                const SizedBox(height: 4),
                Text('${_capturedImages.length} Photo(s), ${_capturedVideos.length} Video(s)', style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 48),
          AppButton(
            text: 'Submit Report',
            onPressed: _submitReport,
          ),
        ],
      ),
    );
  }

  Widget _buildMediaOption({required IconData icon, required String label, required VoidCallback? onTap}) {
    final isDisabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: isDisabled ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: isDisabled ? Colors.grey.shade600 : Theme.of(context).colorScheme.onSurface),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDisabled ? Colors.grey.shade600 : Theme.of(context).colorScheme.onSurface)),
          ],
        ),
      ),
    );
  }
}

extension PaddingExtension on Widget {
  Widget padding(EdgeInsetsGeometry padding) {
    return Padding(padding: padding, child: this);
  }
}
