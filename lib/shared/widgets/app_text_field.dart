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
  final FocusNode? focusNode;

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
    this.focusNode,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        obscureText: widget.inputType == 'password' ? _obscureText : false,
        maxLines: widget.maxLines,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: (widget.hintText != null && widget.hintText!.isNotEmpty)
              ? widget.hintText
              : widget.placeholderText,
          border: const OutlineInputBorder(),
          suffixIcon: widget.inputType == 'password'
              ? IconButton(
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
    );
  }
}
