import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'package:ecopin_app/shared/widgets/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import '../widgets/auth_page_body.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  final Logger _log = Logger("Email Verification Screen");
  bool _isResending = false;
  String? _resendResult;
  String? _resendError;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle deep links when app is in foreground/background
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _log.info('Received deep link: $uri');
        if (uri.scheme == 'ecopin' &&
            uri.host == 'auth' &&
            uri.path == '/verified') {
          _handleVerified();
        }
      },
      onError: (err) {
        _log.severe('Deep link error', err);
        if (mounted) setState(() => _resendError = 'The verification link could not open. Request another email or return to sign in.');
      },
    );
  }

  void _handleVerified() {
    if (mounted) {
      SnackbarHelper.showMessage(
        'Verification link opened. Sign in to continue.',
      );
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _resendVerification() async {
    if (_isResending || _cooldownSeconds > 0) return;
    setState(() { _resendError = null; _resendResult = null; });
    if (widget.email.isEmpty) {
      SnackbarHelper.showError('No email provided to resend.');
      return;
    }

    setState(() => _isResending = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.resendVerification(widget.email);

      if (mounted) {
        setState(() => _resendResult = 'A new verification email was requested. Check your inbox and spam folder.');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to resend email';
      if (e.response?.data != null && e.response?.data['message'] != null) {
        errorMessage = e.response?.data['message'];
      }
      _log.severe(e);
      if (mounted) setState(() => _resendError = errorMessage);
      final retryAfter = int.tryParse(e.response?.headers.value('retry-after') ?? '');
      if (e.response?.statusCode == 429 && retryAfter != null && retryAfter > 0 && mounted) {
        _cooldownTimer?.cancel();
        setState(() => _cooldownSeconds = retryAfter);
        _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) { timer.cancel(); return; }
          setState(() => _cooldownSeconds--);
          if (_cooldownSeconds <= 0) timer.cancel();
        });
      }
    } catch (e, stackTrace) {
      _log.severe(e, stackTrace);
      if (mounted) setState(() => _resendError = 'The email could not be requested. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(leading: IconButton(tooltip: 'Back to sign in', icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/login'))),
    body: AuthPageBody(title: 'Check your inbox', description: 'Open the verification link in your email to activate your account.', children: [
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Verification email'), const SizedBox(height: 8),
          SelectableText(widget.email.isEmpty ? 'Email address not provided' : widget.email, style: Theme.of(context).textTheme.bodyLarge),
        ])),
      const SizedBox(height: 24),
      Text('If the link has expired, request another email. You can sign in after your address has been verified.', style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 24),
      if (_resendResult != null) ...[
        Semantics(liveRegion: true, child: Text(_resendResult!, style: Theme.of(context).textTheme.bodyMedium)),
        const SizedBox(height: 16),
      ],
      if (_resendError != null) ...[
        Semantics(liveRegion: true, child: Text(_resendError!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error))),
        const SizedBox(height: 16),
      ],
      AppButton(text: _cooldownSeconds > 0 ? 'Resend in ${_cooldownSeconds}s' : 'Resend verification email',
        isLoading: _isResending, onPressed: widget.email.isEmpty || _isResending || _cooldownSeconds > 0 ? null : _resendVerification),
      const SizedBox(height: 16),
      AppButton(text: 'Back to sign in', variant: ButtonVariant.secondary, onPressed: () => context.go('/login')),
    ]),
  );
}
