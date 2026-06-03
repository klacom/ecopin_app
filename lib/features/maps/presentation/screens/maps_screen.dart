import 'package:ecopin_app/features/auth/providers/auth_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ecopin_app/core/constants/app_constants.dart';

import 'package:go_router/go_router.dart';
import 'package:ecopin_app/routes/app_routes.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  // Constrain to Pasig Area only

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EcoPin Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authNotifierProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter:
              pasigInitialCenter, // Manila coordinates as a better default
          initialZoom: 14.0,
          minZoom: 12,
          maxZoom: 18,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
          cameraConstraint: CameraConstraint.contain(bounds: pasigBounds),
          onTap: (tapPosition, point) {
            context.push(ProtectedAppRoutes.createReport, extra: point);
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'dev.ecopinas.ecopin_app',
            tileBounds: pasigBounds,
          ),
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution(
                'OpenStreetMap contributors',
                onTap: () =>
                    launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
