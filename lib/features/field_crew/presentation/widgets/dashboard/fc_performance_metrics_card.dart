import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import 'fc_performance_weekly_bar_chart.dart';

// ── Work Quality Enum ─────────────────────────────────────────────────────────

enum WorkQuality {
  excellent,
  great,
  good,
  bad,
  worse;

  String get label {
    switch (this) {
      case WorkQuality.excellent:
        return 'Excellent';
      case WorkQuality.great:
        return 'Great';
      case WorkQuality.good:
        return 'Good';
      case WorkQuality.bad:
        return 'Bad';
      case WorkQuality.worse:
        return 'Worse';
    }
  }

  Color get color {
    switch (this) {
      case WorkQuality.excellent:
        return const Color(0xFF1B5E20); // deep green
      case WorkQuality.great:
        return const Color(0xFF388E3C); // green
      case WorkQuality.good:
        return const Color(0xFF0288D1); // teal-blue
      case WorkQuality.bad:
        return const Color(0xFFE65100); // deep orange
      case WorkQuality.worse:
        return const Color(0xFFB71C1C); // deep red
    }
  }

  Color get backgroundColor {
    switch (this) {
      case WorkQuality.excellent:
        return const Color(0xFFE8F5E9);
      case WorkQuality.great:
        return const Color(0xFFF1F8E9);
      case WorkQuality.good:
        return const Color(0xFFE1F5FE);
      case WorkQuality.bad:
        return const Color(0xFFFFF3E0);
      case WorkQuality.worse:
        return const Color(0xFFFFEBEE);
    }
  }

  IconData get icon {
    switch (this) {
      case WorkQuality.excellent:
        return Icons.workspace_premium_rounded;
      case WorkQuality.great:
        return Icons.star_rounded;
      case WorkQuality.good:
        return Icons.thumb_up_rounded;
      case WorkQuality.bad:
        return Icons.sentiment_dissatisfied_rounded;
      case WorkQuality.worse:
        return Icons.sentiment_very_dissatisfied_rounded;
    }
  }
}

// ── Circular Progress Ring Painter ───────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0
  final Color trackColor;
  final Color fillColor;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
    this.strokeWidth = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.shortestSide - strokeWidth) / 2;

    final Paint trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final Paint fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Track (background circle)
    canvas.drawCircle(center, radius, trackPaint);

    // Fill arc
    final double sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ── Performance Metrics Card ──────────────────────────────────────────────────

/// A scalable, plug-in-ready card for displaying a field crew member's
/// weekly performance metrics. All data values are parameters with static
/// defaults — swap them for real data when the model is ready.
class FcPerformanceMetricsCard extends StatefulWidget {
  /// Number of tasks completed this week.
  final int completedTasks;

  /// Total tasks assigned this week.
  final int totalTasks;

  /// Qualitative work quality rating.
  final WorkQuality quality;

  /// Daily task counts for the past 7 days (oldest → today).
  final List<int> dailyCounts;

  const FcPerformanceMetricsCard({
    super.key,
    this.completedTasks = 18,
    this.totalTasks = 24,
    this.quality = WorkQuality.great,
    this.dailyCounts = const [3, 5, 4, 7, 6, 8, 5],
  });

  @override
  State<FcPerformanceMetricsCard> createState() =>
      _FcPerformanceMetricsCardState();
}

class _FcPerformanceMetricsCardState extends State<FcPerformanceMetricsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ringController;
  late Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _ringAnimation = CurvedAnimation(
      parent: _ringController,
      curve: Curves.easeOutCubic,
    );
    _ringController.forward();
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double progress = widget.totalTasks > 0
        ? (widget.completedTasks / widget.totalTasks).clamp(0.0, 1.0)
        : 0.0;

    final Color cardBg =
        isDark ? AppColors.surfaceDark : Colors.white;
    final Color accentColor =
        isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final Color textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final Color textSecondary =
        textPrimary.withValues(alpha: 0.55);
    final Color trackColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFECF5E1);

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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Left accent strip ─────────────────────────────
              Container(
                width: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      accentColor,
                      accentColor.withValues(alpha: 0.4),
                    ],
                  ),
                ),
              ),
              // ── Card content ──────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppColors.spaceMD),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section header
                      Row(
                        children: [
                          Icon(
                            Icons.bar_chart_rounded,
                            size: 18,
                            color: accentColor,
                          ),
                          const SizedBox(width: AppColors.spaceXS),
                          Text(
                            "This Week's Performance",
                            style: AppTypography.label.copyWith(
                              color: accentColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppColors.spaceMD),

                      // ── Stats row ───────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Animated ring
                          SizedBox(
                            width: 88,
                            height: 88,
                            child: AnimatedBuilder(
                              animation: _ringAnimation,
                              builder: (context, child) {
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CustomPaint(
                                      size: const Size(88, 88),
                                      painter: _RingPainter(
                                        progress:
                                            progress * _ringAnimation.value,
                                        trackColor: trackColor,
                                        fillColor: accentColor,
                                        strokeWidth: 9,
                                      ),
                                    ),
                                    // Center label
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${widget.completedTasks}',
                                          style: AppTypography.h5.copyWith(
                                            color: textPrimary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          'of ${widget.totalTasks}',
                                          style: AppTypography.caption
                                              .copyWith(color: textSecondary),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),

                          const SizedBox(width: AppColors.spaceMD),

                          // Counter info column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tasks Completed',
                                  style: AppTypography.bodySmall
                                      .copyWith(color: textSecondary),
                                ),
                                const SizedBox(height: 2),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '${widget.completedTasks}',
                                        style: AppTypography.h4.copyWith(
                                          color: textPrimary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' / ${widget.totalTasks}',
                                        style: AppTypography.h6.copyWith(
                                          color: textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppColors.spaceSM),
                                // Work quality badge
                                _WorkQualityBadge(quality: widget.quality),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppColors.spaceMD),

                      // ── Divider ─────────────────────────────────
                      Divider(
                        color: isDark
                            ? AppColors.dividerDark
                            : AppColors.dividerLight,
                        thickness: 1,
                        height: 1,
                      ),

                      const SizedBox(height: AppColors.spaceMD),

                      // ── 7-day chart ─────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '7-Day Activity',
                            style: AppTypography.caption.copyWith(
                              color: textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Today ▲',
                            style: AppTypography.caption.copyWith(
                              color: accentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppColors.spaceSM),
                      SizedBox(
                        height: 72,
                        child: FcPerformanceWeeklyBarChart(
                          dailyCounts: widget.dailyCounts,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Work Quality Badge ────────────────────────────────────────────────────────

class _WorkQualityBadge extends StatelessWidget {
  final WorkQuality quality;

  const _WorkQualityBadge({required this.quality});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // In dark mode use a slightly lighter background
    final Color bg = isDark
        ? quality.color.withValues(alpha: 0.2)
        : quality.backgroundColor;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppColors.spaceSM + 2,
        vertical: AppColors.spaceXS,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppColors.radiusChip),
        border: Border.all(
          color: quality.color.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(quality.icon, size: 14, color: quality.color),
          const SizedBox(width: 4),
          Text(
            quality.label,
            style: AppTypography.caption.copyWith(
              color: quality.color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
