import 'dart:async';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/features/field_crew/data/models/route_model.dart';
import 'package:ecopin_app/features/field_crew/data/models/waypoint_model.dart';
import 'package:ecopin_app/features/field_crew/offline/fc_offline_package_notifier.dart';
import 'package:ecopin_app/features/field_crew/presentation/controllers/fc_sync_ui_providers.dart';
import 'package:ecopin_app/features/field_crew/presentation/screens/field_crew_dashboard_screen.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_current_objective_card.dart';
import 'package:ecopin_app/features/field_crew/providers/cleanup_tasks_provider.dart';
import 'package:ecopin_app/features/field_crew/providers/my_route_provider.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_photo_sync_manager.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_gate.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_result.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_settings.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_trigger.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:ecopin_app/shared/profile/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'crew_dashboard_presentation_test.dart';
import 'crew_offline_ui_test.dart';

class SyntheticDashboard {
  List<CleanupTask> rows = [
    CleanupTask.fromJson({
      'id': 'active task',
      'title':
          'Clear waste beside the residential street near San Nicolas in Pasig',
      'status': 'in_progress',
      'priority': 'urgent',
      'street_address': 'Caruncho Avenue, San Nicolas, Pasig City',
    }),
    dashboardTask(
      'route-first',
      address:
          'A long address beside the public market and neighborhood school in Pasig',
    ),
    dashboardTask('priority', priority: 'high'),
    dashboardTask('last'),
    dashboardTask('finished', status: 'completed'),
    dashboardTask('cancelled', status: 'cancelled'),
    dashboardTask('held'),
    dashboardTask('local-complete'),
  ];
  RouteModel? route = RouteModel(
    id: 'synthetic-route',
    crewName: 'SWMO',
    totalDistanceMeters: 2400,
    totalDurationMin: 35,
    waypoints: [
      WaypointModel(waypointType: 'depot_start', sequenceOrder: 0),
      WaypointModel(
        waypointType: 'task',
        cleanupTaskId: 'route-first',
        sequenceOrder: 1,
      ),
      WaypointModel(
        waypointType: 'task',
        cleanupTaskId: 'active task',
        sequenceOrder: 2,
      ),
    ],
  );
  bool failTasks = false, failRoute = false;
  int taskReads = 0;
  Completer<List<CleanupTask>>? pendingTasks;
  Future<List<CleanupTask>> readTasks() async {
    taskReads++;
    if (failTasks) throw StateError('Synthetic private debugging details');
    return pendingTasks?.future ?? rows;
  }

  Future<RouteModel?> readRoute() async {
    if (failRoute) throw StateError('Synthetic private route details');
    return route;
  }
}

