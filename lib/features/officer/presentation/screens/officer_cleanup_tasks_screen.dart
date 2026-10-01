import 'package:flutter/material.dart';
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
          'Cleanup Tasks',
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
                          const Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: tempStatus,
                        decoration: inputDecoration.copyWith(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All')),
                          DropdownMenuItem(value: 'pending', child: Text('Pending')),
                          DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                          DropdownMenuItem(value: 'completed', child: Text('Completed')),
                        ],
                        onChanged: (value) => setModalState(() => tempStatus = value ?? 'all'),
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
                                  tempStatus = 'all';
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
                                  _statusFilter = tempStatus;
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

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
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
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
                  decoration: inputDecoration.copyWith(
                    hintText: 'Search tasks...',
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: _showFilterSheet,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tune, color: Colors.white),
                ),
              ),
            ],
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
                children: [
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('CUSTOM', style: TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ),
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
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                Text(
                  task.description!,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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


