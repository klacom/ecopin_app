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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: onSearchChanged,
                style: AppTypography.body.copyWith(color: AppColors.textPrimaryDark),
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  hintStyle: AppTypography.body.copyWith(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: AppColors.surfaceDark,
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
              onPressed: () {
                _showFilterBottomSheet(context);
              },
              icon: const Icon(Icons.filter_list, color: AppColors.primaryDark),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppColors.radiusInput)),
                padding: const EdgeInsets.all(12),
              ),
            )
          ],
        ),
        const SizedBox(height: AppColors.spaceSM),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (searchQuery.isNotEmpty || statusFilter != 'All' || assignedToMeOnly)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    label: const Text('Reset', style: TextStyle(color: AppColors.backgroundDark)),
                    backgroundColor: AppColors.primaryDark,
                    onPressed: onReset,
                  ),
                ),
              if (statusFilter != 'All')
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Chip(
                    label: Text(statusFilter, style: const TextStyle(color: AppColors.textPrimaryDark)),
                    backgroundColor: AppColors.surfaceDark,
                    side: const BorderSide(color: AppColors.primaryDark),
                    onDeleted: () => onStatusChanged('All'),
                    deleteIconColor: AppColors.primaryDark,
                  ),
                ),
              if (assignedToMeOnly)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Chip(
                    label: const Text('Assigned to Me', style: TextStyle(color: AppColors.textPrimaryDark)),
                    backgroundColor: AppColors.surfaceDark,
                    side: const BorderSide(color: AppColors.primaryDark),
                    onDeleted: () => onAssignmentChanged(false),
                    deleteIconColor: AppColors.primaryDark,
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

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppColors.radiusDialog)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(AppColors.spaceLG),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filters', style: AppTypography.h4.copyWith(color: AppColors.textPrimaryDark)),
                  const SizedBox(height: AppColors.spaceLG),
                  Text('Status', style: AppTypography.label.copyWith(color: Colors.grey)),
                  const SizedBox(height: AppColors.spaceSM),
                  Wrap(
                    spacing: 8,
                    children: ['All', 'Pending', 'In Progress', 'Completed'].map((status) {
                      final isSelected = tempStatus == status;
                      return ChoiceChip(
                        label: Text(status, style: TextStyle(color: isSelected ? AppColors.backgroundDark : AppColors.textPrimaryDark)),
                        selected: isSelected,
                        selectedColor: AppColors.primaryDark,
                        backgroundColor: AppColors.surfaceDark,
                        onSelected: (val) {
                          if (val) {
                            setModalState(() {
                              tempStatus = status;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppColors.spaceLG),
                  Text('Assignment', style: AppTypography.label.copyWith(color: Colors.grey)),
                  const SizedBox(height: AppColors.spaceSM),
                  SwitchListTile(
                    title: Text('Assigned to Me Only', style: AppTypography.body.copyWith(color: AppColors.textPrimaryDark)),
                    value: tempAssigned,
                    activeTrackColor: AppColors.primaryDark.withValues(alpha: 0.5),
                    activeThumbColor: AppColors.primaryDark,
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
                        backgroundColor: AppColors.primaryDark,
                        foregroundColor: AppColors.backgroundDark,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppColors.radiusButton)),
                      ),
                      child: Text('Apply Filters', style: AppTypography.button.copyWith(color: AppColors.backgroundDark)),
                    ),
                  )
                ],
              ),
            );
          }
        );
      },
    );
  }
}
