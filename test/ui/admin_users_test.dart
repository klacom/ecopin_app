import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/features/admin/data/admin_repository.dart';
import 'package:ecopin_app/features/admin/presentation/screens/admin_users_screen.dart';
import 'package:ecopin_app/shared/notifications/providers/notifications_provider.dart';
import 'package:ecopin_app/shared/profile/providers/profile_provider.dart';

class SyntheticUsersRepository extends AdminRepository {
  SyntheticUsersRepository() : super(ApiClient());
  final queries = <Map<String, dynamic>>[];
  final mutations = <Map<String, dynamic>>[];
  bool deleteFails = true;
  final delayed = <String, Completer<Map<String, dynamic>>>{};
  final own = <String, dynamic>{
    'id': 'own-account',
    'full_name': 'Current administrator',
    'role': 'admin',
    'email': 'own@example.invalid',
    'require_password_change': false,
  };
  final other = <String, dynamic>{
    'id': 'other-account',
    'full_name': 'Maria from the response team',
    'role': 'officer',
    'email': 'maria@example.invalid',
    'require_password_change': true,
  };
  @override
  Future<Map<String, dynamic>> getUsers({
    int page = 1,
    String search = '',
    String role = '',
  }) async {
    queries.add({'page': page, 'search': search, 'role': role});
    if (delayed.containsKey(search)) return delayed[search]!.future;
    final users = search.isNotEmpty ? [other] : [own, other];
    return {
      'users': users,
      'pagination': {'page': page, 'total': 22, 'totalPages': 2},
    };
  }

  @override
  Future<Map<String, dynamic>> getUser(String id) async => {
    ...(id == own['id'] ? own : other),
    'auth': {
      'email': id == own['id'] ? own['email'] : other['email'],
      'last_sign_in_at': '2026-10-13T00:00:00Z',
    },
  };
  @override
  Future<Map<String, dynamic>> getSettings() async => {
    'password_min_length': 10,
    'password_require_uppercase': true,
    'password_require_lowercase': true,
    'password_require_numbers': true,
    'password_require_special_chars': true,
  };
  @override
  Future<void> changeRole(String id, String role) async {
    mutations.add({'action': 'role', 'id': id, 'role': role});
    other['role'] = role;
  }

  @override
  Future<void> deleteUser(String id) async {
    if (deleteFails) throw const FormatException('Synthetic deletion failure');
    mutations.add({'action': 'delete', 'id': id});
  }

