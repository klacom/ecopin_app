import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';

// GoRouter owns navigation; this screen adds no delay.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Image.asset(Theme.of(context).brightness == Brightness.light
          ? 'assets/logos/Full Logo Light.png' : 'assets/logos/Full Logo Dark.png', height: 48),
      const SizedBox(height: 32),
      const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(
        strokeWidth: 2.5, color: AppColors.accent, semanticsLabel: 'Opening EcoPin')),
      const SizedBox(height: 16),
      Text('Opening EcoPin…', style: Theme.of(context).textTheme.bodyMedium),
    ]),
  ))));
}
