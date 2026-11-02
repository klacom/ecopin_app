import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/report_details_widgets/report_details_body.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/report_details_widgets/report_share_helper.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/report_details_widgets/report_share_button.dart';
import 'package:ecopin_app/shared/reports/providers/report_provider.dart';
import 'package:ecopin_app/shared/screens/no_internet_screen.dart';
import 'package:flutter/material.dart';
import 'package:ecopin_app/shared/support/official_contacts_screen.dart';
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
  bool _evidenceFailed = false;
  int _proofRevision = 0;
  int _evidenceRequest = 0;
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

  @override
  void didUpdateWidget(covariant ReportDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reportId != widget.reportId) {
      _evidence = [];
      _proofRevision++;
      _fetchEvidence();
    }
  }

  Future<void> _onRefresh() async {
    ref.invalidate(reportDetailsProvider(widget.reportId));
    await _fetchEvidence();
    if (mounted) {
      setState(() => _proofRevision++);
      _refreshController.refreshCompleted();
    }
  }

  Future<void> _fetchEvidence() async {
    final request = ++_evidenceRequest;
    final reportId = widget.reportId;
    if (mounted) {
      setState(() {
        _isLoadingEvidence = true;
        _evidenceFailed = false;
      });
    }
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.getReportEvidence(reportId);
      if (mounted &&
          request == _evidenceRequest &&
          reportId == widget.reportId) {
        setState(() => _evidence = response.data);
      }
    } catch (e, stackTrace) {
      if (mounted && request == _evidenceRequest) {
        setState(() => _evidenceFailed = true);
      }
      _log.severe('Failed to fetch evidence: $e', stackTrace);
    } finally {
      if (mounted && request == _evidenceRequest) {
        setState(() => _isLoadingEvidence = false);
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
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: MediaQuery.textScalerOf(context).scale(20) > 26
            ? 112
            : 64,
        title: const Text(
          'Report details',
          maxLines: 2,
          textAlign: TextAlign.center,
        ),
        actions: [
          const OfficialContactsButton(),
          reportAsync.maybeWhen(
            data: (report) {
              final isRejected =
                  report.status.toLowerCase() == 'rejected' ||
                  report.validationStatus.toLowerCase() == 'rejected';
              final submitted = _evidence.whereType<Map>().firstOrNull;
              final photoUrl = submitted?['url'] ?? submitted?['file_url'];

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isRejected && photoUrl is String && photoUrl.isNotEmpty)
                    ReportShareButton(
                      onShare: () => ReportShareHelper.shareReportPhoto(
                        report: report,
                        photoUrl: photoUrl,
                        isVideo: submitted?['resource_type'] == 'video',
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
            final canWithdraw = isOwner && report.canBeWithdrawn;

            return ReportDetailsBody(
              report: report,
              evidence: _evidence,
              isLoadingEvidence: _isLoadingEvidence,
              evidenceFailed: _evidenceFailed,
              onRetryEvidence: _fetchEvidence,
              isOwner: isOwner,
              proofRevision: _proofRevision,
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
