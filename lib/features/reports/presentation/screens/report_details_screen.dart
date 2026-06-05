import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/features/reports/data/models/report_model.dart';
import 'package:ecopin_app/features/reports/providers/report_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ReportDetailsScreen extends ConsumerStatefulWidget {
  final String reportId;

  const ReportDetailsScreen({super.key, required this.reportId});

  @override
  ConsumerState<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends ConsumerState<ReportDetailsScreen> {
  List<dynamic> _evidence = [];
  bool _isLoadingEvidence = false;

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
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _ReportDetailsBody extends StatelessWidget {
  final ReportModel report;
  final List<dynamic> evidence;
  final bool isLoadingEvidence;

  const _ReportDetailsBody({
    required this.report,
    required this.evidence,
    required this.isLoadingEvidence,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat(
      'MMMM dd, yyyy - hh:mm a',
    ).format(report.createdAt);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatusBadge(status: report.status),
              _ValidationBadge(status: report.validationStatus),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            report.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Issue: ${report.issueType ?? "General"}',
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
            report.description ?? 'No description provided.',
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
                '${report.location.latitude.toStringAsFixed(6)}, ${report.location.longitude.toStringAsFixed(6)}',
          ),
          _InfoRow(icon: Icons.calendar_today, text: dateStr),
          const SizedBox(height: 24),
          const Text(
            'Evidence',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (isLoadingEvidence)
            const Center(child: CircularProgressIndicator())
          else if (evidence.isEmpty)
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
                itemCount: evidence.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FullScreenImageView(
                              imageUrl: evidence[index]['url'],
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          evidence[index]['url'],
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 200,
                              height: 200,
                              color: Colors.grey.shade300,
                              child: const Center(
                                child: Icon(Icons.broken_image, color: Colors.grey),
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
          if (report.status.toLowerCase() == 'resolved') ...[
            const SizedBox(height: 24),
            const Text(
              'Before & After',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Expanded(child: _PlaceholderImage(label: 'Before')),
                SizedBox(width: 8),
                Expanded(child: _PlaceholderImage(label: 'After')),
              ],
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
    final isValidated = status.toLowerCase() == 'validated';
    final color = isValidated ? Colors.blue : Colors.grey;

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
          Icon(
            isValidated ? Icons.verified : Icons.hourglass_empty,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isValidated ? 'AI VALIDATED' : 'PENDING VALIDATION',
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
