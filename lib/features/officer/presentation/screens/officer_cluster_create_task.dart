import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/features/officer/providers/officer_cleanup_tasks_provider.dart';
import 'package:ecopin_app/routes/app_routes.dart';

class OfficerClusterCreateTaskScreen extends ConsumerStatefulWidget {
  const OfficerClusterCreateTaskScreen({super.key});

  @override
  ConsumerState<OfficerClusterCreateTaskScreen> createState() =>
      _OfficerClusterCreateTaskScreenState();
}

class _OfficerClusterCreateTaskScreenState
    extends ConsumerState<OfficerClusterCreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  List<String> _selectedReportIds = [];
  bool _didInitialize = false;
  List<Map<String, dynamic>> _fieldCrews = [];
  String? _selectedFieldCrewId;

  @override
  void initState() {
    super.initState();
    _loadFieldCrews();
  }

  Future<void> _loadFieldCrews() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.getFieldCrews();
      if (response.data is List && mounted) {
        setState(() {
          _fieldCrews = List<Map<String, dynamic>>.from(response.data);
        });
      }
    } catch (e) {
      debugPrint('Failed to load field crews: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitialize) {
      final extra = GoRouterState.of(context).extra;
      if (extra != null && extra is Map<String, dynamic>) {
        final List<String>? passedReportIds =
            extra['reportIds'] as List<String>?;
        if (passedReportIds != null) {
          _selectedReportIds = passedReportIds;
        }
      }
      _didInitialize = true;
    }
  }

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFieldCrewId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a field crew to assign')),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final selectedCrew = _fieldCrews.firstWhere(
        (c) => c['id']?.toString() == _selectedFieldCrewId,
        orElse: () => {},
      );
      final rawMemberIds = [
        if (selectedCrew['member_profile_ids'] is List)
          ...(selectedCrew['member_profile_ids'] as List).map((e) => e.toString()),
        if (selectedCrew['team_lead_profile_id'] != null)
          selectedCrew['team_lead_profile_id'].toString(),
      ];
      final memberIds = rawMemberIds.toSet().toList();

      await apiClient.createCustomCleanupTask(
        reportIds: _selectedReportIds,
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        fieldCrewId: _selectedFieldCrewId,
        assignedCrewIds: memberIds.isNotEmpty ? memberIds : null,
      );
      if (!mounted) return;
      ref.read(officerCleanupTasksProvider).loadTasks();
      context.go(OfficerAppRoutes.cleanupTasks);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cleanup task created successfully')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create task: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Create Cleanup Task', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionContainer(
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cluster Task',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_selectedReportIds.length} reports selected from cluster',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionContainer(
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Task Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: inputDecoration.copyWith(
                          labelText: 'Task Title *',
                          hintText: 'Enter task title',
                        ),
                        validator: (value) =>
                            (value?.isEmpty ?? true) ? 'Required' : null,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: inputDecoration.copyWith(
                          labelText: 'Description (Optional)',
                          hintText: 'Describe the cleanup task',
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Assign to Field Crew *',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (_fieldCrews.isEmpty)
                        const Text('No field crews available', style: TextStyle(color: Colors.grey))
                      else
                        Container(
                          constraints: const BoxConstraints(maxHeight: 240),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).dividerColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _fieldCrews.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final crew = _fieldCrews[index];
                              final crewId = crew['id']?.toString() ?? '';
                              final crewName = crew['name']?.toString() ?? 'Unnamed Crew';
                              final members = crew['members'] as List? ?? [];
                              final memberCount = (crew['member_profile_ids'] as List?)?.length ?? members.length;
                              final isSelected = _selectedFieldCrewId == crewId;
                              final activeTasks = (crew['active_task_count'] as num?)?.toInt() ??
                                  ((crew['active_tasks'] as List?)?.length ?? 0);
                              final maxTasks = (crew['max_tasks_per_shift'] as num?)?.toInt() ?? 10;
                              final isAtCapacity = crew['is_at_capacity'] == true || activeTasks >= maxTasks;
                              final isDark = Theme.of(context).brightness == Brightness.dark;

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                                  foregroundColor: isSelected ? Colors.white : null,
                                  child: const Icon(Icons.groups, size: 20),
                                ),
                                title: Text(
                                  crewName,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$memberCount member${memberCount == 1 ? '' : 's'}${crew['shift_start'] != null ? ' · Shift: ${crew['shift_start']}' : ''}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Icon(
                                          activeTasks == 0
                                              ? Icons.check_circle_outline
                                              : (isAtCapacity ? Icons.warning_amber_rounded : Icons.assignment_outlined),
                                          size: 13,
                                          color: activeTasks == 0
                                              ? AppColors.success
                                              : (isAtCapacity ? AppColors.error : AppColors.primaryDark),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          activeTasks == 0
                                              ? '0 tasks currently assigned (Available)'
                                              : '$activeTasks task${activeTasks == 1 ? '' : 's'} assigned${isAtCapacity ? ' (At capacity $activeTasks/$maxTasks)' : ' ($activeTasks/$maxTasks)'}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: isAtCapacity ? FontWeight.bold : FontWeight.w500,
                                            color: activeTasks == 0
                                                ? AppColors.success
                                                : (isAtCapacity
                                                    ? AppColors.error
                                                    : (isDark ? Colors.grey.shade300 : Colors.grey.shade700)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Radio<String>(
                                  value: crewId,
                                  groupValue: _selectedFieldCrewId,
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedFieldCrewId = val;
                                    });
                                  },
                                ),
                                selected: isSelected,
                                onTap: () {
                                  setState(() {
                                    _selectedFieldCrewId = crewId;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed:
                              (_titleController.text.isEmpty || _isSubmitting)
                              ? null
                              : _submitTask,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Create Cleanup Task', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () => context.pop(),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}


