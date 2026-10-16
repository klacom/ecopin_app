import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';

// Operational Notes Section (Formerly LGU Notes)
typedef FcNotesSection = FcLguNotesSection;

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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade100;
    final inputBorderColor = isDark ? Colors.white10 : Colors.grey.shade300;
    final textColor = isDark ? AppColors.textPrimaryDark : Colors.black87;
    final fillColor = isDark ? AppColors.surfaceDark : Colors.grey.shade100;

    return Container(
      padding: const EdgeInsets.all(AppColors.spaceLG),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Operational Note', style: AppTypography.h5.copyWith(color: textColor)),
          const SizedBox(height: AppColors.spaceSM),
          Text('This note will be visible to officers and other crew members.', style: AppTypography.caption.copyWith(color: Colors.grey)),
          const SizedBox(height: AppColors.spaceLG),
          TextField(
            controller: _controller,
            maxLines: 3,
            style: AppTypography.body.copyWith(color: textColor),
            decoration: InputDecoration(
              hintText: 'Enter your notes here...',
              hintStyle: AppTypography.body.copyWith(color: Colors.grey),
              filled: true,
              fillColor: fillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppColors.radiusInput),
                borderSide: BorderSide(color: inputBorderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppColors.radiusInput),
                borderSide: BorderSide(color: inputBorderColor),
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
                foregroundColor: Colors.white,
                disabledBackgroundColor: fillColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppColors.radiusButton)),
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Add Note', style: AppTypography.button),
            ),
          ),
        ],
      ),
    );
  }
}
