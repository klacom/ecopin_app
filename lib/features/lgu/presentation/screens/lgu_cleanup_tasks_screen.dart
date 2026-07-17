import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/features/lgu/providers/lgu_cleanup_tasks_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/routes/app_routes.dart';

class LguCleanupTasksScreen extends ConsumerStatefulWidget {
  const LguCleanupTasksScreen({super.key});

  @override
  ConsumerState<LguCleanupTasksScreen> createState() =>
      _LguCleanupTasksScreenState();
}

class _LguCleanupTasksScreenState extends ConsumerState<LguCleanupTasksScreen> {
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(lguCleanupTasksProvider).tasks;

    return Scaffold(
      appBar: AppBar(title: const Text('Cleanup Tasks'), elevation: 0),
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
                          ref.read(lguCleanupTasksProvider).loadTasks(),
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

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.go('${LguAppRoutes.cleanupTasks}/create');
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Custom Cleanup Task'),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search tasks...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _statusFilter,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All')),
              DropdownMenuItem(value: 'pending', child: Text('Pending')),
              DropdownMenuItem(
                value: 'in_progress',
                child: Text('In Progress'),
              ),
              DropdownMenuItem(value: 'completed', child: Text('Completed')),
            ],
            onChanged: (value) {
              setState(() {
                _statusFilter = value ?? 'all';
              });
            },
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
    return Card(
      color: Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.go(LguAppRoutes.taskDetails.replaceAll(':id', task.id));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (task.isCustom)
                          Chip(
                            label: const Text('Custom'),
                            labelStyle: const TextStyle(fontSize: 10),
                            padding: const EdgeInsets.all(0),
                          ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(task.status),
                ],
              ),
              const SizedBox(height: 8),
              if (task.description != null && task.description!.isNotEmpty)
                Text(
                  task.description!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    task.createdAt != null
                        ? _formatDate(task.createdAt!)
                        : 'N/A',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  if (task.clusterId != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.group_work, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Cluster ${_truncateClusterId(task.clusterId!)}',
                        style: TextStyle(color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
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
