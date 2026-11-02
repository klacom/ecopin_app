import 'package:flutter/material.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'fc_offline_ui.dart';

// Operational notes section (formerly LGU notes).
typedef FcNotesSection = FcLguNotesSection;

/// A note for officers and other crew members. It saves on this phone first.
class FcLguNotesSection extends StatefulWidget {
  final Future<void> Function(String note) onSubmit;
  final bool isAssigned;

  const FcLguNotesSection({
    super.key,
    required this.onSubmit,
    required this.isAssigned,
  });

  @override
  State<FcLguNotesSection> createState() => _FcLguNotesSectionState();
}

class _FcLguNotesSectionState extends State<FcLguNotesSection> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final note = _controller.text.trim();
    if (note.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(note).timeout(const Duration(seconds: 15));
      _controller.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The note could not be saved. Try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isAssigned) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return FcOfflineCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text('Add a note', style: theme.textTheme.titleMedium),
          ),
          const SizedBox(height: 4),
          Text(
            'Officers and other crew members can read this note.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            minLines: 3,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Note',
              hintText: 'What did you find or do?',
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            text: 'Send note',
            icon: Icons.send_outlined,
            isLoading: _isSubmitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
