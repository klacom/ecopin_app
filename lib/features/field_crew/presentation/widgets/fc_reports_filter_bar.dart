import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';

class FcReportsFilterBar extends StatelessWidget {
  final String searchQuery;
  final String selectedStatus;
  final String selectedType;
  final String selectedValidation;
  final List<String> availableTypes;
  final Function(String) onSearchChanged;
  final Function(String) onStatusChanged;
  final Function(String) onTypeChanged;
  final Function(String) onValidationChanged;
  final VoidCallback onReset;

  const FcReportsFilterBar({
    super.key,
    required this.searchQuery,
    required this.selectedStatus,
    required this.selectedType,
    required this.selectedValidation,
    required this.availableTypes,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onTypeChanged,
    required this.onValidationChanged,
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
                  hintText: 'Search reports...',
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
              if (searchQuery.isNotEmpty || selectedStatus != 'All Status' || selectedType != 'All Types' || selectedValidation != 'All Validation')
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    label: const Text('Reset', style: TextStyle(color: AppColors.backgroundDark)),
                    backgroundColor: AppColors.primaryDark,
                    onPressed: onReset,
                  ),
                ),
              if (selectedStatus != 'All Status')
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Chip(
                    label: Text(_formatDisplay(selectedStatus), style: const TextStyle(color: AppColors.textPrimaryDark)),
                    backgroundColor: AppColors.surfaceDark,
                    side: const BorderSide(color: AppColors.primaryDark),
                    onDeleted: () => onStatusChanged('All Status'),
                    deleteIconColor: AppColors.primaryDark,
                  ),
                ),
              if (selectedType != 'All Types')
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Chip(
                    label: Text(selectedType, style: const TextStyle(color: AppColors.textPrimaryDark)),
                    backgroundColor: AppColors.surfaceDark,
                    side: const BorderSide(color: AppColors.primaryDark),
                    onDeleted: () => onTypeChanged('All Types'),
                    deleteIconColor: AppColors.primaryDark,
                  ),
                ),
              if (selectedValidation != 'All Validation')
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Chip(
                    label: Text(_formatDisplay(selectedValidation), style: const TextStyle(color: AppColors.textPrimaryDark)),
                    backgroundColor: AppColors.surfaceDark,
                    side: const BorderSide(color: AppColors.primaryDark),
                    onDeleted: () => onValidationChanged('All Validation'),
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
    String tempStatus = selectedStatus;
    String tempType = selectedType;
    String tempValidation = selectedValidation;

    final statusOptions = [
      'All Status', 'unresolved', 'in_progress', 'resolved', 'closed', 'pending_owner_consent', 'waiting_for_feedback'
    ];
    
    final validationOptions = [
      'All Validation', 'pending', 'automatically_valid', 'manual_review', 'validated', 'rejected'
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppColors.radiusDialog)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
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
                      Text('Filters', style: AppTypography.h4.copyWith(color: AppColors.textPrimaryDark)),
                      const SizedBox(height: AppColors.spaceLG),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            Text('Status', style: AppTypography.label.copyWith(color: Colors.grey)),
                            const SizedBox(height: AppColors.spaceSM),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: statusOptions.map((status) {
                                final isSelected = tempStatus == status;
                                return ChoiceChip(
                                  label: Text(_formatDisplay(status), style: TextStyle(color: isSelected ? AppColors.backgroundDark : AppColors.textPrimaryDark)),
                                  selected: isSelected,
                                  selectedColor: AppColors.primaryDark,
                                  backgroundColor: AppColors.surfaceDark,
                                  onSelected: (val) {
                                    if (val) setModalState(() => tempStatus = status);
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: AppColors.spaceLG),
                            Text('Issue Type', style: AppTypography.label.copyWith(color: Colors.grey)),
                            const SizedBox(height: AppColors.spaceSM),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: ['All Types', ...availableTypes].map((type) {
                                final isSelected = tempType == type;
                                return ChoiceChip(
                                  label: Text(type, style: TextStyle(color: isSelected ? AppColors.backgroundDark : AppColors.textPrimaryDark)),
                                  selected: isSelected,
                                  selectedColor: AppColors.primaryDark,
                                  backgroundColor: AppColors.surfaceDark,
                                  onSelected: (val) {
                                    if (val) setModalState(() => tempType = type);
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: AppColors.spaceLG),
                            Text('Validation', style: AppTypography.label.copyWith(color: Colors.grey)),
                            const SizedBox(height: AppColors.spaceSM),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: validationOptions.map((valOpt) {
                                final isSelected = tempValidation == valOpt;
                                return ChoiceChip(
                                  label: Text(_formatDisplay(valOpt), style: TextStyle(color: isSelected ? AppColors.backgroundDark : AppColors.textPrimaryDark)),
                                  selected: isSelected,
                                  selectedColor: AppColors.primaryDark,
                                  backgroundColor: AppColors.surfaceDark,
                                  onSelected: (val) {
                                    if (val) setModalState(() => tempValidation = valOpt);
                                  },
                                );
                              }).toList(),
                            ),
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
          }
        );
      },
    );
  }

  String _formatDisplay(String key) {
    switch (key) {
      case 'unresolved': return 'Unresolved';
      case 'in_progress': return 'In Progress';
      case 'resolved': return 'Resolved';
      case 'closed': return 'Closed';
      case 'pending_owner_consent': return 'Pending Owner Consent';
      case 'waiting_for_feedback': return 'Waiting for Feedback';
      case 'pending': return 'Pending';
      case 'automatically_valid': return 'Automatically Valid';
      case 'manual_review': return 'Manual Review';
      case 'validated': return 'Validated';
      case 'rejected': return 'Rejected';
      default: return key;
    }
  }
}
