import 'dart:async';
import 'package:dio/dio.dart' as dio;
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/shared/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class RequiredChangeApi extends ApiClient {
  int updates = 0, policyLoads = 0;
  bool policyFails = false;
  String? submittedToken, submittedPassword;
  Completer<dio.Response> result = Completer<dio.Response>();
  @override
  Future<dio.Response> login(String email, String password) async =>
      dio.Response(
        requestOptions: dio.RequestOptions(path: '/synthetic-login'),
        data: {
          'requirePasswordChange': true,
          'session': {
            'access_token': 'synthetic-pending-token',
            'refresh_token': 'must-not-promote',
          },
          'user': {'role': 'admin'},
        },
      );
  @override
  Future<dio.Response> getPasswordRequirements() async {
    policyLoads++;
    if (policyFails) throw StateError('Synthetic unavailable policy');
    return dio.Response(
      requestOptions: dio.RequestOptions(path: '/synthetic-policy'),
      data: {
        'password_min_length': 10,
        'password_require_uppercase': true,
        'password_require_lowercase': true,
        'password_require_numbers': true,
        'password_require_special_chars': true,
      },
    );
  }

  @override
  Future<dio.Response> forceChangePassword({
    required String newPassword,
    required String accessToken,
  }) {
    updates++;
    submittedPassword = newPassword;
    submittedToken = accessToken;
    return result.future;
  }
}

Future<void> openRequiredChange(
  WidgetTester tester,
  RequiredChangeApi api, {
  bool dark = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(api)],
      child: MaterialApp(
        theme: dark ? AppTheme.dark : AppTheme.light,
        home: const LoginScreen(),
      ),
    ),
  );
  await tester.enterText(find.byType(TextField).at(0), 'admin@example.test');
  await tester.enterText(find.byType(TextField).at(1), 'Temporary123!');
  await tester.tap(find.text('Sign in'));
  await tester.pumpAndSettle();
  expect(find.text('Set a new password'), findsOneWidget);
}

void main() {
  setUp(() => dotenv.loadFromString(envString: 'SYNTHETIC_TEST=true'));
  testWidgets(
    'required change stays outside SDK session, validates policy and locks submission',
    (tester) async {
      final api = RequiredChangeApi();
      // Supabase is deliberately not initialized: pending credentials must not be promoted.
      await openRequiredChange(tester, api);
      expect(find.text('At least 10 characters long'), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(0), 'NewPassword123!');
      await tester.enterText(find.byType(TextField).at(1), 'Different123!');
      await tester.ensureVisible(find.text('Update password'));
      await tester.tap(find.text('Update password'));
      await tester.pump();
      expect(find.text('Passwords do not match.'), findsOneWidget);
      expect(api.updates, 0);
      await tester.enterText(find.byType(TextField).at(1), 'NewPassword123!');
      await tester.tap(find.text('Update password'));
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(api.updates, 1);
      expect(api.submittedToken, 'synthetic-pending-token');
      expect(api.submittedPassword, 'NewPassword123!');
      final options = dio.RequestOptions(path: '/synthetic-update');
      api.result.completeError(
        dio.DioException(
          requestOptions: options,
          response: dio.Response(requestOptions: options, statusCode: 500),
          type: dio.DioExceptionType.badResponse,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('We could not update your password. Please try again.'),
        findsOneWidget,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'NewPassword123!',
      );
      api.result = Completer<dio.Response>();
      await tester.tap(find.text('Update password'));
      api.result.complete(
        dio.Response(
          requestOptions: options,
          statusCode: 200,
          data: {'message': 'Password changed successfully'},
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Password updated. Sign in with your new password.'),
        findsOneWidget,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text,
        'admin@example.test',
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text,
        isEmpty,
      );
    },
  );
  testWidgets(
    'unavailable policy can retry and cancellation leaves login unauthenticated',
    (tester) async {
      final api = RequiredChangeApi()..policyFails = true;
      await openRequiredChange(tester, api, dark: true);
      expect(
        find.text(
          'Password rules are unavailable. Reload them before continuing.',
        ),
        findsOneWidget,
      );
      api.policyFails = false;
      await tester.tap(find.text('Reload password rules'));
      await tester.pumpAndSettle();
      expect(api.policyLoads, 2);
      await tester.tap(find.byTooltip('Back to sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome back'), findsOneWidget);
      expect(api.updates, 0);
    },
  );
  testWidgets(
    'expired pending token offers sign-in recovery and does not retry update',
    (tester) async {
      final api = RequiredChangeApi();
      await openRequiredChange(tester, api);
      await tester.enterText(find.byType(TextField).at(0), 'NewPassword123!');
      await tester.enterText(find.byType(TextField).at(1), 'NewPassword123!');
      await tester.ensureVisible(find.text('Update password'));
      await tester.tap(find.text('Update password'));
      final options = dio.RequestOptions(path: '/synthetic-expired');
      api.result.completeError(
        dio.DioException(
          requestOptions: options,
          response: dio.Response(requestOptions: options, statusCode: 401),
          type: dio.DioExceptionType.badResponse,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Your sign-in has expired. Return to sign in and try again.'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Back to sign in'));
      await tester.tap(find.text('Back to sign in'));
      await tester.pumpAndSettle();
      expect(api.updates, 1);
      expect(find.text('Welcome back'), findsOneWidget);
    },
  );
}
