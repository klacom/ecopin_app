import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/report_marker.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/my_marker_cluster_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:ecopin_app/core/constants/app_constants.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/features/field_crew/providers/my_route_provider.dart';
import 'package:ecopin_app/features/field_crew/providers/cleanup_tasks_provider.dart';
import 'package:ecopin_app/features/field_crew/providers/fc_route_card_provider.dart';
import 'package:ecopin_app/features/field_crew/providers/fc_route_order_provider.dart';
import 'package:ecopin_app/features/field_crew/presentation/controllers/fc_dashboard_presentation.dart';
import 'package:ecopin_app/features/field_crew/presentation/controllers/fc_route_order.dart';
import 'package:ecopin_app/features/field_crew/presentation/controllers/fc_route_presentation.dart';
import 'package:ecopin_app/features/field_crew/presentation/controllers/fc_sync_ui_providers.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_current_objective_card.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_offline_ui.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_task_status_badge.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/map/fc_route_nav_banner.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/map/fc_route_next_card.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/map/fc_route_notice.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/map/fc_route_preview_sheet.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/map/fc_route_stops_sheet.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_gate.dart';
import 'package:ecopin_app/core/services/location_service.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/features/field_crew/data/models/route_model.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/reports_screen_widgets/status_badge.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/crew_navigation_plan.dart';
import '../../data/repositories/crew_navigation_cache.dart';

enum _LocationState { finding, ready, unavailable }

class FieldCrewMapScreen extends ConsumerStatefulWidget {
  const FieldCrewMapScreen({super.key, this.tileProvider, this.focus});
  final TileProvider? tileProvider;

  /// Optional report location to center on (from a report's View on Map action).
  final LatLng? focus;

  @override
  ConsumerState<FieldCrewMapScreen> createState() => _FieldCrewMapScreenState();
}

