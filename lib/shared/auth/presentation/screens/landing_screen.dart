import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
    final theme = Theme.of(context);
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Center(child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 480, minHeight: (constraints.maxHeight - 48).clamp(0, double.infinity)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Align(alignment: Alignment.centerLeft, child: Image.asset(
          theme.brightness == Brightness.light ? 'assets/logos/Full Logo Light.png' : 'assets/logos/Full Logo Dark.png', height: 40)),
        const SizedBox(height: 32),
        Semantics(header: true, child: Text('A cleaner Pasig starts with us.', style: theme.textTheme.headlineSmall)),
        const SizedBox(height: 16),
        Text('Report an environmental concern, put it on the map, and follow its progress.', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 32),
        for (final benefit in [
          (Icons.add_a_photo_outlined, 'Add a photo and location'),
          (Icons.edit_note, 'Describe it in your own words'),
          (Icons.update, 'Follow your report'),
        ]) Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(benefit.$1, color: theme.brightness == Brightness.dark ? AppColors.linkDark : AppColors.accent),
          const SizedBox(width: 12), Expanded(child: Text(benefit.$2, style: theme.textTheme.bodyMedium)),
        ])),
        const SizedBox(height: 16),
        AppButton(text: 'Sign in', onPressed: () => context.go('/login')),
        const SizedBox(height: 16),
        AppButton(text: 'Create an account', variant: ButtonVariant.secondary, onPressed: () => context.go('/register')),
      ]),
    )));
  })));
}
