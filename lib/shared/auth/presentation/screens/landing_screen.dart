import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Cyber dot-matrix background
          Positioned.fill(
            child: CustomPaint(
              painter: _DotMatrixPainter(Theme.of(context).brightness),
            ),
          ),
          
          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppColors.spaceXL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),
                  
                  // App Title / Logo area
                  Image.asset(
                    Theme.of(context).brightness == Brightness.light 
                        ? 'assets/logos/Full Logo Light.png' 
                        : 'assets/logos/Full Logo Dark.png',
                    height: 80,
                  ),
                  const SizedBox(height: AppColors.spaceMD),
                  
                  // Value Proposition
                  Text(
                    'Empowering communities for a cleaner environment. Report, track, and resolve issues in real-time.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).brightness == Brightness.light ? Colors.black87 : Colors.white70,
                      height: 1.5,
                    ),
                  ),
                  
                  const Spacer(flex: 3),
                  
                  // Login Button
                  AppButton(
                    text: 'Login',
                    variant: ButtonVariant.primary, // Neon Lime by default
                    onPressed: () => context.go('/login'),
                  ),
                  const SizedBox(height: AppColors.spaceMD),
                  
                  // Register Button
                  AppButton(
                    text: 'Register',
                    variant: ButtonVariant.secondary, // Assuming secondary is dark grey/outline
                    onPressed: () => context.go('/register'),
                  ),
                  
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotMatrixPainter extends CustomPainter {
  final Brightness brightness;
  _DotMatrixPainter(this.brightness);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (brightness == Brightness.light ? Colors.black : const Color(0xFFCCFF00)).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    const double spacing = 20.0;
    const double radius = 1.5;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        // Create a subtle fade out pattern or random missing dots for terminal feel
        if (Random().nextDouble() > 0.15) {
          canvas.drawCircle(Offset(x, y), radius, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
