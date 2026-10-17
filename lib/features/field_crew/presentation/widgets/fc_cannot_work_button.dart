import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/features/field_crew/providers/cleanup_tasks_provider.dart';
import 'package:ecopin_app/features/field_crew/providers/fc_local_repository_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FcCannotWorkButton extends ConsumerWidget {
  final CleanupTask task;
  final void Function(String reasonCode) onFailureQueued;

  const FcCannotWorkButton({
    super.key,
    required this.task,
    required this.onFailureQueued,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showCannotWorkDialog(context, ref),
        icon: const Icon(
          Icons.report_problem_outlined,
          color: AppColors.error,
          size: 20,
        ),
        label: Text(
          'Unable to Work This Site',
          style: AppTypography.button.copyWith(
            color: AppColors.error,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: AppColors.error.withValues(alpha: isDark ? 0.5 : 0.4),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusButton),
          ),
        ),
      ),
    );
  }

  Future<void> _showCannotWorkDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final photoRepo = ref.read(fcLocalPhotoRepositoryProvider);
    final before = await photoRepo.getActivePhoto(task.id, 'task', 'before');
    final after = await photoRepo.getActivePhoto(task.id, 'task', 'after');

    File? localPickedEvidence;
    String? existingEvidenceRef = before != null
        ? 'local-photo:${before.localPhotoId}'
        : after != null
            ? 'local-photo:${after.localPhotoId}'
            : (task.beforePhotoUrl?.startsWith('https://') == true)
                ? task.beforePhotoUrl
                : (task.afterPhotoUrl?.startsWith('https://') == true)
                    ? task.afterPhotoUrl
                    : null;

    if (!context.mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    var reason = 'site_inaccessible';
    final notes = TextEditingController();

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final hasPhoto = localPickedEvidence != null || existingEvidenceRef != null;

            Future<void> pickPhoto(ImageSource source) async {
              try {
                final picker = ImagePicker();
                final picked = await picker.pickImage(
                  source: source,
                  imageQuality: 80,
                );
                if (picked == null) return;
                setDialogState(() {
                  localPickedEvidence = File(picked.path);
                });
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Failed to pick photo: $e')),
                  );
                }
              }
            }

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Cannot Work This Site',
                style: TextStyle(
                  color: isDark ? AppColors.textPrimaryDark : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report a hazard or access issue to pause work at this location and notify dispatch.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: reason,
                      dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                      style: TextStyle(
                        color: isDark ? AppColors.textPrimaryDark : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Reason',
                        labelStyle: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                        filled: true,
                        fillColor: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white12 : Colors.grey.shade300,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white12 : Colors.grey.shade300,
                          ),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'site_inaccessible',
                          child: Text('Site inaccessible (road/gate blocked)'),
                        ),
                        DropdownMenuItem(
                          value: 'safety_hazard',
                          child: Text('Safety hazard (wires/dogs/hazmat)'),
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
                        if (value != null) setDialogState(() => reason = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notes,
                      maxLines: 3,
                      style: TextStyle(
                        color: isDark ? AppColors.textPrimaryDark : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        labelText: 'What happened?',
                        labelStyle: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                        hintText: 'Describe the issue or obstruction...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                        ),
                        filled: true,
                        fillColor: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white12 : Colors.grey.shade300,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white12 : Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Evidence Photo',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Photo preview or camera picker button
                    if (localPickedEvidence != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Image.file(
                              localPickedEvidence!,
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            IconButton(
                              icon: const CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.black54,
                                child: Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  localPickedEvidence = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => pickPhoto(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt, size: 18),
                              label: const Text('Take Photo'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(
                                  color: hasPhoto
                                      ? AppColors.primaryDark
                                      : (isDark ? Colors.white24 : Colors.grey.shade400),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => pickPhoto(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library, size: 18),
                              label: const Text('Gallery'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(
                                  color: isDark ? Colors.white24 : Colors.grey.shade400,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (existingEvidenceRef != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          '✓ Existing task photo will be attached as evidence.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.green.shade300 : Colors.green.shade700,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final currentHasPhoto = localPickedEvidence != null || existingEvidenceRef != null;
                    if (!currentHasPhoto) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Please capture an evidence photo of the issue.'),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(dialogContext, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Stop This Location'),
                ),
              ],
            );
          },
        ),
      );

      if (confirmed != true || !context.mounted) return;

      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User session not found')),
        );
        return;
      }

      final evidence = <String>[];
      if (localPickedEvidence != null) {
        // Upload / register local photo via repository
        final taskRepo = ref.read(cleanupTaskRepositoryProvider);
        await taskRepo.uploadTaskPhoto(task.id, localPickedEvidence!, 'before');
        final savedPhoto = await photoRepo.getActivePhoto(task.id, 'task', 'before');
        if (savedPhoto != null) {
          evidence.add('local-photo:${savedPhoto.localPhotoId}');
        } else {
          evidence.add(localPickedEvidence!.path);
        }
      } else if (existingEvidenceRef != null) {
        evidence.add(existingEvidenceRef);
      }

      await ref.read(fcLocalRepositoryProvider).enqueueTaskFailure(
        task: task,
        actorId: currentUserId,
        reasonCode: reason,
        notes: notes.text.trim().isEmpty ? 'Site unable to be worked' : notes.text.trim(),
        observedAt: DateTime.now(),
        evidenceRefs: evidence,
      );

      onFailureQueued(reason);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This location is stopped. Feedback is saved for sync.'),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      notes.dispose();
    }
  }
}
