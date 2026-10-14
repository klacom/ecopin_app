import 'package:flutter/material.dart';
import 'app_button.dart';

class AppStateView extends StatelessWidget {
  const AppStateView({super.key, required this.title, required this.message, required this.icon, this.onAction, this.actionLabel = 'Try again'});
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String actionLabel;

  @override
  Widget build(BuildContext context) => SafeArea(child: LayoutBuilder(builder: (context, constraints) {
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Center(child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 480, minHeight: constraints.hasBoundedHeight ? (constraints.maxHeight - 48).clamp(0, double.infinity) : 0),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 48, color: Theme.of(context).colorScheme.onSurface),
        const SizedBox(height: 24),
        Semantics(header: true, child: Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge)),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
        if (onAction != null) ...[const SizedBox(height: 24), AppButton(text: actionLabel, onPressed: onAction)],
      ]),
    )));
  }));
}
