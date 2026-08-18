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
import 'package:ecopin_app/shared/maps/presentation/widgets/cluster_marker.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/report_marker.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/status_badge.dart';
import 'package:logging/logging.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/core/theme/colors.dart';

class OfficerMapScreen extends ConsumerStatefulWidget {
  const OfficerMapScreen({super.key});

  @override
  ConsumerState<OfficerMapScreen> createState() => _OfficerMapScreenState();
}

class _OfficerMapScreenState extends ConsumerState<OfficerMapScreen> {
  final Logger log = Logger("Lgu Maps Screen");
  final MapController _mapController = MapController();
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
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
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
        if (mounted) {
          setState(() {
            _suggestions = results;
            _showSuggestions = results.isNotEmpty;
            _isSearching = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _showSuggestions = false;
            _suggestions = [];
            _isSearching = false;
          });
        }
      }
    });
  }

  List<Marker> _buildClusterMarkers(List<ReportModel> reports) {
    // Group reports by clusterId
    final Map<String?, List<ReportModel>> groupedReports = {};
    
    for (final report in reports) {
      final clusterId = report.clusterId;
      if (!groupedReports.containsKey(clusterId)) {
        groupedReports[clusterId] = [];
      }
      groupedReports[clusterId]!.add(report);
    }

    final List<Marker> markers = [];

    // Process each group
    for (final entry in groupedReports.entries) {
      final clusterId = entry.key;
      final clusterReports = entry.value;

      if (clusterId == null || clusterReports.length == 1) {
        // Individual report (no cluster or single report in cluster)
        for (final report in clusterReports) {
          markers.add(
            Marker(
              point: report.location,
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => _showReportPreview(context, report),
                child: ReportMarker(status: report.status),
              ),
            ),
          );
        }
      } else {
        // Cluster marker for reports with same clusterId
        // Calculate centroid of cluster
        final double avgLat = clusterReports
            .map((r) => r.location.latitude)
            .reduce((a, b) => a + b) / clusterReports.length;
        final double avgLng = clusterReports
            .map((r) => r.location.longitude)
            .reduce((a, b) => a + b) / clusterReports.length;

        // Determine dominant issue type
        final Map<String, int> issueTypeCounts = {};
        for (final report in clusterReports) {
          final issueType = report.issueType ?? 'unknown';
          issueTypeCounts[issueType] = (issueTypeCounts[issueType] ?? 0) + 1;
        }
        final dominantIssueType = issueTypeCounts.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;

        // Determine severity based on report count
        final severity = clusterReports.length >= 5 ? 'high'
                      : clusterReports.length >= 3 ? 'medium'
                      : 'low';

        markers.add(
          Marker(
            point: LatLng(avgLat, avgLng),
            width: 50,
            height: 50,
            child: ClusterMarker(
              reportCount: clusterReports.length,
              severity: severity,
              issueType: dominantIssueType,
              onTap: () => _showClusterPreview(context, clusterReports),
            ),
          ),
        );
      }
    }

    return markers;
  }

  void _showClusterPreview(BuildContext context, List<ReportModel> clusterReports) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.group_work, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Cluster (${clusterReports.length} reports)',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: clusterReports.length,
                  itemBuilder: (context, index) {
                    final report = clusterReports[index];
                    return ListTile(
                      leading: ReportMarker(status: report.status),
                      title: Text(report.title),
                      subtitle: Text(report.issueType ?? 'Unknown'),
                      onTap: () {
                        Navigator.pop(context);
                        _showReportPreview(context, report);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                      data: reports.map((report) {
                        double weight;
                        switch (report.status.toLowerCase()) {
                          case 'resolved':
                          case 'closed':
                            weight = 0.3;
                            break;
                          case 'in progress':
                          case 'acknowledged':
                          case 'waiting for feedback':
                            weight = 0.6;
                            break;
                          case 'pending owner consent':
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
                  style: LocationMarkerStyle(
                    marker: DefaultLocationMarker(
                      child: Icon(Icons.navigation, color: colorScheme.surface),
                    ),
                    markerSize: Size(40, 40),
                    markerDirection: MarkerDirection.heading,
                    accuracyCircleColor: Colors.blue,
                    headingSectorColor: Colors.blue,
                    headingSectorRadius: 60,
                    showAccuracyCircle: true,
                  ),
                ),
                // Custom clustering based on DBSCAN clusterId
                MarkerLayer(
                  markers: _buildClusterMarkers(reports),
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
                                Theme.of(context).brightness == Brightness.dark;
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
                                    color: Colors.black.withValues(alpha: 0.2),
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
                                                    ? AppColors.textPrimaryDark
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
        ), // Margin at bottom to stay above floating nav bar
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
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
              style: TextStyle(color: Colors.grey[600]),
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
                  context.push('${OfficerAppRoutes.reports}/${report.id}');
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

