import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';

class FcReportsFilterBar extends StatefulWidget {
  final String searchQuery;
  final String selectedStatus;
  final String selectedType;
  final String selectedValidation;
  final String selectedDeadline;
  final List<String> availableTypes;
  final Function(String) onSearchChanged;
  final Function(String) onStatusChanged;
  final Function(String) onTypeChanged;
  final Function(String) onValidationChanged;
  final Function(String) onDeadlineChanged;
  final VoidCallback onReset;

  const FcReportsFilterBar({
    super.key,
    required this.searchQuery,
    required this.selectedStatus,
    required this.selectedType,
    required this.selectedValidation,
    required this.selectedDeadline,
    required this.availableTypes,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onTypeChanged,
    required this.onValidationChanged,
    required this.onDeadlineChanged,
    required this.onReset,
  });

  /// Deadline filter values (labels double as the stored selection).
  static const deadlineOptions = ['All deadlines', 'At risk', 'Overdue'];

  @override
  State<FcReportsFilterBar> createState() => _FcReportsFilterBarState();
}

class _FcReportsFilterBarState extends State<FcReportsFilterBar> {
  late final TextEditingController _search = TextEditingController(
    text: widget.searchQuery,
  );

  @override
  void didUpdateWidget(FcReportsFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset (or any parent change) must clear the visible search text too.
    if (widget.searchQuery != _search.text) {
      _search.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _anyFilterActive =>
      widget.searchQuery.isNotEmpty ||
      widget.selectedStatus != 'All Status' ||
      widget.selectedType != 'All Types' ||
      widget.selectedValidation != 'All Validation' ||
      widget.selectedDeadline != 'All deadlines';

  @override
  Widget build(BuildContext context) {
    final selectedStatus = widget.selectedStatus;
    final selectedType = widget.selectedType;
    final selectedValidation = widget.selectedValidation;
    final selectedDeadline = widget.selectedDeadline;
    final onSearchChanged = widget.onSearchChanged;
    final onStatusChanged = widget.onStatusChanged;
    final onTypeChanged = widget.onTypeChanged;
    final onValidationChanged = widget.onValidationChanged;
    final onDeadlineChanged = widget.onDeadlineChanged;
    final onReset = widget.onReset;
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
                controller: _search,
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
              tooltip: 'Filter reports',
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
              if (_anyFilterActive)
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
              if (selectedStatus != 'All Status')
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Chip(
                    label: Text(
                      _formatDisplay(selectedStatus),
                      style: TextStyle(color: textColor),
                    ),
                    backgroundColor: fillColor,
                    side: BorderSide(color: officerColor),
                    onDeleted: () => onStatusChanged('All Status'),
                    deleteIconColor: officerColor,
                  ),
                ),
              if (selectedType != 'All Types')
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Chip(
                    label: Text(
                      selectedType,
                      style: TextStyle(color: textColor),
                    ),
                    backgroundColor: fillColor,
                    side: BorderSide(color: officerColor),
                    onDeleted: () => onTypeChanged('All Types'),
                    deleteIconColor: officerColor,
                  ),
                ),
              if (selectedDeadline != 'All deadlines')
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Chip(
                    label: Text(
                      selectedDeadline,
                      style: TextStyle(color: textColor),
                    ),
                    backgroundColor: fillColor,
                    side: BorderSide(color: officerColor),
                    onDeleted: () => onDeadlineChanged('All deadlines'),
                    deleteIconColor: officerColor,
                  ),
                ),
              if (selectedValidation != 'All Validation')
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Chip(
                    label: Text(
                      _formatDisplay(selectedValidation),
                      style: TextStyle(color: textColor),
                    ),
                    backgroundColor: fillColor,
                    side: BorderSide(color: officerColor),
                    onDeleted: () => onValidationChanged('All Validation'),
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
    final selectedStatus = widget.selectedStatus;
    final selectedType = widget.selectedType;
    final selectedValidation = widget.selectedValidation;
    final selectedDeadline = widget.selectedDeadline;
    final availableTypes = widget.availableTypes;
    final onStatusChanged = widget.onStatusChanged;
    final onTypeChanged = widget.onTypeChanged;
    final onValidationChanged = widget.onValidationChanged;
    final onDeadlineChanged = widget.onDeadlineChanged;
    String tempStatus = selectedStatus;
    String tempType = selectedType;
    String tempValidation = selectedValidation;
    String tempDeadline = selectedDeadline;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final officerColor = AppColors.primaryDark;
    final fillColor = isDark ? AppColors.surfaceDark : Colors.grey.shade100;
    final textColor = isDark ? AppColors.textPrimaryDark : Colors.black87;

    final statusOptions = [
      'All Status',
      'unresolved',
      'acknowledged',
      'responded',
      'in_progress',
      'resolved',
      'closed',
      'pending_owner_consent',
      'waiting_for_feedback',
    ];

    final validationOptions = [
      'All Validation',
      'pending',
      'automatically_valid',
      'manual_review',
      'validated',
    ];

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      isScrollControlled: true,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppColors.radiusDialog),
        ),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          Widget choices(
            String title,
            List<String> values,
            String selected,
            void Function(String) select,
          ) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(ctx).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: values
                    .toSet()
                    .map(
                      (value) => ChoiceChip(
                        label: Text(
                          _formatDisplay(value),
                          style: TextStyle(
                            color: selected == value ? Colors.white : textColor,
                          ),
                        ),
                        selected: selected == value,
                        selectedColor: officerColor,
                        checkmarkColor: Colors.white,
                        backgroundColor: fillColor,
                        onSelected: (active) {
                          if (active) setModalState(() => select(value));
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
            ],
          );
          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Filters', style: Theme.of(ctx).textTheme.headlineSmall),
                  const SizedBox(height: 20),
                  choices(
                    'Status',
                    statusOptions,
                    tempStatus,
                    (value) => tempStatus = value,
                  ),
                  choices(
                    'Issue Type',
                    ['All Types', ...availableTypes],
                    tempType,
                    (value) => tempType = value,
                  ),
                  choices(
                    'Response deadline',
                    FcReportsFilterBar.deadlineOptions,
                    tempDeadline,
                    (value) => tempDeadline = value,
                  ),
                  choices(
                    'Validation',
                    validationOptions,
                    tempValidation,
                    (value) => tempValidation = value,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      onStatusChanged(tempStatus);
                      onTypeChanged(tempType);
                      onValidationChanged(tempValidation);
                      onDeadlineChanged(tempDeadline);
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: officerColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Apply Filters'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDisplay(String key) {
    switch (key) {
      case 'acknowledged':
        return 'Acknowledged';
      case 'responded':
        return 'Responded';
      case 'unresolved':
        return 'Unresolved';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      case 'pending_owner_consent':
        return 'Pending Owner Consent';
      case 'waiting_for_feedback':
        return 'Waiting for Feedback';
      case 'pending':
        return 'Pending';
      case 'automatically_valid':
        return 'Automatically Valid';
      case 'manual_review':
        return 'Manual Review';
      case 'validated':
        return 'Validated';
      case 'rejected':
        return 'Rejected';
      default:
        return key;
    }
  }
}
