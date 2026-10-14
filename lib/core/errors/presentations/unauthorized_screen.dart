import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/shared/widgets/app_state_view.dart';

class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AppStateView(
      title: 'This page is not available for your account',
      message: 'Return to EcoPin to open the pages available to your role.',
      icon: Icons.lock_outline,
      actionLabel: 'Return to EcoPin',
      onAction: () => context.go('/landing'),
    ),
  );
}
