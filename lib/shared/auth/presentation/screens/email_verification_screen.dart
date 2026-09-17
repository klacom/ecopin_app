import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'package:ecopin_app/shared/widgets/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String email;

  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  final Logger _log = Logger("Email Verification Screen");
  bool _isResending = false;
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
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _log.info('Received deep link: $uri');
      if (uri.scheme == 'ecopin' && uri.host == 'auth' && uri.path == '/verified') {
        _handleVerified();
      }
    }, onError: (err) {
      _log.severe('Deep link error', err);
    });
  }

  void _handleVerified() {
    if (mounted) {
      SnackbarHelper.showMessage('Email verified successfully! You can now log in.');
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _resendVerification() async {
    if (widget.email.isEmpty) {
      SnackbarHelper.showError('No email provided to resend.');
      return;
    }

    setState(() => _isResending = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.resendVerification(widget.email);
      
      if (mounted) {
        SnackbarHelper.showMessage('Verification email resent. Please check your inbox.');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to resend email';
      if (e.response?.data != null && e.response?.data['message'] != null) {
        errorMessage = e.response?.data['message'];
      }
      _log.severe(e);
      SnackbarHelper.showError(errorMessage);
    } catch (e, stackTrace) {
      _log.severe(e, stackTrace);
      SnackbarHelper.showError('An unexpected error occurred.');
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppColors.spaceXL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Envelope Icon
                const Icon(
                  Icons.mark_email_unread_rounded,
                  size: 80,
                  color: AppColors.primaryLight,
                ),
                const SizedBox(height: AppColors.spaceLG),
                
                Text(
                  'Check your inbox',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppColors.spaceMD),
                
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimaryDark.withOpacity(0.8),
                    ),
                    children: [
                      const TextSpan(text: 'We sent a verification link to\n'),
                      TextSpan(
                        text: widget.email,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppColors.spaceXXL),
                
                Text(
                  'Please click the link in the email to activate your account.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimaryDark.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: AppColors.spaceLG),
                
                AppButton(
                  text: 'Resend Email',
                  isLoading: _isResending,
                  variant: ButtonVariant.primary,
                  onPressed: _isResending ? null : _resendVerification,
                ),
                const SizedBox(height: AppColors.spaceMD),
                
                AppButton(
                  text: 'Back to Login',
                  variant: ButtonVariant.secondary,
                  onPressed: () => context.go('/login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
