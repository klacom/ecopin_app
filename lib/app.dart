import 'package:flutter/material.dart';
import 'package:ecopin_app/routes/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ecopin_app/core/services/connectivity_service.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final connectivityAsync = ref.watch(connectivityProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Ecopin App',
      theme: ThemeData(primarySwatch: Colors.green),
      routerConfig: router,
      builder: (context, child) {
        return connectivityAsync.when(
          data: (connectivityResults) {
            final hasConnection = !connectivityResults.contains(
              ConnectivityResult.none,
            );
            if (!hasConnection) {
              return const NoInternetScreen();
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

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 24),
              const Text(
                'No Internet Connection',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your internet connection and try again',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
