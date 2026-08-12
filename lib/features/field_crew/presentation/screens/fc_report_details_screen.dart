import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/report_details_widgets/report_details_body.dart';
import 'package:ecopin_app/shared/reports/providers/report_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

class FcReportDetailsScreen extends ConsumerStatefulWidget {
  final String reportId;

  const FcReportDetailsScreen({super.key, required this.reportId});

  @override
  ConsumerState<FcReportDetailsScreen> createState() => _FcReportDetailsScreenState();
}

class _FcReportDetailsScreenState extends ConsumerState<FcReportDetailsScreen> {
  List<dynamic> _evidence = [];
  bool _isLoadingEvidence = false;
  bool _isUpdating = false;
  final Logger _log = Logger('FcReportDetailsScreen');

  @override
  void initState() {
    super.initState();
    _fetchEvidence();
  }

  Future<void> _fetchEvidence() async {
    if (mounted) {
      setState(() => _isLoadingEvidence = true);
    }
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.getReportEvidence(widget.reportId);
      if (mounted) {
        setState(() => _evidence = response.data);
      }
    } catch (e, stackTrace) {
      _log.severe('Failed to fetch evidence: $e', stackTrace);
    } finally {
      if (mounted) {
        setState(() => _isLoadingEvidence = false);
      }
    }
  }

  Future<void> _updateStatus(String status) async {
    if (mounted) {
      setState(() => _isUpdating = true);
    }
    try {
      final apiClient = ref.read(apiClientProvider);
      if (status == 'resolved') {
        await apiClient.lguResolveReport(widget.reportId);
      } else {
        await apiClient.updateReportStatus(widget.reportId, status);
      }
      
      // Refresh the report details and the global reports stream
      ref.invalidate(reportDetailsProvider(widget.reportId));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report marked as $status')),
        );
        if (status == 'invalid') {
          context.pop(); // Go back to the reports list if invalid
        }
      }
    } catch (e) {
      _log.severe('Failed to update status to $status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update report status')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(reportDetailsProvider(widget.reportId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
        elevation: 0,
      ),
      body: reportAsync.when(
        data: (report) => Stack(
          children: [
            ReportDetailsBody(
              report: report,
              evidence: _evidence,
              isLoadingEvidence: _isLoadingEvidence,
              isLoadingCleanupTask: false,
              isOfficerUser: false, // Don't show officer-specific UI
            ),
            if (_isUpdating)
              Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      bottomNavigationBar: reportAsync.whenOrNull(
        data: (report) {
          if (report.status.toLowerCase() == 'unresolved' || 
              report.status.toLowerCase() == 'in_progress') {
            return SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (report.status.toLowerCase() == 'unresolved') ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isUpdating ? null : () => _updateStatus('invalid'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: Colors.red),
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Mark Invalid'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isUpdating ? null : () => _updateStatus('in_progress'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Start Work'),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (report.status.toLowerCase() == 'in_progress') ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isUpdating ? null : () => _updateStatus('resolved'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Mark as Resolved'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}
