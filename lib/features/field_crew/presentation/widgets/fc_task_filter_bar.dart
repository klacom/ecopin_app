import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';

class FcTaskFilterBar extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final String statusFilter;
  final ValueChanged<String> onStatusChanged;
  final bool assignedToMeOnly;
  final ValueChanged<bool> onAssignmentChanged;
  final VoidCallback onReset;

  const FcTaskFilterBar({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.statusFilter,
    required this.onStatusChanged,
    required this.assignedToMeOnly,
    required this.onAssignmentChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final officerColor = AppColors.primaryDark;
    final fillColor = isDark ? AppColors.surfaceDark : Colors.grey.shade100;
    final textColor = isDark ? AppColors.textPrimaryDark : Colors.black87;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: onSearchChanged,
                style: AppTypography.body.copyWith(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  hintStyle: AppTypography.body.copyWith(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: fillColor,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppColors.radiusInput),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppColors.spaceSM),
            IconButton(
              tooltip: 'Filter cleanup tasks',
              onPressed: () {
                _showFilterBottomSheet(context);
              },
              icon: Icon(Icons.filter_list, color: officerColor),
              style: IconButton.styleFrom(
                backgroundColor: fillColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppColors.radiusInput),
                ),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppColors.spaceSM),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (searchQuery.isNotEmpty ||
                  statusFilter != 'All' ||
                  assignedToMeOnly)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    label: const Text(
                      'Reset',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: officerColor,
                    onPressed: onReset,
                  ),
                ),
              if (statusFilter != 'All')
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Chip(
                    label: Text(
                      statusFilter,
                      style: TextStyle(color: textColor),
                    ),
                    backgroundColor: fillColor,
                    side: BorderSide(color: officerColor),
                    onDeleted: () => onStatusChanged('All'),
                    deleteIconColor: officerColor,
                  ),
                ),
              if (assignedToMeOnly)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Chip(
                    label: Text(
                      'Assigned to Me',
                      style: TextStyle(color: textColor),
                    ),
                    backgroundColor: fillColor,
                    side: BorderSide(color: officerColor),
                    onDeleted: () => onAssignmentChanged(false),
                    deleteIconColor: officerColor,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    String tempStatus = statusFilter;
    bool tempAssigned = assignedToMeOnly;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final officerColor = AppColors.primaryDark;
    final fillColor = isDark ? AppColors.surfaceDark : Colors.grey.shade100;
    final textColor = isDark ? AppColors.textPrimaryDark : Colors.black87;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppColors.radiusDialog),
        ),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppColors.spaceLG,
                  12,
                  AppColors.spaceLG,
                  16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filters',
                      style: AppTypography.h4.copyWith(color: textColor),
                    ),
                    const SizedBox(height: AppColors.spaceLG),
                    Text(
                      'Status',
                      style: AppTypography.label.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: AppColors.spaceSM),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['All', 'Pending', 'In Progress', 'Completed']
                          .map((status) {
                            final isSelected = tempStatus == status;
                            return ChoiceChip(
                              label: Text(
                                status,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : textColor,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: officerColor,
                              checkmarkColor: Colors.white,
                              backgroundColor: fillColor,
                              onSelected: (val) {
                                if (val) {
                                  setModalState(() {
                                    tempStatus = status;
                                  });
                                }
                              },
                            );
                          })
                          .toList(),
                    ),
                    const SizedBox(height: AppColors.spaceLG),
                    Text(
                      'Assignment',
                      style: AppTypography.label.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: AppColors.spaceSM),
                    SwitchListTile(
                      title: Text(
                        'Assigned to Me Only',
                        style: AppTypography.body.copyWith(color: textColor),
                      ),
                      value: tempAssigned,
                      activeTrackColor: officerColor.withValues(alpha: 0.5),
                      activeThumbColor: officerColor,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setModalState(() {
                          tempAssigned = val;
                        });
                      },
                    ),
                    const SizedBox(height: AppColors.spaceXL),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          onStatusChanged(tempStatus);
                          onAssignmentChanged(tempAssigned);
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: officerColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppColors.radiusButton,
                            ),
                          ),
                        ),
                        child: Text(
                          'Apply Filters',
                          style: AppTypography.button.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
