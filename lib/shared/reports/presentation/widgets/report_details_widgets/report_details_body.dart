import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:ecopin_app/shared/reports/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/reports/data/models/report_prefill_data.dart';
import 'package:ecopin_app/shared/reports/presentation/screens/satisfaction_rating_screen.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/report_details_widgets/fullscreen_image_view.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/report_details_widgets/info_row.dart';
import 'package:ecopin_app/shared/reports/providers/report_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';

import '../reports_screen_widgets/status_badge.dart';
import '../reports_screen_widgets/validation_badge.dart';

class ReportDetailsBody extends ConsumerStatefulWidget {
  final ReportModel report;
  final List<dynamic> evidence;
  final bool isLoadingEvidence;
  final CleanupTaskModel? cleanupTask;
  final bool isLoadingCleanupTask;
  final VoidCallback? onFetchCleanupTask;
  final bool isOfficerUser;

  const ReportDetailsBody({
    super.key,
    required this.report,
    required this.evidence,
    required this.isLoadingEvidence,
    this.cleanupTask,
    required this.isLoadingCleanupTask,
    this.onFetchCleanupTask,
    this.isOfficerUser = false,
  });

  @override
  ConsumerState<ReportDetailsBody> createState() => _ReportDetailsBodyState();
}

class _ReportDetailsBodyState extends ConsumerState<ReportDetailsBody> {
  Color _getSeverityColor(String level) {
    switch (level.toLowerCase()) {
      case 'minimal':
        return Colors.green;
      case 'low':
        return Colors.lightGreen;
      case 'moderate':
        return Colors.orange;
      case 'high':
        return Colors.deepOrange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  /// Navigate to the Create Report screen with the rejected report's details
  /// prefilled. The citizen can edit everything and must add new media.
  /// This does NOT call the backend yet — submission happens normally through
  /// the standard Create Report flow.
  void _handleCreateNewReport() {
    ref.invalidate(
      myReportsProvider,
    ); // ensure My Reports refreshes after submit

    final prefill = ReportPrefillData(
      location: widget.report.location,
      title: widget.report.title,
      description: widget.report.description,
    );

    context.push(ProtectedAppRoutes.createReport, extra: prefill);
  }

  @override
  void initState() {
    super.initState();
    if (widget.report.status.toLowerCase() == 'resolved' &&
        widget.report.clusterId != null &&
        widget.onFetchCleanupTask != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onFetchCleanupTask!();
      });
    }
  }

