import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/shared/auth/presentation/widgets/auth_page_body.dart';
import 'package:ecopin_app/shared/auth/presentation/screens/login_screen.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:async';
import 'package:dio/dio.dart' as dio;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/shared/auth/presentation/screens/register_screen.dart';
import 'package:ecopin_app/shared/auth/presentation/screens/landing_screen.dart';
import 'package:ecopin_app/shared/screens/no_internet_screen.dart';
import 'package:ecopin_app/shared/auth/presentation/screens/email_verification_screen.dart';
import 'package:flutter/services.dart';

class SyntheticAccountApi extends ApiClient {
  final loginResult = Completer<dio.Response>();
  final registrationResult = Completer<dio.Response>();
  final resendResult = Completer<dio.Response>();
  var loginRequests = 0;
  String? lastLoginPassword;
  String? lastRegistrationPassword, lastRegistrationConfirmation;
  var registrationRequests = 0;
  var resendRequests = 0;
  @override
  Future<dio.Response> getPasswordRequirements() async => dio.Response(requestOptions: dio.RequestOptions(path: '/synthetic-policy'), data: {
    'password_min_length': 10, 'password_require_uppercase': true,
    'password_require_lowercase': true, 'password_require_numbers': true,
    'password_require_special_chars': true,
  });
  @override
  Future<dio.Response> login(String email, String password) { loginRequests++; lastLoginPassword = password; return loginResult.future; }
  @override
  Future<dio.Response> register(String email, String password, String confirmPassword) { registrationRequests++; lastRegistrationPassword = password; lastRegistrationConfirmation = confirmPassword; return registrationResult.future; }
  @override
  Future<dio.Response> resendVerification(String email) { resendRequests++; return resendResult.future; }
}

dio.DioException rejection(String message) {
  final options = dio.RequestOptions(path: '/synthetic-rejection');
  return dio.DioException(requestOptions: options, type: dio.DioExceptionType.badResponse,
    response: dio.Response(requestOptions: options, statusCode: 400, data: {'message': message}));
}

void main() {
  setUp(() => dotenv.loadFromString(envString: 'SYNTHETIC_TEST=true'));
  testWidgets('resend respects server cooldown and never marks a timed wait verified', (tester) async {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(const MethodChannel('com.llfbandit.app_links/events'), (call) async => null);
    addTearDown(() => messenger.setMockMethodCallHandler(const MethodChannel('com.llfbandit.app_links/events'), null));
    final api = SyntheticAccountApi();
    await tester.pumpWidget(ProviderScope(overrides: [apiClientProvider.overrideWithValue(api)], child: MaterialApp(theme: AppTheme.dark, home: const EmailVerificationScreen(email: 'citizen@example.test'))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resend verification email'));
    await tester.pump();
    expect(api.resendRequests, 1);
    final options = dio.RequestOptions(path: '/synthetic-rate-limit');
    api.resendResult.completeError(dio.DioException(requestOptions: options, type: dio.DioExceptionType.badResponse,
      response: dio.Response(requestOptions: options, statusCode: 429, headers: dio.Headers.fromMap({'retry-after': ['2']}), data: {'message': 'Please wait before requesting another email.'})));
    await tester.pump();
    expect(find.text('Resend in 2s'), findsOneWidget);
    final resend = find.widgetWithText(TextButton, 'Resend in 2s');
    expect(tester.widget<TextButton>(resend).onPressed, isNull);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Resend verification email'), findsOneWidget);
    expect(find.textContaining('verified successfully'), findsNothing);
    expect(api.resendRequests, 1);
  });
  testWidgets('login keeps values after rejection and blocks repeat submit', (tester) async {
    final api = SyntheticAccountApi();
    await tester.pumpWidget(ProviderScope(overrides: [apiClientProvider.overrideWithValue(api)], child: MaterialApp(theme: AppTheme.light, home: const LoginScreen())));
    await tester.enterText(find.byType(TextField).at(0), 'citizen@example.test');
    await tester.enterText(find.byType(TextField).at(1), ' NewPassword123! ');
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(api.loginRequests, 1);
    expect(api.lastLoginPassword, ' NewPassword123! ');
    expect(tester.widget<TextField>(find.byType(TextField).first).enabled, isFalse);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(api.loginRequests, 1);
    api.loginResult.completeError(rejection('Your sign-in details could not be verified.'));
    await tester.pumpAndSettle();
    expect(find.text('Your sign-in details could not be verified.'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField).first).controller!.text, 'citizen@example.test');
    expect(tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text, ' NewPassword123! ');
  });
  testWidgets('registration preserves policy and displays rejection with values retained', (tester) async {
    final api = SyntheticAccountApi();
    await tester.pumpWidget(ProviderScope(overrides: [apiClientProvider.overrideWithValue(api)], child: MaterialApp(theme: AppTheme.dark, home: const RegisterScreen())));
    await tester.pumpAndSettle();
    expect(find.text('At least 10 characters long'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'citizen@example.test');
    await tester.enterText(find.byType(TextField).at(1), ' NewPassword123! ');
    await tester.enterText(find.byType(TextField).at(2), 'Different123!');
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pump();
    expect(api.registrationRequests, 0);
    expect(find.text('Passwords do not match'), findsWidgets);
    await tester.enterText(find.byType(TextField).at(2), ' NewPassword123! ');
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pump();
    expect(api.registrationRequests, 1);
    expect(api.lastRegistrationPassword, ' NewPassword123! ');
    expect(api.lastRegistrationConfirmation, ' NewPassword123! ');
    api.registrationResult.completeError(rejection('This email already has an account.'));
    await tester.pumpAndSettle();
    expect(find.text('This email already has an account.'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text, 'citizen@example.test');
  });
  testWidgets('intro and error recovery fit large text with a real retry callback', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: MediaQuery(data: const MediaQueryData(textScaler: TextScaler.linear(2)), child: const LandingScreen())));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    var retries = 0;
    await tester.pumpWidget(MaterialApp(theme: AppTheme.dark, home: Scaffold(body: NoInternetScreen(onRetry: () => retries++))));
    await tester.tap(find.text('Try again'));
    expect(retries, 1);
    expect(find.textContaining('will be synced'), findsNothing);
  });
  testWidgets('account forms remain scrollable above keyboard at large text', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.dark, home: MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(2), viewInsets: EdgeInsets.only(bottom: 300)),
      child: Scaffold(body: AuthPageBody(title: 'Welcome back', description: 'Sign in to follow your reports or continue your work.', children: [
        const TextField(decoration: InputDecoration(labelText: 'Email')),
        const SizedBox(height: 24),
        AppButton(text: 'Sign in to your account', onPressed: () {}),
      ])),
    )));
    await tester.ensureVisible(find.byType(AppButton));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('login required fields are displayed inline without a request', (tester) async {
    await tester.pumpWidget(ProviderScope(child: MaterialApp(theme: AppTheme.light, home: const LoginScreen())));
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(find.text('Enter your email.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    expect(find.text('Please enter email and password'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
