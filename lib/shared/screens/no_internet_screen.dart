import 'package:flutter/material.dart';
import 'package:ecopin_app/shared/widgets/app_state_view.dart';

// Retains the public class name for existing consumers; failures aren't always network loss.
class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key, this.onRetry, this.message = 'Check your connection and try again.'});
  final VoidCallback? onRetry;
  final String message;

  @override
  Widget build(BuildContext context) => AppStateView(title: 'This page could not load',
    message: message, icon: Icons.cloud_off_outlined, onAction: onRetry);
}
