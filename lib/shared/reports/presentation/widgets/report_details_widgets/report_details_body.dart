import 'package:ecopin_app/shared/reports/presentation/widgets/response_deadline_indicator.dart';
import 'report_video_player.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/report_marker.dart';
import 'package:ecopin_app/shared/widgets/private_media_image.dart';

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
  final TileProvider? tileProvider;
  final VideoPlayerController Function(Uri source)? videoControllerFactory;
  final VoidCallback? onWithdraw;

  const ReportDetailsBody({
    super.key,
    required this.report,
    required this.evidence,
    required this.isLoadingEvidence,
    this.cleanupTask,
    required this.isLoadingCleanupTask,
    this.onFetchCleanupTask,
    this.isOfficerUser = false,
    this.tileProvider,
    this.videoControllerFactory,
    this.onWithdraw,
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
      hideIdentity: widget.report.hideIdentity,
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
    ).format(widget.report.createdAt.toLocal());

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
          ResponseDeadlineIndicator(report: widget.report, details: true),
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
          if (widget.report.validationStatus.toLowerCase() == 'rejected') ...[
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
                  Row(
                    children: [
                      Icon(
                        Icons.cancel_outlined,
                        size: 20,
                        color: Colors.red.shade800,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.report.manualReviewRequestReason != null
                            ? 'Manual Review Rejected'
                            : 'Rejection Reason',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.report.rejectionReason != null &&
                            widget.report.rejectionReason!.trim().isNotEmpty
                        ? widget.report.rejectionReason!
                        : 'This report was rejected during validation. You may submit a new report with clearer photos or updated details.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red.shade800,
                      height: 1.4,
                    ),
                  ),
                  if (widget.report.manualReviewRequestReason != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your review request note:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.report.manualReviewRequestReason!,
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (widget.report.rejectedAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Rejected on: ${DateFormat('MMMM dd, yyyy - hh:mm a').format(widget.report.rejectedAt!.toLocal())}',
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
          // Show Private Property & Consent Status
          if (widget.report.onPrivateProperty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.home_work_outlined,
                        color: Colors.amber.shade900,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Private Property',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.report.propertyOwnerConsentStatus == 'obtained' ||
                            widget.report.propertyOwnerConsentStatus ==
                                'granted'
                        ? 'Property owner consent has been granted for cleanup crews to enter.'
                        : widget.report.propertyOwnerConsentStatus == 'denied'
                        ? 'Property owner consent was denied. Crews cannot enter private premises.'
                        : 'This site is located on private property. LGU review and property owner consent are required before dispatch.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.amber.shade900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Consent Status: ${widget.report.propertyOwnerConsentStatus.replaceAll('_', ' ').toUpperCase()}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.amber.shade900,
                    ),
                  ),
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
                (widget.report.streetAddress != null ||
                    widget.report.barangay != null)
                ? widget.report.formattedAddress
                : '${widget.report.location.latitude.toStringAsFixed(6)}, ${widget.report.location.longitude.toStringAsFixed(6)}',
          ),
          if (widget.report.streetAddress != null ||
              widget.report.barangay != null)
            Padding(
              padding: const EdgeInsets.only(left: 32, bottom: 4),
              child: Text(
                '${widget.report.location.latitude.toStringAsFixed(6)}, ${widget.report.location.longitude.toStringAsFixed(6)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          InfoRow(icon: Icons.calendar_today, text: dateStr),
          if (widget.report.locationVerificationStatus != null) ...[
            const SizedBox(height: 8),
            _buildLocationVerificationBadge(
              widget.report.locationVerificationStatus!,
              widget.report.photoDistanceMeters,
            ),
          ],
          const SizedBox(height: 12),
          // Static, non-interactive map showing the report location.
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 180,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: widget.report.location,
                  initialZoom: 17.0,
                  // Disable all gestures — this map is view-only.
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
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
                    markers: [
                      Marker(
                        point: widget.report.location,
                        width: ReportPinFrame.width,
                        height: ReportPinFrame.height,
                        alignment: Alignment.topCenter,
                        child: ReportMarker(
                          status: widget.report.status,
                          title: widget.report.title,
                          issueType: widget.report.issueType,
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
                            ? ReportVideoPlayer(
                                videoUrl: evidence['url'],
                                createController: widget.videoControllerFactory,
                              )
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
                                child: PrivateMediaImage(
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
                            child: PrivateMediaImage.cached(
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
                            child: PrivateMediaImage.cached(
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
          // Satisfaction rating button if waiting for feedback or resolved (citizen only)
          if (!widget.isOfficerUser &&
              (widget.report.status.toLowerCase() == 'waiting_for_feedback' ||
                  widget.report.status.toLowerCase() == 'resolved')) ...[
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
          if (!widget.isOfficerUser &&
              widget.onWithdraw != null &&
              widget.report.canBeWithdrawn) ...[
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Withdraw report',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'You can withdraw this report before it is triaged or dispatched for cleanup.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Withdraw Report'),
                      onPressed: widget.onWithdraw,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 100),
          // Shared details link to the authorized officer tools instead of no-op actions.
          if (widget.isOfficerUser) ...[
            const SizedBox(height: 24),
            Text(
              'Officer tools',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              'Review and update this report in your officer workspace.',
            ),
            const SizedBox(height: 16),
            AppButton(
              text: 'Open officer report tools',
              onPressed: () => context.push(
                OfficerAppRoutes.reportDetails.replaceFirst(
                  ':id',
                  widget.report.id,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationVerificationBadge(
    String status,
    double? distanceMeters,
  ) {
    Color bg;
    Color border;
    Color text;
    IconData icon;
    String label;

    switch (status.toLowerCase()) {
      case 'verified_on_site':
        bg = const Color(0xFFECFDF5);
        border = const Color(0xFFA7F3D0);
        text = const Color(0xFF065F46);
        icon = Icons.verified;
        label = distanceMeters != null
            ? 'Verified On-Site (${distanceMeters.toStringAsFixed(0)}m)'
            : 'Verified On-Site';
        break;
      case 'nearby_approximate':
        bg = const Color(0xFFFFFBEB);
        border = const Color(0xFFFDE68A);
        text = const Color(0xFF92400E);
        icon = Icons.near_me_outlined;
        label = distanceMeters != null
            ? 'Nearby (~${distanceMeters.toStringAsFixed(0)}m)'
            : 'Nearby Location';
        break;
      case 'location_mismatch':
        bg = const Color(0xFFFEF2F2);
        border = const Color(0xFFFECACA);
        text = const Color(0xFF991B1B);
        icon = Icons.warning_amber_rounded;
        label = distanceMeters != null
            ? 'Location Mismatch (${distanceMeters.toStringAsFixed(0)}m away)'
            : 'Location Discrepancy';
        break;
      case 'unverified_gallery':
      default:
        bg = const Color(0xFFF8FAFC);
        border = const Color(0xFFE2E8F0);
        text = const Color(0xFF475569);
        icon = Icons.photo_library_outlined;
        label = 'Gallery Upload';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: text),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: text,
              ),
            ),
          ),
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
