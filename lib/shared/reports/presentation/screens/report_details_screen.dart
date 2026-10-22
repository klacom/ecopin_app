import 'package:ecopin_app/core/constants/app_constants.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/shared/auth/providers/auth_notifier.dart';
import 'package:ecopin_app/shared/reports/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/report_details_widgets/report_details_body.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/report_details_widgets/report_share_helper.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/report_details_widgets/report_share_button.dart';
import 'package:ecopin_app/shared/reports/providers/report_provider.dart';
import 'package:ecopin_app/shared/screens/no_internet_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart' as pull_refresh;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart' as dio;
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';

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
  final pull_refresh.RefreshController _refreshController =
      pull_refresh.RefreshController(initialRefresh: false);

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchEvidence();
  }

  Future<void> _onRefresh() async {
    ref.invalidate(reportDetailsProvider(widget.reportId));
    await _fetchEvidence();
    _refreshController.refreshCompleted();
  }

  Future<void> _fetchEvidence() async {
    if (mounted) {
      setState(() => _isLoadingEvidence = true);
    }
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.getReportEvidence(widget.reportId);
      _log.fine('Evidence response: ${response.data}');
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

  Future<void> _fetchCleanupTask(String clusterId) async {
    if (mounted) {
      setState(() => _isLoadingCleanupTask = true);
    }
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.getCleanupTasksByCluster(clusterId);

      if (response.data != null && response.data is List) {
        final List<CleanupTaskModel> tasks = (response.data as List)
            .map((taskJson) => CleanupTaskModel.fromJson(taskJson))
            .toList();

        if (mounted && tasks.isNotEmpty) {
          setState(() {
            _cleanupTask = tasks.first;
          });
        }
      }
    } catch (e, stackTrace) {
      _log.severe('Failed to fetch cleanup tasks: $e', stackTrace);
    } finally {
      if (mounted) {
        setState(() => _isLoadingCleanupTask = false);
      }
    }
  }

  Future<void> _handleWithdrawReport(ReportModel report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw report?'),
        content: const Text(
          'Are you sure you want to withdraw this report? It will be removed from your reports and the map. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final dataSource = ref.read(reportDataSourceProvider);
      await dataSource.withdrawReport(report.id);

      ref.invalidate(myReportsProvider);
      ref.invalidate(publicReportsProvider);
      ref.invalidate(reportDetailsProvider(report.id));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report withdrawn successfully.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      String msg = 'Failed to withdraw report. Please try again.';
      if (e is dio.DioException) {
        final resData = e.response?.data;
        if (resData is Map) {
          if (resData['message'] != null) {
            msg = resData['message'].toString();
          } else if (resData['error'] != null) {
            msg = resData['error'].toString();
          }
        } else if (resData is String && resData.trim().isNotEmpty) {
          msg = resData.trim();
        } else if (e.message != null && e.message!.isNotEmpty) {
          msg = e.message!;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(reportDetailsProvider(widget.reportId));
    final authState = ref.watch(authNotifierProvider);
    final isOfficerUser = authState.state.role == UserRole.officer;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
        actions: [
          reportAsync.maybeWhen(
            data: (report) {
              final isOwner =
                  currentUserId != null &&
                  report.userId != null &&
                  report.userId == currentUserId;
              final canWithdraw =
                  !isOfficerUser && isOwner && report.canBeWithdrawn;

              final isRejected =
                  report.status.toLowerCase() == 'rejected' ||
                  report.validationStatus.toLowerCase() == 'rejected';
              final photoUrl =
                  report.beforePhotoUrl ??
                  (_evidence.isNotEmpty
                      ? _evidence.first['url'] ?? _evidence.first['file_url']
                      : null);

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canWithdraw)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Withdraw report',
                      onPressed: () => _handleWithdrawReport(report),
                    ),
                  if (!isRejected)
                    ReportShareButton(
                      onShare: () => ReportShareHelper.shareReportPhoto(
                        report: report,
                        photoUrl: photoUrl,
                        isVideo:
                            report.beforePhotoUrl == null &&
                            _evidence.isNotEmpty &&
                            _evidence.first['resource_type'] == 'video',
                      ),
                    ),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: pull_refresh.SmartRefresher(
        controller: _refreshController,
        onRefresh: _onRefresh,
        enablePullDown: true,
        child: reportAsync.when(
          data: (report) {
            final isOwner =
                currentUserId != null &&
                report.userId != null &&
                report.userId == currentUserId;
            final canWithdraw =
                !isOfficerUser && isOwner && report.canBeWithdrawn;

            return ReportDetailsBody(
              report: report,
              evidence: _evidence,
              isLoadingEvidence: _isLoadingEvidence,
              cleanupTask: _cleanupTask,
              isLoadingCleanupTask: _isLoadingCleanupTask,
              onFetchCleanupTask: report.clusterId != null
                  ? () => _fetchCleanupTask(report.clusterId!)
                  : null,
              isOfficerUser: isOfficerUser,
              onWithdraw: canWithdraw
                  ? () => _handleWithdrawReport(report)
                  : null,
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => NoInternetScreen(
            onRetry: () =>
                ref.invalidate(reportDetailsProvider(widget.reportId)),
          ),
        ),
      ),
    );
  }
}
