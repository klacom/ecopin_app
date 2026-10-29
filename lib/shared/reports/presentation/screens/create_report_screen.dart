import 'package:ecopin_app/shared/maps/presentation/widgets/report_marker.dart';
import 'package:ecopin_app/shared/reports/data/models/video_submission_policy.dart';
import 'dart:io';
import 'dart:async';
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
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/services/location_search_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/local_media_preview.dart';
import 'package:ecopin_app/core/services/photo_verification_service.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/photo_review_dialog.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/report_priority_picker.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/citizen_trust_status.dart';
import 'package:ecopin_app/shared/reports/providers/citizen_trust_provider.dart';
// Note: LoadingDialog import removed since we're using an inline overlay

class CreateReportScreen extends ConsumerStatefulWidget {
  final ReportPrefillData? prefillData;
  final TileProvider? tileProvider;
  final LocationSearchService? locationSearchService;
  final ImagePicker? imagePicker;
  final LocalVideoControllerFactory? videoControllerFactory;
  const CreateReportScreen({
    super.key,
    this.prefillData,
    this.tileProvider,
    this.locationSearchService,
    this.imagePicker,
    this.videoControllerFactory,
  });

  @override
  ConsumerState<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends ConsumerState<CreateReportScreen> {
  final Logger _log = Logger('Create Report Screen');
  final PageController _pageController = PageController();
  final MapController _locationMap = MapController();
  final ScrollController _mediaScroll = ScrollController();
  int _currentStep = 0;
  static const int _totalSteps = 4;
  bool _isSubmitting = false;
  String? _submissionError;
  String? _mediaError;
  bool _mediaPermissionDenied = false;
  bool _isSelectingMedia = false;
  VideoSubmissionPolicy? _videoPolicy;
  bool _loadingVideoPolicy = false;
  String? _videoPolicyError;
  late Future<String?> _addressFuture;
  bool _locationConfirmed = false;
  bool _addressRequested = false;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priorityExplanationController = TextEditingController();
  bool _urgent = false;
  String? _priorityReason;
  bool get _priorityComplete =>
      !_urgent ||
      (_priorityReason != null &&
          ref.read(citizenTrustProvider).asData?.value.urgentAllowed == true &&
          !ref.read(citizenTrustProvider).isLoading);
  final _titleFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();

  late LatLng _reportLocation;
  File? _selectedImage;
  late final ImagePicker _picker;
  final List<File> _capturedImages = [];
  final List<File> _cleanImages = [];
  final Map<String, String> _photosForReview = {};
  String? get _manualReviewReason => _photosForReview.isEmpty
      ? null
      : _cleanImages
            .asMap()
            .entries
            .where((entry) => _photosForReview.containsKey(entry.value.path))
            .map(
              (entry) =>
                  'Photo ${entry.key + 1}: ${_photosForReview[entry.value.path]}',
            )
            .join('\n');
  final List<File> _capturedVideos = [];
  final Map<String, Duration> _videoDurations = {};
  bool _onPrivateProperty = false;
  bool _consentGiven = false;
  static const String _defaultScale = 'medium';
  static const String _defaultObstruction = 'none';
  PhotoVerificationResult? _photoVerificationResult;

  static const List<String> _validImageExtensions = [
    'jpeg',
    'jpg',
    'png',
    'webp',
  ];
  static const List<String> _validVideoExtensions = ['mp4', 'mov', 'webm'];

  @override
  void initState() {
    super.initState();
    _picker = widget.imagePicker ?? ImagePicker();
    _reportLocation = widget.prefillData?.location ?? pasigInitialCenter;
    _locationConfirmed = widget.prefillData?.location != null;
    _addressRequested = _locationConfirmed;
    _addressFuture = _locationConfirmed ? _findAddress() : Future.value(null);
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
    _locationMap.dispose();
    _mediaScroll.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _priorityExplanationController.dispose();
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  bool _canNavigateToStep(int targetStep) {
    if (_isSubmitting) return false;
    if (targetStep < 0 || targetStep >= _totalSteps) return false;
    if (targetStep <= _currentStep) return true;

    // Advancing forward requires earlier steps to meet validation
    if (targetStep >= 1 && !_locationConfirmed) return false;
    if (targetStep >= 2 && _titleController.text.trim().isEmpty) return false;
    if (targetStep >= 2 && !_priorityComplete) return false;
    if (targetStep >= 3 &&
        _capturedImages.isEmpty &&
        _selectedImage == null &&
        _capturedVideos.isEmpty) {
      return false;
    }
    return true;
  }

  void _jumpToStep(int targetStep) {
    if (!_canNavigateToStep(targetStep) || targetStep == _currentStep) return;
    _titleFocusNode.unfocus();
    _descriptionFocusNode.unfocus();
    setState(() => _currentStep = targetStep);
    if (targetStep == 2 && _videoPolicy == null && !_loadingVideoPolicy) {
      _loadVideoPolicy();
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _pageController.jumpToPage(targetStep);
    } else {
      _pageController.animateToPage(
        targetStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _jumpToStep(_currentStep + 1);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _jumpToStep(_currentStep - 1);
    }
  }

  bool _isValidImageExtension(String ext) =>
      _validImageExtensions.contains(ext.toLowerCase());
  bool _isValidVideoExtension(String ext) =>
      _validVideoExtensions.contains(ext.toLowerCase());

  String _formatDurationSeconds(int seconds) {
    final int mm = seconds ~/ 60;
    final int ss = seconds.remainder(60);
    return '${mm.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
  }

  void _showMediaError(String message, {bool permissionDenied = false}) {
    if (mounted) {
      setState(() {
        _mediaError = message;
        _mediaPermissionDenied = permissionDenied;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _currentStep == 2 && _mediaScroll.hasClients) {
          _mediaScroll.animateTo(
            0,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _handlePickerFailure(Object error) {
    final code = error is PlatformException ? error.code.toLowerCase() : '';
    final denied =
        code.contains('access_denied') ||
        code.contains('permission_denied') ||
        code.contains('restricted');
    _showMediaError(
      denied
          ? 'Media access is unavailable. Allow camera, microphone, or photo access in your device’s app settings, then try again. You can also choose a different media source.'
          : 'The media could not be selected. Try again or choose another file. Your report details and selected media are still here.',
      permissionDenied: denied,
    );
  }

  Future<void> _openMediaSettings() async {
    try {
      if (!await openAppSettings()) {
        _showMediaError(
          'Device settings could not be opened. Open EcoPin’s permissions from your device settings, then return to your report.',
          permissionDenied: true,
        );
      }
    } catch (_) {
      _showMediaError(
        'Device settings could not be opened. Open EcoPin’s permissions from your device settings, then return to your report.',
        permissionDenied: true,
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isSelectingMedia) return;
    ImageSource? retrySource;
    setState(() {
      _isSelectingMedia = true;
      _mediaError = null;
      _mediaPermissionDenied = false;
    });
    try {
      final List<XFile> images;
      if (source == ImageSource.gallery) {
        images = await _picker.pickMultiImage();
      } else {
        final image = await _picker.pickImage(source: source);
        images = image == null ? [] : [image];
      }
      if (!mounted) return;
      for (final xFile in images) {
        final ext = xFile.path.split('.').last;
        if (!_isValidImageExtension(ext)) {
          _showMediaError('Unsupported photo type. Use JPG, PNG, or WEBP.');
          continue;
        }
        final rawFile = File(xFile.path);
        if (_cleanImages.any((image) => image.path == rawFile.path)) {
          continue;
        }
        if (_capturedImages.length >= reportMaxPhotos) {
          _showMediaError(
            'You can attach up to $reportMaxPhotos photos. Remove one before adding another.',
          );
          break;
        }

        String? reviewReason;
        bool attachPhoto = false;
        while (true) {
          Map? validation;
          try {
            final response = await ref
                .read(apiClientProvider)
                .validateImage(rawFile.path);
            if (response.data is Map) validation = response.data as Map;
          } catch (error) {
            _log.warning('Photo check unavailable: $error');
          }
          if (!mounted) return;
          final status = validation?['validation_status'];
          final decision = validation?['decision'];
          final unavailable =
              validation == null ||
              validation['check_available'] == false ||
              (status == null &&
                  decision == null &&
                  validation['is_valid'] != true);
          final approved =
              !unavailable &&
              status != 'manual_review' &&
              status != 'rejected' &&
              decision != 'MANUAL_REVIEW' &&
              decision != 'REJECTED' &&
              (status == 'approved' ||
                  decision == 'APPROVED' ||
                  validation['is_valid'] == true);
          if (approved) {
            attachPhoto = true;
            break;
          }
          _showMediaError(
            unavailable
                ? 'Photo check unavailable. The check could not be completed; this is not a rejection. The photo is not attached.'
                : 'Unable to verify this photo. It is not attached. Take another photo or request manual review with an explanation.',
          );
          final choice = await showDialog<PhotoReviewChoice>(
            context: context,
            builder: (_) =>
                PhotoReviewDialog(photo: rawFile, unavailable: unavailable),
          );
          if (!mounted) return;
          if (choice?.action == 'retry') continue;
          if (choice?.action == 'camera' || choice?.action == 'gallery') {
            retrySource = choice!.action == 'camera'
                ? ImageSource.camera
                : ImageSource.gallery;
          } else if (choice?.action == 'review') {
            reviewReason = choice!.reason;
            attachPhoto = reviewReason != null && reviewReason.isNotEmpty;
          }
          break;
        }
        if (retrySource != null) break;
        if (!attachPhoto) continue;

        // Add location telemetry and the watermark only after attachment is confirmed.
        String? currentAddress;
        if (_locationConfirmed) {
          try {
            currentAddress = await _addressFuture;
          } catch (_) {}
        }
        final processed = await PhotoVerificationService.processPhoto(
          originalFile: rawFile,
          source: source == ImageSource.camera ? 'camera' : 'gallery',
          knownAddress: currentAddress,
          fallbackLat: _locationConfirmed ? _reportLocation.latitude : null,
          fallbackLng: _locationConfirmed ? _reportLocation.longitude : null,
          qrPayload:
              dotenv.env['WEB_BASE_URL'] ?? 'https://ecopin-web.vercel.app',
        );
        _photoVerificationResult = processed;
        final file = processed.file;
        final currentSize = _capturedImages.fold<int>(
          0,
          (total, image) => total + image.lengthSync(),
        );
        final newSize = await file.length();
        if (!mounted) return;
        if (currentSize + newSize > reportTotalPhotosSize) {
          _showMediaError(
            'Your photos exceed the ${reportTotalPhotosSize ~/ (1024 * 1024)} MB combined limit. Remove a photo or choose a smaller file.',
          );
          continue;
        }
        setState(() {
          _capturedImages.add(file);
          _cleanImages.add(rawFile);
          if (reviewReason != null) {
            _photosForReview[rawFile.path] = reviewReason;
          }
          _mediaError = null;
          if (source == ImageSource.camera) _selectedImage = file;
        });
      }
    } catch (error) {
      _log.warning('Image selection failed', error);
      _handlePickerFailure(error);
    } finally {
      if (mounted) setState(() => _isSelectingMedia = false);
    }
    if (mounted && retrySource != null) await _pickImage(retrySource);
  }

  Future<VideoSubmissionPolicy?> _loadVideoPolicy() async {
    if (!mounted || _loadingVideoPolicy) return null;
    setState(() {
      _loadingVideoPolicy = true;
      _videoPolicyError = null;
    });
    try {
      final response = await ref.read(apiClientProvider).getReportVideoPolicy();
      final policy = VideoSubmissionPolicy.fromJson(response.data);
      if (mounted) setState(() => _videoPolicy = policy);
      return policy;
    } catch (_) {
      if (mounted) {
        setState(() {
          _videoPolicy = null;
          _videoPolicyError =
              'Video limits could not load. Retry or attach photos instead.';
        });
      }
      return null;
    } finally {
      if (mounted) setState(() => _loadingVideoPolicy = false);
    }
  }

  Future<void> _pickVideo() async {
    if (_isSelectingMedia) return;
    setState(() {
      _isSelectingMedia = true;
      _mediaError = null;
      _mediaPermissionDenied = false;
    });
    try {
      if (_capturedVideos.length >= reportMaxVideos) {
        _showMediaError('Remove the selected video before choosing another.');
        return;
      }
      final policy = await _loadVideoPolicy();
      if (policy == null || !mounted) return;
      final picked = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: Duration(seconds: policy.maxSeconds),
      );
      if (picked == null || !mounted) return;
      final ext = picked.path.split('.').last;
      if (!_isValidVideoExtension(ext)) {
        _showMediaError('Unsupported video type. Use MP4, MOV, or WEBM.');
        return;
      }
      final file = File(picked.path);
      final duration = await readLocalVideoDuration(
        file,
        createController: widget.videoControllerFactory,
      );
      if (!mounted) return;
      if (duration == null) {
        _showMediaError(
          'This video’s duration could not be read. Try another video or attach photos instead. Your report details are still here.',
        );
        return;
      }
      if (!policy.accepts(duration)) {
        _showMediaError(
          'Record a video between ${VideoSubmissionPolicy.minSeconds} and ${policy.maxSeconds} seconds long. This video is ${duration.inMilliseconds / 1000} seconds.',
        );
        return;
      }
      setState(() {
        _capturedVideos.add(file);
        _videoDurations[file.path] = duration;
      });
    } catch (error) {
      _log.warning('Video selection failed', error);
      _handlePickerFailure(error);
    } finally {
      if (mounted) setState(() => _isSelectingMedia = false);
    }
  }

  void _previewPhoto(int index) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LocalPhotoPreview(
          photos: List.of(_capturedImages),
          initialIndex: index,
        ),
      ),
    );
  }

  void _previewVideo() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LocalVideoPreview(
          file: _capturedVideos.first,
          createController: widget.videoControllerFactory,
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (!_consentGiven) {
      setState(() {
        _submissionError = 'You must agree to share the pinned location and incident details to submit.';
      });
      return;
    }
    if (!_priorityComplete) return;
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });
    try {
      final apiClient = ref.read(apiClientProvider);
      final mainVideo = _capturedVideos.isNotEmpty
          ? _capturedVideos.first
          : null;
      if (mainVideo != null) {
        final policy = await _loadVideoPolicy();
        if (!mounted) return;
        final duration = _videoDurations[mainVideo.path];
        if (policy == null || duration == null || !policy.accepts(duration)) {
          setState(() {
            _isSubmitting = false;
            _submissionError = policy == null
                ? 'Video limits could not load. Please retry.'
                : 'The video limit changed. Record a video between 5 and ${policy.maxSeconds} seconds.';
          });
          return;
        }
      }
      final result = await apiClient.createReport(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        citizenPriority: _urgent ? 'urgent' : 'non_urgent',
        priorityReason: _urgent ? _priorityReason : null,
        priorityExplanation: _urgent
            ? _priorityExplanationController.text.trim()
            : null,
        latitude: _reportLocation.latitude,
        longitude: _reportLocation.longitude,
        imagePaths: _capturedImages.isNotEmpty
            ? _capturedImages.map((img) => img.path).toList()
            : null,
        cleanImagePaths: _cleanImages.isNotEmpty
            ? _cleanImages.map((img) => img.path).toList()
            : null,
        requestManualReview: _photosForReview.isNotEmpty,
        manualReviewReason: _manualReviewReason,
        videoPath: mainVideo?.path,
        onPrivateProperty: _onPrivateProperty,
        scaleLevel: _defaultScale,
        obstructionLevel: _defaultObstruction,
        photoLat: _photoVerificationResult?.latitude,
        photoLng: _photoVerificationResult?.longitude,
        photoAccuracy: _photoVerificationResult?.accuracy,
        photoCapturedAt: _photoVerificationResult?.capturedAt,
        photoSource: _photoVerificationResult?.source,
        isMocked: _photoVerificationResult?.isMocked,
      );
      if (mounted) {
        ref.invalidate(myReportsProvider);
        final savedLocally =
            result.data is Map && result.data['saved_locally'] == true;
        SnackbarHelper.showMessage(
          savedLocally
              ? 'Saved on this device. Your report still needs to be sent when a connection is available.'
              : 'Report sent. You can follow its review and response in My reports.',
        );
        context.pop(); // Pop back to dashboard
      }
    } on DioException catch (e) {
      if (mounted) {
        if (e.response?.data is Map &&
            e.response?.data['code'] == 'URGENT_TRUST_LOCKED') {
          ref.invalidate(citizenTrustProvider);
        }
        setState(() => _isSubmitting = false);
        String message =
            e.response?.data?['message'] ?? 'Failed to submit report.';
        if (e.response?.statusCode == 413) message = 'File is too large.';
        setState(() => _submissionError = message);
        SnackbarHelper.showError(message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        setState(
          () => _submissionError =
              'The report could not be sent. Your entries are still here. Please try again.',
        );
        SnackbarHelper.showError('An unexpected error occurred.');
      }
    }
  }

  Future<String?> _findAddress() =>
      (widget.locationSearchService ?? LocationSearchService())
          .getAddressFromCoordinates(
            _reportLocation.latitude,
            _reportLocation.longitude,
          );

  Widget _addressSummary() => FutureBuilder<String?>(
    future: _addressFuture,
    builder: (context, snapshot) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          !_locationConfirmed
              ? 'Choose the concern’s location on the map. The initial view is Pasig, not your detected location.'
              : !_addressRequested
              ? 'Finding the street address…'
              : snapshot.connectionState == ConnectionState.waiting
              ? 'Finding the street address…'
              : snapshot.data ??
                    'Street address unavailable. Confirm the map pin before continuing.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Text(
          '${_reportLocation.latitude.toStringAsFixed(6)}, ${_reportLocation.longitude.toStringAsFixed(6)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (_locationConfirmed &&
            (!_addressRequested ||
                (snapshot.connectionState != ConnectionState.waiting &&
                    snapshot.data == null)))
          TextButton(
            onPressed: () => setState(() {
              _addressRequested = true;
              _addressFuture = _findAddress();
            }),
            child: const Text('Retry street address'),
          ),
      ],
    ),
  );

  void _chooseLocation(LatLng location) => setState(() {
    _reportLocation = location;
    _locationConfirmed = true;
    _addressRequested = true;
    _addressFuture = _findAddress();
  });

  @override
  Widget build(BuildContext context) {
    ref.watch(citizenTrustProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final bool isPrefilled = widget.prefillData?.title != null;

    return PopScope(
      canPop: _currentStep == 0 && !_isSubmitting,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentStep > 0 && !_isSubmitting) {
          _prevStep();
        }
      },
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              toolbarHeight:
                  MediaQuery.textScalerOf(
                        context,
                      ).clamp(maxScaleFactor: 1.3).scale(24) *
                      2 +
                  16,
              title: Text(isPrefilled ? 'Resubmit report' : 'Report a concern'),
              leading: _currentStep > 0
                  ? IconButton(
                      tooltip: 'Previous step',
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _prevStep,
                    )
                  : const BackButton(),
            ),
            body: Column(
              children: [
                LinearProgressIndicator(
                  semanticsLabel: 'Step ${_currentStep + 1} of $_totalSteps',
                  value: (_currentStep + 1) / _totalSteps,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  color: AppColors.accent, // Civic blue
                  minHeight: 4,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Step ${_currentStep + 1} of $_totalSteps · ${['Location', 'Details', 'Photos and video', 'Review'][_currentStep]}',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ),
                _buildStepNavHeader(colorScheme),
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
                        const CircularProgressIndicator(
                          color: AppColors.accent,
                        ),
                        const SizedBox(height: 32),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            'Sending your report…',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Keep this screen open while your report is sent. You can track it after it is accepted.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                        ).padding(const EdgeInsets.symmetric(horizontal: 40)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepNavHeader(ColorScheme colorScheme) {
    const stepTitles = ['Location', 'Details', 'Media', 'Review'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_totalSteps, (index) {
            final isCurrent = index == _currentStep;
            final canJump = _canNavigateToStep(index);
            final isCompleted =
                index < _currentStep ||
                (index == 0 && _locationConfirmed) ||
                (index == 1 && _titleController.text.trim().isNotEmpty) ||
                (index == 2 &&
                    (_capturedImages.isNotEmpty || _capturedVideos.isNotEmpty));
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Semantics(
                button: true,
                enabled: canJump && !isCurrent,
                label:
                    'Step ${index + 1}: ${stepTitles[index]}${isCurrent ? ', current step' : (canJump ? '' : ', locked')}',
                child: ActionChip(
                  avatar: CircleAvatar(
                    radius: 9,
                    backgroundColor: isCurrent
                        ? AppColors.accent
                        : (isCompleted
                              ? AppColors.success
                              : colorScheme.outline.withValues(alpha: 0.3)),
                    child: Icon(
                      isCompleted && !isCurrent ? Icons.check : null,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                  label: Text(
                    '${index + 1}. ${stepTitles[index]}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      color: isCurrent
                          ? AppColors.accent
                          : (canJump
                                ? colorScheme.onSurface
                                : colorScheme.onSurface.withValues(alpha: 0.4)),
                    ),
                  ),
                  backgroundColor: isCurrent
                      ? AppColors.accent.withValues(alpha: 0.12)
                      : (canJump
                            ? colorScheme.surfaceContainerLow
                            : colorScheme.surfaceContainerLowest),
                  side: BorderSide(
                    color: isCurrent
                        ? AppColors.accent
                        : (canJump
                              ? colorScheme.outlineVariant
                              : colorScheme.outlineVariant.withValues(
                                  alpha: 0.3,
                                )),
                  ),
                  onPressed: canJump && !isCurrent
                      ? () => _jumpToStep(index)
                      : null,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildStepBottomButtons({
    required String nextText,
    required VoidCallback? onNext,
    VoidCallback? onPrev,
    bool isLoading = false,
  }) {
    if (onPrev == null) {
      return AppButton(text: nextText, isLoading: isLoading, onPressed: onNext);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final shouldStack = constraints.maxWidth < 280 || textScale > 1.3;
        if (shouldStack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppButton(
                text: nextText,
                isLoading: isLoading,
                onPressed: onNext,
              ),
              const SizedBox(height: 12),
              AppButton(
                text: 'Back',
                variant: ButtonVariant.secondary,
                onPressed: isLoading ? null : onPrev,
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              flex: 1,
              child: AppButton(
                text: 'Back',
                variant: ButtonVariant.secondary,
                onPressed: isLoading ? null : onPrev,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: AppButton(
                text: nextText,
                isLoading: isLoading,
                onPressed: onNext,
              ),
            ),
          ],
        );
      },
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
            'Tap the map to place the pin, or move the map and use its center.',
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),

          // Map FIRST
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 250,
              child: FlutterMap(
                mapController: _locationMap,
                options: MapOptions(
                  initialCenter: _reportLocation,
                  initialZoom: 17.0,
                  onTap: (position, point) => _chooseLocation(point),
                ),
                children: [
                  TileLayer(
                    tileProvider: widget.tileProvider,
                    urlTemplate: Theme.of(context).brightness == Brightness.dark
                        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png?key=${dotenv.env['CARTO_API_KEY'] ?? ''}'
                        : 'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png?key=${dotenv.env['CARTO_API_KEY'] ?? ''}',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'dev.ecopinas.ecopin_app',
                  ),
                  MarkerLayer(
                    markers: _locationConfirmed
                        ? [
                            Marker(
                              point: _reportLocation,
                              width: ReportPinFrame.width,
                              height: ReportPinFrame.height,
                              alignment: Alignment.topCenter,
                              child: Semantics(
                                label: 'Selected report location',
                                child: ReportPinFrame(
                                  color: colorScheme.primary,
                                  badge: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  child: Icon(
                                    Icons.my_location,
                                    color: colorScheme.primary,
                                    size: 25,
                                  ),
                                ),
                              ),
                            ),
                          ]
                        : [],
                  ),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                        onTap: () => launchUrl(
                          Uri.parse('https://www.openstreetmap.org/copyright'),
                        ),
                      ),
                      TextSourceAttribution(
                        'CARTO',
                        onTap: () => launchUrl(
                          Uri.parse('https://carto.com/attributions'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            text: 'Use this map center',
            variant: ButtonVariant.secondary,
            onPressed: () => _chooseLocation(_locationMap.camera.center),
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
                Expanded(child: _addressSummary()),
              ],
            ),
          ),
          const SizedBox(height: 48),
          _buildStepBottomButtons(
            nextText: 'Next: Details',
            onNext: _locationConfirmed ? _nextStep : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Details() {
    final trust = ref.watch(citizenTrustProvider);
    final bool canProceed =
        _titleController.text.trim().isNotEmpty && _priorityComplete;
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
            textInputAction: TextInputAction.next,
            hintText: 'Brief summary of the issue',
          ),
          const SizedBox(height: 8),
          Text(
            'Required. Give the concern a short title to continue.',
            style: Theme.of(context).textTheme.bodySmall,
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
          ReportPriorityPicker(
            urgentEnabled:
                !trust.isLoading && trust.asData?.value.urgentAllowed == true,
            urgent: _urgent,
            reason: _priorityReason,
            explanationController: _priorityExplanationController,
            onUrgentChanged: (urgent) => setState(() {
              if (_urgent == urgent) return;
              _urgent = urgent;
              _priorityReason = null;
              _priorityExplanationController.clear();
            }),
            onReasonChanged: (reason) =>
                setState(() => _priorityReason = reason),
          ),
          const CitizenTrustStatus(compact: true),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text(
              'On Private Property',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text(
              'Check this if the issue is located on private property.',
            ),
            value: _onPrivateProperty,
            contentPadding: EdgeInsets.zero,
            onChanged: (value) => setState(() => _onPrivateProperty = value),
          ),
          const SizedBox(height: 48),
          _buildStepBottomButtons(
            nextText: 'Next: Attach Media',
            onNext: canProceed ? _nextStep : null,
            onPrev: _prevStep,
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Media(ColorScheme colorScheme) {
    final hasMedia = _capturedImages.isNotEmpty || _capturedVideos.isNotEmpty;
    return SingleChildScrollView(
      controller: _mediaScroll,
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
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),

          if (_mediaError != null) ...[
            Semantics(
              liveRegion: true,
              child: Text(
                _mediaError!,
                style: TextStyle(color: colorScheme.error),
              ),
            ),
            if (_mediaPermissionDenied)
              AppButton(
                text: 'Open app settings',
                variant: ButtonVariant.link,
                onPressed: _openMediaSettings,
              ),
            const SizedBox(height: 16),
          ],
          if (_isSelectingMedia) ...[
            const LinearProgressIndicator(
              semanticsLabel: 'Checking selected media',
            ),
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: const Text('Checking selected media…'),
            ),
            const SizedBox(height: 16),
          ],
          if (_photosForReview.isNotEmpty) ...[
            _photoReviewNotice(),
            const SizedBox(height: 16),
          ],
          Text(
            'Photos · Up to $reportMaxPhotos',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            '${reportTotalPhotosSize ~/ (1024 * 1024)} MB combined · JPG, PNG, WEBP. Tap a photo to inspect it. Remove a photo and use Camera to retake it.',
          ),
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
                        child: Semantics(
                          button: true,
                          label: 'Preview selected photo ${index + 1}',
                          excludeSemantics: true,
                          child: InkWell(
                            onTap: () => _previewPhoto(index),
                            child: Image.file(
                              _capturedImages[index],
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) =>
                                  const SizedBox(
                                    width: 120,
                                    height: 120,
                                    child: Center(
                                      child: Text(
                                        'Photo unavailable',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          tooltip: 'Remove photo ${index + 1}',
                          onPressed: () => setState(() {
                            final removed = _capturedImages.removeAt(index);
                            if (_cleanImages.length > index) {
                              _photosForReview.remove(_cleanImages[index].path);
                              _cleanImages.removeAt(index);
                            }
                            if (_selectedImage?.path == removed.path) {
                              _selectedImage = null;
                            }
                          }),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.close, size: 20),
                        ),
                      ),
                      if (index < _cleanImages.length &&
                          _photosForReview.containsKey(
                            _cleanImages[index].path,
                          ))
                        Positioned(
                          left: 4,
                          right: 4,
                          bottom: 4,
                          child: Tooltip(
                            message: 'For manual review — not yet verified',
                            child: const Chip(
                              avatar: Icon(Icons.person_search, size: 16),
                              label: Text('Unverified'),
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

          Text(
            'Video · Up to $reportMaxVideos',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            _videoPolicy == null
                ? 'Camera recording only. Video limits must load before recording.'
                : '${VideoSubmissionPolicy.minSeconds}–${_videoPolicy!.maxSeconds} seconds · Camera recording only · MP4, MOV, WEBM',
          ),
          if (_loadingVideoPolicy) const Text('Loading video limits…'),
          if (_videoPolicyError != null) ...[
            Text(_videoPolicyError!),
            TextButton(
              onPressed: _loadingVideoPolicy ? null : _loadVideoPolicy,
              child: const Text('Retry video limits'),
            ),
          ],
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
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
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
                          'Selected Video',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Duration: ${_formatDurationSeconds((_videoDurations[_capturedVideos.first.path] ?? Duration.zero).inSeconds)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove selected video',
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => setState(() {
                      final removed = _capturedVideos.removeAt(0);
                      _videoDurations.remove(removed.path);
                    }),
                  ),
                ],
              ),
            ),
            AppButton(
              text: 'Preview selected video',
              icon: Icons.play_arrow,
              variant: ButtonVariant.link,
              onPressed: _previewVideo,
            ),
            const SizedBox(height: 16),
          ],
          _buildMediaOption(
            icon: Icons.videocam,
            label: 'Record Video',
            onTap:
                _capturedVideos.isEmpty &&
                    _videoPolicy != null &&
                    !_loadingVideoPolicy
                ? _pickVideo
                : null,
          ),
          const SizedBox(height: 48),
          _buildStepBottomButtons(
            nextText: 'Next: Review',
            onNext: hasMedia && !_isSelectingMedia ? _nextStep : null,
            onPrev: _prevStep,
          ),
        ],
      ),
    );
  }

  Widget _photoReviewNotice() => Semantics(
    liveRegion: true,
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.person_search),
      title: const Text('For manual review — not yet verified'),
      subtitle: Text(
        'An officer will review the photo evidence after you submit. This is not an approval. A connection is required to submit this review request.\n\n${_manualReviewReason ?? ''}',
      ),
    ),
  );

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
            'Review the details before sending your report.',
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          if (_photosForReview.isNotEmpty) _photoReviewNotice(),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Title',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                    TextButton.icon(
                      key: const ValueKey('edit-details-button'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(48, 24),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _jumpToStep(1),
                      icon: const Icon(Icons.edit, size: 14),
                      label: const Text('Edit', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _titleController.text,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Location',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                    TextButton.icon(
                      key: const ValueKey('edit-location-button'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(48, 24),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _jumpToStep(0),
                      icon: const Icon(Icons.edit, size: 14),
                      label: const Text('Edit', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _addressSummary(),
                const SizedBox(height: 16),
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  _descriptionController.text.isEmpty
                      ? 'No description added'
                      : _descriptionController.text,
                ),
                const SizedBox(height: 16),
                Text(
                  'Property and access',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  _onPrivateProperty
                      ? 'On private property'
                      : 'Not marked as private property',
                ),
                const SizedBox(height: 16),
                Text(
                  'Priority',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                Text(
                  _urgent
                      ? 'Urgent · Pending officer verification'
                      : 'Non-urgent',
                ),
                if (_urgent && _priorityReason != null)
                  Text(reportPriorityReasons[_priorityReason]!),
                if (_urgent &&
                    _priorityExplanationController.text.trim().isNotEmpty)
                  Text(_priorityExplanationController.text.trim()),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Media',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                    TextButton.icon(
                      key: const ValueKey('edit-media-button'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(48, 24),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _jumpToStep(2),
                      icon: const Icon(Icons.edit, size: 14),
                      label: const Text('Edit', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_capturedImages.length} Photo(s), ${_capturedVideos.length} Video(s)',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: _submissionError != null && !_consentGiven
                    ? colorScheme.error
                    : colorScheme.outlineVariant,
              ),
            ),
            child: CheckboxListTile(
              value: _consentGiven,
              onChanged: (val) {
                setState(() {
                  _consentGiven = val ?? false;
                  if (_consentGiven && _submissionError?.contains('agree') == true) {
                    _submissionError = null;
                  }
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                'Do you agree to share the pinned location and incident details publicly for waste monitoring?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              subtitle: Text(
                'Required for report submission',
                style: TextStyle(
                  color: _submissionError != null && !_consentGiven
                      ? colorScheme.error
                      : colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_submissionError != null) ...[
            Semantics(
              liveRegion: true,
              child: Text(
                _submissionError!,
                style: TextStyle(color: colorScheme.error),
              ),
            ),
            const SizedBox(height: 16),
          ],
          _buildStepBottomButtons(
            nextText: 'Submit Report',
            isLoading: _isSubmitting,
            onNext: _isSubmitting || !_priorityComplete || !_consentGiven ? null : _submitReport,
            onPrev: _isSubmitting ? null : _prevStep,
          ),
        ],
      ),
    );
  }

  Widget _buildMediaOption({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null || _isSelectingMedia;
    return Semantics(
      button: true,
      enabled: !isDisabled,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 100),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDisabled
                ? Theme.of(context).colorScheme.surface
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: isDisabled
                    ? Colors.grey.shade600
                    : Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
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
