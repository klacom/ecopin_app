import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:ecopin_app/core/services/api_service.dart';

class ResponseLog {
  final String id;
  final String? actionType;
  final String? actionDetails;
  final DateTime? createdAt;
  final String? userId;
  final Map<String, dynamic>? profile;

  ResponseLog({
    required this.id,
    this.actionType,
    this.actionDetails,
    this.createdAt,
    this.userId,
    this.profile,
  });

  factory ResponseLog.fromJson(Map<String, dynamic> json) {
    return ResponseLog(
      id: json['id']?.toString() ?? '',
      actionType: json['action_type'] as String?,
      actionDetails: json['action_details'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      userId: json['user_id']?.toString(),
      profile: json['profiles'] as Map<String, dynamic>?,
    );
  }
}

class ResponseLogsNotifier extends ChangeNotifier {
  final ApiClient _apiClient;
  AsyncValue<List<ResponseLog>> _logs = const AsyncValue.loading();

  ResponseLogsNotifier(this._apiClient) {
    loadLogs();
  }

  AsyncValue<List<ResponseLog>> get logs => _logs;

  Future<void> loadLogs({Map<String, dynamic>? params}) async {
    _logs = const AsyncValue.loading();
    notifyListeners();
    try {
      final response = await _apiClient.getResponseLogs(params: params);
      final List<dynamic> data = response.data['logs'] is List
          ? response.data['logs'] as List<dynamic>
          : [];
      final logs = data
          .map((json) => ResponseLog.fromJson(json as Map<String, dynamic>))
          .toList();
      _logs = AsyncValue.data(logs);
      notifyListeners();
    } catch (e, stackTrace) {
      _logs = AsyncValue.error(e, stackTrace);
      notifyListeners();
    }
  }

  void reset() {
    _logs = const AsyncValue.loading();
    notifyListeners();
  }
}

final officerResponseLogsProvider = ChangeNotifierProvider<ResponseLogsNotifier>((
  ref,
) {
  final apiClient = ref.watch(apiClientProvider);
  return ResponseLogsNotifier(apiClient);
});

class OfficerResponseLogsScreen extends ConsumerStatefulWidget {
  const OfficerResponseLogsScreen({super.key});

  @override
  ConsumerState<OfficerResponseLogsScreen> createState() =>
      _OfficerResponseLogsScreenState();
}

class _OfficerResponseLogsScreenState extends ConsumerState<OfficerResponseLogsScreen> {
  String _searchQuery = '';
  String _actionTypeFilter = 'all';
  String _sortBy = 'newest';

