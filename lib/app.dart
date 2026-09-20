import 'package:flutter/material.dart';
import 'package:ecopin_app/routes/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ecopin_app/core/services/connectivity_service.dart';
import 'package:ecopin_app/core/constants/app_constants.dart';
import 'package:ecopin_app/shared/screens/no_internet_screen.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/core/providers/theme_mode_provider.dart';
import 'package:ecopin_app/core/services/sync_service.dart';
import 'package:ecopin_app/shared/common/presentation/widgets/offline_sync_banner.dart';

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
            final hasConnection = !connectivityResults.contains(ConnectivityResult.none);
            
            // Trigger sync when connection is restored
            if (hasConnection) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(syncServiceProvider).syncAll();
              });
            }

            return Column(
              children: [
                if (!hasConnection)
                  const Material(
                    child: SafeArea(
                      bottom: false,
                      child: OfflineSyncBanner(),
                    ),
                  ),
                Expanded(
                  child: child ?? const SizedBox.shrink(),
                ),
              ],
            );
          },
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, stackTrace) => Scaffold(body: Center(child: Text('Error: $error'))),
        );
      },
    );
  }
}
