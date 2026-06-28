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

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final Logger _log = Logger("Profile Screen");
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
              padding: const EdgeInsets.all(24),
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
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundImage:
                                avatarUrl != null && avatarUrl.isNotEmpty
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl == null || avatarUrl.isEmpty
                                ? Text(
                                    _getInitials(fullName),
                                    style: const TextStyle(
                                      fontSize: 36,
                                      color: Colors.white,
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
                                color: Colors.grey.shade800,
                                shape: BoxShape.circle,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: _isUploading
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _pickImage,
                      child: _isUploading
                          ? const Text('Uploading...')
                          : const Text('Change Profile Picture'),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      enabled: false,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Member Since',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            createdAt != null
                                ? DateTime.parse(
                                    createdAt,
                                  ).toLocal().toString().split(' ')[0]
                                : 'N/A',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text('Save Changes'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _logout,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.red),
                        ),
                        child: const Text(
                          'Log Out',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
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
