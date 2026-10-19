import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/shared/notifications/presentation/widgets/notification_badge_action.dart';

class OfficerCrewManagementScreen extends ConsumerStatefulWidget {
  const OfficerCrewManagementScreen({super.key});

  @override
  ConsumerState<OfficerCrewManagementScreen> createState() =>
      _OfficerCrewManagementScreenState();
}

class _OfficerCrewManagementScreenState
    extends ConsumerState<OfficerCrewManagementScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _crews = [];
  List<dynamic> _unassigned = [];
  String? _mutatingMemberId;
  final Set<String> _expandedCrewTaskIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final results = await Future.wait([
        apiClient.getFieldCrews(),
        apiClient.getUnassignedCrewMembers(),
      ]);

      final crewsData = results[0].data;
      final unassignedData = results[1].data;

      setState(() {
        _crews = crewsData is List ? crewsData : [];
        _unassigned = unassignedData is List ? unassignedData : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _modifyMember({
    required String crewId,
    required String userId,
    required String action,
  }) async {
    setState(() => _mutatingMemberId = userId);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.updateCrewMember(crewId, userId, action);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'add'
                  ? 'Crew member added successfully'
                  : 'Crew member removed',
            ),
            backgroundColor: action == 'add' ? AppColors.success : Colors.grey.shade800,
          ),
        );
      }
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update member: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _mutatingMemberId = null);
      }
    }
  }

  void _showAddMemberSheet(BuildContext context, dynamic crew) {
    final crewId = crew['id']?.toString() ?? '';
    final crewName = crew['name']?.toString() ?? 'Field Crew';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Add Member to $crewName',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Select an unassigned field crew member from the roster.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              const Divider(height: 24),
              Expanded(
                child: _unassigned.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off_outlined,
                                size: 48, color: Colors.grey.shade500),
                            const SizedBox(height: 12),
                            const Text(
                              'No unassigned crew members available',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _unassigned.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (ctx, idx) {
                          final user = _unassigned[idx];
                          final userId = user['id']?.toString() ?? '';
                          final fullName =
                              user['full_name'] as String? ?? 'Unnamed';
                          final avatarUrl = user['avatar_url'] as String?;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary,
                              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                                  ? NetworkImage(avatarUrl)
                                  : null,
                              child: avatarUrl == null || avatarUrl.isEmpty
                                  ? Text(
                                      fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            title: Text(fullName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 15)),
                            subtitle: const Text('Available Field Crew',
                                style: TextStyle(fontSize: 12, color: Colors.grey)),
                            trailing: ElevatedButton.icon(
                              onPressed: _mutatingMemberId == userId
                                  ? null
                                  : () {
                                      Navigator.pop(ctx);
                                      _modifyMember(
                                        crewId: crewId,
                                        userId: userId,
                                        action: 'add',
                                      );
                                    },
                              icon: const Icon(Icons.person_add, size: 16),
                              label: const Text('Add'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crew Management'),
        actions: const [NotificationBadgeAction()],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text('Error loading crews: $_error',
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      // Overview Header Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF242424) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.groups,
                                color: AppColors.primaryDark,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    () {
                                      final totalActiveTasks = _crews.fold<int>(
                                        0,
                                        (sum, c) => sum + ((c['active_task_count'] as num?)?.toInt() ?? 0),
                                      );
                                      return '${_crews.length} Active Crews · $totalActiveTasks Tasks Assigned';
                                    }(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_unassigned.length} unassigned field members available',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // List of Crews
                      ..._crews.map((crew) => _buildCrewCard(crew, isDark)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCrewCard(dynamic crew, bool isDark) {
    final crewId = crew['id']?.toString() ?? '';
    final crewName = crew['name']?.toString() ?? 'Field Crew';
    final members = (crew['members'] as List<dynamic>?) ?? [];
    final activeTaskCount = (crew['active_task_count'] as num?)?.toInt() ??
        ((crew['active_tasks'] as List?)?.length ?? 0);
    final maxTasks = (crew['max_tasks_per_shift'] as num?)?.toInt() ?? 10;
    final isAtCapacity = crew['is_at_capacity'] == true || activeTaskCount >= maxTasks;
    final activeTasks = (crew['active_tasks'] as List<dynamic>?) ?? [];
    final isTasksExpanded = _expandedCrewTaskIds.contains(crewId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_outlined,
                        size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      crewName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _showAddMemberSheet(context, crew),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Member'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Workload & Current Tasks Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: activeTaskCount == 0
                    ? (isDark ? const Color(0xFF143322) : const Color(0xFFE8F5E9))
                    : (isAtCapacity
                        ? (isDark ? const Color(0xFF3B1818) : const Color(0xFFFFEBEE))
                        : (isDark ? const Color(0xFF1B2E3D) : const Color(0xFFE1F5FE))),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: activeTaskCount == 0
                      ? AppColors.success.withValues(alpha: 0.4)
                      : (isAtCapacity
                          ? AppColors.error.withValues(alpha: 0.4)
                          : AppColors.primaryDark.withValues(alpha: 0.4)),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    activeTaskCount == 0
                        ? Icons.check_circle_outline
                        : (isAtCapacity
                            ? Icons.warning_amber_rounded
                            : Icons.assignment_outlined),
                    size: 18,
                    color: activeTaskCount == 0
                        ? AppColors.success
                        : (isAtCapacity ? AppColors.error : AppColors.primaryDark),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      activeTaskCount == 0
                          ? 'Available · 0 active tasks assigned'
                          : '$activeTaskCount active task${activeTaskCount == 1 ? '' : 's'} assigned ($activeTaskCount / $maxTasks capacity)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: activeTaskCount == 0
                            ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32))
                            : (isAtCapacity
                                ? (isDark ? const Color(0xFFE57373) : const Color(0xFFC62828))
                                : (isDark ? const Color(0xFF64B5F6) : const Color(0xFF0277BD))),
                      ),
                    ),
                  ),
                  if (activeTaskCount > 0)
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        setState(() {
                          if (isTasksExpanded) {
                            _expandedCrewTaskIds.remove(crewId);
                          } else {
                            _expandedCrewTaskIds.add(crewId);
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isTasksExpanded ? 'Hide' : 'Details',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            Icon(
                              isTasksExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 16,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Expandable Active Tasks Details
            if (isTasksExpanded && activeTasks.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Currently Assigned Tasks (${activeTasks.length})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            context.go(
                              '${OfficerAppRoutes.cleanupTasks}?crewId=$crewId&crewName=${Uri.encodeComponent(crewName)}',
                            );
                          },
                          child: const Text(
                            'Open in Tasks →',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...activeTasks.map((t) {
                      final taskId = t['id']?.toString() ?? '';
                      final title = t['title']?.toString() ?? 'Cleanup Task';
                      final status = t['status']?.toString() ?? 'pending';

                      return InkWell(
                        onTap: taskId.isNotEmpty
                            ? () => context.push(
                                  OfficerAppRoutes.taskDetails.replaceAll(':id', taskId),
                                )
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.circle, size: 8, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: status == 'in_progress'
                                      ? AppColors.primary.withValues(alpha: 0.2)
                                      : Colors.grey.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  status.replaceAll('_', ' '),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),
            Text(
              '${members.length} Assigned Members',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 10),
            if (members.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'No members assigned to this crew yet',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: members.map((m) {
                  final userId = m['id']?.toString() ?? '';
                  final name = m['full_name'] as String? ?? 'Member';
                  final isMutating = _mutatingMemberId == userId;

                  return Chip(
                    avatar: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                    ),
                    label: Text(name),
                    deleteIcon: isMutating
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.close, size: 16),
                    onDeleted: isMutating
                        ? null
                        : () => _modifyMember(
                              crewId: crewId,
                              userId: userId,
                              action: 'remove',
                            ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