Future<ProviderContainer> mountDashboard(
  WidgetTester tester, {
  required SyntheticDashboard data,
  SyntheticCrewGate? gate,
  bool dark = false,
  double scale = 2,
  GoRouter? router,
  FcNetworkType network = FcNetworkType.wifi,
  SyntheticCrewSettings? settings,
  Size size = const Size(320, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  Widget wrap(BuildContext context, Widget? child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(scale),
      padding: const EdgeInsets.only(bottom: 24),
    ),
    child: RepaintBoundary(
      key: const Key('crew-dashboard-preview'),
      child: child!,
    ),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        myCleanupTasksProvider.overrideWith((ref) => data.readTasks()),
        myRouteProvider.overrideWith((ref) => data.readRoute()),
        profileProvider.overrideWith(
          (ref) => Stream.value({'full_name': 'Alexandra SWMO field crew'}),
        ),
        fcSyncGateProvider.overrideWithValue(gate ?? SyntheticCrewGate()),
        fcSyncNetworkProvider.overrideWith((ref) => Stream.value(network)),
        fcSyncSettingsProvider.overrideWith(
          () => settings ?? SyntheticCrewSettings(),
        ),
        fcOfflinePackageNotifierProvider.overrideWith(
          () => SyntheticCrewPackage(crewPackage()),
        ),
      ],
      child: router == null
          ? MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              builder: wrap,
              home: const FieldCrewDashboardScreen(),
            )
          : MaterialApp.router(
              theme: dark ? AppTheme.dark : AppTheme.light,
              builder: wrap,
              routerConfig: router,
            ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return ProviderScope.containerOf(
    tester.element(find.byType(FieldCrewDashboardScreen)),
  );
}

void main() {
  testWidgets(
    'dashboard shortcuts keep the existing map, task, sync, and preparation destinations',
    (tester) async {
      final destinations = {
        'Open route map': FieldCrewAppRoutes.map,
        'View all assignments': FieldCrewAppRoutes.tasks,
        'Open Sync Center': FieldCrewAppRoutes.syncCenter,
        'Offline package has gaps': FieldCrewAppRoutes.prepareOffline,
      };
      final router = GoRouter(
        initialLocation: FieldCrewAppRoutes.dashboard,
        routes: [
          GoRoute(
            path: FieldCrewAppRoutes.dashboard,
            builder: (_, _) => const FieldCrewDashboardScreen(),
          ),
          for (final path in destinations.values)
            GoRoute(
              path: path,
              builder: (_, state) =>
                  Scaffold(body: Text('Destination ${state.uri.path}')),
            ),
        ],
      );
      addTearDown(router.dispose);
      await mountDashboard(tester, data: SyntheticDashboard(), router: router);
      await tester.pumpAndSettle();
      for (final entry in destinations.entries) {
        await tester.ensureVisible(find.text(entry.key));
        await tester.tap(find.text(entry.key));
        await tester.pumpAndSettle();
        expect(find.text('Destination ${entry.value}'), findsOneWidget);
        router.go(FieldCrewAppRoutes.dashboard);
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'dashboard puts the complete current task before progress and separates local/held work',
    (tester) async {
      final data = SyntheticDashboard();
      final container = await mountDashboard(tester, data: data);
      container.read(heldTasksProvider.notifier).holdTask('held');
      container
          .read(completedTasksProvider.notifier)
          .addCompletedTask('local-complete');
      await tester.pumpAndSettle();
      final current = tester.widget<FcCurrentObjectiveCard>(
        find.byType(FcCurrentObjectiveCard),
      );
      expect(current.task.id, 'active task');
      expect(
        tester.widget<Text>(find.text(current.task.title)).maxLines,
        isNull,
      );
      expect(find.text('Recorded complete on this device'), findsOneWidget);
      expect(find.text('On hold on this device'), findsOneWidget);
      expect(
        find.text('1 of 8 loaded assignments are completed.'),
        findsOneWidget,
      );
      expect(find.text('Stop 2'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Open current task')).dy,
        lessThan(tester.getTopLeft(find.text('Assigned task progress')).dy),
      );
      expect(find.text('Start Task'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'task opening preserves the route ID and returning refreshes only local queue counts',
    (tester) async {
      final data = SyntheticDashboard(), gate = SyntheticCrewGate();
      final router = GoRouter(
        initialLocation: FieldCrewAppRoutes.dashboard,
        routes: [
          GoRoute(
            path: FieldCrewAppRoutes.dashboard,
            builder: (_, _) => const FieldCrewDashboardScreen(),
          ),
          GoRoute(
            path: FieldCrewAppRoutes.taskDetail,
            builder: (_, state) => Scaffold(
              appBar: AppBar(title: const Text('Task details')),
              body: Text('Task destination: ${state.pathParameters['id']}'),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await mountDashboard(tester, data: data, gate: gate, router: router);
      await tester.pumpAndSettle();
      final initialReads = gate.reads;
      await tester.ensureVisible(find.text('Open current task'));
      await tester.tap(find.text('Open current task'));
      await tester.pumpAndSettle();
      expect(find.text('Task destination: active task'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(gate.reads, greaterThan(initialReads));
      expect(data.taskReads, 1);
    },
  );
  testWidgets(
    'loading, failed retry, and stale task refresh do not erase useful work',
    (tester) async {
      final data = SyntheticDashboard()
        ..pendingTasks = Completer<List<CleanupTask>>();
      final container = await mountDashboard(tester, data: data);
      expect(find.byType(LinearProgressIndicator), findsWidgets);
      expect(find.text('No active task to open next'), findsNothing);
      data.pendingTasks!.completeError(
        StateError('Synthetic private debugging details'),
      );
      data.pendingTasks = null;
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Assignments could not load. Try again to retrieve your assigned work.',
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Retry assignments'));
      await tester.tap(find.text('Retry assignments'));
      await tester.pumpAndSettle();
      expect(find.byType(FcCurrentObjectiveCard), findsOneWidget);
      data.failTasks = true;
      container.invalidate(myCleanupTasksProvider);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('The last loaded tasks remain below'),
        findsOneWidget,
      );
      expect(find.byType(FcCurrentObjectiveCard), findsOneWidget);
      expect(find.textContaining('Synthetic private'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'photo-only failures and pending removals are reflected in the dashboard sync control',
    (tester) async {
      final gate = SyntheticCrewGate()
        ..summary = const FcPendingSummary(
          mutationCount: 0,
          photoCount: 0,
          failedPhotoCount: 0,
          pendingDeleteCount: 2,
          estimatedBytes: 0,
        );
      final container = await mountDashboard(
        tester,
        data: SyntheticDashboard(),
        gate: gate,
        dark: true,
      );
      await tester.pumpAndSettle();
      expect(find.text('2 items waiting to sync'), findsOneWidget);
      container
          .read(fcSyncStateProvider.notifier)
          .setResult(
            const FcSyncRunResult(
              total: 0,
              succeeded: 0,
              merged: 0,
              conflicted: 0,
              retryable: 0,
              permanent: 0,
              results: [],
            ),
            const FcPhotoSyncRunResult(
              uploadAttempted: 1,
              uploadSucceeded: 0,
              uploadFailed: 1,
              deleteAttempted: 0,
              deleteSucceeded: 0,
              deleteFailed: 0,
            ),
          );
      await tester.pumpAndSettle();
      expect(find.text('Sync needs attention'), findsOneWidget);
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('Sync needs attention'), findsOneWidget);
      expect(find.text('Synced'), findsNothing);
    },
  );
  testWidgets('unknown queue and route states stay unavailable with recovery', (
    tester,
  ) async {
    final gate = SyntheticCrewGate()..failSummary = true;
    final data = SyntheticDashboard()..failRoute = true;
    await mountDashboard(tester, data: data, gate: gate);
    await tester.pumpAndSettle();
    expect(find.text('Queue could not be checked'), findsOneWidget);
    expect(find.text('No queued crew work'), findsNothing);
    expect(find.text('Retry route context'), findsOneWidget);
    expect(find.byType(FcCurrentObjectiveCard), findsOneWidget);
    data.failRoute = false;
    await tester.ensureVisible(find.text('Retry route context'));
    await tester.tap(find.text('Retry route context'));
    await tester.pumpAndSettle();
    expect(find.text('Retry route context'), findsNothing);
    expect(find.text('Stop 2'), findsOneWidget);
  });
  testWidgets('an empty assignment list does not announce a completed shift', (
    tester,
  ) async {
    await mountDashboard(
      tester,
      data: SyntheticDashboard()
        ..rows = []
        ..route = null,
    );
    await tester.pumpAndSettle();
    expect(find.text('No active task to open next'), findsOneWidget);
    expect(
      find.text(
        'No assignments are available in the loaded records. Refresh when connected to check for updates.',
      ),
      findsOneWidget,
    );
    expect(find.text('You\'re all caught up!'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
