import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';

enum ButtonVariant { primary, secondary, danger, link }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final ButtonVariant variant;
  final double width;
  final double height;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = ButtonVariant.primary,
    this.width = double.infinity,
    this.height = 56.0,
  });

  Color _backgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (variant) {
      case ButtonVariant.primary:
        return AppColors.accent;

      case ButtonVariant.secondary:
        return isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

      case ButtonVariant.danger:
        return AppColors.error;

      case ButtonVariant.link:
        return Colors.transparent;
    }
  }

  Color _textColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (variant) {
      case ButtonVariant.primary:
        return Colors.black;
      case ButtonVariant.danger:
        return Colors.white;

      case ButtonVariant.secondary:
        return isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
      case ButtonVariant.link:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;

    return SizedBox(
      width: width,
      height: height,
      child: TextButton(
        onPressed: disabled ? null : onPressed,
        style: TextButton.styleFrom(
          backgroundColor: disabled
              ? _backgroundColor(context).withValues(alpha: 0.5)
              : _backgroundColor(context),
          foregroundColor: _textColor(context),
          side: variant == ButtonVariant.secondary 
              ? BorderSide(color: Theme.of(context).brightness == Brightness.light ? Colors.black26 : Colors.white24, width: 1.5)
              : BorderSide.none,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(AppColors.radiusButton),
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppColors.spaceLG,
            vertical: AppColors.spaceMD,
          ),
          textStyle: Theme.of(context).textTheme.labelLarge,
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: _textColor(context),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: AppColors.spaceSM),
                  ],
                  Text(text),
                ],
              ),
      ),
    );
  }
}
