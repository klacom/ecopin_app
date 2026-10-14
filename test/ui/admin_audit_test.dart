import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/features/admin/data/admin_repository.dart';
import 'package:ecopin_app/features/admin/presentation/screens/admin_audit_logs_screen.dart';
import 'package:ecopin_app/shared/notifications/providers/notifications_provider.dart';

class SyntheticAuditRepository extends AdminRepository {
  SyntheticAuditRepository() : super(ApiClient());
  final queries = <Map<String, dynamic>>[];
  Object? failure;
  @override
  Future<Map<String, dynamic>> getAuditLogs({
    int page = 1,
    String action = '',
    String userId = '',
    String startDate = '',
    String endDate = '',
  }) async {
    queries.add({
      'page': page,
      'action': action,
      'user': userId,
      'start': startDate,
      'end': endDate,
    });
    if (failure != null) throw failure!;
    return {
      'logs': [
        {
          'id': 'entry-1',
          'action_type': 'profile_update',
          'user_id': 'actor-1',
          'created_at': '2026-10-13T06:00:00Z',
          'profiles': {'full_name': 'Maria', 'email': 'maria@example.invalid'},
          'event_data': {
            'note': 'Role updated',
            'password': 'SyntheticHiddenSecret',
          },
        },
        {
          'id': 'entry-2',
          'action_type': 'login',
          'user_id': 'actor-2',
          'created_at': '2026-10-12T06:00:00Z',
          'profiles': {'full_name': 'Jose'},
          'action_details': 'Signed in',
        },
      ],
      'pagination': {'page': page, 'total': 202, 'totalPages': 5},
    };
  }
}

void main() {
  setUp(() => dotenv.loadFromString(envString: 'SYNTHETIC_TEST=true'));
  testWidgets(
    'unapplied actor and action edits do not change refresh queries',
    (tester) async {
      final repository = SyntheticAuditRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminRepositoryProvider.overrideWithValue(repository),
            unreadNotificationsCountProvider.overrideWith(
              (ref) => Stream.value(0),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const AdminAuditLogsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Filters'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('admin-audit-actor')),
        'draft-actor',
      );
      await tester.enterText(
        find.byKey(const Key('admin-audit-action')),
        'manual_note',
      );
      await tester.pumpAndSettle();
      await tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh();
      await tester.pumpAndSettle();
      expect(repository.queries.last['user'], '');
      expect(repository.queries.last['action'], '');
      await tester.ensureVisible(find.text('Apply filters'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply filters'));
      await tester.pumpAndSettle();
      expect(repository.queries.last['user'], 'draft-actor');
      expect(repository.queries.last['action'], 'manual_note');
    },
  );
  testWidgets('date filters include the whole selected local end day', (
    tester,
  ) async {
    final repository = SyntheticAuditRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminRepositoryProvider.overrideWithValue(repository),
          unreadNotificationsCountProvider.overrideWith(
            (ref) => Stream.value(0),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const AdminAuditLogsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Choose date range'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose date range'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Switch to input'));
    await tester.pumpAndSettle();
    final dateFields = find.descendant(
      of: find.byType(DateRangePickerDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(dateFields.at(0), '10/13/2026');
    await tester.enterText(dateFields.at(1), '10/14/2026');
    await tester.tap(find.text('Use dates'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Apply filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();
    final start = DateTime.parse(
      repository.queries.last['start'] as String,
    ).toLocal();
    final end = DateTime.parse(
      repository.queries.last['end'] as String,
    ).toLocal();
    expect(start.day, 13);
    expect(start.hour, 0);
    expect(end.day, 14);
    expect(end.hour, 23);
    expect(end.minute, 59);
    expect(end.second, 59);
    expect(end.millisecond, 999);
    expect(end.microsecond, 999);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'audit search describes this page and detail hides credential fields',
    (tester) async {
      final repository = SyntheticAuditRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminRepositoryProvider.overrideWithValue(repository),
            unreadNotificationsCountProvider.overrideWith(
              (ref) => Stream.value(0),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const AdminAuditLogsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('admin-audit-search')),
        'Maria',
      );
      await tester.pumpAndSettle();
      expect(repository.queries.length, 1);
      expect(find.text('Jose'), findsNothing);
      expect(find.textContaining('1 visible of 2 loaded'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey('admin-audit-view-entry-1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('admin-audit-view-entry-1')));
      await tester.pumpAndSettle();
      expect(find.text('Audit entry'), findsOneWidget);
      expect(find.textContaining('SyntheticHiddenSecret'), findsNothing);
      expect(find.textContaining('[hidden]'), findsWidgets);
      expect(find.text('actor-1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('audit failure is recoverable and server filters are explicit', (
    tester,
  ) async {
    final repository = SyntheticAuditRepository()
      ..failure = const FormatException('Synthetic failure');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminRepositoryProvider.overrideWithValue(repository),
          unreadNotificationsCountProvider.overrideWith(
            (ref) => Stream.value(0),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const AdminAuditLogsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No audit entries returned'), findsNothing);
    repository.failure = null;
    await tester.ensureVisible(find.text('Retry audit logs'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry audit logs'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('admin-audit-actor')),
      'actor-1',
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Apply filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();
    expect(repository.queries.last['user'], 'actor-1');
    await tester.ensureVisible(find.text('Next page'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next page'));
    await tester.pumpAndSettle();
    expect(repository.queries.last['page'], 2);
    expect(tester.takeException(), isNull);
  });
}
