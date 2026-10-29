import 'package:flutter/material.dart';

class AppTextField extends StatefulWidget {
  final String? labelText;
  final String text;
  final bool isLoading;
  final IconData? icon;
  final double width;
  final double? height;
  final String? placeholderText;
  final String? inputType;
  final TextEditingController controller;
  final String? hintText;
  final int? maxLines;
  final int? maxLength;
  final FocusNode? focusNode;
  final String? errorText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  const AppTextField({
    super.key,
    this.labelText,
    this.text = '',
    this.isLoading = false,
    this.icon,
    this.width = double.infinity,
    this.height,
    this.placeholderText = '',
    this.inputType = 'text',
    required this.controller,
    this.hintText = "",
    this.maxLines = 1,
    this.maxLength,
    this.focusNode,
    this.errorText,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: widget.height ?? 0),
      child: SizedBox(
      width: widget.width,
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        enabled: !widget.isLoading,
        keyboardType: widget.inputType == 'email'
            ? TextInputType.emailAddress
            : widget.inputType == 'number'
            ? TextInputType.number
            : TextInputType.text,
        textInputAction: widget.textInputAction,
        onSubmitted: widget.onSubmitted,
        autofillHints: widget.autofillHints ?? (widget.inputType == 'email'
            ? const [AutofillHints.email]
            : widget.inputType == 'password'
            ? const [AutofillHints.password]
                : null),
        autocorrect:
            widget.inputType != 'password' && widget.inputType != 'email',
        enableSuggestions: widget.inputType != 'password',
        obscureText: widget.inputType == 'password' ? _obscureText : false,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        decoration: InputDecoration(
          labelText: widget.labelText,
          errorText: widget.errorText,
          errorMaxLines: 3,
          hintText: (widget.hintText != null && widget.hintText!.isNotEmpty)
              ? widget.hintText
              : widget.placeholderText,
          // Inherits border styling from app_theme.dart
          suffixIcon: widget.inputType == 'password'
              ? IconButton(
                  tooltip: _obscureText ? 'Show password' : 'Hide password',
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                )
              : null,
        ),
      ),
      ),
    );
  }
}
