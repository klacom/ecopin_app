import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import 'package:ecopin_app/shared/notifications/presentation/widgets/notification_badge_action.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/features/officer/providers/officer_cleanup_tasks_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/routes/app_routes.dart';

class OfficerCleanupTasksScreen extends ConsumerStatefulWidget {
  const OfficerCleanupTasksScreen({super.key});

  @override
  ConsumerState<OfficerCleanupTasksScreen> createState() =>
      _OfficerCleanupTasksScreenState();
}

class _OfficerCleanupTasksScreenState extends ConsumerState<OfficerCleanupTasksScreen> {
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(officerCleanupTasksProvider).tasks;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Operations',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: false,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: NotificationBadgeAction(),
          )
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: tasksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(officerCleanupTasksProvider).loadTasks(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (tasks) {
                final filteredTasks = _filterTasks(tasks);
                if (filteredTasks.isEmpty) {
                  return const Center(child: Text('No cleanup tasks found'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 80,
                  ),
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final task = filteredTasks[index];
                    return _buildTaskCard(task);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    String tempStatus = _statusFilter;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final officerColor = AppColors.primaryDark;
    final fillColor = isDark ? AppColors.surfaceDark : Colors.grey.shade100;
    final textColor = isDark ? AppColors.textPrimaryDark : Colors.black87;

    final statusOptions = ['all', 'pending', 'in_progress', 'completed'];

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
          initialChildSize: 0.4,
          minChildSize: 0.3,
          maxChildSize: 0.6,
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
                      Text('Filters', style: AppTypography.h4.copyWith(color: textColor)),
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
                                  label: Text(_formatStatus(status),
                                      style: TextStyle(
                                          color: isSelected ? Colors.white : textColor)),
                                  selected: isSelected,
                                  selectedColor: officerColor,
                                  backgroundColor: fillColor,
                                  onSelected: (val) {
                                    if (val) setModalState(() => tempStatus = status);
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
                              _statusFilter = tempStatus;
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

  String _formatStatus(String val) {
    if (val == 'all') return 'All';
    if (val == 'in_progress') return 'In Progress';
    if (val == 'completed') return 'Completed';
    if (val == 'pending') return 'Pending';
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
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                context.go('${OfficerAppRoutes.cleanupTasks}/create');
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Custom Cleanup Task', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: officerColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppColors.radiusButton),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) {
                    setState(() { _searchQuery = val; });
                  },
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
                if (_searchQuery.isNotEmpty || _statusFilter != 'all')
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      label: const Text('Reset', style: TextStyle(color: Colors.white)),
                      backgroundColor: officerColor,
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _statusFilter = 'all';
                        });
                      },
                    ),
                  ),
                if (_statusFilter != 'all')
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Chip(
                      label: Text(_formatStatus(_statusFilter), style: TextStyle(color: textColor)),
                      backgroundColor: fillColor,
                      side: BorderSide(color: officerColor),
                      onDeleted: () { setState(() { _statusFilter = 'all'; }); },
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

  List<CleanupTask> _filterTasks(List<CleanupTask> tasks) {
    return tasks.where((task) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          (task.title?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false) ||
          (task.description?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false);

      final matchesStatus =
          _statusFilter == 'all' || task.status == _statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  Widget _buildTaskCard(CleanupTask task) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.go(OfficerAppRoutes.taskDetails.replaceAll(':id', task.id));
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          task.title ?? 'Untitled Task',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (task.isCustom)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('CUSTOM', style: TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(task.status),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    task.createdAt != null
                        ? _formatDate(task.createdAt!)
                        : 'N/A',
                    style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                  if (task.clusterId != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.group_work, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Cluster ${_truncateClusterId(task.clusterId!)}',
                        style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              if (task.description != null && task.description!.isNotEmpty) ...[
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
                    task.description!,
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 2,
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

  Widget _buildStatusBadge(String? status) {
    Color color;
    switch (status) {
      case 'completed':
        color = Colors.green;
        break;
      case 'in_progress':
        color = Colors.orange;
        break;
      case 'pending':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status?.replaceAll('_', ' ').toUpperCase() ?? 'N/A',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _truncateClusterId(String clusterId) {
    if (clusterId.length <= 8) return clusterId;
    return '${clusterId.substring(0, 8)}...';
  }
}


