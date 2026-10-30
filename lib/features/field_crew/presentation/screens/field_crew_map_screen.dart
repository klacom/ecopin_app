import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/report_marker.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/my_marker_cluster_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import 'package:ecopin_app/features/field_crew/providers/my_route_provider.dart';
import 'package:ecopin_app/features/field_crew/providers/cleanup_tasks_provider.dart';
import 'package:ecopin_app/features/field_crew/providers/fc_route_order_provider.dart';
import 'package:ecopin_app/features/field_crew/presentation/controllers/fc_route_order.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_shimmer_card.dart';
import 'package:ecopin_app/core/services/location_service.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'package:dio/dio.dart' as dio;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/crew_navigation_plan.dart';
import '../../data/repositories/crew_navigation_cache.dart';

class FieldCrewMapScreen extends ConsumerStatefulWidget {
  const FieldCrewMapScreen({super.key, this.tileProvider});
  final TileProvider? tileProvider;

  @override
  ConsumerState<FieldCrewMapScreen> createState() => _FieldCrewMapScreenState();
}

class _FieldCrewMapScreenState extends ConsumerState<FieldCrewMapScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  StreamSubscription<LatLng>? _locationSubscription;

  bool _isNavigating = false;
  bool _isStartingNavigation = false; // Loading guard for Start Next Job
  String? _activeNavigationTaskId;
  List<LatLng> _liveNavigationPolyline = []; // Will store the API route
  String? _currentInstruction; // Turn-by-turn text
  bool _usingSavedRoute = false;
  bool _directionsSaved = false;
  double? _liveRouteDistance;
  double? _liveRouteDuration;

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
    // This will request permissions if not already granted
    final loc = await LocationService.getCurrentLocation();
    if (loc != null && mounted) {
      setState(() {
        _currentLocation = loc;
      });
      // Start stream
      _locationSubscription = LocationService.getPositionStream()?.listen((
        position,
      ) {
        if (mounted) {
          setState(() {
            _currentLocation = position;
          });
          _checkStepProgression(position);
        }
      });
    }
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

    // 1. Advance Step if very close (e.g. 15m)
    if (distToManeuver <= 15) {
      if (_currentStepIndex < _routeSteps.length - 1) {
        setState(() {
          _currentStepIndex++;
          _currentInstruction = _parseInstruction(
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

  // --- TICKET 2: Single-Destination Routing Logic ---
  // Isolates the active task and prevents routing to the entire queue
  Future<void> _startLiveNavigation(CleanupTask targetTask) async {
    if (targetTask.status.toLowerCase() == 'cancelled' ||
        ref.read(heldTasksProvider).contains(targetTask.id)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This location is on hold for officer review.'),
          ),
        );
      }
      return;
    }
    // ── Loading guard: prevent double-tap and give immediate visual feedback ──
    if (_isStartingNavigation) return;
    if (mounted) setState(() => _isStartingNavigation = true);

    final tStart = DateTime.now();
    debugPrint('[NAV] Start Next Job pressed at $tStart');

    try {
      if (_currentLocation == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Waiting for GPS signal...')),
          );
        }
        return;
      }

      // 1. Isolate Origin (Current GPS)
      final origin = _currentLocation!;

      // 2. Isolate the current active task as the final destination
      final routeAsync = ref.read(myRouteProvider);
      final route = routeAsync.value;
      if (route == null) return;

      final targetWaypoint = route.waypoints
          .where((w) => w.cleanupTaskId == targetTask.id)
          .firstOrNull;
      if (targetWaypoint == null ||
          targetWaypoint.latitude == null ||
          targetWaypoint.longitude == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not find destination coordinates for this task.',
              ),
            ),
          );
        }
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
        final client = dio.Dio(
          dio.BaseOptions(
            connectTimeout: const Duration(seconds: 3),
            receiveTimeout: const Duration(seconds: 3),
          ),
        );
        final cancel = dio.CancelToken();
        try {
          final url =
              'https://router.project-osrm.org/route/v1/driving/'
              '${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}'
              '?steps=true&geometries=geojson&overview=full';
          final response = await client
              .get(url, cancelToken: cancel)
              .timeout(
                const Duration(seconds: 3),
                onTimeout: () {
                  cancel.cancel('Navigation request timed out');
                  throw TimeoutException('Navigation request timed out');
                },
              );
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
        } finally {
          client.close(force: true);
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
          throw const FormatException(
            'No saved road path or turn directions for this stop. Connect to the internet and try again.',
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
        _currentInstruction = plan.steps.isEmpty
            ? 'Saved path only. Turn directions are unavailable offline.'
            : crewTurnInstruction(plan.steps.first);
        _isNavigating = true;
        _activeNavigationTaskId = targetTask.id;
        _lastLocationUpdate = null;
        _lastSpokenStepIndex = -1;
        _lastSpokenDistanceThreshold = 999999;
      });
      if (_routeSteps.isNotEmpty) {
        unawaited(_speakInstruction(99999, _currentInstruction!));
      }
      _mapController.move(origin, 17);
    } catch (error) {
      if (mounted) {
        final message = error is FormatException
            ? error.message
            : 'Directions could not load. Please reconnect and try again.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message.toString())));
      }
    } finally {
      // Always clear the loading guard, regardless of success or any failure path
      if (mounted) setState(() => _isStartingNavigation = false);
    }
  }

  String _parseInstruction(Map<String, dynamic> step) =>
      crewTurnInstruction(step);

  @override
  void dispose() {
    _locationSubscription?.cancel();
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routeAsync = ref.watch(myRouteProvider);
    final tasksAsync = ref.watch(myCleanupTasksProvider);
    final completedTasks = ref.watch(completedTasksProvider);
    final heldTasks = ref.watch(heldTasksProvider);
    final routeOrder = ref.watch(fcRouteOrderProvider);

    // Cancel navigation if the active task gets completed
    ref.listen(completedTasksProvider, (previous, next) {
      if (_isNavigating && _activeNavigationTaskId != null) {
        if (next.contains(_activeNavigationTaskId!)) {
          flutterTts.stop();
          if (mounted) {
            setState(() {
              _isNavigating = false;
              _activeNavigationTaskId = null;
              _lastSpokenStepIndex = -1;
              _lastSpokenDistanceThreshold = 999999;
            });
          }
        }
      }
    });

    ref.listen(heldTasksProvider, (previous, next) {
      if (_isNavigating &&
          _activeNavigationTaskId != null &&
          next.contains(_activeNavigationTaskId!)) {
        flutterTts.stop();
        if (mounted) {
          setState(() {
            _isNavigating = false;
            _activeNavigationTaskId = null;
            _lastSpokenStepIndex = -1;
            _lastSpokenDistanceThreshold = 999999;
          });
        }
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: routeAsync.when(
        data: (route) {
          if (route == null) {
            return _buildEmptyState();
          }

          final tasks = tasksAsync.value ?? [];
          final taskStops = route.waypoints
              .where((w) => w.waypointType == 'task')
              .length;
          final center =
              route.startDepot ?? const LatLng(14.561433, 121.075636);

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
                  color: Theme.of(context).colorScheme.primary,
                  strokeWidth: 4,
                ),
              )
              .toList();

          // Build markers
          List<Marker> markers = [];
          for (var wp in route.waypoints) {
            if (wp.latitude == null || wp.longitude == null) continue;
            final pos = LatLng(wp.latitude!, wp.longitude!);

            if (wp.waypointType == 'depot_start' ||
                wp.waypointType == 'depot_end') {
              markers.add(
                Marker(
                  point: pos,
                  width: 36,
                  height: 36,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🏢', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
              );
            } else if (wp.waypointType == 'task') {
              final task = tasks
                  .where((t) => t.id == wp.cleanupTaskId)
                  .firstOrNull;
              if (task != null) {
                bool isCompleted =
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
                        color: Theme.of(context).colorScheme.primary,
                        layered: true,
                        badge: Icon(
                          isCompleted ? Icons.check : Icons.layers_outlined,
                          size: 14,
                          color: Colors.white,
                        ),
                        child: Text(
                          '${wp.sequenceOrder}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
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
          List<Polyline> microRouteLines = [];
          for (var task in tasks) {
            if (task.reports == null || task.reports!.isEmpty) continue;
            // ignore: depend_on_referenced_packages
            final wp = route.waypoints
                .where((w) => w.cleanupTaskId == task.id)
                .firstOrNull;
            if (wp == null || wp.latitude == null || wp.longitude == null) {
              continue;
            }

            final centerCoords = LatLng(wp.latitude!, wp.longitude!);

            final sortedReports = List.of(task.reports!);
            sortedReports.sort((a, b) {
              int idxA = task.reportSequence.indexOf(a.id);
              int idxB = task.reportSequence.indexOf(b.id);
              if (idxA == -1) idxA = 999;
              if (idxB == -1) idxB = 999;
              return idxA.compareTo(idxB);
            });

            List<LatLng> positions = [centerCoords];
            for (int i = 0; i < sortedReports.length; i++) {
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
                  color: AppColors.primaryDark.withValues(alpha: 0.7),
                  strokeWidth: 3.0,
                  pattern: StrokePattern.dashed(segments: [5.0, 10.0]),
                ),
              );
            }
          }

          return Stack(
            children: [
              // Map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(initialCenter: center, initialZoom: 14.0),
                children: [
                  TileLayer(
                    tileProvider: widget.tileProvider,
                    urlTemplate: Theme.of(context).brightness == Brightness.dark
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
                          color: AppColors.primaryDark,
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
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.blueAccent,
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // Unified Top Panel
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        (Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF1E1E1E)
                                : Colors.white)
                            .withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white10
                          : Colors.grey.shade200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: Theme.of(context).brightness == Brightness.dark
                              ? 0.45
                              : 0.08,
                        ),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Turn-by-Turn Header (if navigating)
                      if (_isNavigating && _currentInstruction != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryDark,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(19),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.directions,
                                color: Colors.white,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _currentInstruction!,
                                  style: AppTypography.body.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (_isNavigating)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Text(
                            !_usingSavedRoute
                                ? (_directionsSaved
                                      ? 'Directions saved for offline use'
                                      : 'Online directions · offline saving unavailable')
                                : _routeSteps.isEmpty
                                ? 'Saved route preview · no turn-by-turn guidance'
                                : 'Saved directions · no live rerouting',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      // Route Stats
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildTopStat(
                              'Stops',
                              _isNavigating ? '1' : taskStops.toString(),
                            ),
                            _buildTopStat(
                              'Est. time',
                              _formatDuration(
                                _isNavigating
                                    ? _liveRouteDuration
                                    : route.totalDurationMin,
                              ),
                            ),
                            _buildTopStat(
                              'Distance',
                              _formatDistance(
                                _isNavigating
                                    ? _liveRouteDistance
                                    : route.totalDistanceMeters,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Footer Hint (if not navigating)
                      if (!_isNavigating)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white10
                                    : Colors.grey.shade200,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.touch_app,
                                color: Colors.grey,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Tap a pin for details',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.caption.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Unified Bottom Action Card, with the map actions stacked above
              // it so they follow the card's height.
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
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            (Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF1E1E1E)
                                    : Colors.white)
                                .withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white10
                              : Colors.grey.shade200,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? 0.45
                                  : 0.08,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _isNavigating
                          ? SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  flutterTts.stop();
                                  setState(() {
                                    _isNavigating = false;
                                    _activeNavigationTaskId = null;
                                    _lastSpokenStepIndex = -1;
                                    _lastSpokenDistanceThreshold = 999999;
                                  });
                                },
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  _routeSteps.isEmpty
                                      ? 'Exit preview'
                                      : 'Exit navigation',
                                  style: AppTypography.h4.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            )
                          : Builder(
                              builder: (context) {
                                final next = pickNextCrewStop(
                                  tasks: tasks,
                                  route: route,
                                  completed: completedTasks,
                                  held: heldTasks,
                                  order: routeOrder,
                                  origin: _currentLocation,
                                );
                                if (next == null) {
                                  return Center(
                                    child: Text(
                                      'All Route Tasks Completed',
                                      style: AppTypography.body.copyWith(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                }
                                final nextTask = next.task;

                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildOrderSwitch(routeOrder),
                                    const SizedBox(height: 8),
                                    _buildNextSummary(next, routeOrder),
                                    const SizedBox(height: 12),
                                    ElevatedButton.icon(
                                      onPressed: _isStartingNavigation
                                          ? null
                                          : () {
                                              _startLiveNavigation(nextTask);
                                            },
                                      icon: _isStartingNavigation
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.near_me,
                                              color: Colors.white,
                                            ),
                                      label: Text(
                                        _isStartingNavigation
                                            ? 'Loading directions…'
                                            : 'Start next job',
                                        style: AppTypography.body.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryDark,
                                        disabledBackgroundColor: AppColors
                                            .primaryDark
                                            .withValues(alpha: 0.6),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 12),
                    // Map Action Buttons (TTS & Recenter)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isNavigating && _routeSteps.isNotEmpty) ...[
                            FloatingActionButton(
                              heroTag: 'tts_mute_toggle',
                              backgroundColor:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFF1E1E1E)
                                  : Colors.white,
                              mini: true,
                              child: Icon(
                                _isTtsMuted
                                    ? Icons.volume_off
                                    : Icons.volume_up,
                                color: _isTtsMuted
                                    ? AppColors.error
                                    : AppColors.primaryDark,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isTtsMuted = !_isTtsMuted;
                                });
                                if (_isTtsMuted) {
                                  flutterTts.stop();
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                          FloatingActionButton(
                            heroTag: 'recenter_map',
                            backgroundColor:
                                Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF1E1E1E)
                                : Colors.white,
                            child: const Icon(
                              Icons.my_location,
                              color: AppColors.primaryDark,
                            ),
                            onPressed: () {
                              if (_currentLocation != null) {
                                _mapController.move(_currentLocation!, 15.0);
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
        loading: () => const _MapSkeleton(),
        error: (err, _) => _buildEmptyState(unavailable: true),
      ),
    );
  }

  Widget _buildOrderSwitch(CrewRouteOrder order) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: 'Route order',
      child: SegmentedButton<CrewRouteOrder>(
        showSelectedIcon: false,
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          textStyle: WidgetStatePropertyAll(
            AppTypography.body.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.primaryDark
                : null,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? Colors.white
                : scheme.onSurface,
          ),
        ),
        segments: [
          for (final value in CrewRouteOrder.values)
            ButtonSegment(
              value: value,
              label: Text(value.label, textAlign: TextAlign.center),
              tooltip: switch (value) {
                CrewRouteOrder.priority =>
                  'Most urgent job first, following the published route',
                CrewRouteOrder.nearest => 'Closest job to you first',
              },
            ),
        ],
        selected: {order},
        onSelectionChanged: (selection) =>
            ref.read(fcRouteOrderProvider.notifier).select(selection.single),
      ),
    );
  }

  Widget _buildNextSummary(CrewNextStop next, CrewRouteOrder order) {
    final detail = switch (order) {
      CrewRouteOrder.priority => 'Stop ${next.waypoint.sequenceOrder}',
      CrewRouteOrder.nearest =>
        next.distanceMeters != null
            ? '${_formatDistance(next.distanceMeters)} straight-line'
            : 'Waiting for GPS, showing priority order',
    };
    return Semantics(
      liveRegion: true,
      child: Text(
        'Next: ${next.task.title} · $detail',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildTopStat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.body.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDistance(num? meters) {
    if (meters == null) return '—';
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }

  String _formatDuration(num? minutes) {
    if (minutes == null) return '—';
    final h = (minutes / 60).floor();
    final m = (minutes % 60).round();
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  void _showTaskPreview(
    BuildContext context,
    CleanupTask task,
    bool isCompleted,
  ) {
    _showRoutePreview(
      title: task.title,
      subtitle:
          'Cleanup task · ${isCompleted ? 'Completed' : task.status.replaceAll('_', ' ')}',
      description: task.description,
      location: task.streetAddress ?? task.location,
      details:
          '${task.reports?.length ?? task.reportIds.length} linked reports',
      onDetails: () => context.push(
        FieldCrewAppRoutes.taskDetail.replaceFirst(
          ':id',
          Uri.encodeComponent(task.id),
        ),
      ),
      onStart: isCompleted ? null : () => _startLiveNavigation(task),
    );
  }

  void _showReportPreview(
    BuildContext context,
    ReportModel report,
    String taskId,
  ) {
    _showRoutePreview(
      title: report.title,
      subtitle: 'Report · ${report.status.replaceAll('_', ' ')}',
      description: report.description ?? 'No description provided.',
      details: report.issueType?.replaceAll('_', ' '),
      onDetails: () => context.push(
        FieldCrewAppRoutes.reportDetail
            .replaceFirst(':id', Uri.encodeComponent(taskId))
            .replaceFirst(':reportId', Uri.encodeComponent(report.id)),
      ),
    );
  }

  void _showRoutePreview({
    required String title,
    required String subtitle,
    required String description,
    required VoidCallback onDetails,
    String? location,
    String? details,
    VoidCallback? onStart,
  }) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final colors = theme.colorScheme;
        return SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * .75,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subtitle,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close preview',
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (details != null) ...[
                    Text(
                      details,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                  if (location != null && location.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 20,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            location,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      onDetails();
                    },
                    child: const Text('View details'),
                  ),
                  if (onStart != null) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        onStart();
                      },
                      child: const Text('Navigate to task'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({bool unavailable = false}) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              unavailable
                  ? 'Route could not load'
                  : 'No published route available',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              unavailable
                  ? 'Check your connection and refresh. Your assigned tasks are still available in Tasks.'
                  : 'Assigned tasks can exist without a published route. Review your Tasks, or ask your officer to publish a route for your crew.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                ref.invalidate(activeRoutesProvider);
                ref.invalidate(myRouteProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh route'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapSkeleton extends StatelessWidget {
  const _MapSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final skeletonBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Column(
      children: [
        const Expanded(child: FcShimmerCard(height: double.infinity)),
        Container(
          height: 300,
          padding: const EdgeInsets.all(AppColors.spaceLG),
          decoration: BoxDecoration(
            color: skeletonBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: const Column(
            children: [
              FcShimmerCard(height: 100),
              SizedBox(height: AppColors.spaceLG),
              Expanded(child: FcShimmerCard(height: 200)),
            ],
          ),
        ),
      ],
    );
  }
}
