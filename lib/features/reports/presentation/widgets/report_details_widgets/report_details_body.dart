import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecopin_app/features/reports/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/features/reports/data/models/report_model.dart';
import 'package:ecopin_app/features/reports/presentation/screens/satisfaction_rating_screen.dart';
import 'package:ecopin_app/features/reports/presentation/widgets/report_details_widgets/fullscreen_image_view.dart';
import 'package:ecopin_app/features/reports/presentation/widgets/report_details_widgets/info_row.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../reports_screen_widgets/status_badge.dart';
import '../reports_screen_widgets/validation_badge.dart';

class ReportDetailsBody extends StatefulWidget {
  final ReportModel report;
  final List<dynamic> evidence;
  final bool isLoadingEvidence;
  final CleanupTaskModel? cleanupTask;
  final bool isLoadingCleanupTask;
  final VoidCallback? onFetchCleanupTask;

  const ReportDetailsBody({
    super.key,
    required this.report,
    required this.evidence,
    required this.isLoadingEvidence,
    this.cleanupTask,
    required this.isLoadingCleanupTask,
    this.onFetchCleanupTask,
  });

  @override
  State<ReportDetailsBody> createState() => _ReportDetailsBodyState();
}

class _ReportDetailsBodyState extends State<ReportDetailsBody> {
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
                    Icon(Icons.image, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'No evidence images',
                      style: TextStyle(color: Colors.grey),
                    ),
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
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FullScreenImageView(
                              imageUrl: widget.evidence[index]['url'],
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.evidence[index]['url'],
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
                  );
                },
              ),
            ),
          if (widget.report.status.toLowerCase() == 'resolved' || widget.report.status.toLowerCase() == 'waiting_for_feedback' || widget.report.status.toLowerCase() == 'closed') ...[
            const SizedBox(height: 24),
            const Text(
              'Before & After',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (widget.isLoadingCleanupTask)
              const Center(child: CircularProgressIndicator())
            else if (widget.report.beforePhotoUrl != null || widget.report.afterPhotoUrl != null || widget.cleanupTask != null)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        if ((widget.cleanupTask?.beforePhotoUrl != null) || (widget.report.beforePhotoUrl != null))
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: widget.cleanupTask?.beforePhotoUrl ?? widget.report.beforePhotoUrl!,
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
                        if ((widget.cleanupTask?.afterPhotoUrl != null) || (widget.report.afterPhotoUrl != null))
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: widget.cleanupTask?.afterPhotoUrl ?? widget.report.afterPhotoUrl!,
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
          // Satisfaction rating button if waiting for feedback
          if (widget.report.status.toLowerCase() == 'waiting_for_feedback') ...[
            const Text(
              'The issue has been resolved! Please rate the service.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SatisfactionRatingScreen(reportId: widget.report.id),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                ),
                child: const Text(
                  'Rate & Close Report',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Show satisfaction rating if already closed
          if (widget.report.status.toLowerCase() == 'closed' &&
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
