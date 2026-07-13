import 'package:ecopin_app/core/constants/app_constants.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/features/auth/providers/auth_notifier.dart';
import 'package:ecopin_app/features/reports/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/features/reports/presentation/widgets/report_details_widgets/report_details_body.dart';
import 'package:ecopin_app/features/reports/providers/report_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

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
  final Logger _log = Logger('Report Detail Screen');

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
      _log.fine('Evidence response: ${response.data}');
      setState(() => _evidence = response.data);
    } catch (e, stackTrace) {
      _log.severe('Failed to fetch evidence: $e', stackTrace);
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
    } catch (e, stackTrace) {
      _log.severe('Failed to fetch cleanup tasks: $e', stackTrace);
    } finally {
      setState(() => _isLoadingCleanupTask = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(reportDetailsProvider(widget.reportId));
    final authState = ref.watch(authNotifierProvider);
    final isLguUser = authState.state.role == UserRole.lgu;

    return Scaffold(
      appBar: AppBar(title: const Text('Report Details')),
      body: reportAsync.when(
        data: (report) => ReportDetailsBody(
          report: report,
          evidence: _evidence,
          isLoadingEvidence: _isLoadingEvidence,
          cleanupTask: _cleanupTask,
          isLoadingCleanupTask: _isLoadingCleanupTask,
          onFetchCleanupTask: report.clusterId != null
              ? () => _fetchCleanupTask(report.clusterId!)
              : null,
          isLguUser: isLguUser,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}