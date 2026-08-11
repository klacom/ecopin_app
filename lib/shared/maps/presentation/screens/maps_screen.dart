import 'dart:convert';

import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/status_badge.dart';
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
import 'package:ecopin_app/shared/reports/providers/report_provider.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/my_marker_cluster_layer.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/report_marker.dart';
import 'package:ecopin_app/shared/profile/providers/profile_provider.dart';
import 'package:logging/logging.dart';
import 'package:ecopin_app/core/services/api_service.dart';

class MapScreen extends ConsumerStatefulWidget {
  final bool isFieldCrewMode;
  final bool showOptimizedRoute;
  final bool showOtherCrews;
  final bool showBaseOfOperations;

  const MapScreen({
    super.key,
    this.isFieldCrewMode = false,
    this.showOptimizedRoute = false,
    this.showOtherCrews = false,
    this.showBaseOfOperations = false,
  });

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final Logger log = Logger("Maps Screen");
  final MapController _mapController = MapController();

  // Mock Field Crew Data for high-fidelity visualization
  final LatLng _baseLocation = LatLng(14.5762, 121.0855);
  
  final List<Map<String, dynamic>> _otherCrews = [
    {
      'name': 'Juan Cruz',
      'location': LatLng(14.5710, 121.0820),
      'status': 'Active',
      'color': const Color(0xFF2E7D32),
    },
    {
      'name': 'Pedro Santos',
      'location': LatLng(14.5780, 121.0760),
      'status': 'Active',
      'color': const Color(0xFFF9A825),
    },
  ];

  final List<LatLng> _optimizedRoutePoints = [
    LatLng(14.5762, 121.0855), // Base
    LatLng(14.5745, 121.0830),
    LatLng(14.5720, 121.0815),
    LatLng(14.5710, 121.0820), // Crew 1
    LatLng(14.5680, 121.0840), // Task location 1
    LatLng(14.5700, 121.0900), // Task location 2
    LatLng(14.5735, 121.0880),
    LatLng(14.5762, 121.0855), // Back to base
  ];
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
    final colorScheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = textPrimary.withValues(alpha: 0.6);

