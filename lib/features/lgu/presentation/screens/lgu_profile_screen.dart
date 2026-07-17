import 'package:dio/dio.dart' as dio;
import 'package:ecopin_app/shared/widgets/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/features/auth/providers/auth_notifier.dart';
import 'package:ecopin_app/features/profile/providers/profile_provider.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecopin_app/core/providers/theme_mode_provider.dart';
import 'package:ecopin_app/core/theme/colors.dart';

class LguProfileScreen extends ConsumerStatefulWidget {
  const LguProfileScreen({super.key});

  @override
  ConsumerState<LguProfileScreen> createState() => _LguProfileScreenState();
}

class _LguProfileScreenState extends ConsumerState<LguProfileScreen> {
  final Logger _log = Logger("LGU Profile Screen");
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  bool _isSaving = false;
  bool _isUploading = false;

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

        if (e.response?.data != null && e.response?.data['message'] != null) {
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

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate() && !_isSaving) {
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (mounted) {
        context.go(PublicAppRoutes.login);
      }
    }
  }

  Future<void> _changePassword() async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isObscureOld = true;
    bool isObscureNew = true;
    bool isObscureConfirm = true;
    bool isLoading = false;

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordController,
                obscureText: isObscureOld,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isObscureOld ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setStateDialog(() => isObscureOld = !isObscureOld),
                  ),
                ),
              ),
              const SizedBox(height: AppColors.spaceMD),
              TextField(
                controller: newPasswordController,
                obscureText: isObscureNew,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isObscureNew ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setStateDialog(() => isObscureNew = !isObscureNew),
                  ),
                ),
              ),
              const SizedBox(height: AppColors.spaceMD),
              TextField(
                controller: confirmPasswordController,
                obscureText: isObscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isObscureConfirm
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () => setStateDialog(
                      () => isObscureConfirm = !isObscureConfirm,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () async {
                      if (newPasswordController.text !=
                          confirmPasswordController.text) {
                        SnackbarHelper.showError('Passwords do not match!');
                        return;
                      }
                      if (newPasswordController.text.length < 6) {
                        SnackbarHelper.showError(
                          'Password must be at least 6 characters!',
                        );
                        return;
                      }

                      setStateDialog(() => isLoading = true);
                      try {
                        final apiClient = ref.read(apiClientProvider);
                        await apiClient.changePassword(
                          oldPassword: oldPasswordController.text,
                          newPassword: newPasswordController.text,
                        );
                        if (context.mounted) {
                          SnackbarHelper.showValidMessage(
                            'Password changed successfully!',
                          );
                          Navigator.pop(context);
                        }
                      } on dio.DioException catch (e, stackTrace) {
                        _log.severe(e, stackTrace);
                        if (context.mounted) {
                          SnackbarHelper.showError(
                            e.response?.data['message'] ??
                                'Failed to change password!',
                          );
                        }
                      } catch (e, stackTrace) {
                        _log.severe(e, stackTrace);
                        if (context.mounted) {
                          SnackbarHelper.showError(
                            'Failed to change password!',
                          );
                        }
                      } finally {
                        if (context.mounted) {
                          setStateDialog(() => isLoading = false);
                        }
                      }
                    },
                    child: const Text('Save'),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(profileProvider);
          await ref.read(profileProvider.future);
        },
        child: profileAsync.when(
          data: (profile) {
            final fullName = profile?['full_name'] as String?;
            final avatarUrl = profile?['avatar_url'] as String?;
            final createdAt = profile?['created_at'] as String?;
            final userEmail = Supabase.instance.client.auth.currentUser?.email;

            if (_fullNameController.text.isEmpty) {
              _fullNameController.text = fullName ?? '';
            }
            if (_emailController.text.isEmpty) {
              _emailController.text = userEmail ?? '';
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppColors.spaceXL),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            key: ValueKey(avatarUrl),
                            radius: 50,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundImage:
                                avatarUrl != null && avatarUrl.isNotEmpty
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl == null || avatarUrl.isEmpty
                                ? Text(
                                    _getInitials(fullName),
                                    style: TextStyle(
                                      fontSize: 36,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary,
                                shape: BoxShape.circle,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(
                                  AppColors.spaceXS,
                                ),
                                child: _isUploading
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSecondary,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(
                                        Icons.camera_alt,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSecondary,
                                        size: 16,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppColors.spaceXXL),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppColors.spaceMD),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.email),
                      ),
                      enabled: false,
                    ),
                    const SizedBox(height: AppColors.spaceMD),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppColors.spaceMD),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(
                          AppColors.radiusCard,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Member Since',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                          ),
                          const SizedBox(height: AppColors.spaceXS),
                          Text(
                            createdAt != null
                                ? DateTime.parse(
                                    createdAt,
                                  ).toLocal().toString().split(' ')[0]
                                : 'N/A',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppColors.spaceMD),

                    // Dark Mode Switch
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(
                          AppColors.radiusCard,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(
                          AppColors.radiusCard,
                        ),
                        child: Consumer(
                          builder: (context, ref, child) {
                            final themeMode = ref.watch(themeModeProvider);
                            final isDarkMode =
                                themeMode == ThemeMode.dark ||
                                (themeMode == ThemeMode.system &&
                                    MediaQuery.platformBrightnessOf(context) ==
                                        Brightness.dark);

                            return SwitchListTile(
                              secondary: const Icon(Icons.dark_mode_outlined),
                              title: const Text(
                                "Dark Mode",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                isDarkMode
                                    ? "Using dark theme."
                                    : "Using light theme.",
                              ),
                              value: isDarkMode,
                              onChanged: (value) {
                                ref
                                    .read(themeModeProvider.notifier)
                                    .setThemeMode(
                                      value ? ThemeMode.dark : ThemeMode.light,
                                    );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: AppColors.spaceMD),

                    // Change Password Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _changePassword,
                        icon: const Icon(Icons.lock_reset),
                        label: const Text('Change Password'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppColors.spaceMD,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppColors.spaceMD),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppColors.spaceMD,
                          ),
                        ),
                        child: _isSaving
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                              )
                            : const Text('Save Changes'),
                      ),
                    ),
                    const SizedBox(height: AppColors.spaceMD),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _logout,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppColors.spaceMD,
                          ),
                          side: const BorderSide(color: AppColors.error),
                          foregroundColor: AppColors.error,
                        ),
                        child: const Text(
                          'Log Out',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ),
                    const SizedBox(height: 128),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) =>
              Center(child: Text('Error loading profile: $err')),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
