import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';

class FcLguNotesSection extends StatefulWidget {
  final Future<void> Function(String note) onSubmit;
  final bool isAssigned;

  const FcLguNotesSection({super.key, required this.onSubmit, required this.isAssigned});

  @override
  State<FcLguNotesSection> createState() => _FcLguNotesSectionState();
}

class _FcLguNotesSectionState extends State<FcLguNotesSection> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  void _submit() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(_controller.text.trim()).timeout(const Duration(seconds: 15));
      _controller.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add note: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isAssigned) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppColors.spaceLG),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Operational Note', style: AppTypography.h5.copyWith(color: AppColors.textPrimaryDark)),
          const SizedBox(height: AppColors.spaceSM),
          Text('This note will be visible to officers and other crew members.', style: AppTypography.caption.copyWith(color: Colors.grey)),
          const SizedBox(height: AppColors.spaceLG),
          TextField(
            controller: _controller,
            maxLines: 3,
            style: AppTypography.body.copyWith(color: AppColors.textPrimaryDark),
            decoration: InputDecoration(
              hintText: 'Enter your notes here...',
              hintStyle: AppTypography.body.copyWith(color: Colors.grey),
              filled: true,
              fillColor: AppColors.backgroundDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppColors.radiusInput),
                borderSide: const BorderSide(color: AppColors.dividerDark),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppColors.radiusInput),
                borderSide: const BorderSide(color: AppColors.dividerDark),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppColors.radiusInput),
                borderSide: const BorderSide(color: AppColors.primaryDark),
              ),
            ),
          ),
          const SizedBox(height: AppColors.spaceMD),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: AppColors.backgroundDark,
                disabledBackgroundColor: AppColors.surfaceDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppColors.radiusButton)),
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.backgroundDark))
                  : const Text('Add Note', style: AppTypography.button),
            ),
          ),
        ],
      ),
    );
  }
}
