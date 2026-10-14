import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/core/constants/app_constants.dart';
import 'package:ecopin_app/features/admin/data/admin_repository.dart';
import 'package:ecopin_app/features/admin/data/admin_page.dart';
import 'package:ecopin_app/features/admin/presentation/widgets/admin_widgets.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:ecopin_app/shared/notifications/presentation/widgets/notification_badge_action.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'package:ecopin_app/shared/widgets/app_state_view.dart';
import 'admin_account_form.dart';
import 'admin_user_detail_screen.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _role = '', _loadedSearch = '', _loadedRole = '';
  AdminPage? _data;
  int _page = 1, _request = 0;
  bool _loading = true, _accountRecovery = false;
  String? _error, _notice;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({int? page}) async {
    _debounce?.cancel();
    final request = ++_request;
    final query = _search.text.trim(),
        role = _role,
        requestedPage = page ?? _page;
    setState(() {
      _page = requestedPage;
      _loading = true;
      _error = null;
      _accountRecovery = false;
    });
    try {
      final response = await ref
          .read(adminRepositoryProvider)
          .getUsers(page: requestedPage, search: query, role: role);
      final data = AdminPage.fromResponse(response, 'users', requestedPage);
      if (!mounted || request != _request) return;
      if (data.records.isEmpty &&
          data.totalPages != null &&
          data.totalPages! > 0 &&
          requestedPage > data.totalPages!) {
        await _load(page: data.totalPages);
        return;
      }
      setState(() {
        _data = data;
        _loadedSearch = query;
        _loadedRole = role;
        _page = data.page;
        _loading = false;
      });
    } catch (error) {
      if (mounted && request == _request) {
        setState(() {
          _loading = false;
          _error = adminErrorMessage(error);
          _accountRecovery = adminRequiresAccountRecovery(error);
        });
      }
    }
  }

  void _searchChanged(String value) {
    _debounce?.cancel();
    ++_request;
    setState(() {
      _loading = true;
      _notice = null;
    });
    _debounce = Timer(const Duration(milliseconds: 300), () => _load(page: 1));
  }

  Future<void> _create() async {
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const AdminAccountForm()));
    if (created == true && mounted) {
      setState(() => _notice = 'Account created');
      ref.invalidate(adminStatsProvider);
      await _load(page: 1);
    }
  }

  Future<void> _openUser(String id) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AdminUserDetailScreen(userId: id)),
    );
    if (mounted) {
      ref.invalidate(adminStatsProvider);
      await _load();
    }
  }

  void _clearFilters() {
    _search.clear();
    setState(() => _role = '');
    _load(page: 1);
  }

  @override
  Widget build(BuildContext context) {
    final previousFilters =
        _data != null &&
        (_loadedSearch != _search.text.trim() ||
            _loadedRole != _role ||
            _data!.page != _page);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage users'),
        toolbarHeight:
            MediaQuery.textScalerOf(
                  context,
                ).clamp(maxScaleFactor: 1.3).scale(24) *
                2 +
            16,
        actions: const [NotificationBadgeAction(role: UserRole.admin)],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppButton(
                      text: 'Create account',
                      icon: Icons.person_add_outlined,
                      onPressed: _create,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Search accounts',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'Search accounts',
                      child: TextField(
                        key: const Key('admin-user-search'),
                        controller: _search,
                        onChanged: _searchChanged,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Name/email',
                          suffixIcon: _search.text.isEmpty
                              ? const Icon(Icons.search)
                              : IconButton(
                                  tooltip: 'Clear account search',
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    _search.clear();
                                    _load(page: 1);
                                  },
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AdminSelect(
                      label: 'Role filter',
                      value: _role,
                      options: {'': 'All roles', ...adminRoles},
                      onChanged: (value) {
                        setState(() {
                          _role = value;
                          _notice = null;
                        });
                        _load(page: 1);
                      },
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      text: 'Reset filters',
                      variant: ButtonVariant.link,
                      onPressed: _search.text.isNotEmpty || _role.isNotEmpty
                          ? _clearFilters
                          : null,
                    ),
                    if (_notice != null)
                      Semantics(liveRegion: true, child: Text(_notice!)),
                    if (_loading) ...[
                      const LinearProgressIndicator(
                        semanticsLabel: 'Loading accounts',
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (previousFilters) ...[
                      const Text(
                        'Previous results are shown. Updated filters have not loaded.',
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_error != null) ...[
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                      AppButton(
                        text: _accountRecovery
                            ? 'Open Account'
                            : 'Retry accounts',
                        variant: ButtonVariant.secondary,
                        onPressed: _accountRecovery
                            ? () => context.go(AdminAppRoutes.profile)
                            : _load,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_data != null) ...[
                      if (_data!.records.isEmpty)
                        const AppStateView(
                          title: 'No accounts returned',
                          message: 'Try another name, email, role, or page.',
                          icon: Icons.people_outline,
                        ),
                      for (final user in _data!.records)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  user['full_name']?.toString() ??
                                      'Name unavailable',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  user['email']?.toString() ??
                                      'Email unavailable',
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Role: ${adminRoles[user['role']] ?? adminLabel(user['role'])}',
                                ),
                                if (user['require_password_change'] == true)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Text('Password change requested'),
                                  ),
                                const SizedBox(height: 16),
                                Semantics(
                                  label:
                                      'View ${user['full_name'] ?? 'account'}',
                                  child: AppButton(
                                    key: ValueKey('admin-view-${user['id']}'),
                                    text: 'View account',
                                    variant: ButtonVariant.secondary,
                                    onPressed:
                                        user['id'] is String &&
                                            (user['id'] as String).isNotEmpty
                                        ? () => _openUser(user['id'] as String)
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      AdminPageNavigation(
                        data: _data!,
                        busy: _loading,
                        onPage: (page) => _load(page: page),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
