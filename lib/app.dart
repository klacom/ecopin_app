import 'package:flutter/material.dart';
import 'package:ecopin_app/routes/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ecopin_app/core/services/connectivity_service.dart';
import 'package:ecopin_app/core/constants/app_constants.dart';
import 'package:ecopin_app/shared/screens/no_internet_screen.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/core/providers/theme_mode_provider.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final connectivityAsync = ref.watch(connectivityProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      scaffoldMessengerKey: messengerKey, // in app constants
      debugShowCheckedModeBanner: false,
      title: 'Ecopin App',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        return connectivityAsync.when(
          data: (connectivityResults) {
            final hasConnection = !connectivityResults.contains(
              ConnectivityResult.none,
            );
            if (!hasConnection) {
              return const NoInternetScreen(); // show now interenet
            }
            return child!;
          },
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, stackTrace) =>
              Scaffold(body: Center(child: Text('Error: $error'))),
        );
      },
    );
  }
}