  @override
  void didUpdateWidget(covariant ReportDetailsBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.report.status.toLowerCase() == 'resolved' &&
        widget.report.clusterId != null &&
        widget.cleanupTask == null &&
        widget.onFetchCleanupTask != null &&
        !widget.isLoadingCleanupTask) {
      widget.onFetchCleanupTask!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat(
      'MMMM dd, yyyy - hh:mm a',
    ).format(widget.report.createdAt);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(status: widget.report.status),
              ValidationBadge(status: widget.report.validationStatus),
            ],
          ),
          if (widget.report.severityScore != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getSeverityColor(
                  widget.report.severityLevel ?? 'Moderate',
                ).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getSeverityColor(
                    widget.report.severityLevel ?? 'Moderate',
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Severity',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getSeverityColor(
                            widget.report.severityLevel ?? 'Moderate',
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${widget.report.severityScore}/100 - ${widget.report.severityLevel ?? 'Moderate'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.report.severityFactors != null &&
                      widget.report.severityFactors!['explanation'] !=
                          null) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.report.severityFactors!['explanation'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          // Show rejection reason if report is rejected
          if (widget.report.validationStatus.toLowerCase() == 'rejected' &&
              widget.report.rejectionReason != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rejection Reason',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.report.rejectionReason!,
                    style: TextStyle(fontSize: 14, color: Colors.red.shade700),
                  ),
                  if (widget.report.rejectedAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Rejected on: ${DateFormat('MMMM dd, yyyy - hh:mm a').format(widget.report.rejectedAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          // Show Create New Report button for rejected reports
          if (widget.report.validationStatus.toLowerCase() == 'rejected' &&
              !widget.isOfficerUser) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                onPressed: _handleCreateNewReport,
                text: 'Create New Report',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Opens the report creation form with your original title,'
              ' description, and location pre-filled.'
              ' You can edit all fields and must add new evidence photos.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          Text(
            widget.report.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Issue: ${widget.report.issueType ?? "General"}',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Description',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            widget.report.description ?? 'No description provided.',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          const Text(
            'Location & Date',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          InfoRow(
            icon: Icons.location_pin,
            text:
                '${widget.report.location.latitude.toStringAsFixed(6)}, ${widget.report.location.longitude.toStringAsFixed(6)}',
          ),
          InfoRow(icon: Icons.calendar_today, text: dateStr),
          const SizedBox(height: 12),
          // Static, non-interactive map showing the report location.
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 180,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: widget.report.location,
                  initialZoom: 15.0,
                  // Disable all gestures — this map is view-only.
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://api.maptiler.com/maps/streets-v2-dark/{z}/{x}/{y}.png?key=${dotenv.env['MAPTILER_API_KEY'] ?? ''}',
                    userAgentPackageName: 'dev.ecopinas.ecopin_app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: widget.report.location,
                        width: 40,
                        height: 40,
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
          const SizedBox(height: 24),
          const Text(
            'Evidence',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (widget.isLoadingEvidence)
            const Center(child: CircularProgressIndicator())
          else if (widget.evidence.isEmpty)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text('No evidence', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.evidence.length,
                itemBuilder: (context, index) {
                  final evidence = widget.evidence[index];
                  final isVideo = evidence['resource_type'] == 'video';

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: isVideo
                            ? _VideoPlayerWidget(videoUrl: evidence['url'])
                            : GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FullScreenImageView(
                                        imageUrl: evidence['url'],
                                      ),
                                    ),
                                  );
                                },
                                child: Image.network(
                                  evidence['url'],
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 200,
                                      height: 200,
                                      color: Colors.grey.shade300,
                                      child: const Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          if (widget.report.status.toLowerCase() == 'resolved' ||
              widget.report.status.toLowerCase() == 'waiting_for_feedback' ||
              widget.report.status.toLowerCase() == 'closed') ...[
            const SizedBox(height: 24),
            const Text(
              'Before & After',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (widget.isLoadingCleanupTask)
              const Center(child: CircularProgressIndicator())
            else if (widget.report.beforePhotoUrl != null ||
                widget.report.afterPhotoUrl != null ||
                widget.cleanupTask != null)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        if ((widget.cleanupTask?.beforePhotoUrl != null) ||
                            (widget.report.beforePhotoUrl != null))
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl:
                                  widget.cleanupTask?.beforePhotoUrl ??
                                  widget.report.beforePhotoUrl!,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: 150,
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 150,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey.shade200,
                                ),
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        size: 40,
                                        color: Colors.red,
                                      ),
                                      SizedBox(height: 8),
                                      Text('Image not available'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            height: 150,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey.shade200,
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 40,
                                  ),
                                  SizedBox(height: 8),
                                  Text('Before'),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        const Text(
                          'Before',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      children: [
                        if ((widget.cleanupTask?.afterPhotoUrl != null) ||
                            (widget.report.afterPhotoUrl != null))
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl:
                                  widget.cleanupTask?.afterPhotoUrl ??
                                  widget.report.afterPhotoUrl!,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: 150,
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 150,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey.shade200,
                                ),
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        size: 40,
                                        color: Colors.red,
                                      ),
                                      SizedBox(height: 8),
                                      Text('Image not available'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            height: 150,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey.shade200,
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 40,
                                  ),
                                  SizedBox(height: 8),
                                  Text('After'),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        const Text(
                          'After',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else
              const Text(
                'No before/after photos available yet.',
                style: TextStyle(fontSize: 14),
              ),
          ],
          const SizedBox(height: 32),
          // Satisfaction rating button if waiting for feedback (citizen only)
          if (!widget.isOfficerUser &&
              widget.report.status.toLowerCase() == 'waiting_for_feedback') ...[
            const Text(
              'The issue has been resolved! Please rate the service.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SatisfactionRatingScreen(reportId: widget.report.id),
                    ),
                  );
                },
                text: 'Rate & Close Report',
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Show satisfaction rating if already closed (citizen only)
          if (!widget.isOfficerUser &&
              widget.report.status.toLowerCase() == 'closed' &&
              widget.report.satisfactionRating != null) ...[
            const Text(
              'Your Satisfaction Rating',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text(
                    _getEmojiForRating(widget.report.satisfactionRating!),
                    style: const TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getLabelForRating(widget.report.satisfactionRating!),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 100),
          // LGU-specific actions
          if (widget.isOfficerUser) ...[
            const SizedBox(height: 24),
            const Text(
              'LGU Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (widget.report.status.toLowerCase() == 'unresolved' ||
                widget.report.status.toLowerCase() == 'in_progress')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Implement resolve report
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                  ),
                  child: const Text(
                    'Mark as Resolved',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            if (widget.report.status.toLowerCase() == 'unresolved')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Implement mark as in progress
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text(
                    'Mark as In Progress',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _getEmojiForRating(int rating) {
    switch (rating) {
      case 1:
        return '😢';
      case 2:
        return '😕';
      case 3:
        return '😐';
      case 4:
        return '😊';
      case 5:
        return '😄';
      default:
        return '😐';
    }
  }

  String _getLabelForRating(int rating) {
    switch (rating) {
      case 1:
        return 'Very Dissatisfied';
      case 2:
        return 'Dissatisfied';
      case 3:
        return 'Neutral';
      case 4:
        return 'Satisfied';
      case 5:
        return 'Very Satisfied';
      default:
        return 'Neutral';
    }
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const _VideoPlayerWidget({required this.videoUrl});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      await controller.initialize();

      if (mounted) {
        setState(() {
          _controller = controller;
          _isInitialized = true;
        });

        controller.addListener(() {
          if (mounted) {
            setState(() {
              _isPlaying = controller.value.isPlaying;
            });
          }
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isInitialized = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    final controller = _controller;
    if (controller == null) return;

    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
        _isPlaying = false;
      } else {
        controller.play();
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        width: 200,
        height: 200,
        color: Colors.grey.shade300,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final controller = _controller;
    if (_hasError || controller == null) {
      return Container(
        width: 200,
        height: 200,
        color: Colors.grey.shade300,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 32, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Video load failed',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: _togglePlayPause,
          child: SizedBox(
            width: 200,
            height: 200,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
          ),
        ),
        if (!_isPlaying)
          Container(
            width: 200,
            height: 200,
            color: Colors.black26,
            child: const Center(
              child: Icon(
                Icons.play_circle_outline,
                size: 64,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}
