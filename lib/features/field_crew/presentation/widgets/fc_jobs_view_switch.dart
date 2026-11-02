import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import '../controllers/fc_tasks_presentation.dart';
import 'fc_offline_ui.dart';

/// Two large choices, “To do” and “Done”, each with a count. It replaces the
/// filter sheet so the crew's first question (“what is left?”) is one tap.
class FcJobsViewSwitch extends StatelessWidget {
  const FcJobsViewSwitch({
    super.key,
    required this.view,
    required this.todoCount,
    required this.doneCount,
    required this.onChanged,
    this.leftLabel = 'To do',
    this.rightLabel = 'Done',
    this.noun = 'job',
  });

  /// Labels default to the Jobs tab wording; task details reuse the switch as
  /// “To handle” / “Handled” for reports.
  final String leftLabel, rightLabel, noun;
  final CrewJobView view;
  final int todoCount, doneCount;
  final ValueChanged<CrewJobView> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget option(CrewJobView value, String label, int count) {
      final selected = view == value;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          label: '$label, $count ${count == 1 ? noun : '${noun}s'}',
          excludeSemantics: true,
          child: Material(
            color: selected ? theme.colorScheme.surface : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppColors.radiusChip),
              side: BorderSide(
                color: selected ? fcAccent(context) : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppColors.radiusChip),
              onTap: selected ? null : () => onChanged(value),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Text(
                      '$label · $count',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? fcAccent(context)
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? AppColors.quietSurfaceDark
            : AppColors.quietSurfaceLight,
        border: Border.all(
          color: theme.dividerTheme.color ?? theme.dividerColor,
        ),
        borderRadius: BorderRadius.circular(AppColors.radiusChip),
      ),
      child: Row(
        children: [
          option(CrewJobView.todo, leftLabel, todoCount),
          option(CrewJobView.done, rightLabel, doneCount),
        ],
      ),
    );
  }
}
