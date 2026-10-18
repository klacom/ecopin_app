import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ecopin_app/core/constants/app_constants.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:ecopin_app/shared/reports/providers/public_report_map_provider.dart';
import 'package:ecopin_app/shared/reports/data/datasources/public_report_map_datasource.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/report_map_status.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/my_marker_cluster_layer.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/report_marker.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/search_overlay.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/report_map_preview.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/report_map_controls.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/report_map_info.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/map_privacy_consent_dialog.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ecopin_app/core/services/api_service.dart';

class MapScreen extends ConsumerStatefulWidget {
  final bool isFieldCrewMode;
  final bool showOptimizedRoute;
  final bool showOtherCrews;
  final bool showBaseOfOperations;
  final TileProvider? tileProvider;

  const MapScreen({
    super.key,
    this.isFieldCrewMode = false,
    this.showOptimizedRoute = false,
    this.showOtherCrews = false,
    this.showBaseOfOperations = false,
    this.tileProvider,
  });

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();

  Timer? _viewportDebounce;
  Timer? _refreshTimer;
  ReportViewport? _viewport;

  bool _showHeatmap = false;
  bool _isLoadingLocation = false;
  bool _checkingPrivacy = false;
  String? _selectedReportId;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      if (mounted &&
          _viewport != null &&
          TickerMode.valuesOf(context).enabled &&
          (lifecycle == null || lifecycle == AppLifecycleState.resumed)) {
        ref.invalidate(publicReportMapProvider(_viewport!));
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runOnce(); // check and ask for user data/location disclosure initially.
    });
  }

  Future<void> _runOnce() async {
    if (!mounted || _checkingPrivacy) return;
    _checkingPrivacy = true;
    try {
      final response = await ref.read(apiClientProvider).getProfile();
      final data = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      final profile = data is Map ? data['profile'] : null;
      if (profile is! Map) {
        throw const FormatException('Privacy preference unavailable');
      }
      if (mounted && profile['data_consent'] == null) {
        await _dialogBuilder(context);
      }
    } catch (_) {
      if (mounted) {
        _notice(
          'Privacy preferences could not load. Please try again.',
          actionLabel: 'Retry',
          action: _runOnce,
        );
      }
    } finally {
      _checkingPrivacy = false;
    }
  }

  @override
  void dispose() {
    _viewportDebounce?.cancel();
    _refreshTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _updateViewport(MapCamera camera) {
    final bounds = camera.visibleBounds;
    final next = ReportViewport(
      south: bounds.south.clamp(-90.0, 90.0),
      north: bounds.north.clamp(-90.0, 90.0),
      west: bounds.west,
      east: bounds.east,
    );
    _viewportDebounce?.cancel();
    _viewportDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted && next != _viewport) setState(() => _viewport = next);
    });
  }

  // For Data/Location Disclosure

  Future<void> _dialogBuilder(BuildContext context) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => MapPrivacyConsentDialog(
      onSave: (choice) async {
        await ref.read(apiClientProvider).updateDataConsent(choice);
      },
    ),
  );

  void _notice(String message, {String? actionLabel, VoidCallback? action}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 6),
        action: action == null
            ? null
            : SnackBarAction(label: actionLabel ?? 'Retry', onPressed: action),
      ),
    );
  }

  Future<void> _locationSettings(bool serviceSettings) async {
    try {
      final opened = await (serviceSettings
          ? Geolocator.openLocationSettings()
          : Geolocator.openAppSettings());
      if (!opened && mounted) {
        _notice(
          'Device settings could not open. You can still explore the map.',
        );
      }
    } catch (_) {
      if (mounted) {
        _notice(
          'Device settings could not open. You can still explore the map.',
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    if (_isLoadingLocation) return;
    setState(() => _isLoadingLocation = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) {
          _notice(
            'Turn on location services to center the map on your position.',
            actionLabel: 'Settings',
            action: () => _locationSettings(true),
          );
        }
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        if (mounted) {
          _notice(
            'Location access was not allowed. You can still explore the map.',
          );
        }
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          _notice(
            'Enable location access in device settings to find your position.',
            actionLabel: 'Settings',
            action: () => _locationSettings(false),
          );
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        _mapController.move(LatLng(position.latitude, position.longitude), 16);
      }
    } catch (_) {
      if (mounted) {
        _notice(
          'We could not find your location. Please try again.',
          actionLabel: 'Retry',
          action: _getCurrentLocation,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = _viewport == null
        ? const AsyncLoading<ReportMapPage>()
        : ref.watch(publicReportMapProvider(_viewport!));
    final reports = reportsAsync.value?.reports ?? <ReportModel>[];
    final colorScheme = Theme.of(context).colorScheme;
    // Filter out rejected reports
    var visibleReports = reports
        .where((r) => r.validationStatus.toLowerCase() != 'rejected')
        .toList();

    if (widget.isFieldCrewMode) {
      visibleReports = visibleReports
          .where(
            (r) =>
                r.status.toLowerCase() == 'in progress' ||
                r.status.toLowerCase() == 'acknowledged' ||
                r.status.toLowerCase() == 'pending',
          )
          .toList();
    }

    return Scaffold(
      body: Stack(
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
              onMapReady: () => _updateViewport(_mapController.camera),
              onPositionChanged: (camera, hasGesture) =>
                  _updateViewport(camera),
              onTap: null,
            ),
            children: [
              TileLayer(
                tileProvider: widget.tileProvider,
                urlTemplate: Theme.of(context).brightness == Brightness.dark
                    ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png?key=${dotenv.env['CARTO_API_KEY'] ?? ''}'
                    : 'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png?key=${dotenv.env['CARTO_API_KEY'] ?? ''}',
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
                        case 'in_progress':
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
                style: LocationMarkerStyle(
                  marker: DefaultLocationMarker(
                    child: Icon(Icons.navigation, color: colorScheme.surface),
                  ),
                  markerSize: const Size(40, 40),
                  markerDirection: MarkerDirection.heading,
                  accuracyCircleColor: const Color(0x182196F3),
                  headingSectorColor: const Color(0xCC2196F3),
                  headingSectorRadius: 60,
                  showAccuracyCircle: true,
                  showHeadingSector: true,
                ),
              ),
              if (widget.showOptimizedRoute)
                const PolylineLayer(polylines: <Polyline<Object>>[]),
              if (widget.showBaseOfOperations) const MarkerLayer(markers: []),
              if (widget.showOtherCrews) const MarkerLayer(markers: []),
              MyMarkerClusterLayer(
                markers: visibleReports
                    .map(
                      (report) => Marker(
                        key: ValueKey(report.id),
                        point: report.location,
                        width: 48,
                        height: 48,
                        child: ReportMarker(
                          status: report.status,
                          title: report.title,
                          selected: _selectedReportId == report.id,
                          onTap: () => _showReportPreview(report),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: widget.isFieldCrewMode
                ? 16
                : MediaQuery.textScalerOf(context).scale(48) + 40,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 64),
                    child: ReportMapStatus(
                      value: reportsAsync,
                      onRetry: () {
                        if (_viewport != null) {
                          ref.invalidate(publicReportMapProvider(_viewport!));
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!widget.isFieldCrewMode)
            Positioned(
              top: 16,
              right: 16,
              child: SafeArea(
                child: ReportMapControls(
                  heatmap: _showHeatmap,
                  locating: _isLoadingLocation,
                  onSearch: () => showGeneralDialog(
                    context: context,
                    pageBuilder: (_, animation, secondaryAnimation) =>
                        SearchOverlay(mapController: _mapController),
                  ),
                  onHeatmap: () => setState(() => _showHeatmap = !_showHeatmap),
                  onLocate: _getCurrentLocation,
                  onInfo: _showMapInfo,
                ),
              ),
            ),
          if (widget.isFieldCrewMode)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: SafeArea(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Public map preview',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Open an assigned task for its route details and report response actions.',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showReportPreview(ReportModel report) async {
    if (_selectedReportId != null) return;
    setState(() => _selectedReportId = report.id);
    bool? open;
    try {
      open = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => ReportMapPreview(report: report),
      );
    } finally {
      if (mounted) setState(() => _selectedReportId = null);
    }
    if (mounted && open == true) {
      context.push(
        '${ProtectedAppRoutes.reports}/${Uri.encodeComponent(report.id)}',
      );
    }
  }

  void _showMapInfo() => showDialog<void>(
    context: context,
    builder: (_) => ReportMapInfo(openSource: _openSource),
  );

  Future<void> _openSource(Uri url) async {
    try {
      if (!await launchUrl(url) && mounted) {
        _notice('This link could not open on your device.');
      }
    } catch (_) {
      if (mounted) _notice('This link could not open on your device.');
    }
  }
}
