import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/features/lgu/providers/lgu_cleanup_tasks_provider.dart';
import 'package:ecopin_app/routes/app_routes.dart';

class LguClusterCreateTaskScreen extends ConsumerStatefulWidget {
  const LguClusterCreateTaskScreen({super.key});

  @override
  ConsumerState<LguClusterCreateTaskScreen> createState() =>
      _LguClusterCreateTaskScreenState();
}

class _LguClusterCreateTaskScreenState
    extends ConsumerState<LguClusterCreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  List<String> _selectedReportIds = [];
  bool _didInitialize = false;

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

    setState(() => _isSubmitting = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.createCustomCleanupTask(
        reportIds: _selectedReportIds,
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
      );
      if (!mounted) return;
      ref.read(lguCleanupTasksProvider).loadTasks();
      context.go(LguAppRoutes.cleanupTasks);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Cleanup Task')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Theme.of(context).colorScheme.surface,
                child: Padding(
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
              Card(
                color: Theme.of(context).colorScheme.surface,
                child: Padding(
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
                        decoration: const InputDecoration(
                          labelText: 'Task Title *',
                          border: OutlineInputBorder(),
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
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          border: OutlineInputBorder(),
                          hintText: 'Describe the cleanup task',
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed:
                              (_titleController.text.isEmpty || _isSubmitting)
                              ? null
                              : _submitTask,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Create Cleanup Task'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () => context.pop(),
                          child: const Text('Cancel'),
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