class _FieldCrewMapScreenState extends ConsumerState<FieldCrewMapScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  StreamSubscription<LatLng>? _locationSubscription;
  _LocationState _locationState = _LocationState.finding;

  bool _isNavigating = false;
  bool _isStartingNavigation = false; // Loading guard for Start next job
  String? _activeNavigationTaskId;
  CleanupTask? _destinationTask;
  LatLng? _destination;
  bool _arrived = false;
  List<LatLng> _liveNavigationPolyline = []; // Will store the API route
  String? _currentInstruction; // Turn-by-turn text
  bool _usingSavedRoute = false;
  bool _directionsSaved = false;
  // Online when the job started but live directions did not load.
  bool _liveFailed = false;
  double? _liveRouteDistance;
  double? _liveRouteDuration;
  double? _distanceToTurn;

  // TTS & Spam Prevention State
  FlutterTts flutterTts = FlutterTts();
  int _lastSpokenStepIndex = -1;
  int _lastSpokenDistanceThreshold = 999999;
  bool _isSpeaking = false;
  bool _isTtsMuted = false;
  List<dynamic> _routeSteps = [];
  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();
    _initTts();
    _initLocationTracking();
  }

  Future<void> _initTts() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await flutterTts.setSharedInstance(true);
        await flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [IosTextToSpeechAudioCategoryOptions.duckOthers],
        );
      }
      await flutterTts.awaitSpeakCompletion(true);
    } catch (error) {
      debugPrint('[TTS] Voice guidance unavailable: $error');
    }
  }

  Future<void> _initLocationTracking() async {
    if (mounted) setState(() => _locationState = _LocationState.finding);
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    // This will request permissions if not already granted
    final loc = await LocationService.getCurrentLocation();
    if (!mounted) return;
    if (loc == null) {
      setState(() => _locationState = _LocationState.unavailable);
      return;
    }
    setState(() {
      _currentLocation = loc;
      _locationState = _LocationState.ready;
    });
    // Start stream
    _locationSubscription = LocationService.getPositionStream()?.listen((
      position,
    ) {
      if (mounted) {
        setState(() {
          _currentLocation = position;
          if (_isNavigating &&
              !_arrived &&
              _destination != null &&
              crewIsNearDestination(position, _destination!)) {
            _arrived = true;
          }
        });
        _checkStepProgression(position);
      }
    });
  }

  DateTime? _lastLocationUpdate;

  void _checkStepProgression(LatLng position) {
    if (!_isNavigating ||
        _routeSteps.isEmpty ||
        _currentStepIndex >= _routeSteps.length) {
      return;
    }

    final now = DateTime.now();
    if (_lastLocationUpdate != null &&
        now.difference(_lastLocationUpdate!).inMilliseconds < 1000) {
      return;
    }
    _lastLocationUpdate = now;

    final currentManeuver = _routeSteps[_currentStepIndex]['maneuver'];
    final maneuverLoc = currentManeuver['location'] as List; // [lon, lat]
    final maneuverPoint = LatLng(maneuverLoc[1], maneuverLoc[0]);

    final distance = const Distance();
    final distToManeuver = distance.as(
      LengthUnit.Meter,
      position,
      maneuverPoint,
    );
    setState(() => _distanceToTurn = distToManeuver);

    // 1. Advance Step if very close (e.g. 15m)
    if (distToManeuver <= 15) {
      if (_currentStepIndex < _routeSteps.length - 1) {
        setState(() {
          _currentStepIndex++;
          _currentInstruction = crewTurnInstruction(
            _routeSteps[_currentStepIndex],
          );
        });
        _speakInstruction(99999, _currentInstruction!);
      }
      return; // Skip rest of checks for this tick
    }

    // 2. Threshold checks for TTS (Spam Prevention)
    if (distToManeuver <= 100) {
      _speakInstruction(100, 'In 100 meters, ${_currentInstruction ?? ''}');
    } else if (distToManeuver <= 500) {
      _speakInstruction(500, 'In 500 meters, ${_currentInstruction ?? ''}');
    }
  }

  Future<void> _speakInstruction(int distanceThreshold, String text) async {
    if (_lastSpokenStepIndex != _currentStepIndex) {
      _lastSpokenStepIndex = _currentStepIndex;
      _lastSpokenDistanceThreshold = 999999;
    }

    if (distanceThreshold >= _lastSpokenDistanceThreshold) {
      return;
    }

    if (_isSpeaking) {
      await flutterTts.stop();
    }

    _isSpeaking = true;
    _lastSpokenDistanceThreshold = distanceThreshold;

    try {
      if (!_isTtsMuted) {
        await flutterTts.speak(text);
      }
    } catch (e) {
      debugPrint('[TTS] speak error: $e');
    } finally {
      _isSpeaking = false;
    }
  }

  void _stopNavigation() {
    flutterTts.stop();
    if (!mounted) return;
    setState(() {
      _isNavigating = false;
      _activeNavigationTaskId = null;
      _destinationTask = null;
      _destination = null;
      _arrived = false;
      _distanceToTurn = null;
      _lastSpokenStepIndex = -1;
      _lastSpokenDistanceThreshold = 999999;
    });
  }

  void _say(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // Single-destination routing: isolates the chosen task and prevents routing
  // to the entire queue.
  Future<void> _startLiveNavigation(CleanupTask targetTask) async {
    if (targetTask.status.toLowerCase() == 'cancelled' ||
        ref.read(heldTasksProvider).contains(targetTask.id)) {
      _say('This location is on hold for officer review.');
      return;
    }
    // Loading guard: prevent double-tap and give immediate visual feedback.
    if (_isStartingNavigation) return;
    if (mounted) setState(() => _isStartingNavigation = true);

    try {
      if (_currentLocation == null) {
        _say('Your location is not available yet. Try again in a moment.');
        return;
      }

      // 1. Isolate Origin (Current GPS)
      final origin = _currentLocation!;

      // 2. Isolate the current active task as the final destination
      final route = ref.read(myRouteProvider).value;
      if (route == null) return;

      final targetWaypoint = route.waypoints
          .where((w) => w.cleanupTaskId == targetTask.id)
          .firstOrNull;
      if (targetWaypoint == null ||
          targetWaypoint.latitude == null ||
          targetWaypoint.longitude == null) {
        _say('Could not find destination coordinates for this job.');
        return;
      }

      final destination = LatLng(
        targetWaypoint.latitude!,
        targetWaypoint.longitude!,
      );

      final interfaces = await Connectivity().checkConnectivity();
      final online = interfaces.any(
        (value) => value != ConnectivityResult.none,
      );
      CrewNavigationPlan? plan;
      String? owner;
      try {
        owner = Supabase.instance.client.auth.currentUser?.id;
      } catch (_) {}
      var saved = false;
      var directionsSaved = false;
      if (online) {
        try {
          final response = await ref
              .read(apiClientProvider)
              .getDrivingDirections(
                fromLat: origin.latitude,
                fromLng: origin.longitude,
                toLat: destination.latitude,
                toLng: destination.longitude,
              )
              .timeout(const Duration(seconds: 12));
          plan = CrewNavigationPlan.fromOsrm(
            Map<String, dynamic>.from(response.data as Map),
          );
          if (owner != null) {
            try {
              await CrewNavigationCache.save(
                owner,
                route.id,
                targetTask.id,
                destination,
                plan,
              );
              directionsSaved = true;
            } catch (error) {
              debugPrint('[NAV] Could not save turn directions: $error');
            }
          }
        } catch (error) {
          debugPrint('[NAV] Online directions unavailable: $error');
        }
      }
      if (plan == null && owner != null) {
        plan = await CrewNavigationCache.load(
          owner,
          route.id,
          targetTask.id,
          destination,
          origin,
        );
        saved = plan != null;
      }
      if (plan == null) {
        // Published geometry describes this leg only; stop coordinates are not a road path.
        if (targetWaypoint.polyline.length < 2) {
          throw FormatException(
            online
                ? 'Live directions are not loading right now and none are saved for this stop. Try again in a moment.'
                : 'No saved road path or turn directions for this stop. Connect to the internet and try again.',
          );
        }
        plan = CrewNavigationPlan(
          points: targetWaypoint.polyline
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList(),
        ).fromPosition(origin);
        saved = true;
      }
      if (!mounted) return;
      if (ref.read(completedTasksProvider).contains(targetTask.id) ||
          ref.read(heldTasksProvider).contains(targetTask.id)) {
        return;
      }
      setState(() {
        _liveNavigationPolyline = plan!.points;
        _routeSteps = plan.steps;
        _currentStepIndex = 0;
        _liveRouteDistance = plan.distanceMeters;
        _liveRouteDuration = plan.durationMinutes;
        _usingSavedRoute = saved;
        _directionsSaved = directionsSaved;
        // Saved or preview directions while the phone is online mean the live
        // request failed, which the banner says in plain words.
        _liveFailed = online && saved;
        _currentInstruction = plan.steps.isEmpty
            ? 'Saved path only. Turn directions are unavailable offline.'
            : crewTurnInstruction(plan.steps.first);
        _isNavigating = true;
        _activeNavigationTaskId = targetTask.id;
        _destinationTask = targetTask;
        _destination = destination;
        _arrived = crewIsNearDestination(origin, destination);
        _distanceToTurn = null;
        _lastLocationUpdate = null;
        _lastSpokenStepIndex = -1;
        _lastSpokenDistanceThreshold = 999999;
      });
      if (_routeSteps.isNotEmpty) {
        unawaited(_speakInstruction(99999, _currentInstruction!));
      }
      _mapController.move(origin, 17);
    } catch (error) {
      _say(
        error is FormatException
            ? error.message
            : 'Directions could not load. Reconnect and try again.',
      );
    } finally {
      // Always clear the loading guard, regardless of success or any failure path
      if (mounted) setState(() => _isStartingNavigation = false);
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    flutterTts.stop();
    super.dispose();
  }

  void _showAllStops(RouteModel route, List<CrewStopRow> rows) {
    showFcRouteStopsSheet(
      context,
      rows: rows,
      totals: crewRouteTotals(
        route.totalDistanceMeters,
        route.totalDurationMin,
      ),
      onSelect: (row) {
        final lat = row.waypoint.latitude, lng = row.waypoint.longitude;
        if (lat != null && lng != null) {
          _mapController.move(LatLng(lat, lng), 17);
        }
        _showTaskPreview(context, row.task, row.finished);
      },
    );
  }

  /// Zooms and moves the map so every stop, the published route lines and the
  /// crew's own position are in view.
  void _showAllOnMap(RouteModel route) {
    final points = [
      for (final w in route.waypoints) ...[
        if (w.latitude != null && w.longitude != null)
          LatLng(w.latitude!, w.longitude!),
        for (final p in w.polyline) LatLng(p.latitude, p.longitude),
      ],
      ?_currentLocation,
    ];
    if (points.isEmpty) {
      _say('No stop locations are saved for this route.');
      return;
    }
    if (points.length == 1) {
      _mapController.move(points.first, 15);
      return;
    }
    final camera = _mapController.camera;
    final fitted = CameraFit.coordinates(
      coordinates: points,
      padding: const EdgeInsets.fromLTRB(48, 160, 48, 320),
      maxZoom: 17,
    ).fit(camera);
    // The Pasig camera limit refuses any view too wide to sit inside its
    // bounds, and a refused move does nothing at all. On a tall phone that is
    // every zoom below about 14, so zoom in only as far as the limit allows.
    var zoom = fitted.zoom;
    while (zoom < 18 &&
        pasigCameraConstraint.constrain(
              camera.withPosition(center: fitted.center, zoom: zoom),
            ) ==
            null) {
      zoom += 0.25;
    }
    _mapController.move(fitted.center, zoom);
  }

  @override
  Widget build(BuildContext context) {
    final routeAsync = ref.watch(myRouteProvider);
    final tasksAsync = ref.watch(myCleanupTasksProvider);
    final completedTasks = ref.watch(completedTasksProvider);
    final heldTasks = ref.watch(heldTasksProvider);
    final routeOrder = ref.watch(fcRouteOrderProvider);
    final cardCollapsed = ref.watch(fcRouteCardCollapsedProvider);
    final offline =
        ref.watch(fcSyncNetworkProvider).value == FcNetworkType.none;
    final theme = Theme.of(context);

    // Cancel navigation if the active task gets completed or held.
    ref.listen(completedTasksProvider, (previous, next) {
      if (_isNavigating &&
          _activeNavigationTaskId != null &&
          next.contains(_activeNavigationTaskId!)) {
        _stopNavigation();
      }
    });
    ref.listen(heldTasksProvider, (previous, next) {
      if (_isNavigating &&
          _activeNavigationTaskId != null &&
          next.contains(_activeNavigationTaskId!)) {
        _stopNavigation();
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: routeAsync.when(
        data: (route) {
          if (route == null) return _buildEmptyState();

          final tasks = tasksAsync.value ?? [];
          final taskStops = route.waypoints
              .where((w) => w.waypointType == 'task')
              .length;
          final center = route.startDepot ?? pasigSwmoDepot;
          final next = pickNextCrewStop(
            tasks: tasks,
            route: route,
            completed: completedTasks,
            held: heldTasks,
            order: routeOrder,
            origin: _currentLocation,
          );
          final stopRows = crewRouteStops(
            route: route,
            tasks: tasks,
            completed: completedTasks,
            held: heldTasks,
            nextTaskId: next?.task.id,
          );

          // #0052CC disappears on dark tiles, so routes switch to the lighter brand blue there.
          final routeColor = theme.brightness == Brightness.dark
              ? AppColors.linkDark
              : AppColors.primaryDark;
          final mainRoutePoints = _isNavigating
              ? _liveNavigationPolyline
              : <LatLng>[];
          final overviewLines = route.waypoints
              .where((waypoint) => waypoint.polyline.length >= 2)
              .map(
                (waypoint) => Polyline(
                  points: waypoint.polyline
                      .map((p) => LatLng(p.latitude, p.longitude))
                      .toList(),
                  color: routeColor,
                  strokeWidth: 4,
                ),
              )
              .toList();

          // Build markers
          final markers = <Marker>[];
          for (final wp in route.waypoints) {
            if (wp.latitude == null || wp.longitude == null) continue;
            final pos = LatLng(wp.latitude!, wp.longitude!);

            if (wp.waypointType == 'depot_start' ||
                wp.waypointType == 'depot_end') {
              markers.add(
                Marker(
                  point: pos,
                  width: 48,
                  height: 48,
                  child: Semantics(
                    label: 'Depot',
                    child: Container(
                      decoration: BoxDecoration(
                        color: routeColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.warehouse_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              );
            } else if (wp.waypointType == 'task') {
              final task = tasks
                  .where((t) => t.id == wp.cleanupTaskId)
                  .firstOrNull;
              if (task != null) {
                final isCompleted =
                    completedTasks.contains(task.id) ||
                    task.status.toLowerCase() == 'completed';
                markers.add(
                  Marker(
                    point: pos,
                    width: ReportPinFrame.width,
                    height: ReportPinFrame.height,
                    alignment: Alignment.topCenter,
                    child: IconButton(
                      tooltip:
                          'Stop ${wp.sequenceOrder}: ${task.title}${isCompleted ? ', completed' : ''}',
                      padding: EdgeInsets.zero,
                      onPressed: () =>
                          _showTaskPreview(context, task, isCompleted),
                      icon: ReportPinFrame(
                        color: theme.colorScheme.primary,
                        layered: true,
                        selected: task.id == next?.task.id,
                        badge: Icon(
                          isCompleted ? Icons.check : Icons.layers_outlined,
                          size: 14,
                          color: Colors.white,
                        ),
                        child: Text(
                          '${wp.sequenceOrder}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
            }
          }

          // Build micro routes (dashed polylines and sub-waypoint markers)
          final microRouteLines = <Polyline>[];
          for (final task in tasks) {
            if (task.reports == null || task.reports!.isEmpty) continue;
            final wp = route.waypoints
                .where((w) => w.cleanupTaskId == task.id)
                .firstOrNull;
            if (wp == null || wp.latitude == null || wp.longitude == null) {
              continue;
            }

            final sortedReports = List.of(task.reports!);
            sortedReports.sort((a, b) {
              int idxA = task.reportSequence.indexOf(a.id);
              int idxB = task.reportSequence.indexOf(b.id);
              if (idxA == -1) idxA = 999;
              if (idxB == -1) idxB = 999;
              return idxA.compareTo(idxB);
            });

            final positions = <LatLng>[LatLng(wp.latitude!, wp.longitude!)];
            for (var i = 0; i < sortedReports.length; i++) {
              final report = sortedReports[i];
              if (report.location.latitude != 0) {
                positions.add(report.location);
                markers.add(
                  Marker(
                    point: report.location,
                    width: ReportPinFrame.width,
                    height: ReportPinFrame.height,
                    alignment: Alignment.topCenter,
                    child: ReportMarker(
                      status: report.status,
                      title: '${wp.sequenceOrder}.${i + 1} ${report.title}',
                      issueType: report.issueType,
                      onTap: () => _showReportPreview(context, report, task.id),
                    ),
                  ),
                );
              }
            }
            if (positions.length > 1) {
              microRouteLines.add(
                Polyline(
                  points: positions,
                  color: routeColor.withValues(alpha: 0.8),
                  strokeWidth: 3.0,
                  pattern: StrokePattern.dashed(segments: [5.0, 10.0]),
                ),
              );
            }
          }

          final totals = crewRouteTotals(
            route.totalDistanceMeters,
            route.totalDurationMin,
          );
          final turnStep =
              _routeSteps.isNotEmpty && _currentStepIndex < _routeSteps.length
              ? Map<String, dynamic>.from(_routeSteps[_currentStepIndex] as Map)
              : null;

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: widget.focus ?? center,
                  initialZoom: widget.focus != null ? 17.0 : 14.0,
                  minZoom: pasigMinZoom,
                  cameraConstraint: pasigCameraConstraint,
                ),
                children: [
                  TileLayer(
                    tileProvider: widget.tileProvider,
                    urlTemplate: theme.brightness == Brightness.dark
                        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png?key=${dotenv.env['CARTO_API_KEY'] ?? ''}'
                        : 'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png?key=${dotenv.env['CARTO_API_KEY'] ?? ''}',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'dev.ecopinas.ecopin_app',
                  ),
                  if (mainRoutePoints.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: mainRoutePoints,
                          color: routeColor,
                          strokeWidth: 4.0,
                        ),
                      ],
                    ),
                  if (!_isNavigating && overviewLines.isNotEmpty)
                    PolylineLayer(polylines: overviewLines),
                  if (microRouteLines.isNotEmpty)
                    PolylineLayer(polylines: microRouteLines),
                  if (markers.isNotEmpty)
                    MarkerClusterLayerWidget(
                      options: MarkerClusterLayerOptions(
                        markers: markers,
                        size: const Size(
                          ReportPinFrame.width,
                          ReportPinFrame.height,
                        ),
                        alignment: Alignment.topCenter,
                        maxClusterRadius: 60,
                        spiderfyCircleRadius: 90,
                        zoomToBoundsOnClick: true,
                        polygonOptions: const PolygonOptions(
                          color: Colors.transparent,
                          borderColor: Colors.transparent,
                          borderStrokeWidth: 0,
                        ),
                        animationsOptions:
                            MediaQuery.disableAnimationsOf(context)
                            ? const AnimationsOptions(
                                zoom: Duration.zero,
                                fitBound: Duration.zero,
                                centerMarker: Duration.zero,
                                spiderfy: Duration.zero,
                              )
                            : const AnimationsOptions(),
                        builder: (_, grouped) => Builder(
                          builder: (clusterContext) => Semantics(
                            label: '${grouped.length} route pins',
                            child: ExcludeSemantics(
                              child: ReportClusterBadge(
                                count: grouped.length,
                                onActivate: clusterContext
                                    .findAncestorWidgetOfExactType<
                                      GestureDetector
                                    >()
                                    ?.onTap,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_currentLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentLocation!,
                          width: 24,
                          height: 24,
                          child: Semantics(
                            label: 'Your location',
                            child: Container(
                              decoration: BoxDecoration(
                                color: routeColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // Top: route chip or turn banner, then persistent notices.
              Positioned(
                top: MediaQuery.paddingOf(context).top + 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    if (_isNavigating && _currentInstruction != null)
                      FcRouteNavBanner(
                        instruction: _currentInstruction!,
                        turnIcon: crewTurnIcon(turnStep),
                        distanceToTurn:
                            turnStep != null && _distanceToTurn != null
                            ? crewFormatDistance(_distanceToTurn)
                            : null,
                        destinationTitle: _destinationTask?.title ?? '',
                        routeSummary:
                            crewRouteTotals(
                                  _liveRouteDistance,
                                  _liveRouteDuration,
                                ) ==
                                null
                            ? 'Distance and time are not available.'
                            : 'Route: ${crewRouteTotals(_liveRouteDistance, _liveRouteDuration)}',
                        status: crewDirectionsStatus(
                          usingSaved: _usingSavedRoute,
                          liveFailed: _liveFailed,
                          hasTurnSteps: _routeSteps.isNotEmpty,
                          copySaved: _directionsSaved,
                        ),
                      )
                    else
                      FcRouteChip(
                        text:
                            '$taskStops ${taskStops == 1 ? 'stop' : 'stops'}${totals == null ? '' : ' · $totals'}',
                      ),
                    if (_locationState == _LocationState.finding)
                      const FcRouteNotice(
                        icon: Icons.my_location,
                        busy: true,
                        message: 'Finding your location',
                      ),
                    if (_locationState == _LocationState.unavailable)
                      FcRouteNotice(
                        icon: Icons.location_off_outlined,
                        message:
                            'Your location is not available. Turn on location and allow EcoPin to use Nearest and navigation.',
                        actions: [
                          TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48),
                            ),
                            onPressed: _initLocationTracking,
                            child: const Text('Try again'),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48),
                            ),
                            onPressed: Geolocator.openLocationSettings,
                            child: const Text('Location settings'),
                          ),
                        ],
                      ),
                    if (offline)
                      const FcRouteNotice(
                        icon: Icons.cloud_off_outlined,
                        message:
                            'No signal. The map may be blank. Your stops are in the list.',
                      ),
                  ],
                ),
              ),

              // Bottom: map actions stacked above the card so they follow its height.
              Positioned(
                bottom:
                    16, // The parent Scaffold already reserves the bottom navigation bar.
                left: 16,
                right: 16,
                child: Column(
                  verticalDirection: VerticalDirection.up,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isNavigating)
                      _buildNavigationCard()
                    else if (next == null)
                      _buildNoStopCard()
                    else
                      // At large text the card scrolls instead of covering the
                      // map, and Minimize stays reachable above its content.
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.sizeOf(context).height * .7,
                        ),
                        child: FcRouteNextCard(
                          next: next,
                          order: routeOrder,
                          stopCount: stopRows.length,
                          collapsed: cardCollapsed,
                          starting: _isStartingNavigation,
                          onOrderChanged: (order) => ref
                              .read(fcRouteOrderProvider.notifier)
                              .select(order),
                          onStart: () => _startLiveNavigation(next.task),
                          onToggle: () => ref
                              .read(fcRouteCardCollapsedProvider.notifier)
                              .set(!cardCollapsed),
                          onSeeStops: () => _showAllStops(route, stopRows),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 12,
                        children: [
                          if (_isNavigating && _routeSteps.isNotEmpty)
                            _mapButton(
                              tag: 'tts_mute_toggle',
                              tooltip: _isTtsMuted
                                  ? 'Turn voice on'
                                  : 'Turn voice off',
                              icon: _isTtsMuted
                                  ? Icons.volume_off
                                  : Icons.volume_up,
                              onPressed: () {
                                setState(() => _isTtsMuted = !_isTtsMuted);
                                if (_isTtsMuted) flutterTts.stop();
                              },
                            ),
                          _mapButton(
                            tag: 'show_all_stops',
                            tooltip: 'Show all stops on the map',
                            icon: Icons.zoom_out_map,
                            onPressed: () => _showAllOnMap(route),
                          ),
                          _mapButton(
                            tag: 'recenter_map',
                            tooltip: 'Show my location',
                            icon: Icons.my_location,
                            onPressed: () {
                              if (_currentLocation != null) {
                                _mapController.move(_currentLocation!, 15.0);
                              } else {
                                _initLocationTracking();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Align(
          alignment: Alignment.topCenter,
          child: LinearProgressIndicator(semanticsLabel: 'Loading your route'),
        ),
        error: (err, _) => _buildEmptyState(unavailable: true),
      ),
    );
  }

  /// Icon-only map button. The tooltip doubles as the spoken name.
  Widget _mapButton({
    required String tag,
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: tooltip,
      excludeSemantics: true,
      child: FloatingActionButton(
        heroTag: tag,
        tooltip: tooltip,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: fcAccent(context),
        onPressed: onPressed,
        child: Icon(icon),
      ),
    );
  }

  Widget _card({required Widget child}) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        side: BorderSide(color: theme.dividerTheme.color ?? theme.dividerColor),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  Widget _buildNavigationCard() {
    final theme = Theme.of(context);
    final preview = _routeSteps.isEmpty;
    final stop = AppButton(
      text: preview ? 'Stop preview' : 'Stop navigation',
      icon: Icons.stop_circle_outlined,
      variant: ButtonVariant.secondary,
      onPressed: _stopNavigation,
    );
    final retry = _liveFailed && _destinationTask != null
        ? TextButton.icon(
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: _isStartingNavigation
                ? null
                : () => _startLiveNavigation(_destinationTask!),
            icon: const Icon(Icons.refresh),
            label: const Text('Try live directions again'),
          )
        : null;
    if (!_arrived || _destinationTask == null) {
      return _card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [?retry, stop],
        ),
      );
    }
    final task = _destinationTask!;
    return _card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ExcludeSemantics(
                  child: Icon(Icons.where_to_vote_outlined, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You are near the pin',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        'Open the job to start the site visit. Navigation does not complete anything.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            text: 'Open this job',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => context.push(crewTaskPath(task.id)),
          ),
          const SizedBox(height: 8),
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: _stopNavigation,
            child: Text(preview ? 'Stop preview' : 'Stop navigation'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoStopCard() {
    final theme = Theme.of(context);
    return _card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              'No stop left on this route',
              style: theme.textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Check Jobs for held or other work.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            text: 'Open Jobs',
            variant: ButtonVariant.secondary,
            onPressed: () => context.go(FieldCrewAppRoutes.tasks),
          ),
        ],
      ),
    );
  }

  void _showTaskPreview(
    BuildContext context,
    CleanupTask task,
    bool isCompleted,
  ) {
    final place = crewTaskPlace(task);
    final linked = task.reports?.length ?? task.reportIds.length;
    showFcRoutePreview(
      context,
      badges: [
        FcTaskStatusBadge(status: isCompleted ? 'completed' : task.status),
        FcPriorityChip(priority: task.priority),
      ],
      title: task.title,
      place: place.primary,
      placeDetail: place.detail,
      details: '$linked linked ${linked == 1 ? 'report' : 'reports'}',
      description: task.description,
      primaryLabel: 'Open job',
      onPrimary: () => context.push(crewTaskPath(task.id)),
      secondaryLabel: isCompleted ? null : 'Start navigation to this job',
      onSecondary: isCompleted ? null : () => _startLiveNavigation(task),
    );
  }

  void _showReportPreview(
    BuildContext context,
    ReportModel report,
    String taskId,
  ) {
    showFcRoutePreview(
      context,
      badges: [StatusBadge(status: report.status)],
      title: report.title,
      details: crewTaskLabel(report.issueType ?? 'General concern'),
      description: report.description?.trim().isNotEmpty == true
          ? report.description!
          : 'No description was provided.',
      primaryLabel: 'Open report',
      onPrimary: () => context.push(
        FieldCrewAppRoutes.reportDetail
            .replaceFirst(':id', Uri.encodeComponent(taskId))
            .replaceFirst(':reportId', Uri.encodeComponent(report.id)),
      ),
    );
  }

  Widget _buildEmptyState({bool unavailable = false}) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.map_outlined,
                size: 48,
                color: theme.colorScheme.onSurface,
              ),
              const SizedBox(height: 24),
              Semantics(
                header: true,
                child: Text(
                  unavailable
                      ? 'Route could not load'
                      : 'No published route available',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                unavailable
                    ? 'Check your signal and try again. Your jobs are still in Jobs.'
                    : 'Jobs can exist without a published route. Open Jobs, or ask your officer to publish a route for your crew.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              AppButton(
                text: 'Reload route',
                icon: Icons.refresh,
                onPressed: () {
                  ref.invalidate(activeRoutesProvider);
                  ref.invalidate(myRouteProvider);
                },
              ),
              const SizedBox(height: 12),
              AppButton(
                text: 'Open Jobs',
                variant: ButtonVariant.secondary,
                onPressed: () => context.go(FieldCrewAppRoutes.tasks),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
