import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/features/reports/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/features/reports/data/models/report_model.dart';
import 'package:ecopin_app/features/reports/providers/report_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ReportDetailsScreen extends ConsumerStatefulWidget {
  final String reportId;

  const ReportDetailsScreen({super.key, required this.reportId});

  @override
  ConsumerState<ReportDetailsScreen> createState() =>
      _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends ConsumerState<ReportDetailsScreen> {
  List<dynamic> _evidence = [];
  bool _isLoadingEvidence = false;
  CleanupTaskModel? _cleanupTask;
  bool _isLoadingCleanupTask = false;

  @override
  void initState() {
    super.initState();
    _fetchEvidence();
  }

  Future<void> _fetchEvidence() async {
    setState(() => _isLoadingEvidence = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.getReportEvidence(widget.reportId);
      print('Evidence response: ${response.data}');
      setState(() => _evidence = response.data);
    } catch (e) {
      print('Failed to fetch evidence: $e');
    } finally {
      setState(() => _isLoadingEvidence = false);
    }
  }

  Future<void> _fetchCleanupTask(String clusterId) async {
    setState(() => _isLoadingCleanupTask = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.getCleanupTasksByCluster(clusterId);

      if (response.data != null && response.data is List) {
        final List<CleanupTaskModel> tasks = (response.data as List)
            .map((taskJson) => CleanupTaskModel.fromJson(taskJson))
            .toList();

        if (tasks.isNotEmpty) {
          setState(() {
            _cleanupTask = tasks.first;
          });
        }
      }
    } catch (e) {
      print('Failed to fetch cleanup tasks: $e');
    } finally {
      setState(() => _isLoadingCleanupTask = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(reportDetailsProvider(widget.reportId));

    return Scaffold(
      appBar: AppBar(title: const Text('Report Details')),
      body: reportAsync.when(
        data: (report) => _ReportDetailsBody(
          report: report,
          evidence: _evidence,
          isLoadingEvidence: _isLoadingEvidence,
          cleanupTask: _cleanupTask,
          isLoadingCleanupTask: _isLoadingCleanupTask,
          onFetchCleanupTask: report.clusterId != null
              ? () => _fetchCleanupTask(report.clusterId!)
              : null,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _ReportDetailsBody extends StatefulWidget {
  final ReportModel report;
  final List<dynamic> evidence;
  final bool isLoadingEvidence;
  final CleanupTaskModel? cleanupTask;
  final bool isLoadingCleanupTask;
  final VoidCallback? onFetchCleanupTask;

  const _ReportDetailsBody({
    required this.report,
    required this.evidence,
    required this.isLoadingEvidence,
    this.cleanupTask,
    required this.isLoadingCleanupTask,
    this.onFetchCleanupTask,
  });

  @override
  State<_ReportDetailsBody> createState() => _ReportDetailsBodyState();
}

class _ReportDetailsBodyState extends State<_ReportDetailsBody> {
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
  void didUpdateWidget(covariant _ReportDetailsBody oldWidget) {
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
              _StatusBadge(status: widget.report.status),
              _ValidationBadge(status: widget.report.validationStatus),
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
          _InfoRow(
            icon: Icons.location_pin,
            text:
                '${widget.report.location.latitude.toStringAsFixed(6)}, ${widget.report.location.longitude.toStringAsFixed(6)}',
          ),
          _InfoRow(icon: Icons.calendar_today, text: dateStr),
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
          if (widget.report.status.toLowerCase() == 'resolved') ...[
            const SizedBox(height: 24),
            const Text(
              'Before & After',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (widget.isLoadingCleanupTask)
              const Center(child: CircularProgressIndicator())
            else if (widget.cleanupTask != null)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        if (widget.cleanupTask?.beforePhotoUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: widget.cleanupTask!.beforePhotoUrl!,
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
                        if (widget.cleanupTask?.afterPhotoUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: widget.cleanupTask!.afterPhotoUrl!,
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
                'No cleanup task found for this report.',
                style: TextStyle(fontSize: 14),
              ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  final String label;

  const _PlaceholderImage({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(child: Icon(Icons.image, color: Colors.grey)),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'resolved':
        color = Colors.green;
        break;
      case 'in progress':
        color = Colors.orange;
        break;
      default:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ValidationBadge extends StatelessWidget {
  final String status;

  const _ValidationBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'automatically_valid':
        color = Colors.green;
        label = 'AI VALIDATED';
        icon = Icons.verified;
        break;
      case 'manual_review':
        color = Colors.orange;
        label = 'MANUAL REVIEW';
        icon = Icons.rate_review;
        break;
      case 'rejected':
        color = Colors.red;
        label = 'INVALID';
        icon = Icons.error_outline;
        break;
      default:
        color = Colors.grey;
        label = 'PENDING';
        icon = Icons.hourglass_empty;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class FullScreenImageView extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageView({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(Icons.broken_image, color: Colors.white, size: 48),
              );
            },
          ),
        ),
      ),
    );
  }
}
