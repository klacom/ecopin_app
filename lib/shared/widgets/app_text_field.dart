import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  final String? labelText;
  final String text;
  final bool isLoading;
  final IconData? icon;
  final double width;
  final double height;
  final String? placeholderText;
  final String? inputType;
  final TextEditingController controller;

  const AppTextField({
    super.key,
    this.labelText,
    this.text = '',
    this.isLoading = false,
    this.icon,
    this.width = double.infinity,
    this.height = 50.0,
    this.placeholderText = '',
    this.inputType = 'text', 
    required this.controller, 
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: TextField(
        controller: controller,
        obscureText: inputType == 'password',
        decoration: InputDecoration(
          labelText: labelText,
          hintText: placeholderText,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
