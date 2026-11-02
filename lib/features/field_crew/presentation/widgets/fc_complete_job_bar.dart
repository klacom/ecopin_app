import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';

/// Pinned “Complete job” action with the one thing still missing written above
/// it. [blocker] comes from the existing completion rules; the button is
/// available only when it is null. A finished job shows its state instead.
class FcCompleteJobBar extends StatefulWidget {
  const FcCompleteJobBar({
    super.key,
    required this.blocker,
    required this.onComplete,
    this.finishedLabel,
  });
  final String? blocker;
  final Future<void> Function() onComplete;

  /// Set for completed or cancelled jobs (“Job completed”).
  final String? finishedLabel;

  @override
  State<FcCompleteJobBar> createState() => _FcCompleteJobBarState();
}

class _FcCompleteJobBarState extends State<FcCompleteJobBar> {
  bool _saving = false;

  Future<void> _complete() async {
    setState(() => _saving = true);
    try {
      await widget.onComplete();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Completion could not be saved. Refresh the job and try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finished = widget.finishedLabel;
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
          child: finished != null
              ? Row(
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
                        finished,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.blocker ??
                          'Saved on this phone first, then sent when you have signal',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppButton(
                      text: 'Complete job',
                      icon: Icons.check_rounded,
                      isLoading: _saving,
                      onPressed: widget.blocker == null ? _complete : null,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
