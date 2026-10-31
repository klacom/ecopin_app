import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/features/field_crew/offline/fc_offline_package.dart';
import 'package:ecopin_app/features/field_crew/offline/fc_offline_package_notifier.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import '../widgets/fc_offline_ui.dart';
import '../widgets/fc_offline_package_details.dart';

class FieldCrewPrepareOfflineScreen extends ConsumerStatefulWidget {
  const FieldCrewPrepareOfflineScreen({super.key});
  @override
  ConsumerState<FieldCrewPrepareOfflineScreen> createState() =>
      _FieldCrewPrepareOfflineScreenState();
}

class _FieldCrewPrepareOfflineScreenState
    extends ConsumerState<FieldCrewPrepareOfflineScreen> {
  @override
  Widget build(BuildContext context) {
    final package = ref.watch(fcOfflinePackageNotifierProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Prepare offline')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 20,
            children: [
              FcOfflineCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Take assigned work into the field',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Prepare your assigned tasks, linked reports, evidence metadata, notes, and available route records while connected.',
                    ),
                    const SizedBox(height: 12),
                    Text(
                    'This downloads record information. Full-size evidence photos, reference lists, and map tiles may still need a connection. Review each preparation step before leaving.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Preparation starts a separate download when you choose it, including in Offline Only sync mode. Network preferences for queued uploads do not limit this download.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              FcOfflinePackageDetails(state: package),
              if (package.errorMessage != null)
                FcOfflineNotice(error: true, message: package.errorMessage!),
              AppButton(
                text: package.isReady
                    ? 'Update offline package'
                    : package.phase == FcOfflinePackagePhase.failed
                    ? 'Try preparation again'
                    : 'Prepare assigned work',
                isLoading: package.isDownloading,
                onPressed: package.isDownloading
                    ? null
                    : () => ref
                          .read(fcOfflinePackageNotifierProvider.notifier)
                          .prepare(),
              ),
              Text(
                'Updating preparation refreshes cached records. It does not commit queued changes or confirm that reports are complete.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              TextButton.icon(
                onPressed: () => context.push(FieldCrewAppRoutes.syncCenter),
                icon: const Icon(Icons.sync),
                label: const Text('Queued sync preferences are in Sync Center'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
