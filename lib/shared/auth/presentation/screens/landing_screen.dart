import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.scaffoldBackgroundColor;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        systemNavigationBarColor: surface,
        systemNavigationBarIconBrightness: theme.brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 528),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final headlineSize = (constraints.maxWidth * .125)
                              .clamp(34.0, 48.0);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Image.asset(
                                        'assets/logos/Full Logo Dark.png',
                                        width: 136,
                                        height: 40,
                                        fit: BoxFit.contain,
                                        color: Colors.white,
                                        colorBlendMode: BlendMode.srcIn,
                                        semanticLabel: 'EcoPin AI',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Text(
                                    'Made for\nPasig City',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 12,
                                      height: 1.35,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              Semantics(
                                header: true,
                                child: Text.rich(
                                  const TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'A cleaner Pasig\nstarts with ',
                                      ),
                                      TextSpan(
                                        text: 'us.',
                                        style: TextStyle(
                                          color: AppColors.environmentalDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: headlineSize,
                                    height: 1.08,
                                    letterSpacing: -1.4,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'See a concern in your neighborhood?\nPut it on the map. Follow its progress.',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 16,
                                  height: 1.5,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ExcludeSemantics(
                                child: SvgPicture.asset(
                                  'assets/illustrations/welcome_neighborhood.svg',
                                  width: constraints.maxWidth,
                                  height: constraints.maxWidth * .56,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _WelcomeStep(
                                    number: '01',
                                    label: 'Snap & pin',
                                  ),
                                  SizedBox(width: 12),
                                  _WelcomeStep(number: '02', label: 'Describe'),
                                  SizedBox(width: 12),
                                  _WelcomeStep(
                                    number: '03',
                                    label: 'Follow up',
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              SliverLayoutBuilder(
                builder: (context, constraints) => SliverToBoxAdapter(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          (constraints.viewportMainAxisExtent -
                                  constraints.precedingScrollExtent)
                              .clamp(0.0, double.infinity),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: SizedBox(
                              width: (constraints.crossAxisExtent - 48).clamp(
                                0,
                                480,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AppButton(
                                    text: 'Sign in',
                                    onPressed: () =>
                                        context.go(PublicAppRoutes.login),
                                  ),
                                  const SizedBox(height: 12),
                                  AppButton(
                                    text: 'Create an account',
                                    variant: ButtonVariant.secondary,
                                    onPressed: () =>
                                        context.go(PublicAppRoutes.register),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'For the places we call home.',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.number, required this.label});
  final String number;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12,
            color: Colors.white,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w400,
            height: 1.3,
          ),
        ),
      ],
    ),
  );
}
