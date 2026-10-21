import 'package:flutter/material.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/fc_task_detail_presentation.dart';

class FcMarkCompleteButton extends StatefulWidget {
  const FcMarkCompleteButton({
    super.key,
    required this.task,
    required this.reports,
    required this.onComplete,
    this.isRefreshing = false,
  });
  final CleanupTask task;
  final List<ReportModel> reports;
  final Future<void> Function() onComplete;
  final bool isRefreshing;
  @override
  State<FcMarkCompleteButton> createState() => _FcMarkCompleteButtonState();
}

class _FcMarkCompleteButtonState extends State<FcMarkCompleteButton> {
  bool _saving = false;
  @override
  Widget build(BuildContext context) {
    final actor = Supabase.instance.client.auth.currentUser?.id;
    if (actor == null || !widget.task.assignedCrewIds.contains(actor)) {
      return const SizedBox.shrink();
    }
    final terminal = {
      'completed',
      'cancelled',
    }.contains(widget.task.status.toLowerCase());
    final canComplete =
        !terminal &&
        !widget.isRefreshing &&
        widget.reports.length == taskReportIds(widget.task).length &&
        widget.reports.every(reportIsHandled);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: canComplete && !_saving
              ? () async {
                  setState(() => _saving = true);
                  try {
                    await widget.onComplete();
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Completion could not be saved. Refresh the task and try again.',
                          ),
                        ),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    terminal
                        ? (widget.task.status == 'completed'
                              ? 'Task completed'
                              : 'Task cancelled')
                        : 'Mark task complete',
                  ),
          ),
        ),
        if (!terminal) ...[
          const SizedBox(height: 8),
          Text(
            canComplete
                ? 'Completion is saved locally, then checked by the server during sync.'
                : 'Handle every linked report before completing this task.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
