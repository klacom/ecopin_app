import 'dart:async';
import 'package:ecopin_app/core/constants/app_constants.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/shared/notifications/data/notification_repository.dart';
import 'package:ecopin_app/shared/notifications/data/notification_destination.dart';
import 'package:ecopin_app/shared/notifications/providers/notifications_provider.dart';
import 'package:ecopin_app/shared/notifications/presentation/screens/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class SyntheticNotifications implements NotificationRepository {
  int allRequests = 0, readRequests = 0, deleteRequests = 0;
  bool readFails = false, deleteFails = true;
  Completer<int>? pendingAll;
  @override
  Stream<List<Map<String, dynamic>>> watch() => Stream.value([]);
  @override
  Future<int> markAllRead() async {
    allRequests++;
    return pendingAll?.future ?? 2;
  }

  @override
  Future<void> markRead(String id) async {
    readRequests++;
    if (readFails) throw StateError('Synthetic failure');
  }

  @override
  Future<void> delete(String id) async {
    deleteRequests++;
    if (deleteFails) throw StateError('Synthetic failure');
  }
}

final notificationRows = <Map<String, dynamic>>[
  {
    'id': 'one',
    'title': 'Your report has an update',
    'body': 'The response team has reviewed your concern.',
    'is_read': false,
    'report_id': 'report-one',
    'created_at': DateTime.now().toIso8601String(),
  },
  {
    'id': 'two',
    'title': 'Earlier response',
    'body': 'A previous update.',
    'is_read': true,
    'created_at': DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String(),
  },
  {
    'id': 'three',
    'title': 'General notice',
    'body': 'No report link is attached.',
    'is_read': false,
    'created_at': 'invalid-date',
  },
];

Future<GoRouter> showNotifications(
  WidgetTester tester,
  SyntheticNotifications repository, {
  UserRole role = UserRole.citizen,
  Stream<List<Map<String, dynamic>>>? stream,
  bool large = false,
}) async {
  final router = GoRouter(
    initialLocation: '/notifications',
    routes: [
      GoRoute(
        path: '/notifications',
        builder: (_, _) => NotificationsScreen(role: role),
      ),
      GoRoute(
        path: '/officer/reports/:id',
        builder: (_, state) => Scaffold(
          body: Text('Officer report ${state.pathParameters['id']}'),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        notificationRepositoryProvider.overrideWithValue(repository),
        notificationsProvider.overrideWith(
          (ref) => stream ?? Stream.value(notificationRows),
        ),
        unreadNotificationsCountProvider.overrideWith((ref) => Stream.value(2)),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(large ? 2 : 1)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  test(
    'report links preserve each role and encode identifiers without inventing task links',
    () {
      const row = {'report_id': 'id/with space'};
      expect(
        notificationDestination(row, UserRole.citizen)?.path,
        '/reports/id%2Fwith%20space',
      );
      expect(
        notificationDestination(row, UserRole.officer)?.path,
        '/officer/reports/id%2Fwith%20space',
      );
      expect(
        notificationDestination(row, UserRole.fieldCrew)?.path,
        '/field-crew/reports/id%2Fwith%20space',
      );
      expect(notificationDestination(row, UserRole.admin), isNull);
      expect(
        notificationDestination({
          'title': 'New Task Assigned',
        }, UserRole.fieldCrew),
        isNull,
      );
    },
  );
  testWidgets(
    'read hierarchy, honest dates and unread filter remain usable at 320px/2x',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await showNotifications(tester, SyntheticNotifications(), large: true);
      expect(find.text('Today'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Unread'));
      await tester.pumpAndSettle();
      expect(find.text('Earlier response'), findsNothing);
      await tester.scrollUntilVisible(find.text('General notice'), 180);
      expect(find.text('Date unavailable'), findsOneWidget);
      expect(find.text('General notice'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('mark all locks repeats, reports rejection, then permits retry', (
    tester,
  ) async {
    final repository = SyntheticNotifications()..pendingAll = Completer<int>();
    await showNotifications(tester, repository);
    await tester.tap(find.text('Mark all as read'));
    await tester.pump();
    expect(repository.allRequests, 1);
    repository.pendingAll!.completeError(StateError('Synthetic failure'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not mark all notifications as read. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Your report has an update'), findsOneWidget);
    repository.pendingAll = null;
    await tester.ensureVisible(find.text('Mark all as read'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark all as read'));
    await tester.pumpAndSettle();
    expect(repository.allRequests, 2);
    expect(find.text('2 notifications marked as read.'), findsOneWidget);
  });
  testWidgets(
    'removal requires confirmation and a failed removal retains the update',
    (tester) async {
      final repository = SyntheticNotifications();
      await showNotifications(tester, repository);
      await tester.tap(find.byTooltip('Actions for Your report has an update'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove notification'));
      await tester.pumpAndSettle();
      expect(repository.deleteRequests, 0);
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(repository.deleteRequests, 1);
      expect(
        find.text('Could not remove this notification. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Your report has an update'), findsOneWidget);
    },
  );
  testWidgets(
    'officer report destination stays available if marking read fails',
    (tester) async {
      final repository = SyntheticNotifications()..readFails = true;
      final router = await showNotifications(
        tester,
        repository,
        role: UserRole.officer,
      );
      await tester.tap(find.text('Open report').first);
      await tester.pumpAndSettle();
      expect(find.text('Officer report report-one'), findsOneWidget);
      expect(repository.readRequests, 1);
      router.pop();
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Could not mark this notification as read. Please try again.',
        ),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'stream failure is distinct from an empty inbox and offers reload',
    (tester) async {
      final stream = StreamController<List<Map<String, dynamic>>>();
      addTearDown(stream.close);
      final showing = showNotifications(
        tester,
        SyntheticNotifications(),
        stream: stream.stream,
      );
      stream.addError(StateError('Synthetic load failure'));
      await showing;
      expect(find.text('Notifications unavailable'), findsOneWidget);
      expect(find.text('No notifications yet'), findsNothing);
      expect(find.text('Reload notifications'), findsOneWidget);
    },
  );
  testWidgets(
    'stream interruption keeps loaded updates with a stale-data notice',
    (tester) async {
      final stream = StreamController<List<Map<String, dynamic>>>();
      addTearDown(stream.close);
      stream.add(notificationRows);
      await showNotifications(
        tester,
        SyntheticNotifications(),
        stream: stream.stream,
      );
      stream.addError(StateError('Synthetic interruption'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Updates are unavailable. Showing the last loaded notifications.',
        ),
        findsOneWidget,
      );
      expect(find.text('Your report has an update'), findsOneWidget);
      expect(find.text('No notifications yet'), findsNothing);
    },
  );
  testWidgets('reload recovers an unavailable inbox with actual new data', (
    tester,
  ) async {
    var loads = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(
            SyntheticNotifications(),
          ),
          notificationsProvider.overrideWith(
            (ref) => ++loads == 1
                ? Stream.error(StateError('Synthetic first load failure'))
                : Stream.value(notificationRows),
          ),
          unreadNotificationsCountProvider.overrideWith(
            (ref) => Stream.value(2),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const NotificationsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Notifications unavailable'), findsOneWidget);
    await tester.tap(find.byTooltip('Reload notifications'));
    await tester.pumpAndSettle();
    expect(loads, 2);
    expect(find.text('Notifications unavailable'), findsNothing);
    expect(find.text('Your report has an update'), findsOneWidget);
  });
}
