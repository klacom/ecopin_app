import 'package:flutter/material.dart';

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
    switch (variant) {
      case ButtonVariant.primary:
        return Theme.of(context).primaryColor;

      case ButtonVariant.secondary:
        return Colors.grey.shade200;

      case ButtonVariant.danger:
        return Colors.red;

      case ButtonVariant.link:
        return Colors.transparent;
    }
  }

  Color _textColor(BuildContext context) {
    switch (variant) {
        case ButtonVariant.primary:
        case ButtonVariant.danger:
          return Colors.white;
    
        case ButtonVariant.secondary:
        case ButtonVariant.link:
            return Colors.black;
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                    ),
                )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        if (icon != null) ...[
                            Icon(icon),
                            const SizedBox(width:8),
                        ],
                        Text(text),
                    ],
                ),
        )
    );
  }
}