  @override
  Future<void> createUser({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    mutations.add({
      'action': 'create',
      'email': email,
      'password': password,
      'name': name,
      'role': role,
    });
  }

  @override
  Future<void> resetPassword(String id, String password) async {
    mutations.add({'action': 'password', 'id': id, 'password': password});
  }
}

Future<void> mountUsers(
  WidgetTester tester,
  SyntheticUsersRepository repository, {
  bool dark = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        adminRepositoryProvider.overrideWithValue(repository),
        profileProvider.overrideWith((ref) => Stream.value(repository.own)),
        unreadNotificationsCountProvider.overrideWith((ref) => Stream.value(0)),
      ],
      child: MaterialApp(
        theme: dark ? AppTheme.dark : AppTheme.light,
        home: const AdminUsersScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => dotenv.loadFromString(envString: 'SYNTHETIC_TEST=true'));
  testWidgets('an older search response cannot replace newer account results', (
    tester,
  ) async {
    final repository = SyntheticUsersRepository();
    repository.delayed['old'] = Completer();
    await mountUsers(tester, repository);
    await tester.enterText(find.byKey(const Key('admin-user-search')), 'old');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('admin-user-search')), 'new');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    repository.delayed['old']!.complete({
      'users': [
        {'id': 'old-result', 'full_name': 'Old result', 'role': 'citizen'},
      ],
      'pagination': {'page': 1, 'total': 1, 'totalPages': 1},
    });
    await tester.pumpAndSettle();
    expect(find.text('Old result'), findsNothing);
    expect(find.text('Maria from the response team'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'password reset is explicit, follows policy, and returns to the same account',
    (tester) async {
      final repository = SyntheticUsersRepository();
      await mountUsers(tester, repository);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('admin-view-other-account')),
      );
      await tapVisible(tester, find.text('Reset password'));
      await tester.enterText(
        find.byKey(const Key('admin-account-password')),
        'SyntheticOnly!123',
      );
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Review password reset'));
      expect(repository.mutations, isEmpty);
      await tester.tap(find.text('Reset password').last);
      await tester.pumpAndSettle();
      expect(repository.mutations.single['action'], 'password');
      expect(repository.mutations.single['id'], 'other-account');
      expect(find.text('Account details'), findsOneWidget);
      expect(find.text('Password updated'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'search uses the server query and self account cannot change role or be deleted',
    (tester) async {
      final repository = SyntheticUsersRepository();
      await mountUsers(tester, repository);
      await tester.enterText(
        find.byKey(const Key('admin-user-search')),
        'maria',
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(repository.queries.last['search'], 'maria');
      await tapVisible(tester, find.byTooltip('Clear account search'));
      await tapVisible(
        tester,
        find.byKey(const ValueKey('admin-view-own-account')),
      );
      expect(
        find.textContaining('cannot change your own role'),
        findsOneWidget,
      );
      final delete = find.widgetWithText(TextButton, 'Delete account');
      expect(tester.widget<TextButton>(delete).onPressed, isNull);
      expect(repository.mutations, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'role changes require confirmation; failed deletion keeps the account visible',
    (tester) async {
      final repository = SyntheticUsersRepository();
      await mountUsers(tester, repository, dark: true);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('admin-view-other-account')),
      );
      await tapVisible(tester, find.byKey(const Key('admin-user-role')));
      await tester.tap(find.text('Field crew').last);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButton<String>>(
              find.descendant(
                of: find.byKey(const Key('admin-user-role')),
                matching: find.byType(DropdownButton<String>),
              ),
            )
            .focusNode!
            .hasFocus,
        isTrue,
      );
      await tapVisible(tester, find.text('Save role'));
      expect(repository.mutations, isEmpty);
      await tester.tap(find.text('Change role'));
      await tester.pumpAndSettle();
      expect(repository.mutations.single['role'], 'field_crew');
      await tapVisible(tester, find.text('Delete account'));
      await tester.tap(find.text('Delete permanently'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('could not be loaded or saved'),
        findsOneWidget,
      );
      expect(find.text('Maria from the response team'), findsWidgets);
      expect(repository.mutations.length, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'creation follows loaded password policy and confirms account without showing password',
    (tester) async {
      final repository = SyntheticUsersRepository();
      await mountUsers(tester, repository);
      await tapVisible(tester, find.text('Create account'));
      await tester.enterText(
        find.byKey(const Key('admin-create-name')),
        'New crew member',
      );
      await tester.enterText(
        find.byKey(const Key('admin-create-email')),
        'new@example.invalid',
      );
      await tester.enterText(
        find.byKey(const Key('admin-account-password')),
        'short',
      );
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Review account'));
      expect(repository.mutations, isEmpty);
      expect(find.textContaining('at least 10'), findsWidgets);
      await tester.enterText(
        find.byKey(const Key('admin-account-password')),
        'SyntheticOnly!123',
      );
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Review account'));
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('SyntheticOnly!123'),
        ),
        findsNothing,
      );
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: find.byKey(const Key('admin-account-password')),
                matching: find.byType(EditableText),
              ),
            )
            .obscureText,
        isTrue,
      );
      await tester.tap(find.text('Create account').last);
      await tester.pumpAndSettle();
      expect(repository.mutations.single['action'], 'create');
      expect(repository.mutations.single['email'], 'new@example.invalid');
      expect(tester.takeException(), isNull);
    },
  );
}