  Widget _buildSectionContainer(Widget child) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(officerResponseLogsProvider).logs;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Response Logs', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: logsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(officerResponseLogsProvider).loadLogs(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (logs) {
                final filteredLogs = _filterAndSortLogs(logs);
                if (filteredLogs.isEmpty) {
                  return const Center(child: Text('No response logs found'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 80,
                  ),
                  itemCount: filteredLogs.length,
                  itemBuilder: (context, index) {
                    final log = filteredLogs[index];
                    return _buildLogCard(log);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    String tempAction = _actionTypeFilter;
    String tempSort = _sortBy;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final officerColor = AppColors.primaryDark;
    final fillColor = isDark ? AppColors.surfaceDark : Colors.grey.shade100;
    final textColor = isDark ? AppColors.textPrimaryDark : Colors.black87;

    final actionOptions = [
      {'value': 'all', 'label': 'All Actions'},
      {'value': 'status_update', 'label': 'Status Update'},
      {'value': 'lifecycle_stage_update', 'label': 'Lifecycle'},
      {'value': 'acknowledge_complaint', 'label': 'Acknowledge'},
      {'value': 'manual_note', 'label': 'Manual Note'}
    ];
    
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
          initialChildSize: 0.5,
          minChildSize: 0.4,
          maxChildSize: 0.8,
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
                      Text('Filters & Sort', style: AppTypography.h4.copyWith(color: textColor)),
                      const SizedBox(height: AppColors.spaceLG),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            Text('Action Type', style: AppTypography.label.copyWith(color: Colors.grey)),
                            const SizedBox(height: AppColors.spaceSM),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: actionOptions.map((opt) {
                                final val = opt['value']!;
                                final isSelected = tempAction == val;
                                return ChoiceChip(
                                  label: Text(opt['label']!,
                                      style: TextStyle(
                                          color: isSelected ? Colors.white : textColor)),
                                  selected: isSelected,
                                  selectedColor: officerColor,
                                  backgroundColor: fillColor,
                                  onSelected: (selected) {
                                    if (selected) setModalState(() => tempAction = val);
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: AppColors.spaceLG),
                            Text('Sort By', style: AppTypography.label.copyWith(color: Colors.grey)),
                            const SizedBox(height: AppColors.spaceSM),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: sortOptions.map((sortOpt) {
                                final isSelected = tempSort == sortOpt;
                                return ChoiceChip(
                                  label: Text(_formatSort(sortOpt),
                                      style: TextStyle(
                                          color: isSelected ? Colors.white : textColor)),
                                  selected: isSelected,
                                  selectedColor: officerColor,
                                  backgroundColor: fillColor,
                                  onSelected: (val) {
                                    if (val) setModalState(() => tempSort = sortOpt);
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
                            setState(() {
                              _actionTypeFilter = tempAction;
                              _sortBy = tempSort;
                            });
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: officerColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppColors.radiusButton)),
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

  String _formatSort(String val) {
    if (val == 'newest') return 'Newest First';
    if (val == 'oldest') return 'Oldest First';
    return val;
  }

  String _formatAction(String val) {
    if (val == 'all') return 'All Actions';
    if (val == 'status_update') return 'Status Update';
    if (val == 'lifecycle_stage_update') return 'Lifecycle';
    if (val == 'acknowledge_complaint') return 'Acknowledge';
    if (val == 'manual_note') return 'Manual Note';
    return val;
  }

  Widget _buildFilters() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final officerColor = AppColors.primaryDark;
    final fillColor = isDark ? AppColors.surfaceDark : Colors.grey.shade100;
    final textColor = isDark ? AppColors.textPrimaryDark : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) {
                    setState(() { _searchQuery = val; });
                  },
                  style: AppTypography.body.copyWith(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Search logs...',
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
                onPressed: _showFilterSheet,
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
                if (_searchQuery.isNotEmpty || _actionTypeFilter != 'all' || _sortBy != 'newest')
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      label: const Text('Reset', style: TextStyle(color: Colors.white)),
                      backgroundColor: officerColor,
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _actionTypeFilter = 'all';
                          _sortBy = 'newest';
                        });
                      },
                    ),
                  ),
                if (_actionTypeFilter != 'all')
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Chip(
                      label: Text(_formatAction(_actionTypeFilter), style: TextStyle(color: textColor)),
                      backgroundColor: fillColor,
                      side: BorderSide(color: officerColor),
                      onDeleted: () { setState(() { _actionTypeFilter = 'all'; }); },
                      deleteIconColor: officerColor,
                    ),
                  ),
                if (_sortBy != 'newest')
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Chip(
                      label: Text(_formatSort(_sortBy), style: TextStyle(color: textColor)),
                      backgroundColor: fillColor,
                      side: BorderSide(color: officerColor),
                      onDeleted: () { setState(() { _sortBy = 'newest'; }); },
                      deleteIconColor: officerColor,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<ResponseLog> _filterAndSortLogs(List<ResponseLog> logs) {
    var filtered = logs;
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((log) {
        final query = _searchQuery.toLowerCase();
        final matchesDetails = log.actionDetails?.toLowerCase().contains(query) ?? false;
        final matchesName = log.profile?['full_name']?.toLowerCase().contains(query) ?? false;
        return matchesDetails || matchesName;
      }).toList();
    }
    
    if (_actionTypeFilter != 'all') {
      filtered = logs
          .where((log) => log.actionType == _actionTypeFilter)
          .toList();
    }

    // Sort by date
    filtered.sort((a, b) {
      if (a.createdAt == null || b.createdAt == null) return 0;
      return _sortBy == 'newest'
          ? b.createdAt!.compareTo(a.createdAt!)
          : a.createdAt!.compareTo(b.createdAt!);
    });

    return filtered;
  }

  Widget _buildLogCard(ResponseLog log) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: _buildSectionContainer(
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Text(
                      'System Log',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildActionTypeBadge(log.actionType),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    log.createdAt != null ? _formatDateTime(log.createdAt!) : 'N/A',
                    style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                  if (log.profile != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.person, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        log.profile!['full_name'] ?? 'Unknown User',
                        style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              if (log.actionDetails != null && log.actionDetails!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                    ),
                  ),
                  child: Text(
                    log.actionDetails!,
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTypeBadge(String? actionType) {
    Color color;
    String label;

    switch (actionType) {
      case 'status_update':
        color = Colors.blue;
        label = 'STATUS UPDATE';
        break;
      case 'lifecycle_stage_update':
        color = Colors.purple;
        label = 'LIFECYCLE UPDATE';
        break;
      case 'acknowledge_complaint':
        color = Colors.green;
        label = 'ACKNOWLEDGED';
        break;
      case 'manual_note':
        color = Colors.orange;
        label = 'NOTE';
        break;
      default:
        color = Colors.grey;
        label = actionType?.toUpperCase() ?? 'UNKNOWN';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

