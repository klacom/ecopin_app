import 'dart:convert';

import 'package:ecopin_app/features/maps/presentation/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
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
import 'package:ecopin_app/features/maps/presentation/widgets/my_marker_cluster_layer.dart';
import 'package:ecopin_app/features/maps/presentation/widgets/report_marker.dart';
import 'package:ecopin_app/features/profile/providers/profile_provider.dart';
import 'package:logging/logging.dart';
import 'package:ecopin_app/core/services/api_service.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final Logger log = Logger("Maps Screen");
  final MapController _mapController = MapController();
  // TODO: Make own Text Editing Controller + Separate controller in different file.
  final TextEditingController _searchController = TextEditingController();
  final LocationSearchService _searchService = LocationSearchService();
  final FocusNode _searchFocusNode = FocusNode();

  List<LocationSuggestion> _suggestions = [];
  bool _showSuggestions = false;
  Timer? _debounce;
  bool _showHeatmap = false;
  bool _isLoadingLocation = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runOnce(); // check and ask for user data/location disclosure initially.
    });
    _searchController.addListener(() {
      setState(() {});
    });
  }

  void _runOnce() async {
    final apiClient = ref.read(apiClientProvider);
    await apiClient.getProfile().then((data) {
      // log.fine('profile in runonce: ', data);
      Map<String, dynamic> user = jsonDecode(data.toString());
      // log.info('USER data consent run once : ', user['profile']['data_consent']);

      // Checking
      // If user hasn't given their consent yet.
      if (user['profile']['data_consent'] == null) {
        // log.info('IS USER CONSENT NULL: ', user['profile']['data_consent'].toString() == "");
        if (mounted) _dialogBuilder(context);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // For Data/Location Disclosure

  Future<void> _dialogBuilder(BuildContext context) {
    final apiClient = ref.read(apiClientProvider);
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.privacy_tip_outlined),
          title: const Text("Data Privacy Consent"),
          content: const SingleChildScrollView(
            child: Text(
              "To help the LGU verify and resolve your reports more efficiently, "
              "you may allow authorized personnel to access your profile information "
              "and location (when applicable).\n\n"
              "Your information will only be used for handling your reports and "
              "will not be shared with unauthorized parties.\n\n"
              "Your consent is optional, and you can continue using the app even if you decline.",
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Disagree"),
              onPressed: () async {
                try {
                  await apiClient.updateDataConsent(false);
                } catch (e) {
                  log.severe("Failed to update consent: $e");
                }

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
            FilledButton(
              child: const Text("Agree"),
              onPressed: () async {
                try {
                  await apiClient.updateDataConsent(true);
                } catch (e) {
                  log.severe("Failed to update consent: $e");
                }

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
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

    if (query.length >= 2) {
      setState(() {
        _isSearching = true;
      });
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (query.length >= 2) {
        final results = await _searchService.searchLocations(query);
        setState(() {
          _suggestions = results;
          _showSuggestions = results.isNotEmpty;
          _isSearching = false;
        });
      } else {
        setState(() {
          _showSuggestions = false;
          _suggestions = [];
          _isSearching = false;
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
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(reportsStreamProvider);

    return Scaffold(
      body: reportsAsync.when(
        data: (reports) => Stack(
          fit: StackFit.expand,
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: pasigInitialCenter,
                initialZoom: 15.0,
                minZoom: 3,
                maxZoom: 18,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
                onTap: (tapPosition, point) {
                  context.push(ProtectedAppRoutes.createReport, extra: point);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'dev.ecopinas.ecopin_app',
                ),
                if (_showHeatmap)
                  HeatMapLayer(
                    heatMapDataSource: InMemoryHeatMapDataSource(
                      data: reports.map((report) {
                        double weight;
                        switch (report.status.toLowerCase()) {
                          case 'resolved':
                          case 'closed':
                            weight = 0.3;
                            break;
                          case 'in progress':
                          case 'acknowledged':
                          case 'waiting_for_feedback':
                            weight = 0.6;
                            break;
                          case 'pending_owner_consent':
                            weight = 0.8;
                            break;
                          default:
                            weight = 1.0;
                            break;
                        }
                        return WeightedLatLng(report.location, weight);
                      }).toList(),
                    ),
                    heatMapOptions: HeatMapOptions(radius: 50, minOpacity: 0.6),
                  ),
                CurrentLocationLayer(
                  alignPositionOnUpdate: AlignOnUpdate.never,
                  alignDirectionOnUpdate: AlignOnUpdate.never,
                  style: const LocationMarkerStyle(
                    marker: DefaultLocationMarker(
                      child: Icon(Icons.navigation, color: Colors.white),
                    ),
                    markerSize: Size(40, 40),
                    markerDirection: MarkerDirection.heading,
                    accuracyCircleColor: Colors.blue,
                    headingSectorColor: Colors.blue,
                    headingSectorRadius: 60,
                    showAccuracyCircle: true,
                  ),
                ),
                MyMarkerClusterLayer(
                  markers: reports.map((report) {
                    return Marker(
                      point: report.location,
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => _showReportPreview(context, report),
                        child: ReportMarker(status: report.status),
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
                            if (_searchController.text.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() {
                                    _showSuggestions = false;
                                    _suggestions = [];
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.grey,
                                    size: 18,
                                  ),
                                ),
                              ),
                            if (_isSearching)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 20,
                                height: 20,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            if (_suggestions.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showSuggestions = !_showSuggestions;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: _showSuggestions
                                        ? Colors.grey.shade300
                                        : Colors.grey.shade200,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _showSuggestions
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
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
              bottom: 100,
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
                StatusBadge(status: report.status),
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
