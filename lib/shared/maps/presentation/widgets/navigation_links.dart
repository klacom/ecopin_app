import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
Uri wazeNavigationUri(LatLng destination) => Uri.https('waze.com', '/ul', {
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
    this.compact = false,
  });

  final LatLng destination;
  final NavigationLauncher launcher;
  final bool compact;

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
            compact
                ? 'Could not open $appName. Try another map app or copy the coordinates from Other map options.'
                : 'Could not open $appName. Install it or use the coordinates shown above.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => compact
      ? Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _open(
                  context,
                  googleMapsDirectionsUri(destination),
                  'Google Maps',
                ),
                icon: const Icon(Icons.map_outlined),
                label: const Text(
                  'Open in Google Maps',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              tooltip: 'Other map options',
              icon: const Icon(Icons.more_vert),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'waze', child: Text('Open in Waze')),
                PopupMenuItem(value: 'copy', child: Text('Copy coordinates')),
              ],
              onSelected: (value) async {
                if (value == 'waze') {
                  await _open(context, wazeNavigationUri(destination), 'Waze');
                } else {
                  var copied = false;
                  try {
                    await Clipboard.setData(
                      ClipboardData(
                        text:
                            '${destination.latitude.toStringAsFixed(6)}, ${destination.longitude.toStringAsFixed(6)}',
                      ),
                    );
                    copied = true;
                  } catch (_) {
                    /* Keep the location visible if clipboard access fails. */
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          copied
                              ? 'Coordinates copied.'
                              : 'Could not copy coordinates. Open Report information to view them.',
                        ),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        )
      : Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _open(
                context,
                googleMapsDirectionsUri(destination),
                'Google Maps',
              ),
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

/// One labeled "Directions" control: tapping opens a short menu with Google Maps,
/// Waze and copy-coordinates. Only exact locations should be passed.
class DirectionsMenuButton extends StatelessWidget {
  const DirectionsMenuButton({
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
            'Could not open $appName. Try another map app or copy the coordinates.',
          ),
        ),
      );
    }
  }

  Future<void> _copy(BuildContext context) async {
    var copied = false;
    try {
      await Clipboard.setData(
        ClipboardData(
          text:
              '${destination.latitude.toStringAsFixed(6)}, ${destination.longitude.toStringAsFixed(6)}',
        ),
      );
      copied = true;
    } catch (_) {
      /* The coordinates stay visible in More details if clipboard access fails. */
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            copied
                ? 'Coordinates copied.'
                : 'Could not copy coordinates. Open More details to view them.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: 'Directions',
    onSelected: (value) => switch (value) {
      'google' => _open(
        context,
        googleMapsDirectionsUri(destination),
        'Google Maps',
      ),
      'waze' => _open(context, wazeNavigationUri(destination), 'Waze'),
      _ => _copy(context),
    },
    itemBuilder: (_) => const [
      PopupMenuItem(value: 'google', child: Text('Open in Google Maps')),
      PopupMenuItem(value: 'waze', child: Text('Open in Waze')),
      PopupMenuItem(value: 'copy', child: Text('Copy coordinates')),
    ],
    child: ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 64, minHeight: 48),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            Text(
              'Directions',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
