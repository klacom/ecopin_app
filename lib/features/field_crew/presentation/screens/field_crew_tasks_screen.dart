import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/features/field_crew/providers/cleanup_tasks_provider.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_task_list_tile.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_shimmer_list.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_task_filter_bar.dart';

class FieldCrewTasksScreen extends ConsumerStatefulWidget {
  const FieldCrewTasksScreen({super.key});

  @override
  ConsumerState<FieldCrewTasksScreen> createState() =>
      _FieldCrewTasksScreenState();
}

class _FieldCrewTasksScreenState extends ConsumerState<FieldCrewTasksScreen> {
  String _searchQuery = '';
  String _statusFilter = 'All';
  bool _assignedToMeOnly = false;

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(allCleanupTasksProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: Text(
          'Cleanup Tasks',
          style: AppTypography.h5.copyWith(color: AppColors.textPrimaryDark),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppColors.spaceLG,
              vertical: AppColors.spaceMD,
            ),
            child: FcTaskFilterBar(
              searchQuery: _searchQuery,
                    onSearchChanged: (val) {
                      setState(() => _searchQuery = val);
                    },
                    statusFilter: _statusFilter,
                    onStatusChanged: (val) {
                      setState(() => _statusFilter = val);
                    },
                    assignedToMeOnly: _assignedToMeOnly,
                    onAssignmentChanged: (val) {
                      setState(() => _assignedToMeOnly = val);
                    },
                    onReset: () {
                      setState(() {
                        _searchQuery = '';
                        _statusFilter = 'All';
                        _assignedToMeOnly = false;
                      });
                    },
                  ),
          ),
          Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(allCleanupTasksProvider);
                  await ref.read(allCleanupTasksProvider.future);
                },
                color: AppColors.primaryDark,
                backgroundColor: AppColors.surfaceDark,
                child: tasksAsync.when(
                  data: (tasks) {
                    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
                    final filteredTasks = tasks.where((t) {
                      final query = _searchQuery.toLowerCase();
                      final searchMatch = _searchQuery.isEmpty ||
                          t.title.toLowerCase().contains(query) ||
                          t.description.toLowerCase().contains(query) ||
                          t.location.toLowerCase().contains(query);

                      final statusMatch = _statusFilter == 'All' ||
                          t.status.toLowerCase() == _statusFilter.toLowerCase().replaceAll(' ', '_');

                      final assignmentMatch = !_assignedToMeOnly ||
                          (currentUserId != null && t.assignedCrewIds.contains(currentUserId));

                      return searchMatch && statusMatch && assignmentMatch;
                    }).toList();

                    if (filteredTasks.isEmpty) {
                      return ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: _buildEmptyState(),
                          ),
                        ],
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppColors.spaceLG,
                        vertical: AppColors.spaceMD,
                      ),
                      itemCount: filteredTasks.length,
                      separatorBuilder: (context, index) => const SizedBox(height: AppColors.spaceMD),
                      itemBuilder: (context, index) => FcTaskListTile(task: filteredTasks[index]),
                    );
                  },
                  loading: () => ListView(
                    children: const [FcShimmerList()],
                  ),
                  error: (error, stack) => ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Center(
                          child: Text(
                            'Error loading tasks: $error',
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_turned_in,
            size: 64,
            color: AppColors.primaryDark.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppColors.spaceLG),
          Text(
            'No tasks found',
            style: AppTypography.h5.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: AppColors.spaceSM),
          Text(
            'Try adjusting your filters or checking back later',
            style: AppTypography.body.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
