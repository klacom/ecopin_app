import 'package:flutter/material.dart';

Future<String?> showCleanupNotesDialog(
  BuildContext context, {
  required String title,
  required String description,
}) async {
  final controller = TextEditingController();
  final form = GlobalKey<FormState>();
  try {
    return await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    labelText: 'Action notes (required)',
                    hintText:
                        'Describe the work done and conditions left on site.',
                  ),
                  validator: (value) => value?.trim().isNotEmpty == true
                      ? null
                      : 'Describe the work or observation before continuing.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: const Text('Save for sync'),
          ),
        ],
      ),
    );
  } finally {
    // Let the closing dialog finish its transition before releasing the field.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
  }
}
