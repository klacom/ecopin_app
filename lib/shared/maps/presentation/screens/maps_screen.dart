import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/shared/reports/data/datasources/public_report_map_cache.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/public_report_list.dart';
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
import 'package:ecopin_app/shared/maps/presentation/widgets/report_map_credits.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/report_map_info.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/map_privacy_consent_dialog.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ecopin_app/core/services/api_service.dart';

class MapScreen extends ConsumerStatefulWidget {
  final TileProvider? tileProvider;

  const MapScreen({super.key, this.tileProvider});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();

  Timer? _viewportDebounce;
  Timer? _refreshTimer;
  ReportViewport? _viewport;
  final _areaCache = PublicReportMapCache();
  ReportMapPage? _cachedPage;
  ReportMapPage? _lastFetchedPage;
  ReportMapPage? _lastPage;

  bool _showHeatmap = false;
  bool _listView = false;
  bool _listOpened = false;
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
          !_listView &&
          TickerMode.valuesOf(context).enabled &&
          (lifecycle == null || lifecycle == AppLifecycleState.resumed)) {
        _refreshArea();
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
    if (_listView) return;
    _viewportDebounce = Timer(
      _viewport == null ? Duration.zero : const Duration(milliseconds: 150),
      () {
        if (!mounted || next == _viewport) return;
        final cached = _areaCache.get(next);
        setState(() {
          _viewport = next;
          _cachedPage = cached;
        });
      },
    );
  }

  void _refreshArea() {
    if (_viewport == null) return;
    _areaCache.clear();
    setState(() => _cachedPage = null);
    ref.invalidate(publicReportMapProvider(_viewport!));
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
        : _cachedPage != null
        ? AsyncData(_cachedPage!)
        : ref.watch(publicReportMapProvider(_viewport!));
    if (reportsAsync.hasValue) {
      _lastPage = reportsAsync.value;
      if (_cachedPage == null &&
          !reportsAsync.isLoading &&
          !reportsAsync.hasError &&
          !identical(_lastFetchedPage, reportsAsync.value)) {
        _lastFetchedPage = reportsAsync.value;
        _areaCache.put(_viewport!, _lastFetchedPage!);
      }
    }
    final reports =
        (reportsAsync.value ?? _lastPage)?.reports ?? <ReportModel>[];
    final colorScheme = Theme.of(context).colorScheme;
    // Filter out rejected reports
    final visibleReports = reports
        .where((r) => r.validationStatus.toLowerCase() != 'rejected')
        .toList();

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _listView ? 1 : 0,
              children: [
                Stack(
                  fit: StackFit.expand,
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: pasigInitialCenter,
                        initialZoom: 15.0,
                        minZoom: pasigMinZoom,
                        cameraConstraint: pasigCameraConstraint,
                        maxZoom: 18,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all,
                        ),
                        onMapReady: () =>
                            _updateViewport(_mapController.camera),
                        onPositionChanged: (camera, hasGesture) =>
                            _updateViewport(camera),
                        onTap: null,
                      ),
                      children: [
                        TileLayer(
                          tileProvider: widget.tileProvider,
                          urlTemplate:
                              Theme.of(context).brightness == Brightness.dark
                              ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png?key=${dotenv.env['CARTO_API_KEY'] ?? ''}'
                              : 'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png?key=${dotenv.env['CARTO_API_KEY'] ?? ''}',
                          subdomains: const ['a', 'b', 'c'],
                          userAgentPackageName: 'dev.ecopinas.ecopin_app',
                        ),
                        if (_showHeatmap && visibleReports.isNotEmpty)
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
                            markerSize: const Size(40, 40),
                            markerDirection: MarkerDirection.heading,
                            accuracyCircleColor: const Color(0x182196F3),
                            headingSectorColor: const Color(0xCC2196F3),
                            headingSectorRadius: 60,
                            showAccuracyCircle: true,
                            showHeadingSector: true,
                          ),
                        ),
                        MyMarkerClusterLayer(
                          markers: visibleReports
                              .map(
                                (report) => Marker(
                                  key: ValueKey(report.id),
                                  point: report.location,
                                  width: ReportPinFrame.width,
                                  height: ReportPinFrame.height,
                                  alignment: Alignment.topCenter,
                                  child: ReportMarker(
                                    status: report.status,
                                    issueType: report.issueType,
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
                      left: 8,
                      bottom: 8,
                      child: SafeArea(
                        child: ReportMapCredits(openSource: _openSource),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        bottom: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildMapToolbar(reportsAsync),
                            Padding(
                              padding: const EdgeInsets.only(
                                right: 16,
                                top: 16,
                              ),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: ReportMapControls(
                                  heatmap: _showHeatmap,
                                  locating: _isLoadingLocation,
                                  onSearch: () => showGeneralDialog(
                                    context: context,
                                    pageBuilder:
                                        (_, animation, secondaryAnimation) =>
                                            SearchOverlay(
                                              mapController: _mapController,
                                            ),
                                  ),
                                  onHeatmap: () => setState(
                                    () => _showHeatmap = !_showHeatmap,
                                  ),
                                  onLocate: _getCurrentLocation,
                                  onInfo: _showMapInfo,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_listOpened)
                  Column(
                    children: [
                      SafeArea(
                        bottom: false,
                        child: _buildMapToolbar(reportsAsync),
                      ),
                      Expanded(
                        child: PublicReportList(onOpen: _showReportPreview),
                      ),
                    ],
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapToolbar(AsyncValue<ReportMapPage> value) {
    final scheme = Theme.of(context).colorScheme;
    Widget viewLabel(bool list, IconData icon, String label) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _listView == list ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(AppColors.radiusButton),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(label)],
      ),
    );
    final controls = SegmentedButton<bool>(
      showSelectedIcon: false,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
        side: const WidgetStatePropertyAll(BorderSide.none),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(4)),
        backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerLow),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : scheme.onSurface,
        ),
        shape: const WidgetStatePropertyAll(StadiumBorder()),
      ),
      segments: [
        ButtonSegment(
          value: false,
          label: viewLabel(false, Icons.map_outlined, 'Map'),
        ),
        ButtonSegment(
          value: true,
          label: viewLabel(true, Icons.view_list_outlined, 'List'),
        ),
      ],
      selected: {_listView},
      onSelectionChanged: (selection) => setState(() {
        _listView = selection.single;
        _listOpened = _listOpened || _listView;
        if (_listView) {
          _viewportDebounce?.cancel();
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_listView) _updateViewport(_mapController.camera);
          });
        }
      }),
    );
    final status = ReportMapStatus(
      value: value,
      hasPreviousReports: _lastPage != null,
      onRetry: _refreshArea,
      compact: true,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: scheme.surface,
        elevation: 2,
        shadowColor: AppColors.shadowCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.dividerDark
                : AppColors.dividerLight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (_listView) {
                return Align(alignment: Alignment.centerLeft, child: controls);
              }
              if (constraints.maxWidth >= 300 &&
                  MediaQuery.textScalerOf(context).scale(14) <= 18.2) {
                return Row(
                  children: [
                    controls,
                    const SizedBox(width: 12),
                    Expanded(child: status),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(alignment: Alignment.centerLeft, child: controls),
                  const SizedBox(height: 8),
                  status,
                ],
              );
            },
          ),
        ),
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
