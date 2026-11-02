import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import '../controllers/fc_report_detail_presentation.dart';

/// Pinned action for the report, one at a time: Mark as acknowledged, then
/// Complete report. The line above the button is the hint or the one thing
/// still missing. A finished report shows its state and, when there is one,
/// the way to the next report in the job.
class FcReportActionBar extends StatefulWidget {
  const FcReportActionBar({
    super.key,
    required this.stage,
    required this.hint,
    required this.blocker,
    required this.onStatusChange,
    this.onOpenNext,
    this.onBackToJob,
  });
  final CrewReportStage stage;

  /// Shown above Mark as acknowledged.
  final String hint;

  /// Why Complete report is not available yet; null when it is.
  final String? blocker;
  final Future<void> Function(String newStatus) onStatusChange;
  final VoidCallback? onOpenNext, onBackToJob;

  @override
  State<FcReportActionBar> createState() => _FcReportActionBarState();
}

class _FcReportActionBarState extends State<FcReportActionBar> {
  bool _saving = false;

  Future<void> _run(String status) async {
    setState(() => _saving = true);
    try {
      await widget.onStatusChange(status);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quiet = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final Widget content = switch (widget.stage) {
      CrewReportStage.toAcknowledge => _action(
        widget.hint,
        'Mark as acknowledged',
        Icons.check_rounded,
        () => _run('acknowledged'),
      ),
      CrewReportStage.inProgress => _action(
        widget.blocker ??
            'Saved on this phone first, then sent when you have signal',
        'Complete report',
        Icons.check_rounded,
        widget.blocker == null ? () => _run('resolved') : null,
      ),
      CrewReportStage.completed => _finished(
        'Report completed. Waiting for the citizen to close it.',
      ),
      CrewReportStage.closed => _finished('Report closed.'),
      CrewReportStage.rejected => Text(
        'This report was rejected.',
        textAlign: TextAlign.center,
        style: quiet,
      ),
      CrewReportStage.unknown => Text(
        'Status unavailable. Refresh the report.',
        textAlign: TextAlign.center,
        style: quiet,
      ),
    };
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        side: BorderSide(color: theme.dividerTheme.color ?? theme.dividerColor),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: content,
        ),
      ),
    );
  }

  Widget _action(
    String line,
    String label,
    IconData icon,
    VoidCallback? onPressed,
  ) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          line,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        AppButton(
          text: label,
          icon: icon,
          isLoading: _saving,
          onPressed: onPressed,
        ),
      ],
    );
  }

  Widget _finished(String line) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.check_circle_outline,
                color:
                    theme.extension<AppStatusColors>()?.success ??
                    theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                line,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (widget.onOpenNext != null) ...[
          const SizedBox(height: 8),
          AppButton(
            text: 'Open next report',
            icon: Icons.arrow_forward_rounded,
            onPressed: widget.onOpenNext,
          ),
        ] else if (widget.onBackToJob != null) ...[
          const SizedBox(height: 8),
          AppButton(
            text: 'Back to job',
            variant: ButtonVariant.secondary,
            onPressed: widget.onBackToJob,
          ),
        ],
      ],
    );
  }
}
