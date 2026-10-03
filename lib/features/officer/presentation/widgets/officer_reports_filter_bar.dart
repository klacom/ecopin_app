import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';

class OfficerReportsFilterBar extends StatelessWidget {
  final String searchQuery;
  final String selectedStatus;
  final String selectedType;
  final String selectedValidation;
  final String selectedLifecycle;
  final String selectedSort;
  final List<String> availableTypes;
  final Function(String) onSearchChanged;
  final Function(String) onStatusChanged;
  final Function(String) onTypeChanged;
  final Function(String) onValidationChanged;
  final Function(String) onLifecycleChanged;
  final Function(String) onSortChanged;
  final VoidCallback onReset;

  const OfficerReportsFilterBar({
    super.key,
    required this.searchQuery,
    required this.selectedStatus,
    required this.selectedType,
    required this.selectedValidation,
    required this.selectedLifecycle,
    required this.selectedSort,
    required this.availableTypes,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onTypeChanged,
    required this.onValidationChanged,
    required this.onLifecycleChanged,
    required this.onSortChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    // For officer, we ensure the color is the primary blue.
    // In our theme, AppColors.primaryDark is 0xFF0052CC (Blue).
    const Color officerColor = AppColors.primaryDark;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                  hintText: 'Search reports...',
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
              onPressed: () {
                _showFilterBottomSheet(context, officerColor, isDark, fillColor, textColor);
              },
              icon: const Icon(Icons.filter_list, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: officerColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.radiusInput)),
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
              if (searchQuery.isNotEmpty ||
                  selectedStatus != 'all' ||
                  selectedType != 'all' ||
                  selectedValidation != 'all' ||
                  selectedLifecycle != 'all' ||
                  selectedSort != 'newest')
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    label: const Text('Reset',
                        style: TextStyle(color: Colors.white)),
                    backgroundColor: officerColor,
                    onPressed: onReset,
                  ),
                ),
              if (selectedStatus != 'all')
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Chip(
                    label: Text(_formatDisplay(selectedStatus),
                        style: TextStyle(color: textColor)),
                    backgroundColor: fillColor,
                    side: const BorderSide(color: officerColor),
                    onDeleted: () => onStatusChanged('all'),
                    deleteIconColor: officerColor,
                  ),
                ),
              if (selectedType != 'all')
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Chip(
                    label: Text(_formatDisplay(selectedType),
                        style: TextStyle(color: textColor)),
                    backgroundColor: fillColor,
                    side: const BorderSide(color: officerColor),
                    onDeleted: () => onTypeChanged('all'),
                    deleteIconColor: officerColor,
                  ),
                ),
              if (selectedValidation != 'all')
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Chip(
                    label: Text(_formatDisplay(selectedValidation),
                        style: TextStyle(color: textColor)),
                    backgroundColor: fillColor,
                    side: const BorderSide(color: officerColor),
                    onDeleted: () => onValidationChanged('all'),
                    deleteIconColor: officerColor,
                  ),
                ),
              if (selectedLifecycle != 'all')
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Chip(
                    label: Text(_formatDisplay(selectedLifecycle),
                        style: TextStyle(color: textColor)),
                    backgroundColor: fillColor,
                    side: const BorderSide(color: officerColor),
                    onDeleted: () => onLifecycleChanged('all'),
                    deleteIconColor: officerColor,
                  ),
                ),
              if (selectedSort != 'newest')
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Chip(
                    label: Text(_formatDisplay(selectedSort),
                        style: TextStyle(color: textColor)),
                    backgroundColor: fillColor,
                    side: const BorderSide(color: officerColor),
                    onDeleted: () => onSortChanged('newest'),
                    deleteIconColor: officerColor,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showFilterBottomSheet(BuildContext context, Color officerColor, bool isDark, Color fillColor, Color textColor) {
    String tempStatus = selectedStatus;
    String tempType = selectedType;
    String tempValidation = selectedValidation;
    String tempLifecycle = selectedLifecycle;
    String tempSort = selectedSort;

    final statusOptions = ['all', 'unresolved', 'in_progress', 'resolved', 'closed'];
    final validationOptions = ['all', 'pending', 'automatically_valid', 'manual_review', 'rejected'];
    final lifecycleOptions = ['all', 'reported', 'acknowledged', 'in_progress', 'resolved', 'closed'];
    final sortOptions = ['newest', 'oldest'];

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppColors.radiusDialog)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (ctx, setModalState) {
                return Padding(
                  padding: const EdgeInsets.all(AppColors.spaceLG),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Filters',
                          style: AppTypography.h4.copyWith(color: textColor)),
                      const SizedBox(height: AppColors.spaceLG),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            Text('Status',
                                style: AppTypography.label.copyWith(color: Colors.grey)),
                            const SizedBox(height: AppColors.spaceSM),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: statusOptions.map((status) {
                                final isSelected = tempStatus == status;
                                return ChoiceChip(
                                  label: Text(_formatDisplay(status),
                                      style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : textColor)),
                                  selected: isSelected,
                                  selectedColor: officerColor,
                                  backgroundColor: fillColor,
                                  onSelected: (val) {
                                    if (val) setModalState(() => tempStatus = status);
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: AppColors.spaceLG),
                            Text('Issue Type',
                                style: AppTypography.label.copyWith(color: Colors.grey)),
                            const SizedBox(height: AppColors.spaceSM),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: ['all', ...availableTypes].map((type) {
                                final isSelected = tempType == type;
                                return ChoiceChip(
                                  label: Text(_formatDisplay(type),
                                      style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : textColor)),
                                  selected: isSelected,
                                  selectedColor: officerColor,
                                  backgroundColor: fillColor,
                                  onSelected: (val) {
                                    if (val) setModalState(() => tempType = type);
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: AppColors.spaceLG),
                            Text('Validation',
                                style: AppTypography.label.copyWith(color: Colors.grey)),
                            const SizedBox(height: AppColors.spaceSM),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: validationOptions.map((valOpt) {
                                final isSelected = tempValidation == valOpt;
                                return ChoiceChip(
                                  label: Text(_formatDisplay(valOpt),
                                      style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : textColor)),
                                  selected: isSelected,
                                  selectedColor: officerColor,
                                  backgroundColor: fillColor,
                                  onSelected: (val) {
                                    if (val) {
                                      setModalState(() => tempValidation = valOpt);
                                    }
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: AppColors.spaceLG),
                            Text('Lifecycle',
                                style: AppTypography.label.copyWith(color: Colors.grey)),
                            const SizedBox(height: AppColors.spaceSM),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: lifecycleOptions.map((lifeOpt) {
                                final isSelected = tempLifecycle == lifeOpt;
                                return ChoiceChip(
                                  label: Text(_formatDisplay(lifeOpt),
                                      style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : textColor)),
                                  selected: isSelected,
                                  selectedColor: officerColor,
                                  backgroundColor: fillColor,
                                  onSelected: (val) {
                                    if (val) {
                                      setModalState(() => tempLifecycle = lifeOpt);
                                    }
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: AppColors.spaceLG),
                            Text('Sort By',
                                style: AppTypography.label.copyWith(color: Colors.grey)),
                            const SizedBox(height: AppColors.spaceSM),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: sortOptions.map((sortOpt) {
                                final isSelected = tempSort == sortOpt;
                                return ChoiceChip(
                                  label: Text(_formatDisplay(sortOpt),
                                      style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : textColor)),
                                  selected: isSelected,
                                  selectedColor: officerColor,
                                  backgroundColor: fillColor,
                                  onSelected: (val) {
                                    if (val) {
                                      setModalState(() => tempSort = sortOpt);
                                    }
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppColors.spaceLG),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            onStatusChanged(tempStatus);
                            onTypeChanged(tempType);
                            onValidationChanged(tempValidation);
                            onLifecycleChanged(tempLifecycle);
                            onSortChanged(tempSort);
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: officerColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppColors.radiusButton)),
                          ),
                          child: Text('Apply Filters',
                              style: AppTypography.button.copyWith(color: Colors.white)),
                        ),
                      )
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatDisplay(String key) {
    if (key.toLowerCase() == 'all') return 'All';
    switch (key) {
      case 'unresolved':
        return 'Unresolved';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      case 'pending':
        return 'Pending';
      case 'automatically_valid':
        return 'Auto Valid';
      case 'manual_review':
        return 'Manual Review';
      case 'rejected':
        return 'Rejected';
      case 'reported':
        return 'Reported';
      case 'acknowledged':
        return 'Acknowledged';
      case 'newest':
        return 'Newest First';
      case 'oldest':
        return 'Oldest First';
      case 'Waste':
        return 'Waste';
      case 'Flooding':
        return 'Flooding';
      case 'Pollution':
        return 'Pollution';
      case 'Illegal Logging':
        return 'Illegal Logging';
      case 'Others':
        return 'Others';
      default:
        return key;
    }
  }
}
