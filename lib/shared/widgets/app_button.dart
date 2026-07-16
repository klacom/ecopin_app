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
    this.height = 50.0,
  });

  Color _backgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (variant) {
      case ButtonVariant.primary:
        return isDark ? AppColors.primaryDark : AppColors.primaryLight;

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
        return isDark ? AppColors.textPrimaryLight : AppColors.textPrimaryDark;
      case ButtonVariant.danger:
        return Colors.white;

      case ButtonVariant.secondary:
      case ButtonVariant.link:
        return isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
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
          backgroundColor: _backgroundColor(context),
          foregroundColor: _textColor(context),
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
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _textColor(context),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon),
                    const SizedBox(width: AppColors.spaceSM),
                  ],
                  Text(text),
                ],
              ),
      ),
    );
  }
}
