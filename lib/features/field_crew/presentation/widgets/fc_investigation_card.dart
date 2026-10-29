import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../location/crew_investigation.dart';
import '../../location/crew_investigation_session.dart';
import 'fc_offline_ui.dart';

class FcInvestigationCard extends StatelessWidget {
  const FcInvestigationCard({super.key, required this.session, this.reportId});
  final CrewInvestigationSession session;
  final String? reportId;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: session,
    builder: (context, _) => FcOfflineCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'On-site investigation',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Stay within 5 m for 5 continuous minutes per incident. Keep EcoPin open. GPS accuracy must be 5 m or better.',
          ),
          for (final target in session.targets.where(
            (t) => reportId == null || t.id == reportId,
          )) ...[
            const SizedBox(height: 16),
            Text(target.label, style: Theme.of(context).textTheme.titleSmall),
            if (session.gates[target.id] case final gate?) ...[
              const SizedBox(height: 4),
              Text(gate.message),
              if (gate.distanceMetres != null)
                Text(
                  '${gate.distanceMetres!.toStringAsFixed(1)} m away · GPS accuracy ±${gate.accuracyMetres?.toStringAsFixed(1) ?? "?"} m',
                ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value:
                    gate.dwell.inMilliseconds /
                    CrewInvestigation.requiredDwell.inMilliseconds,
                semanticsLabel: 'Investigation time for ${target.label}',
              ),
              const SizedBox(height: 4),
              Text(
                gate.complete
                    ? '5:00 / 5:00 · Investigation recorded'
                    : '${gate.dwell.inMinutes}:${(gate.dwell.inSeconds % 60).toString().padLeft(2, '0')} / 5:00',
              ),
            ] else
              const Text(
                'Incident coordinates unavailable. Refresh the task or ask your officer to correct the pin.',
              ),
          ],
          if (session.error != null) ...[
            const SizedBox(height: 12),
            Text(session.error!),
            TextButton.icon(
              onPressed: session.retry,
              icon: const Icon(Icons.my_location),
              label: const Text('Retry precise location'),
            ),
            Wrap(
              children: [
                TextButton(
                  onPressed: Geolocator.openLocationSettings,
                  child: const Text('GPS settings'),
                ),
                TextButton(
                  onPressed: Geolocator.openAppSettings,
                  child: const Text('Permission settings'),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}
