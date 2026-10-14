import 'package:flutter/material.dart';

/// A bounded, scrollable account form that follows keyboard and text size.
class AuthPageBody extends StatelessWidget {
  const AuthPageBody({super.key, required this.title, required this.description, required this.children});
  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SafeArea(child: LayoutBuilder(builder: (context, constraints) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(24),
      child: Center(child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 480, minHeight: (constraints.maxHeight - 48).clamp(0, double.infinity)),
        child: AutofillGroup(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(header: true, child: Text(title, style: Theme.of(context).textTheme.headlineSmall)),
            const SizedBox(height: 12),
            Text(description, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 32),
            ...children,
          ],
        )),
      )),
    );
  }));
}
