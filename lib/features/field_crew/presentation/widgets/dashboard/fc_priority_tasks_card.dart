import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import 'fc_task_list_item.dart';

class FcPriorityTasksCard extends StatefulWidget {
  const FcPriorityTasksCard({super.key});

  @override
  State<FcPriorityTasksCard> createState() => _FcPriorityTasksCardState();
}

class _FcPriorityTasksCardState extends State<FcPriorityTasksCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  // Static tasks data for visual mockup
  final List<Map<String, dynamic>> _priorityTasks = [
    {
      'title': 'Clear Blocked Drainage at Main St.',
      'location': 'Zone A - Main Street Sector 3',
      'priority': TaskPriority.high,
      'status': TaskStatus.inProgress,
      'time': '1.5 hrs',
    },
    {
      'title': 'Prune Overgrown Branches near Power Lines',
      'location': 'Zone B - Elm Avenue',
      'priority': TaskPriority.medium,
      'status': TaskStatus.pending,
      'time': '2.0 hrs',
    },
  ];

  final List<Map<String, dynamic>> _feasibleTasks = [
    {
      'title': 'Empty Public Waste bins',
      'location': 'Zone A - Public Park',
      'priority': TaskPriority.low,
      'status': TaskStatus.pending,
      'time': '1.0 hr',
    },
    {
      'title': 'Replace Damaged Signboard',
      'location': 'Zone C - West Highway',
      'priority': TaskPriority.low,
      'status': TaskStatus.pending,
      'time': '45 mins',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBg = isDark ? AppColors.surfaceDark : Colors.white;
    final Color accentColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = textPrimary.withValues(alpha: 0.6);
    final feasibleBg = isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFF9FBF7);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppColors.spaceMD,
        vertical: AppColors.spaceSM,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowCard,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppColors.spaceMD,
              AppColors.spaceMD,
              AppColors.spaceMD,
              AppColors.spaceSM,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.assignment_turned_in_rounded,
                  size: 18,
                  color: accentColor,
                ),
                const SizedBox(width: AppColors.spaceXS),
                Text(
                  "Priority Tasks",
                  style: AppTypography.label.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppColors.radiusChip),
                  ),
                  child: Text(
                    '${_priorityTasks.length} Urgent',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Priority/Urgent Tasks List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppColors.spaceMD),
            child: Column(
              children: List.generate(_priorityTasks.length, (index) {
                final task = _priorityTasks[index];
                final double startDelay = index * 0.15;
                final Animation<double> animation = Tween<double>(
                  begin: 0.0,
                  end: 1.0,
                ).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(startDelay, startDelay + 0.5, curve: Curves.easeOutCubic),
                  ),
                );

                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: animation.value,
                      child: Transform.translate(
                        offset: Offset(0, (1.0 - animation.value) * 15),
                        child: child,
                      ),
                    );
                  },
                  child: FcTaskListItem(
                    title: task['title'],
                    location: task['location'],
                    priority: task['priority'],
                    status: task['status'],
                    estimatedTime: task['time'],
                    onTap: () {},
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: AppColors.spaceSM),

          // Feasible for Today subsection
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: feasibleBg,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppColors.radiusCard),
                bottomRight: Radius.circular(AppColors.radiusCard),
              ),
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                  width: 1,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppColors.spaceMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Today's Feasible Tasks",
                        style: AppTypography.caption.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "(Realistically doable)",
                        style: AppTypography.caption.copyWith(
                          color: textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppColors.spaceSM),
                  Column(
                    children: List.generate(_feasibleTasks.length, (index) {
                      final task = _feasibleTasks[index];
                      // Delay so feasible tasks appear after priority tasks
                      final double startDelay = 0.3 + (index * 0.15);
                      final Animation<double> animation = Tween<double>(
                        begin: 0.0,
                        end: 1.0,
                      ).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(startDelay, startDelay + 0.5, curve: Curves.easeOutCubic),
                        ),
                      );

                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: animation.value,
                            child: Transform.translate(
                              offset: Offset(0, (1.0 - animation.value) * 15),
                              child: child,
                            ),
                          );
                        },
                        child: FcTaskListItem(
                          title: task['title'],
                          location: task['location'],
                          priority: task['priority'],
                          status: task['status'],
                          estimatedTime: task['time'],
                          onTap: () {},
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppColors.spaceSM),
                  // View All Tasks text button
                  Center(
                    child: TextButton(
                      onPressed: () {},
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View All Tasks',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: accentColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
