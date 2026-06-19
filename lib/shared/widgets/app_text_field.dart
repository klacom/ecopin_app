import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: inputType == 'password',
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: (hintText != null && hintText!.isNotEmpty)
              ? hintText
              : placeholderText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
