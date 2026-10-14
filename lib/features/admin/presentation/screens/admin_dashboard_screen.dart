import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/core/constants/app_constants.dart';
import 'package:ecopin_app/features/admin/data/admin_repository.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:ecopin_app/shared/notifications/presentation/widgets/notification_badge_action.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'package:ecopin_app/shared/widgets/app_state_view.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  String _count(dynamic value) =>
      value is num && value >= 0 ? value.toInt().toString() : 'Unavailable';
  Map _group(Map<String, dynamic> stats, String key) =>
      stats[key] is Map ? stats[key] as Map : {};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminStatsProvider);
    final data = state.value;
    final recovery = adminRequiresAccountRecovery(state.error);
    void retry() => ref.invalidate(adminStatsProvider);
    void recover() => context.go(AdminAppRoutes.profile);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
        toolbarHeight:
            MediaQuery.textScalerOf(
                  context,
                ).clamp(maxScaleFactor: 1.3).scale(24) *
                2 +
            16,
        actions: const [NotificationBadgeAction(role: UserRole.admin)],
      ),
      body: data == null
          ? state.hasError
                ? AppStateView(
                    title: 'Summary unavailable',
                    message: adminErrorMessage(state.error!),
                    icon: Icons.info_outline,
                    actionLabel: recovery ? 'Open Account' : 'Try again',
                    onAction: recovery ? recover : retry,
                  )
                : const Center(
                    child: CircularProgressIndicator(
                      semanticsLabel: 'Loading administration summary',
                    ),
                  )
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(adminStatsProvider);
                try {
                  await ref.read(adminStatsProvider.future);
                } catch (_) {
                  /* The provider retains and presents this failure. */
                }
              },
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
                          Text(
                            'System overview',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          const Text('Manage account access and security.'),
                          const SizedBox(height: 24),
                          if (state.isLoading) ...[
                            const LinearProgressIndicator(
                              semanticsLabel:
                                  'Refreshing administration summary',
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (state.hasError) ...[
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                'The previous summary is still shown. ${adminErrorMessage(state.error!)}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                            AppButton(
                              text: recovery ? 'Open Account' : 'Retry summary',
                              variant: ButtonVariant.link,
                              onPressed: recovery ? recover : retry,
                            ),
                            const SizedBox(height: 16),
                          ],
                          _AdminSummaryCard(
                            title: 'Account summary',
                            count: _count(_group(data, 'users')['total']),
                            description:
                                'Manage roles and account access. This summary reflects the accounts returned by the server.',
                            action: 'Manage users',
                            icon: Icons.people_outline,
                            onOpen: () => context.go(AdminAppRoutes.users),
                          ),
                          const SizedBox(height: 16),
                          _AdminSummaryCard(
                            title: 'Reports',
                            count: _count(_group(data, 'reports')['total']),
                            description:
                                'Review report information in the existing officer workspace.',
                            action: 'Review reports',
                            icon: Icons.description_outlined,
                            onOpen: () =>
                                context.push(OfficerAppRoutes.reports),
                          ),
                          const SizedBox(height: 16),
                          _AdminSummaryCard(
                            title: 'Recorded audit actions',
                            count: _count(_group(data, 'auditLogs')['total']),
                            description:
                                'Inspect recorded account and system activity.',
                            action: 'Open audit logs',
                            icon: Icons.history,
                            onOpen: () => context.go(AdminAppRoutes.auditLogs),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Security settings',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Review password requirements and the configured session timeout.',
                          ),
                          const SizedBox(height: 16),
                          AppButton(
                            text: 'Open security settings',
                            variant: ButtonVariant.secondary,
                            icon: Icons.settings_outlined,
                            onPressed: () =>
                                context.go(AdminAppRoutes.settings),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Operational fleet and algorithm configuration remain in the web administration workspace.',
                          ),
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

class _AdminSummaryCard extends StatelessWidget {
  const _AdminSummaryCard({
    required this.title,
    required this.count,
    required this.description,
    required this.action,
    required this.icon,
    required this.onOpen,
  });
  final String title, count, description, action;
  final IconData icon;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border.all(color: Theme.of(context).dividerColor),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(count, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(description, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        AppButton(
          text: action,
          variant: ButtonVariant.secondary,
          onPressed: onOpen,
        ),
      ],
    ),
  );
}