    return Scaffold(
      body: reportsAsync.when(
        data: (reports) {
          // Filter out rejected reports
          var visibleReports = reports
              .where((r) => r.validationStatus.toLowerCase() != 'rejected')
              .toList();

          if (widget.isFieldCrewMode) {
            visibleReports = visibleReports
                .where((r) =>
                    r.status.toLowerCase() == 'in progress' ||
                    r.status.toLowerCase() == 'acknowledged' ||
                    r.status.toLowerCase() == 'pending')
                .toList();
          }
          return Stack(
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
                    urlTemplate: Theme.of(context).brightness == Brightness.dark
                        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'dev.ecopinas.ecopin_app',
                  ),
                  if (_showHeatmap)
                    HeatMapLayer(
                      heatMapDataSource: InMemoryHeatMapDataSource(
                        data: visibleReports.map((report) {
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
                      heatMapOptions: HeatMapOptions(
                        radius: 50,
                        minOpacity: 0.6,
                      ),
                    ),
                  CurrentLocationLayer(
                    alignPositionOnUpdate: AlignOnUpdate.never,
                    alignDirectionOnUpdate: AlignOnUpdate.never,
                    style: LocationMarkerStyle(
                      marker: DefaultLocationMarker(
                        child: Icon(
                          Icons.navigation,
                          color: colorScheme.surface,
                        ),
                      ),
                      markerSize: Size(40, 40),
                      markerDirection: MarkerDirection.heading,
                      accuracyCircleColor: Colors.blue,
                      headingSectorColor: Colors.blue,
                      headingSectorRadius: 60,
                      showAccuracyCircle: true,
                    ),
                  ),
                  if (widget.showOptimizedRoute)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _optimizedRoutePoints,
                          strokeWidth: 4.5,
                          color: const Color(0xFF699834),
                          borderColor: const Color(0xFF457113),
                          borderStrokeWidth: 1.5,
                        ),
                      ],
                    ),
                  if (widget.showBaseOfOperations)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _baseLocation,
                          width: 45,
                          height: 45,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF457113),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.home_work_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (widget.showOtherCrews)
                    MarkerLayer(
                      markers: _otherCrews.map((crew) {
                        return Marker(
                          point: crew['location'] as LatLng,
                          width: 42,
                          height: 42,
                          child: Tooltip(
                            message: '${crew['name']} (${crew['status']})',
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Pulsing/glow ring
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: (crew['color'] as Color).withValues(alpha: 0.2),
                                    border: Border.all(
                                      color: crew['color'] as Color,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                // Avatar circle
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: crew['color'] as Color,
                                  child: Text(
                                    (crew['name'] as String)
                                        .split(' ')
                                        .map((n) => n[0])
                                        .join(''),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                // Live dot indicator
                                Positioned(
                                  right: 4,
                                  bottom: 4,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2E7D32),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 1),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  MyMarkerClusterLayer(
                    markers: visibleReports.map((report) {
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
                        Consumer(
                          builder: (context, ref, child) {
                            final isDark =
                                Theme.of(context).brightness == Brightness.dark;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppColors.spaceLG,
                                vertical: AppColors.spaceSM,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.surfaceDark
                                    : AppColors.surfaceLight,
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
                                  Icon(
                                    Icons.search,
                                    color: isDark
                                        ? AppColors.secondaryDark
                                        : AppColors.secondaryLight,
                                  ),
                                  const SizedBox(width: AppColors.spaceMD),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      focusNode: _searchFocusNode,
                                      onChanged: _onSearchChanged,
                                      style: TextStyle(
                                        color: isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textPrimaryLight,
                                        fontSize: 16,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Search location...',
                                        hintStyle: TextStyle(
                                          color: isDark
                                              ? AppColors.secondaryDark
                                              : AppColors.secondaryLight,
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
                                        margin: const EdgeInsets.only(
                                          right: AppColors.spaceSM,
                                        ),
                                        padding: const EdgeInsets.all(
                                          AppColors.spaceXS,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.surfaceLight
                                              : AppColors.surfaceDark,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          color: isDark
                                              ? AppColors.secondaryLight
                                              : AppColors.secondaryDark,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  if (_isSearching)
                                    Container(
                                      margin: const EdgeInsets.only(
                                        right: AppColors.spaceSM,
                                      ),
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textPrimaryLight,
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
                                        padding: const EdgeInsets.all(
                                          AppColors.spaceXS,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _showSuggestions
                                              ? isDark
                                                    ? AppColors.surfaceLight
                                                    : AppColors.surfaceDark
                                              : isDark
                                              ? AppColors.surfaceDark
                                              : AppColors.surfaceLight,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          _showSuggestions
                                              ? Icons.keyboard_arrow_up
                                              : Icons.keyboard_arrow_down,
                                          color: isDark
                                              ? AppColors.secondaryDark
                                              : AppColors.secondaryLight,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppColors.spaceSM),
                        if (_showSuggestions)
                          Consumer(
                            builder: (context, ref, child) {
                              final isDark =
                                  Theme.of(context).brightness ==
                                  Brightness.dark;
                              return Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.surfaceDark
                                      : AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(
                                    AppColors.radiusCard,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                width: double.infinity,
                                height: 250,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(
                                    AppColors.spaceSM,
                                  ),
                                  itemCount: _suggestions.length,
                                  itemBuilder: (context, index) {
                                    final suggestion = _suggestions[index];
                                    return InkWell(
                                      onTap: () => _onSuggestionTap(suggestion),
                                      child: Container(
                                        margin: const EdgeInsets.only(
                                          bottom: AppColors.spaceXS,
                                        ),
                                        padding: const EdgeInsets.all(
                                          AppColors.spaceSM,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.backgroundDark
                                              : AppColors.backgroundLight,
                                          borderRadius: BorderRadius.circular(
                                            AppColors.radiusButton,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.location_pin,
                                              color: isDark
                                                  ? AppColors.secondaryDark
                                                  : AppColors.secondaryLight,
                                            ),
                                            const SizedBox(
                                              width: AppColors.spaceSM,
                                            ),
                                            Expanded(
                                              child: Text(
                                                suggestion.displayName,
                                                style: TextStyle(
                                                  color: isDark
                                                      ? AppColors
                                                            .textPrimaryDark
                                                      : AppColors
                                                            .textPrimaryLight,
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
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: AppColors.spaceLG,
                bottom: 100,
                child: SafeArea(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final isDark =
                          Theme.of(context).brightness == Brightness.dark;
                      return Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showHeatmap = !_showHeatmap;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(
                                bottom: AppColors.spaceMD,
                              ),
                              padding: const EdgeInsets.all(AppColors.spaceMD),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.surfaceDark
                                    : AppColors.surfaceLight,
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
                                    ? AppColors.success
                                    : isDark
                                    ? AppColors.secondaryDark
                                    : AppColors.secondaryLight,
                                size: 24,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _getCurrentLocation,
                            child: Container(
                              padding: const EdgeInsets.all(AppColors.spaceMD),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.surfaceDark
                                    : AppColors.surfaceLight,
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
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textPrimaryLight,
                                      ),
                                    )
                                  : Icon(
                                      Icons.my_location,
                                      color: isDark
                                          ? AppColors.secondaryDark
                                          : AppColors.secondaryLight,
                                      size: 24,
                                    ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              if (widget.isFieldCrewMode)
                Positioned(
                  left: AppColors.spaceMD,
                  right: AppColors.spaceMD,
                  bottom: 110, // Positioned above bottom nav bar
                  child: SafeArea(
                    child: Container(
                      padding: const EdgeInsets.all(AppColors.spaceMD),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(AppColors.radiusCard),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.route_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'AI-Optimized Task Route',
                                      style: AppTypography.body.copyWith(
                                        color: textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      'Factors: Traffic (Normal), Weather (Clear), Road works (Avoided)',
                                      style: AppTypography.caption.copyWith(
                                        color: textSecondary,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(AppColors.radiusChip),
                                ),
                                child: Text(
                                  'Live',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildMetric(Icons.linear_scale_rounded, 'Distance', '4.8 km', textPrimary, textSecondary),
                              _buildMetric(Icons.access_time_rounded, 'Est. Time', '24 mins', textPrimary, textSecondary),
                              _buildMetric(Icons.people_alt_rounded, 'Other Crews', '2 Nearby', textPrimary, textSecondary),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
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
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
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

  Widget _buildMetric(IconData icon, String label, String value, Color textPrimary, Color textSecondary) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: textSecondary),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(color: textSecondary, fontSize: 9, fontFamily: 'Outfit'),
            ),
            Text(
              value,
              style: TextStyle(
                color: textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
