import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

/// Directions to [destination] from the device's current position, in the Google Maps app or site.
Uri googleMapsDirectionsUri(LatLng destination) =>
    Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${destination.latitude},${destination.longitude}',
      'travelmode': 'driving',
    });

/// Starts Waze navigation to [destination]; the Waze site opens if the app is not installed.
Uri wazeNavigationUri(LatLng destination) =>
    Uri.https('waze.com', '/ul', {
      'll': '${destination.latitude},${destination.longitude}',
      'navigate': 'yes',
    });

typedef NavigationLauncher = Future<bool> Function(Uri uri);

Future<bool> _launchExternally(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// "Open in Google Maps" and "Open in Waze" actions for a location.
/// Only exact locations should be passed: an approximate point would send people to the wrong place.
class OpenInNavigationButtons extends StatelessWidget {
  const OpenInNavigationButtons({
    super.key,
    required this.destination,
    this.launcher = _launchExternally,
  });

  final LatLng destination;
  final NavigationLauncher launcher;

  Future<void> _open(BuildContext context, Uri uri, String appName) async {
    var opened = false;
    try {
      opened = await launcher(uri);
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open $appName. Install it or use the coordinates shown above.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      OutlinedButton.icon(
        onPressed: () =>
            _open(context, googleMapsDirectionsUri(destination), 'Google Maps'),
        icon: const Icon(Icons.map_outlined),
        label: const Text('Open in Google Maps'),
      ),
      OutlinedButton.icon(
        onPressed: () =>
            _open(context, wazeNavigationUri(destination), 'Waze'),
        icon: const Icon(Icons.navigation_outlined),
        label: const Text('Open in Waze'),
      ),
    ],
  );
}
