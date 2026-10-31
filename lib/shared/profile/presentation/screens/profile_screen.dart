import '../widgets/change_password_dialog.dart';
import '../widgets/delete_account_dialog.dart';
import '../widgets/logout_dialog.dart';
import '../widgets/profile_widgets.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart' as dio;
import 'package:ecopin_app/shared/widgets/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'package:ecopin_app/shared/widgets/app_text_field.dart';
import 'package:ecopin_app/shared/support/official_contacts_screen.dart';
import 'package:ecopin_app/shared/support/help_support_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/shared/auth/providers/auth_notifier.dart';
import 'package:ecopin_app/shared/profile/providers/profile_provider.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:ecopin_app/shared/screens/no_internet_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecopin_app/core/providers/theme_mode_provider.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/citizen_trust_status.dart';
import 'package:ecopin_app/shared/reports/providers/citizen_trust_provider.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/blocked_urgent_reports.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final Logger _log = Logger("Profile Screen");
  String? _nameError;
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  bool _isSaving = false;
  bool _isUploading = false;
  bool _isUpdatingConsent = false;
  bool _nameInitialised = false;
  String _savedName = '';

  String _getInitials(String? fullName) {
    if (fullName == null || fullName.isEmpty) return '?';
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    } else {
      return parts[0][0].toUpperCase();
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _isUploading = true;
      });

      try {
        final apiClient = ref.read(apiClientProvider);
        await apiClient.uploadAvatar(filePath: image.path);

        // Invalidate provider to refresh data
        ref.invalidate(profileProvider);
        await ref.read(profileProvider.future);

        if (mounted) {
          SnackbarHelper.showMessage('Avatar uploaded successfully');
        }
      } on dio.DioException catch (e, stackTrace) {
        _log.severe('DioException during avatar upload: $e', stackTrace);
        String errorMsg = 'Failed to upload avatar';

        if (e.response?.data is Map && e.response?.data['message'] is String) {
          errorMsg = e.response?.data['message'];
        } else if (e.message != null) {
          errorMsg = e.message!;
        }

        if (mounted) {
          SnackbarHelper.showError(errorMsg);
        }
      } catch (e, stackTrace) {
        _log.severe('Error uploading avatar: $e', stackTrace);
        if (mounted) {
          SnackbarHelper.showError('Error uploading avatar');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
        }
      }
    }
  }

  Future<void> _removeAvatar() async {
    if (_isUploading) return;
    setState(() => _isUploading = true);
    try {
      await ref.read(apiClientProvider).removeAvatar();
      ref.invalidate(profileProvider);
      await ref.read(profileProvider.future);
      if (mounted) {
        SnackbarHelper.showMessage('Avatar photo removed successfully');
      }
    } catch (e, stackTrace) {
      _log.severe('Failed to remove avatar', e, stackTrace);
      if (mounted) {
        SnackbarHelper.showError('Failed to remove avatar. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _saveProfile() async {
    final nameMissing = _fullNameController.text.trim().isEmpty;
    setState(
      () => _nameError = nameMissing ? 'Please enter your full name' : null,
    );
    if (!nameMissing && !_isSaving) {
      setState(() {
        _isSaving = true;
      });

      try {
        final apiClient = ref.read(apiClientProvider);
        await apiClient.updateProfile(fullName: _fullNameController.text);

        // Invalidate provider to refresh data
        ref.invalidate(profileProvider);
        await ref.read(profileProvider.future);

        if (mounted) {
          SnackbarHelper.showMessage('Profile updated successfully!');
        }
      } catch (e, stackTrace) {
        if (mounted) {
          _log.severe(e, stackTrace);
          SnackbarHelper.showError('Error updating profile');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  Future<void> _logout() async {
    if (!await confirmLogout(context) || !mounted) return;
    await ref.read(authNotifierProvider.notifier).signOut();
    if (mounted) context.go(PublicAppRoutes.login);
  }

  Future<void> _deleteAccount() async {
    if (_isSaving || ref.read(profileProvider).value?['role'] != 'citizen')
      return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const DeleteAccountDialog(),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _isSaving = true;
      });

      final auth = ref.read(authNotifierProvider.notifier);
      try {
        final apiClient = ref.read(apiClientProvider);
        await apiClient.deleteAccount(confirmation: 'I confirm');
        await auth.signOut();
        SnackbarHelper.showMessage(
          'Account deleted. Personal data removed and waste reports anonymized.',
        );
      } on dio.DioException catch (e, stackTrace) {
        _log.severe('DioException deleting account: $e', stackTrace);
        String errorMsg = 'Failed to delete account. Please try again.';
        if (e.response?.data is Map && e.response?.data['message'] is String) {
          errorMsg = e.response?.data['message'];
        }
        if (e.response?.data is Map && e.response?.data['signed_out'] == true) {
          await auth.signOut();
        }
        SnackbarHelper.showError(errorMsg);
      } catch (e, stackTrace) {
        _log.severe('Error deleting account: $e', stackTrace);
        SnackbarHelper.showError(
          'Account deletion could not be completed. Sign in again to retry.',
        );
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  Future<void> _changePassword() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => const ChangePasswordDialog(),
    );
  }

  Future<void> _updateDataConsent(bool value) async {
    if (_isUpdatingConsent ||
        ref.read(profileProvider).value?['role'] != 'citizen')
      return;

    setState(() {
      _isUpdatingConsent = true;
    });

    try {
      final apiClient = ref.read(apiClientProvider);

      await apiClient.updateDataConsent(value);

      // Refresh profile
      ref.invalidate(profileProvider);
      await ref.read(profileProvider.future);

      if (mounted) {
        SnackbarHelper.showMessage(
          value ? 'Data sharing enabled.' : 'Data sharing disabled.',
        );
      }
    } on dio.DioException catch (e, stackTrace) {
      _log.severe('Failed updating consent: $e', stackTrace);

      if (mounted) {
        SnackbarHelper.showError(
          e.response?.data?['message'] ?? 'Failed to update data consent.',
        );
      }
    } catch (e, stackTrace) {
      _log.severe(e, stackTrace);

      if (mounted) {
        SnackbarHelper.showError('Failed to update data consent.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingConsent = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: const [OfficialContactsButton()],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(profileProvider);
          ref.invalidate(citizenTrustProvider);
          ref.invalidate(blockedUrgentReportsProvider);
          await ref.read(profileProvider.future);
        },
        child: profileAsync.when(
          data: (profile) => _buildBody(context, profile),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) =>
              NoInternetScreen(onRetry: () => ref.invalidate(profileProvider)),
        ),
      ),
    );
  }

  /// Fills the fields once, then only follows the saved profile while the
  /// person has not typed over it, so clearing the name to retype it sticks.
  void _syncControllers(String? fullName, String? email) {
    if (!_nameInitialised) {
      _nameInitialised = true;
      _setName(fullName ?? '');
      _savedName = fullName ?? '';
    } else if ((fullName ?? '') != _savedName) {
      if (_fullNameController.text == _savedName) _setName(fullName ?? '');
      _savedName = fullName ?? '';
    }
    if (_emailController.text.isEmpty) _emailController.text = email ?? '';
  }

  void _setName(String value) {
    _fullNameController.removeListener(_onNameChanged);
    _fullNameController.text = value;
    _fullNameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    if (mounted) setState(() => _nameError = null);
  }

  Widget _buildBody(BuildContext context, Map<String, dynamic>? profile) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final role = profile?['role'];
    final isCitizen = role == 'citizen';
    final fullName = profile?['full_name'] as String?;
    final avatarUrl = profile?['avatar_url'] as String?;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final createdAt = DateTime.tryParse(
      profile?['created_at'] as String? ?? '',
    )?.toLocal();
    final dataConsent = profile?['data_consent'] == true;
    _syncControllers(
      fullName,
      Supabase.instance.client.auth.currentUser?.email,
    );
    final dirty = _fullNameController.text.trim() != (fullName ?? '').trim();
    final shownName = (fullName ?? '').trim();

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Semantics(
              button: true,
              label: 'Change profile photo',
              excludeSemantics: true,
              onTap: _isUploading ? null : _pickImage,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _isUploading ? null : _pickImage,
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: CircleAvatar(
                          key: ValueKey(avatarUrl),
                          backgroundColor: theme.primaryColor,
                          foregroundImage: hasAvatar
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: hasAvatar
                              ? null
                              : Text(
                                  _getInitials(fullName),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: scheme.outlineVariant),
                          ),
                          child: _isUploading
                              ? const Padding(
                                  padding: EdgeInsets.all(9),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  Icons.camera_alt_outlined,
                                  size: 18,
                                  color: scheme.onSurface,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (shownName.isNotEmpty)
            Text(
              shownName,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          if (_emailController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                _emailController.text,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          if (createdAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Member since ${DateFormat.yMMMd().format(createdAt)}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ),
          if (hasAvatar)
            Align(
              child: AppButton(
                text: 'Remove photo',
                icon: Icons.delete_outline,
                variant: ButtonVariant.link,
                width: 200,
                isLoading: _isUploading,
                onPressed: _removeAvatar,
              ),
            ),
          ProfileSection(
            label: 'Your details',
            trailing: dirty
                ? TextButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              semanticsLabel: 'Saving your details',
                            ),
                          )
                        : const Text('Save changes'),
                  )
                : null,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    AppTextField(
                      controller: _fullNameController,
                      labelText: 'Full name',
                      errorText: _nameError,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => dirty ? _saveProfile() : null,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _emailController,
                      labelText: 'Email, cannot be changed here',
                      inputType: 'email',
                      isLoading: true, // read-only: the sign-in email
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isCitizen) ...[
            const SizedBox(height: 16),
            const CitizenTrustStatus(),
            const BlockedUrgentReports(),
          ],
          ProfileSection(
            label: 'Preferences',
            children: [
              Consumer(
                builder: (context, ref, child) {
                  final themeMode = ref.watch(themeModeProvider);
                  final isDarkMode =
                      themeMode == ThemeMode.dark ||
                      (themeMode == ThemeMode.system &&
                          MediaQuery.platformBrightnessOf(context) ==
                              Brightness.dark);
                  return ProfileSwitchRow(
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark mode',
                    subtitle: isDarkMode
                        ? 'Using dark theme.'
                        : 'Using light theme.',
                    value: isDarkMode,
                    onChanged: (value) => ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(value ? ThemeMode.dark : ThemeMode.light),
                  );
                },
              ),
              if (isCitizen)
                ProfileSwitchRow(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Share personal information',
                  subtitle: dataConsent
                      ? 'Officers may access your profile information when handling your reports.'
                      : 'Your identity will remain hidden when possible.',
                  value: dataConsent,
                  onChanged: _isUpdatingConsent ? null : _updateDataConsent,
                ),
            ],
          ),
          if (_isUpdatingConsent)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(
                semanticsLabel: 'Saving your sharing preference',
              ),
            ),
          ProfileSection(
            label: 'Account',
            children: [
              if (role == 'field_crew')
                ProfileRow(
                  icon: Icons.insights_outlined,
                  title: 'My performance and CSAT',
                  onTap: () => context.push(FieldCrewAppRoutes.performance),
                ),
              ProfileRow(
                icon: Icons.lock_reset,
                title: 'Change password',
                onTap: _changePassword,
              ),
              if (isCitizen)
                ProfileRow(
                  icon: Icons.support_agent_outlined,
                  title: 'Help and support',
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => const HelpSupportScreen(),
                    ),
                  ),
                ),
              ProfileRow(
                icon: Icons.logout,
                title: 'Log out',
                chevron: false,
                onTap: _logout,
              ),
            ],
          ),
          if (isCitizen) ...[
            const SizedBox(height: 24),
            ProfileSection(
              children: [
                ProfileRow(
                  icon: Icons.delete_forever_outlined,
                  title: 'Delete account',
                  subtitle:
                      'Removes your personal data. Reports stay anonymized.',
                  destructive: true,
                  chevron: false,
                  onTap: _isSaving ? null : _deleteAccount,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _fullNameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
