import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/features/admin/data/admin_repository.dart';
import 'package:ecopin_app/features/admin/presentation/widgets/admin_widgets.dart';
import 'package:ecopin_app/shared/profile/providers/profile_provider.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'package:ecopin_app/shared/widgets/app_state_view.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'admin_account_form.dart';

class AdminUserDetailScreen extends ConsumerStatefulWidget {
  const AdminUserDetailScreen({super.key, required this.userId});
  final String userId;
  @override
  ConsumerState<AdminUserDetailScreen> createState() =>
      _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends ConsumerState<AdminUserDetailScreen> {
  Map<String, dynamic>? _user;
  bool _loading = true, _busy = false, _changed = false, _confirming = false;
  String? _operation;
  final _feedback = GlobalKey();
  String _role = '';
  String? _error, _notice;
  bool _accountRecovery = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _accountRecovery = false;
    });
    try {
      final user = await ref
          .read(adminRepositoryProvider)
          .getUser(widget.userId);
      if (mounted) {
        setState(() {
          _user = user;
          _role = adminRoles.containsKey(user['role'])
              ? user['role'] as String
              : '';
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = adminErrorMessage(error);
          _accountRecovery = adminRequiresAccountRecovery(error);
          _revealFeedback();
        });
      }
    }
  }

  bool get _canManageOther {
    final currentId = ref.read(profileProvider).value?['id'];
    return currentId is String && currentId != widget.userId;
  }

  void _revealFeedback() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final feedbackContext = _feedback.currentContext;
      if (mounted && feedbackContext != null) {
        Scrollable.ensureVisible(
          feedbackContext,
          alignment: 1,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 200),
        );
      }
    });
  }

  String get _name => _user?['full_name']?.toString() ?? 'Account';
  Future<void> _changeRole() async {
    if (_busy ||
        _accountRecovery ||
        !_canManageOther ||
        !adminRoles.containsKey(_role)) {
      return;
    }
    setState(() {
      _busy = true;
      _confirming = true;
      _operation = 'role';
      _error = null;
      _notice = null;
    });
    final confirmed = await confirmAdminAction(
      context,
      title: 'Change account role?',
      message:
          'Change $_name to ${adminRoles[_role]}? This changes the account’s permitted tools.',
      action: 'Change role',
    );
    if (!mounted) return;
    if (!confirmed) {
      setState(() {
        _busy = false;
        _confirming = false;
      });
      return;
    }
    setState(() => _confirming = false);
    try {
      await ref.read(adminRepositoryProvider).changeRole(widget.userId, _role);
      if (mounted) {
        setState(() {
          _user = {..._user!, 'role': _role};
          _changed = true;
          _busy = false;
          _notice = 'Role updated';
          _revealFeedback();
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = adminErrorMessage(error);
          _accountRecovery = adminRequiresAccountRecovery(error);
          _revealFeedback();
        });
      }
    }
  }

  Future<void> _delete() async {
    if (_busy || _accountRecovery || !_canManageOther) return;
    setState(() {
      _busy = true;
      _confirming = true;
      _operation = 'delete';
      _error = null;
      _notice = null;
    });
    final confirmed = await confirmAdminAction(
      context,
      title: 'Delete this account?',
      message:
          'Permanently delete $_name (${widget.userId})? This removes the account and its profile. This action cannot be undone.',
      action: 'Delete permanently',
      destructive: true,
    );
    if (!mounted) return;
    if (!confirmed) {
      setState(() {
        _busy = false;
        _confirming = false;
      });
      return;
    }
    setState(() => _confirming = false);
    try {
      await ref.read(adminRepositoryProvider).deleteUser(widget.userId);
      if (mounted) {
        setState(() => _busy = false);
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = adminErrorMessage(error);
          _accountRecovery = adminRequiresAccountRecovery(error);
          _revealFeedback();
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_busy || _accountRecovery) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            AdminAccountForm(userId: widget.userId, accountName: _name),
      ),
    );
    if (changed == true && mounted) {
      _changed = true;
      await _load();
      if (mounted) setState(() => _notice = 'Password updated');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final currentId = profile.value?['id'];
    final own = currentId == widget.userId;
    final other = currentId is String && !own;
    final auth = _user?['auth'] is Map ? _user!['auth'] as Map : {};
    final email =
        auth['email']?.toString() ??
        _user?['email']?.toString() ??
        'Unavailable';
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Account details'),
          toolbarHeight:
              MediaQuery.textScalerOf(
                    context,
                  ).clamp(maxScaleFactor: 1.3).scale(24) *
                  2 +
              16,
          leading: BackButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(_changed),
          ),
        ),
        body: _user == null
            ? _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        semanticsLabel: 'Loading account details',
                      ),
                    )
                  : AppStateView(
                      title: 'Account unavailable',
                      message: _error ?? 'Account details could not be loaded.',
                      icon: Icons.person_outline,
                      actionLabel: _accountRecovery
                          ? 'Open Account'
                          : 'Try again',
                      onAction: _accountRecovery
                          ? () => context.go(AdminAppRoutes.profile)
                          : _load,
                    )
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 24),
                          if (_loading) ...[
                            const LinearProgressIndicator(
                              semanticsLabel: 'Refreshing account',
                            ),
                            const SizedBox(height: 16),
                          ],
                          AdminDetailField(label: 'Email', value: email),
                          AdminDetailField(
                            label: 'Account ID',
                            value: widget.userId,
                            technical: true,
                          ),
                          AdminDetailField(
                            label: 'Created',
                            value: adminDate(
                              _user!['created_at'] ?? auth['created_at'],
                            ),
                          ),
                          AdminDetailField(
                            label: 'Last sign-in',
                            value: adminDate(auth['last_sign_in_at']),
                          ),
                          AdminDetailField(
                            label: 'Password change request',
                            value: _user!['require_password_change'] is! bool
                                ? 'Unavailable'
                                : _user!['require_password_change'] == true
                                ? 'Requested'
                                : 'Not requested',
                          ),
                          if (own)
                            const Text(
                              'You cannot change your own role or delete your own account.',
                            )
                          else if (currentId is! String) ...[
                            const Text(
                              'Your current account identity is unavailable. Reload it before changing another account’s access.',
                            ),
                            AppButton(
                              text: 'Reload account identity',
                              variant: ButtonVariant.link,
                              onPressed: () => ref.invalidate(profileProvider),
                            ),
                          ],
                          const SizedBox(height: 20),
                          AdminSelect(
                            key: const Key('admin-user-role'),
                            label: 'Account role',
                            value: _role,
                            options: {'': 'Choose role', ...adminRoles},
                            onChanged:
                                other &&
                                    !_busy &&
                                    !_loading &&
                                    !_accountRecovery
                                ? (value) => setState(() {
                                    _role = value;
                                    _notice = null;
                                  })
                                : null,
                          ),
                          const SizedBox(height: 16),
                          AppButton(
                            text: 'Save role',
                            isLoading:
                                _busy && !_confirming && _operation == 'role',
                            onPressed:
                                other &&
                                    !_busy &&
                                    !_loading &&
                                    !_accountRecovery &&
                                    _role.isNotEmpty &&
                                    _role != _user!['role']
                                ? _changeRole
                                : null,
                          ),
                          const SizedBox(height: 24),
                          AppButton(
                            text: 'Reset password',
                            variant: ButtonVariant.secondary,
                            onPressed: _busy || _loading || _accountRecovery
                                ? null
                                : _resetPassword,
                          ),
                          const SizedBox(height: 16),
                          AppButton(
                            text: 'Delete account',
                            isLoading:
                                _busy && !_confirming && _operation == 'delete',
                            variant: ButtonVariant.danger,
                            onPressed:
                                other &&
                                    !_busy &&
                                    !_loading &&
                                    !_accountRecovery
                                ? _delete
                                : null,
                          ),
                          if (_error != null) ...[
                            const Text(
                              'Last loaded account details are shown.',
                            ),
                            const SizedBox(height: 20),
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                            if (_accountRecovery)
                              AppButton(
                                text: 'Open Account',
                                variant: ButtonVariant.link,
                                onPressed: () =>
                                    context.go(AdminAppRoutes.profile),
                              ),
                          ],
                          if (_error != null && !_accountRecovery)
                            AppButton(
                              text: 'Reload account details',
                              variant: ButtonVariant.link,
                              onPressed: _busy ? null : _load,
                            ),
                          if (_notice != null) ...[
                            const SizedBox(height: 20),
                            Semantics(liveRegion: true, child: Text(_notice!)),
                          ],
                          SizedBox(key: _feedback),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
