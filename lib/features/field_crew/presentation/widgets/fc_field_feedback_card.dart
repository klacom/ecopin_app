import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/features/field_crew/providers/fc_local_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FcFieldFeedbackCard extends ConsumerWidget {
  final CleanupTask task;
  final void Function(String reasonCode) onFailureQueued;

  const FcFieldFeedbackCard({
    super.key,
    required this.task,
    required this.onFailureQueued,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actor = Supabase.instance.client.auth.currentUser?.id;
    if (actor == null ||
        !task.assignedCrewIds.contains(actor) ||
        task.status == 'completed' ||
        task.status == 'cancelled') {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Field feedback',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Record vehicle fill or disposal as the shift changes.'),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _recordLoad(context, ref, actor),
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: const Text('Record load'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _recordDisposal(context, ref, actor),
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('Disposal completed'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _reportFailure(context, ref, actor),
                  icon: const Icon(Icons.report_problem_outlined),
                  label: const Text('Cannot work this site'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recordLoad(
    BuildContext context,
    WidgetRef ref,
    String actor,
  ) async {
    final fill = TextEditingController();
    final volume = TextEditingController();
    final weight = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Current vehicle load'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: fill,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Fill percent (0–100)',
                  ),
                ),
                TextField(
                  controller: volume,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Actual volume (m³), if known',
                  ),
                ),
                TextField(
                  controller: weight,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Actual weight (kg), if known',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save offline'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
      await ref
          .read(fcLocalRepositoryProvider)
          .enqueueFieldLoad(
            task: task,
            actorId: actor,
            eventType: 'load_observation',
            observedAt: DateTime.now(),
            fillPercent: num.tryParse(fill.text.trim()),
            actualVolumeM3: num.tryParse(volume.text.trim()),
            actualWeightKg: num.tryParse(weight.text.trim()),
          );
      if (context.mounted) {
        _message(context, 'Load observation saved for sync.');
      }
    } catch (error) {
      if (context.mounted) _message(context, error.toString());
    } finally {
      fill.dispose();
      volume.dispose();
      weight.dispose();
    }
  }

  Future<void> _recordDisposal(
    BuildContext context,
    WidgetRef ref,
    String actor,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm disposal'),
        content: const Text(
          'This records that the vehicle was emptied and resets its planned load to zero.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Record disposal'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(fcLocalRepositoryProvider)
          .enqueueFieldLoad(
            task: task,
            actorId: actor,
            eventType: 'disposal',
            observedAt: DateTime.now(),
          );
      if (context.mounted) _message(context, 'Disposal event saved for sync.');
    } catch (error) {
      if (context.mounted) _message(context, error.toString());
    }
  }

  Future<void> _reportFailure(
    BuildContext context,
    WidgetRef ref,
    String actor,
  ) async {
    final photoRepo = ref.read(fcLocalPhotoRepositoryProvider);
    final before = await photoRepo.getActivePhoto(task.id, 'task', 'before');
    final after = await photoRepo.getActivePhoto(task.id, 'task', 'after');
    final evidence = <String>[
      if (before != null)
        'local-photo:${before.localPhotoId}'
      else if (after != null)
        'local-photo:${after.localPhotoId}'
      else if (task.beforePhotoUrl?.startsWith('https://') == true)
        task.beforePhotoUrl!
      else if (task.afterPhotoUrl?.startsWith('https://') == true)
        task.afterPhotoUrl!,
    ];
    if (!context.mounted) return;
    if (evidence.isEmpty) {
      _message(
        context,
        'Capture a task photo first so the officer can review this site.',
      );
      return;
    }
    var reason = 'site_inaccessible';
    final notes = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Cannot work this site'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: reason,
                    decoration: const InputDecoration(labelText: 'Reason'),
                    items: const [
                      DropdownMenuItem(
                        value: 'site_inaccessible',
                        child: Text('Site inaccessible'),
                      ),
                      DropdownMenuItem(
                        value: 'safety_hazard',
                        child: Text('Safety hazard'),
                      ),
                      DropdownMenuItem(
                        value: 'vehicle_failure',
                        child: Text('Vehicle failure'),
                      ),
                      DropdownMenuItem(
                        value: 'crew_unavailable',
                        child: Text('Crew unavailable'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => reason = value);
                    },
                  ),
                  TextField(
                    controller: notes,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'What happened?',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Stop this location'),
              ),
            ],
          ),
        ),
      );
      if (confirmed != true || !context.mounted) return;
      await ref
          .read(fcLocalRepositoryProvider)
          .enqueueTaskFailure(
            task: task,
            actorId: actor,
            reasonCode: reason,
            notes: notes.text,
            observedAt: DateTime.now(),
            evidenceRefs: evidence,
          );
      onFailureQueued(reason);
      if (context.mounted) {
        _message(
          context,
          'This location is stopped. Feedback is saved for sync.',
        );
      }
    } catch (error) {
      if (context.mounted) _message(context, error.toString());
    } finally {
      notes.dispose();
    }
  }

  void _message(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}
