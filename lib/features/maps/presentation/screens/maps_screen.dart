import 'package:ecopin_app/features/auth/providers/auth_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ecopin_app/core/constants/app_constants.dart';
import 'package:ecopin_app/core/services/location_search_service.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:ecopin_app/routes/app_routes.dart';

import 'package:ecopin_app/features/reports/providers/report_provider.dart';
import 'package:ecopin_app/features/reports/data/models/report_model.dart';
import 'package:ecopin_app/features/profile/providers/profile_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final LocationSearchService _searchService = LocationSearchService();
  final FocusNode _searchFocusNode = FocusNode();

  List<LocationSuggestion> _suggestions = [];
  bool _showSuggestions = false;
  Timer? _debounce;
  bool _showHeatmap = false;
  bool _isLoadingLocation = false;

  String _getInitials(String? fullName) {
    if (fullName == null || fullName.isEmpty) return '?';
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    } else {
      return parts[0][0].toUpperCase();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled.')),
          );
        }
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied.')),
            );
          }
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permissions are permanently denied, we cannot request permissions.',
              ),
            ),
          );
        }
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          16.0,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (query.length >= 2) {
        final results = await _searchService.searchLocations(
          query,
          city: 'Pasig',
        );
        setState(() {
          _suggestions = results;
          _showSuggestions = results.isNotEmpty;
        });
      } else {
        setState(() {
          _showSuggestions = false;
          _suggestions = [];
        });
      }
    });
  }

  void _onSuggestionTap(LocationSuggestion suggestion) {
    _mapController.move(suggestion.latLng, 16.0);
    _searchController.text = suggestion.displayName;
    setState(() {
      _showSuggestions = false;
      _suggestions = [];
    });
    _searchFocusNode.unfocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(reportsStreamProvider);
    final profileAsync = ref.watch(profileProvider);
    final profileInitials = _getInitials(
      profileAsync.value?['full_name'] as String?,
    );
    final avatarUrl = profileAsync.value?['avatar_url'] as String?;

    return Scaffold(
      body: reportsAsync.when(
        data: (reports) => Stack(
          fit: StackFit.expand,
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: pasigInitialCenter,
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
                if (_showHeatmap)
                  CircleLayer(
                    circles: reports.map((report) {
                      double radius;
                      Color color;
                      switch (report.status.toLowerCase()) {
                        case 'resolved':
                          radius = 50;
                          color = Colors.green.withOpacity(0.3);
                          break;
                        case 'in progress':
                          radius = 80;
                          color = Colors.orange.withOpacity(0.4);
                          break;
                        default:
                          radius = 100;
                          color = Colors.red.withOpacity(0.5);
                          break;
                      }
                      return CircleMarker(
                        point: report.location,
                        radius: radius,
                        color: color,
                        borderStrokeWidth: 0,
                      );
                    }).toList(),
                  ),
                MarkerLayer(
                  markers: reports.map((report) {
                    return Marker(
                      point: report.location,
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => _showReportPreview(context, report),
                        child: _ReportMarker(status: report.status),
                      ),
                    );
                  }).toList(),
                ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                      onTap: () => launchUrl(
                        Uri.parse('https://openstreetmap.org/copyright'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.grey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                onChanged: _onSearchChanged,
                                decoration: const InputDecoration(
                                  hintText: 'Search location...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () =>
                                  context.go(ProtectedAppRoutes.profile),
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundImage:
                                    avatarUrl != null && avatarUrl.isNotEmpty
                                    ? NetworkImage(
                                        "$avatarUrl?t=${DateTime.now().millisecondsSinceEpoch}",
                                      )
                                    : null,
                                child: avatarUrl == null || avatarUrl.isEmpty
                                    ? Text(
                                        profileInitials,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_showSuggestions)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          width: double.infinity,
                          height: 250,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _suggestions.length,
                            itemBuilder: (context, index) {
                              final suggestion = _suggestions[index];
                              return InkWell(
                                onTap: () => _onSuggestionTap(suggestion),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.location_pin,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          suggestion.displayName,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 100, // Above the bottom navbar which is 80px
              child: SafeArea(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showHeatmap = !_showHeatmap;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.thermostat,
                          color: _showHeatmap
                              ? Colors.green
                              : Colors.grey.shade700,
                          size: 24,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _getCurrentLocation,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: _isLoadingLocation
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                Icons.my_location,
                                color: Colors.grey.shade700,
                                size: 24,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showReportPreview(BuildContext context, ReportModel report) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) => Container(
        margin: const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          110,
        ), // Margin at bottom to stay above floating navbar
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    report.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _StatusBadge(status: report.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              report.issueType ?? 'General Issue',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Text(
              report.description ?? 'No description.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('${ProtectedAppRoutes.reports}/${report.id}');
                },
                child: const Text('View Full Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportMarker extends StatelessWidget {
  final String status;

  const _ReportMarker({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'resolved':
        color = Colors.green;
        break;
      case 'in progress':
        color = Colors.orange;
        break;
      default:
        color = Colors.red;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.location_pin, color: Colors.white, size: 20),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'resolved':
        color = Colors.green;
        break;
      case 'in progress':
        color = Colors.orange;
        break;
      default:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
