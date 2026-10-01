import 'package:flutter/material.dart';
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final inputDecoration = InputDecoration(
              filled: true,
              fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              isDense: true,
            );

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Filters & Sort', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: tempAction,
                        decoration: inputDecoration.copyWith(labelText: 'Action Type'),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Actions')),
                          DropdownMenuItem(value: 'status_update', child: Text('Status Update')),
                          DropdownMenuItem(value: 'lifecycle_stage_update', child: Text('Lifecycle')),
                          DropdownMenuItem(value: 'acknowledge_complaint', child: Text('Acknowledge')),
                          DropdownMenuItem(value: 'manual_note', child: Text('Manual Note')),
                        ],
                        onChanged: (value) => setModalState(() => tempAction = value ?? 'all'),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: tempSort,
                        decoration: inputDecoration.copyWith(labelText: 'Sort By'),
                        items: const [
                          DropdownMenuItem(value: 'newest', child: Text('Newest First')),
                          DropdownMenuItem(value: 'oldest', child: Text('Oldest First')),
                        ],
                        onChanged: (value) => setModalState(() => tempSort = value ?? 'newest'),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                setModalState(() {
                                  tempAction = 'all';
                                  tempSort = 'newest';
                                });
                              },
                              child: const Text('Reset'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                setState(() {
                                  _actionTypeFilter = tempAction;
                                  _sortBy = tempSort;
                                });
                                Navigator.pop(context);
                              },
                              child: const Text('Apply Filters'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          InkWell(
            onTap: _showFilterSheet,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.tune, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Filter & Sort', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<ResponseLog> _filterAndSortLogs(List<ResponseLog> logs) {
    var filtered = logs;
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: _buildSectionContainer(
        Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionTypeBadge(log.actionType),
                if (log.createdAt != null)
                  Text(
                    _formatDateTime(log.createdAt!),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (log.actionDetails != null && log.actionDetails!.isNotEmpty)
              Text(log.actionDetails!, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            if (log.profile != null)
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    log.profile!['full_name'] ?? 'Unknown User',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
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

