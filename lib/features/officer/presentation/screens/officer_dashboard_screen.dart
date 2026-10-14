import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/shared/notifications/presentation/widgets/notification_badge_action.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:ecopin_app/features/officer/providers/officer_dashboard_provider.dart';
import 'package:ecopin_app/features/officer/providers/officer_clusters_provider.dart';
import 'package:ecopin_app/shared/profile/providers/profile_provider.dart';
import 'package:ecopin_app/features/officer/presentation/screens/officer_response_logs_screen.dart';

class OfficerDashboardScreen extends ConsumerStatefulWidget {
  const OfficerDashboardScreen({super.key});

  @override
  ConsumerState<OfficerDashboardScreen> createState() => _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends ConsumerState<OfficerDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(officerDashboardProvider).stats;
    final logsAsync = ref.watch(officerResponseLogsProvider).logs;
    final profileAsync = ref.watch(profileProvider);
    final fullName = profileAsync.value?['full_name'] as String? ?? 'Officer';
    final avatarUrl = profileAsync.value?['avatar_url'] as String?;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(officerDashboardProvider).loadStats();
          ref.read(officerResponseLogsProvider).loadLogs();
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverAppBar(
              pinned: true,
              toolbarHeight: 88,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              titleSpacing: 16.0,
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null || avatarUrl.isEmpty
                        ? Icon(Icons.person, color: isDark ? Colors.white70 : Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'COMMAND CENTER',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                                color: isDark ? Colors.white60 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: const [
                NotificationBadgeAction(),
              ],
            ),
            SliverToBoxAdapter(
              child: statsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => Padding(
                  padding: const EdgeInsets.only(top: 80, left: 24, right: 24),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 40),
                        const SizedBox(height: 12),
                        Text('Error: $error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => ref.read(officerDashboardProvider).loadStats(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (stats) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subtitle / Status bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF333333) : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.shield_outlined, size: 18, color: Color(0xFF10B981)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'System status is operational. Live field sync active.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 4 Hero KPI Cards aligned with Web (Active Field Units, Unresolved, SLA Risk, Manual Review)
                      _buildHeroKpiGrid(stats, isDark),
                      const SizedBox(height: 28),

                      // Active Targets Section (In-Progress Cleanup Tasks)
                      _buildActiveTargetsSection(stats, isDark),
                      const SizedBox(height: 28),

                      // Critical Hotzones Section
                      _buildCriticalHotzonesSection(stats, isDark),
                      const SizedBox(height: 28),

                      // AI Command Unit Intel
                      _buildAiCommandUnitCard(isDark),
                      const SizedBox(height: 28),

                      // Recent Activity Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Activity',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              context.push(OfficerAppRoutes.responseLogs);
                            },
                            child: const Text('View all'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Dynamic recent activity logs
                      logsAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (error, stack) => const Text('Failed to load system logs'),
                        data: (logs) {
                          if (logs.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade200,
                                ),
                              ),
                              child: const Center(
                                child: Text('No recent activity', style: TextStyle(color: Colors.grey)),
                              ),
                            );
                          }

                          final recentLogs = logs.take(3).toList();
                          return Column(
                            children: recentLogs.map((log) {
                              IconData icon = Icons.info_outline;
                              Color iconColor = Colors.grey;

                              switch (log.actionType) {
                                case 'status_update':
                                  icon = Icons.update;
                                  iconColor = Colors.blue;
                                  break;
                                case 'lifecycle_stage_update':
                                  icon = Icons.account_tree;
                                  iconColor = Colors.purple;
                                  break;
                                case 'acknowledge_complaint':
                                  icon = Icons.check_circle_outline;
                                  iconColor = Colors.green;
                                  break;
                                case 'manual_note':
                                  icon = Icons.note_alt_outlined;
                                  iconColor = Colors.orange;
                                  break;
                              }

                              String timeStr = '';
                              if (log.createdAt != null) {
                                final diff = DateTime.now().difference(log.createdAt!);
                                if (diff.inDays > 0) {
                                  timeStr = '${diff.inDays}d ago';
                                } else if (diff.inHours > 0) {
                                  timeStr = '${diff.inHours}h ago';
                                } else if (diff.inMinutes > 0) {
                                  timeStr = '${diff.inMinutes}m ago';
                                } else {
                                  timeStr = 'Just now';
                                }
                              }

                              String titleStr = (log.actionType ?? 'System Log')
                                  .split('_')
                                  .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
                                  .join(' ');

                              String truncatedSubtitle = log.actionDetails ?? 'System log';
                              if (truncatedSubtitle.length > 45) {
                                truncatedSubtitle = '${truncatedSubtitle.substring(0, 45)}...';
                              }

                              return _buildRecentActivityItem(
                                icon: icon,
                                iconColor: iconColor,
                                title: titleStr,
                                subtitle: truncatedSubtitle,
                                time: timeStr,
                                isDark: isDark,
                              );
                            }).toList()
                              ..add(
                                Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: () {
                                        context.push(OfficerAppRoutes.responseLogs);
                                      },
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text('View All Activity'),
                                    ),
                                  ),
                                ),
                              ),
                          );
                        },
                      ),
                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4 Hero KPI Cards aligned with Web Command Center
  Widget _buildHeroKpiGrid(DashboardStats stats, bool isDark) {
    final hasSlaRisk = stats.slaRiskCount > 0;
    final hasManualReview = stats.manualReviewCount > 0;

    return Column(
      children: [
        Row(
          children: [
            // Card 1: Active Field Units
            Expanded(
              child: _buildAlignedHeroCard(
                title: 'ACTIVE FIELD UNITS',
                value: stats.activeFieldUnits.toString(),
                subtitle: stats.activeFieldUnits > 0
                    ? '${stats.activeFieldUnits} cleanup task${stats.activeFieldUnits == 1 ? '' : 's'} in progress.'
                    : 'No tasks currently in progress.',
                actionLabel: 'VIEW OPERATIONS',
                icon: Icons.engineering_rounded,
                accentColor: const Color(0xFF10B981),
                isDark: isDark,
                onTap: () {
                  context.push('${OfficerAppRoutes.cleanupTasks}?status=in_progress');
                },
              ),
            ),
            const SizedBox(width: 14),
            // Card 2: Unresolved Reports
            Expanded(
              child: _buildAlignedHeroCard(
                title: 'UNRESOLVED REPORTS',
                value: stats.unresolved.toString(),
                subtitle: stats.unresolved > 0
                    ? '${stats.unresolved} active reports needing attention.'
                    : 'All reports resolved.',
                actionLabel: 'VIEW REPORTS',
                icon: Icons.search_rounded,
                accentColor: const Color(0xFFF59E0B),
                isDark: isDark,
                onTap: () {
                  context.push('${OfficerAppRoutes.reports}?status=unresolved');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            // Card 3: SLA Risk (CRITICAL - Error glow when > 0)
            Expanded(
              child: _buildAlignedHeroCard(
                title: 'SLA RISK',
                value: stats.slaRiskCount.toString(),
                subtitle: hasSlaRisk
                    ? '${stats.slaRiskCount} report${stats.slaRiskCount == 1 ? '' : 's'} exceeded 48hr threshold.'
                    : 'All reports within SLA limit.',
                actionLabel: hasSlaRisk ? 'VIEW OVERDUE' : 'VIEW REPORTS',
                icon: Icons.warning_amber_rounded,
                accentColor: hasSlaRisk ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                isDark: isDark,
                isAlert: hasSlaRisk,
                onTap: () {
                  if (hasSlaRisk) {
                    context.push('${OfficerAppRoutes.reports}?filter=overdue');
                  } else {
                    context.push(OfficerAppRoutes.reports);
                  }
                },
              ),
            ),
            const SizedBox(width: 14),
            // Card 4: Manual Review
            Expanded(
              child: _buildAlignedHeroCard(
                title: 'MANUAL REVIEW',
                value: stats.manualReviewCount.toString(),
                subtitle: hasManualReview
                    ? '${stats.manualReviewCount} pending review.'
                    : 'No reports pending review.',
                actionLabel: hasManualReview ? 'REVIEW REPORTS' : 'VIEW REPORTS',
                icon: Icons.fact_check_outlined,
                accentColor: hasManualReview ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                isDark: isDark,
                isAlert: hasManualReview,
                onTap: () {
                  if (hasManualReview) {
                    context.push('${OfficerAppRoutes.reports}?filter=manual_review');
                  } else {
                    context.push(OfficerAppRoutes.reports);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAlignedHeroCard({
    required String title,
    required String value,
    required String subtitle,
    required String actionLabel,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
    bool isAlert = false,
    required VoidCallback onTap,
  }) {
    final cardBg = isAlert
        ? accentColor.withValues(alpha: isDark ? 0.12 : 0.08)
        : (isDark ? const Color(0xFF1E1E1E) : Colors.white);

    final borderColor = isAlert
        ? accentColor.withValues(alpha: 0.6)
        : (isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade200);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: isAlert ? 1.5 : 1.0),
          boxShadow: [
            if (!isDark && !isAlert)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            if (isAlert)
              BoxShadow(
                color: accentColor.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accentColor, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: isAlert ? accentColor : (isDark ? Colors.white : Colors.black87),
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF333333) : Colors.grey.shade200,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    actionLabel,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: accentColor,
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 15, color: accentColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Active Targets Section (aligned with Web)
  Widget _buildActiveTargetsSection(DashboardStats stats, bool isDark) {
    final activeTasks = stats.activeTasks;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'ACTIVE TARGETS',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      '${activeTasks.length} in progress',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  context.push('${OfficerAppRoutes.cleanupTasks}?status=in_progress');
                },
                child: const Row(
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (activeTasks.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161616) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.task_alt_rounded, size: 32, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'No in-progress cleanup tasks',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'There are currently no cleanup tasks actively in progress.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          else
            Column(
              children: activeTasks.take(4).map((task) {
                final crewCount = (task.assignedCrewIds?.length ?? 0) > 0
                    ? task.assignedCrewIds!.length
                    : (task.assignedTo != null && task.assignedTo!.isNotEmpty ? 1 : 0);
                final reportCount = task.reportIds?.length ?? 0;

                return InkWell(
                  onTap: () {
                    context.push(OfficerAppRoutes.cleanupTasks);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF252525) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFF333333) : Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                task.title?.isNotEmpty == true
                                    ? task.title!
                                    : 'Task #${task.id.length > 8 ? task.id.substring(0, 8) : task.id}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'IN PROGRESS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFF59E0B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (task.description?.isNotEmpty == true) ...[
                          const SizedBox(height: 6),
                          Text(
                            task.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 15,
                                  color: crewCount > 0 ? const Color(0xFF10B981) : Colors.grey,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  crewCount > 0 ? '$crewCount Crew Dispatched' : 'Unassigned',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: crewCount > 0 ? const Color(0xFF10B981) : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            if (reportCount > 0)
                              Text(
                                '$reportCount report${reportCount > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // Critical Hotzones Section (aligned with Web)
  Widget _buildCriticalHotzonesSection(DashboardStats stats, bool isDark) {
    final criticalClusters = stats.criticalClusters;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.my_location_rounded, size: 18, color: Color(0xFFEF4444)),
                  SizedBox(width: 8),
                  Text(
                    'CRITICAL HOTZONES',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  context.push(OfficerAppRoutes.clusters);
                },
                child: const Row(
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (criticalClusters.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161616) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300,
                ),
              ),
              child: const Center(
                child: Text('No hotzones detected', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            Column(
              children: criticalClusters.asMap().entries.map((entry) {
                final idx = entry.key;
                final cluster = entry.value;
                final label = _getPriorityLabel(cluster);
                final score = cluster.priorityScore?.round() ?? ((cluster.reportCount ?? 0) * 10);
                final radius = cluster.radiusMeters?.round() ?? 50;

                return InkWell(
                  onTap: () {
                    context.push('/officer/clusters/${cluster.id}');
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF252525) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFF333333) : Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${label.toUpperCase()} PRIORITY (RANK ${idx + 1})',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  cluster.label ??
                                      cluster.issueType ??
                                      'Cluster #${cluster.id.length > 6 ? cluster.id.substring(0, 6) : cluster.id}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'SCORE',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  '$score',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              'Reports: ',
                              style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                            ),
                            Text(
                              '${cluster.reportCount ?? 0}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Radius: ',
                              style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                            ),
                            Text(
                              '${radius}m',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // AI Command Unit Intel Card (honoring web Command Unit)
  Widget _buildAiCommandUnitCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.psychology_outlined, size: 20, color: Color(0xFF10B981)),
                  SizedBox(width: 8),
                  Text(
                    'COMMAND UNIT INTEL',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Text(
                  '89% CONFIDENCE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildIntelMetric(
                  label: 'Model Precision',
                  value: '91.4%',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildIntelMetric(
                  label: 'Model Recall',
                  value: '88.2%',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.push(OfficerAppRoutes.spatialScan);
              },
              icon: const Icon(Icons.radar_rounded, size: 18),
              label: const Text('Open Spatial Scan & Forecast'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF3F4F6),
                foregroundColor: isDark ? Colors.white : Colors.black87,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isDark ? const Color(0xFF3E3E3E) : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntelMetric({
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262626) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey.shade400,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getPriorityLabel(Cluster cluster) {
    if (cluster.priority != null && cluster.priority!.isNotEmpty) {
      return cluster.priority!;
    }
    final score = cluster.priorityScore ?? ((cluster.reportCount ?? 0) * 10.0);
    if (score >= 80) return 'urgent';
    if (score >= 60) return 'high';
    if (score >= 35) return 'medium';
    return 'low';
  }
}



