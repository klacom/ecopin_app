import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import 'package:ecopin_app/features/field_crew/providers/my_route_provider.dart';
import 'package:ecopin_app/features/field_crew/providers/cleanup_tasks_provider.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_shimmer_card.dart';
import 'package:ecopin_app/core/services/location_service.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'package:dio/dio.dart' as dio;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';

class FieldCrewMapScreen extends ConsumerStatefulWidget {
  const FieldCrewMapScreen({super.key});

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

  int _parsePriority(String priority) {
    if (priority.toLowerCase() == 'high') return 1;
    if (priority.toLowerCase() == 'normal') return 2;
    if (priority.toLowerCase() == 'low') return 3;
    return int.tryParse(priority) ?? 99;
  }

  @override
  void initState() {
    super.initState();
    _initTts();
    _initLocationTracking();
  }

  Future<void> _initTts() async {
    await flutterTts.setSharedInstance(true);
    await flutterTts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      [IosTextToSpeechAudioCategoryOptions.duckOthers],
    );
    await flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> _initLocationTracking() async {
    // This will request permissions if not already granted
    final loc = await LocationService.getCurrentLocation();
    if (loc != null && mounted) {
      setState(() {
        _currentLocation = loc;
      });
      // Start stream
      _locationSubscription = LocationService.getPositionStream()?.listen((position) {
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
    if (!_isNavigating || _routeSteps.isEmpty || _currentStepIndex >= _routeSteps.length) return;
    
    final now = DateTime.now();
    if (_lastLocationUpdate != null && now.difference(_lastLocationUpdate!).inMilliseconds < 1000) {
      return;
    }
    _lastLocationUpdate = now;

    final currentManeuver = _routeSteps[_currentStepIndex]['maneuver'];
    final maneuverLoc = currentManeuver['location'] as List; // [lon, lat]
    final maneuverPoint = LatLng(maneuverLoc[1], maneuverLoc[0]);

    final distance = const Distance();
    final distToManeuver = distance.as(LengthUnit.Meter, position, maneuverPoint);

    // 1. Advance Step if very close (e.g. 15m)
    if (distToManeuver <= 15) {
      if (_currentStepIndex < _routeSteps.length - 1) {
        setState(() {
          _currentStepIndex++;
          _currentInstruction = _parseInstruction(_routeSteps[_currentStepIndex]);
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
          const SnackBar(content: Text('This location is on hold for officer review.')),
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

      final targetWaypoint = route.waypoints.where((w) => w.cleanupTaskId == targetTask.id).firstOrNull;
      if (targetWaypoint == null || targetWaypoint.latitude == null || targetWaypoint.longitude == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not find destination coordinates for this task.')),
          );
        }
        return;
      }

      final destination = LatLng(targetWaypoint.latitude!, targetWaypoint.longitude!);

      // ── OSRM routing with a strict 3-second total wall-clock cap ────────────
      // Pre-flight check: if the device reports no network interface at all,
      // skip OSRM entirely to reach the offline fallback in ~0 ms.
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOffline = connectivityResult.contains(ConnectivityResult.none);

      List<LatLng> finalPolyline = [];
      String? firstInstruction;

      if (!isOffline) {
        debugPrint('[NAV] Device online — attempting OSRM (3 s cap)...');
        final tOsrmStart = DateTime.now();
        try {
          // Race the real request against a 3-second sentinel Future.
          // Using a single 3 s connectTimeout is not enough: a slow TCP
          // handshake can consume it, then receiveTimeout kicks in separately.
          // The race guarantees the total wall-clock window is ≤ 3 s.
          final dioClient = dio.Dio(dio.BaseOptions(
            connectTimeout: const Duration(seconds: 3),
            receiveTimeout: const Duration(seconds: 3),
            headers: {'User-Agent': 'dev.ecopinas.ecopin_app/1.0'},
          ));

          final url = 'http://router.project-osrm.org/route/v1/driving/'
              '${origin.longitude},${origin.latitude};'
              '${destination.longitude},${destination.latitude}'
              '?steps=true&geometries=geojson&overview=full';

          // Sentinel: throws _OsrmTimeout after 3 s regardless of Dio state
          final timeoutFuture = Future.delayed(
            const Duration(seconds: 3),
            () => throw _OsrmTimeout(),
          );

          final response = await Future.any<dio.Response>([dioClient.get(url), timeoutFuture]);
          final data = response.data;

          if (data['code'] == 'Ok') {
            final routeData = data['routes'][0];

            _liveRouteDistance = (routeData['distance'] as num?)?.toDouble();
            _liveRouteDuration = ((routeData['duration'] as num?) ?? 0) / 60;

            final geometry = routeData['geometry']['coordinates'] as List;
            finalPolyline = geometry.map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble())).toList();

            final legs = routeData['legs'] as List;
            if (legs.isNotEmpty) {
              _routeSteps = legs[0]['steps'] as List;
              _currentStepIndex = 0;
              if (_routeSteps.isNotEmpty) {
                firstInstruction = _parseInstruction(_routeSteps[0]);
                _speakInstruction(99999, firstInstruction!);
              }
            }
            final tOsrmDone = DateTime.now();
            debugPrint('[NAV] OSRM success in ${tOsrmDone.difference(tOsrmStart).inMilliseconds} ms');
          } else {
            debugPrint('[NAV] OSRM returned non-Ok code: ${data['code']} — falling back');
          }
        } on _OsrmTimeout {
          final elapsed = DateTime.now().difference(tOsrmStart).inMilliseconds;
          debugPrint('[NAV] OSRM timed out after $elapsed ms — falling back to offline route');
        } catch (e) {
          final elapsed = DateTime.now().difference(tOsrmStart).inMilliseconds;
          debugPrint('[NAV] OSRM failed after $elapsed ms — falling back: $e');
        }
      } else {
        debugPrint('[NAV] Device offline — skipping OSRM, loading pre-rendered route immediately');
      }

      // ── Offline fallback: pre-computed snapped route from backend ─────────
      if (finalPolyline.isEmpty) {
        final tFallbackStart = DateTime.now();
        debugPrint('[NAV] Offline fallback started at $tFallbackStart');

        List<LatLng> fallbackPolyline = [];
        for (var wp in route.waypoints) {
          if (wp.waypointType == 'depot_start') continue;
          if (wp.polyline.isNotEmpty) {
            fallbackPolyline.addAll(wp.polyline.map((p) => LatLng(p.latitude, p.longitude)));
          } else if (wp.latitude != null && wp.longitude != null) {
            fallbackPolyline.add(LatLng(wp.latitude!, wp.longitude!));
          }
          if (wp.cleanupTaskId == targetTask.id) break;
        }

        if (fallbackPolyline.isEmpty) {
          // No route data available at all — tell the user instead of silently
          // entering navigating=true with an empty polyline.
          debugPrint('[NAV] Offline fallback polyline is also empty — aborting navigation');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No cached route available. Please reconnect to load the route.'),
                duration: Duration(seconds: 4),
              ),
            );
          }
          return;
        }

        // Snap to the closest already-snapped point on the offline road network
        final distance = const Distance();
        double minDistance = double.infinity;
        int closestIndex = 0;
        for (int i = 0; i < fallbackPolyline.length; i++) {
          final d = distance.as(LengthUnit.Meter, origin, fallbackPolyline[i]);
          if (d < minDistance) {
            minDistance = d;
            closestIndex = i;
          }
        }

        finalPolyline = fallbackPolyline.sublist(closestIndex);
        firstInstruction = 'Follow the highlighted offline route to destination';

        final tFallbackDone = DateTime.now();
        debugPrint('[NAV] Offline fallback ready in '
            '${tFallbackDone.difference(tFallbackStart).inMilliseconds} ms');
      }

      final tTotal = DateTime.now().difference(tStart).inMilliseconds;
      debugPrint('[NAV] Start Next Job → route ready: ${tTotal} ms');

      if (mounted) {
        setState(() {
          _liveNavigationPolyline = finalPolyline;
          _currentInstruction = firstInstruction;
          _isNavigating = true;
          _activeNavigationTaskId = targetTask.id;
          _lastSpokenStepIndex = -1;
          _lastSpokenDistanceThreshold = 999999;
        });
      }
    } finally {
      // Always clear the loading guard, regardless of success or any failure path
      if (mounted) setState(() => _isStartingNavigation = false);
    }
  }

  String _parseInstruction(Map<String, dynamic> step) {
    try {
      final maneuver = step['maneuver'] as Map<String, dynamic>?;
      final name = step['name'] as String?;
      
      if (maneuver != null) {
        final type = maneuver['type'] as String?;
        final modifier = maneuver['modifier'] as String?;
        
        String instruction = type ?? 'Head';
        if (modifier != null) instruction += ' $modifier';
        if (name != null && name.isNotEmpty) instruction += ' onto $name';
        
        return '${instruction[0].toUpperCase()}${instruction.substring(1)}';
      }
      return name != null && name.isNotEmpty ? 'Head onto $name' : 'Follow the route';
    } catch (e) {
      return 'Follow the route';
    }
  }

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
      backgroundColor: AppColors.backgroundDark,
      body: routeAsync.when(
        data: (route) {
          if (route == null) {
            return _buildEmptyState();
          }

          final tasks = tasksAsync.value ?? [];
          final taskStops = route.waypoints.where((w) => w.waypointType == 'task').length;
          final center = route.startDepot ?? const LatLng(14.561433, 121.075636);

          // Build full polyline from waypoints ONLY if navigating
          List<LatLng> fullPolyline = [];
          if (_isNavigating && _activeNavigationTaskId != null) {
            for (var wp in route.waypoints) {
              if (wp.waypointType == 'depot_start') continue;
              if (wp.polyline.isNotEmpty) {
                fullPolyline.addAll(wp.polyline.map((p) => LatLng(p.latitude, p.longitude)));
              } else if (wp.latitude != null && wp.longitude != null) {
                fullPolyline.add(LatLng(wp.latitude!, wp.longitude!));
              }
              if (wp.cleanupTaskId == _activeNavigationTaskId) {
                break; // Stop path at the target task
              }
            }
          }

          // Dynamically snap and trim route to current location (Overview only)
          List<LatLng> mainRoutePoints = [];
          if (_isNavigating) {
            mainRoutePoints = _liveNavigationPolyline;
          } else if (_currentLocation != null && fullPolyline.isNotEmpty) {
            final distance = const Distance();
            double minDistance = double.infinity;
            int closestIndex = 0;

            for (int i = 0; i < fullPolyline.length; i++) {
              double d = distance.as(LengthUnit.Meter, _currentLocation!, fullPolyline[i]);
              if (d < minDistance) {
                minDistance = d;
                closestIndex = i;
              }
            }

            // Connect current location to the closest point on the pre-computed road network
            mainRoutePoints = [_currentLocation!, ...fullPolyline.sublist(closestIndex)];
          } else {
            mainRoutePoints = fullPolyline;
          }

          // Build markers
          List<Marker> markers = [];
          for (var wp in route.waypoints) {
            if (wp.latitude == null || wp.longitude == null) continue;
            final pos = LatLng(wp.latitude!, wp.longitude!);
            
            if (wp.waypointType == 'depot_start' || wp.waypointType == 'depot_end') {
              markers.add(Marker(
                point: pos,
                width: 36,
                height: 36,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: const Center(child: Text('🏢', style: TextStyle(fontSize: 16))),
                ),
              ));
            } else if (wp.waypointType == 'task') {
              final task = tasks.where((t) => t.id == wp.cleanupTaskId).firstOrNull;
              if (task != null) {
                bool isCompleted = completedTasks.contains(task.id) || task.status.toLowerCase() == 'completed';
                markers.add(Marker(
                  point: pos,
                  width: 32,
                  height: 32,
                  child: GestureDetector(
                    onTap: () => _showTaskPreview(context, task, isCompleted),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isCompleted ? Colors.blueGrey : AppColors.primaryDark,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))],
                      ),
                      child: Center(
                        child: isCompleted
                           ? const Icon(Icons.check, color: Colors.white, size: 16)
                           : Text(
                               wp.sequenceOrder.toString(),
                               style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                             ),
                      ),
                    ),
                  ),
                ));
              }
            }
          }

          // Build micro routes (dashed polylines and sub-waypoint markers)
          List<Polyline> microRouteLines = [];
          for (var task in tasks) {
            if (task.reports == null || task.reports!.isEmpty) continue;
            // ignore: depend_on_referenced_packages
            final wp = route.waypoints.where((w) => w.cleanupTaskId == task.id).firstOrNull;
            if (wp == null || wp.latitude == null || wp.longitude == null) continue;

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
                final isPending = report.validationStatus == 'pending';
                markers.add(Marker(
                  point: report.location,
                  width: 28,
                  height: 28,
                  child: GestureDetector(
                    onTap: () => _showReportPreview(context, report),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isPending ? AppColors.info : AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))],
                      ),
                      child: Center(
                        child: Text(
                          '${wp.sequenceOrder}.${i + 1}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                ));
              }
            }
            if (positions.length > 1) {
              microRouteLines.add(Polyline(
                points: positions,
                color: AppColors.primaryDark.withValues(alpha: 0.7),
                strokeWidth: 3.0,
                pattern: StrokePattern.dashed(segments: [5.0, 10.0]),
              ));
            }
          }

          return Stack(
            children: [
              // Map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 14.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: Theme.of(context).brightness == Brightness.dark
                        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png?key=${dotenv.env['CARTO_API_KEY'] ?? ''}'
                        : 'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png?key=${dotenv.env['CARTO_API_KEY'] ?? ''}',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'dev.ecopinas.ecopin_app',
                  ),
                  if (mainRoutePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: mainRoutePoints,
                          color: AppColors.primaryDark,
                          strokeWidth: 4.0,
                        ),
                      ],
                    ),
                  if (microRouteLines.isNotEmpty)
                    PolylineLayer(
                      polylines: microRouteLines,
                    ),
                  if (markers.isNotEmpty)
                    MarkerLayer(
                      markers: markers,
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
                                )
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
                    color: AppColors.surfaceDark.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.dividerDark),
                    boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, 6))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Turn-by-Turn Header (if navigating)
                      if (_isNavigating && _currentInstruction != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryDark,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.directions, color: Colors.black, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _currentInstruction!,
                                  style: AppTypography.h4.copyWith(color: Colors.black, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Route Stats
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildTopStat('STOPS', _isNavigating ? '1' : taskStops.toString()),
                            _buildTopStat('ETA', _formatDuration(_isNavigating && _liveRouteDuration != null ? _liveRouteDuration : route.totalDurationMin)),
                            _buildTopStat('DIST', _formatDistance(_isNavigating && _liveRouteDistance != null ? _liveRouteDistance : route.totalDistanceMeters)),
                          ],
                        ),
                      ),

                      // Footer Hint (if not navigating)
                      if (!_isNavigating)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: AppColors.dividerDark)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.touch_app, color: Colors.grey, size: 14),
                              const SizedBox(width: 6),
                              Text('Tap any pin to view details', style: AppTypography.caption.copyWith(color: Colors.grey)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Unified Bottom Action Card
              Positioned(
                bottom: 130, // Elevated to avoid navbar labels
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.dividerDark),
                    boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, 4))],
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
                            icon: const Icon(Icons.close, color: Colors.white),
                            label: Text(
                              'EXIT NAVIGATION',
                              style: AppTypography.h4.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                          ),
                        )
                      : Builder(
                          builder: (context) {
                            // ignore: depend_on_referenced_packages
                            final uncompletedTasks = tasks.where((t) {
                              if (t.status.toLowerCase() == 'completed' ||
                                  t.status.toLowerCase() == 'cancelled' ||
                                  completedTasks.contains(t.id) ||
                                  heldTasks.contains(t.id)) {
                                return false;
                              }
                              return route.waypoints.any((w) => w.cleanupTaskId == t.id);
                            }).toList();
                            
                            uncompletedTasks.sort((a, b) {
                              final wpA = route.waypoints.firstWhere((w) => w.cleanupTaskId == a.id);
                              final wpB = route.waypoints.firstWhere((w) => w.cleanupTaskId == b.id);
                              return wpA.sequenceOrder.compareTo(wpB.sequenceOrder);
                            });
                            final nextTask = uncompletedTasks.firstOrNull;
                            if (nextTask == null) {
                              return Center(
                                child: Text(
                                  'All Route Tasks Completed',
                                  style: AppTypography.body.copyWith(color: Colors.grey),
                                ),
                              );
                            }

                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isStartingNavigation ? null : () {
                                  _startLiveNavigation(nextTask);
                                },
                                icon: _isStartingNavigation
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.black,
                                        ),
                                      )
                                    : const Icon(Icons.near_me, color: Colors.black),
                                label: Text(
                                  'START NEXT JOB',
                                  style: AppTypography.h4.copyWith(color: Colors.black, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryDark,
                                  disabledBackgroundColor: AppColors.primaryDark.withValues(alpha: 0.6),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                              ),
                            );
                          }
                        ),
                ),
              ),

              // Map Action Buttons (TTS & Recenter)
              Positioned(
                bottom: 250, // Elevated above the new bottom action card
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isNavigating) ...[
                      FloatingActionButton(
                        heroTag: 'tts_mute_toggle',
                        backgroundColor: AppColors.surfaceDark,
                        mini: true,
                        child: Icon(
                          _isTtsMuted ? Icons.volume_off : Icons.volume_up,
                          color: _isTtsMuted ? AppColors.error : AppColors.primaryDark,
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
                      backgroundColor: AppColors.surfaceDark,
                      child: const Icon(Icons.my_location, color: AppColors.primaryDark),
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
          );
        },
        loading: () => const _MapSkeleton(),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.error))),
      ),
    );
  }

  Widget _buildTopStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.body.copyWith(
            color: AppColors.textPrimaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
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

  void _showTaskPreview(BuildContext context, CleanupTask task, bool isCompleted) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => Container(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.backgroundDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.dividerDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: AppTypography.h4.copyWith(color: AppColors.textPrimaryDark, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.blueGrey.withValues(alpha: 0.2) : AppColors.primaryDark.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isCompleted ? 'COMPLETED' : task.status.toUpperCase(),
                    style: AppTypography.caption.copyWith(
                      color: isCompleted ? Colors.blueGrey : AppColors.primaryDark, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task.description,
              style: AppTypography.body.copyWith(color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: Colors.grey, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.location,
                    style: AppTypography.caption.copyWith(color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Created: ${task.createdAt.toString().split(' ')[0]}',
                  style: AppTypography.caption.copyWith(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (task.reports != null && task.reports!.isNotEmpty) ...[
              Text(
                'Reports in Task (${task.reports!.length})',
                style: AppTypography.h5.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...task.reports!.take(3).map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.dividerDark),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            r.validationStatus == 'pending' ? Icons.pending_actions : Icons.check_circle,
                            color: r.validationStatus == 'pending' ? AppColors.info : AppColors.success,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              r.title,
                              style: AppTypography.body.copyWith(color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(height: 24),
            ],
            
            // Render different buttons based on status and active navigation
            if (isCompleted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceLight,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Close', style: AppTypography.h5.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            else if (_isNavigating && _activeNavigationTaskId == task.id)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    flutterTts.stop();
                    ref.read(completedTasksProvider.notifier).addCompletedTask(task.id);
                    setState(() {
                      _isNavigating = false;
                      _activeNavigationTaskId = null;
                      _lastSpokenStepIndex = -1;
                      _lastSpokenDistanceThreshold = 999999;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Submit Report', style: AppTypography.h5.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _startLiveNavigation(task);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Start Task', style: AppTypography.h5.copyWith(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showReportPreview(BuildContext context, ReportModel report) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => Container(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.backgroundDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.dividerDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    report.title,
                    style: AppTypography.h4.copyWith(color: AppColors.textPrimaryDark, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    report.status.toUpperCase(),
                    style: AppTypography.caption.copyWith(color: AppColors.info, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              report.issueType ?? 'General Issue',
              style: AppTypography.caption.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              report.description ?? 'No description.',
              style: AppTypography.body.copyWith(color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceLight,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('View Details', style: AppTypography.h5.copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 64, color: AppColors.primaryDark.withValues(alpha: 0.5)),
          const SizedBox(height: AppColors.spaceLG),
          Text(
            '[ NO ACTIVE ROUTE ASSIGNED ]',
            style: AppTypography.h5.copyWith(color: AppColors.textPrimaryDark),
          ),
          const SizedBox(height: AppColors.spaceSM),
          Text(
            'You do not have an active route assigned for today,\nor it has not been approved yet.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _MapSkeleton extends StatelessWidget {
  const _MapSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Expanded(child: FcShimmerCard(height: double.infinity)),
        Container(
          height: 300,
          padding: const EdgeInsets.all(AppColors.spaceLG),
          decoration: const BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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

/// Sentinel exception thrown by the 3-second wall-clock timeout Future
/// in [_FieldCrewMapScreenState._startLiveNavigation]. Caught specifically
/// to distinguish a deliberate timeout from other Dio errors.
class _OsrmTimeout implements Exception {
  const _OsrmTimeout();
}
