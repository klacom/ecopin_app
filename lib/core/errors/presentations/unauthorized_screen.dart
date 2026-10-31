import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/shared/auth/providers/auth_notifier.dart';
import 'package:ecopin_app/shared/widgets/app_state_view.dart';

class UnauthorizedScreen extends ConsumerWidget {
  const UnauthorizedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(authNotifierProvider).state.isAuthenticated;
    return Scaffold(
      body: AppStateView(
        title: signedIn
            ? 'This account uses the EcoPin web dashboard'
            : 'This page is not available for your account',
        message: signedIn
            ? 'Officer and administrator workspaces are not part of the mobile app. Sign out here, then sign in on the web dashboard.'
            : 'Return to EcoPin to open the pages available to your role.',
        icon: Icons.lock_outline,
        actionLabel: signedIn ? 'Sign out' : 'Return to EcoPin',
        onAction: () async {
          if (signedIn) await ref.read(authNotifierProvider).signOut();
          if (context.mounted) context.go('/landing');
        },
      ),
    );
  }
}
