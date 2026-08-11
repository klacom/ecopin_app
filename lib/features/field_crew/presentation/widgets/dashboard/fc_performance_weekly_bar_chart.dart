import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';

/// Paints a 7-day horizontal mini bar chart.
/// Each bar's height is proportional to [dailyCounts] max value.
class WeeklyBarChartPainter extends CustomPainter {
  final List<int> dailyCounts;
  final Color barColor;
  final Color barColorToday;
  final Color labelColor;
  final double animationValue; // 0.0 → 1.0 controls bar height

  static const List<String> _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  const WeeklyBarChartPainter({
    required this.dailyCounts,
    required this.barColor,
    required this.barColorToday,
    required this.labelColor,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dailyCounts.isEmpty) return;

    final int maxCount = dailyCounts.reduce(math.max);
    if (maxCount == 0) return;

    final int count = dailyCounts.length;
    final double labelAreaHeight = 18.0;
    final double chartHeight = size.height - labelAreaHeight;
    final double barAreaWidth = size.width / count;
    final double barWidth = barAreaWidth * 0.55;
    final double barSpacing = barAreaWidth * 0.45;
    final double cornerRadius = 4.0;

    final Paint barPaint = Paint()..style = PaintingStyle.fill;
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < count; i++) {
      final double x = i * barAreaWidth + barSpacing / 2;
      final double barHeightRatio = dailyCounts[i] / maxCount;
      final double barHeight = chartHeight * barHeightRatio * animationValue;
      final double top = chartHeight - barHeight;

      final bool isToday = i == count - 1;
      barPaint.color = isToday ? barColorToday : barColor;

      final RRect rRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barWidth, barHeight),
        Radius.circular(cornerRadius),
      );
      canvas.drawRRect(rRect, barPaint);

      // Day label below bar
      textPainter.text = TextSpan(
        text: _dayLabels[i % _dayLabels.length],
        style: TextStyle(
          color: isToday ? barColorToday : labelColor,
          fontSize: 10,
          fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
          fontFamily: 'Outfit',
        ),
      );
      textPainter.layout();
      final double labelX = x + (barWidth - textPainter.width) / 2;
      textPainter.paint(canvas, Offset(labelX, chartHeight + 4));
    }
  }

  @override
  bool shouldRepaint(WeeklyBarChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.dailyCounts != dailyCounts;
  }
}

/// Animated 7-day bar chart widget.
class FcPerformanceWeeklyBarChart extends StatefulWidget {
  final List<int> dailyCounts;

  const FcPerformanceWeeklyBarChart({
    super.key,
    this.dailyCounts = const [3, 5, 4, 7, 6, 8, 5],
  });

  @override
  State<FcPerformanceWeeklyBarChart> createState() =>
      _FcPerformanceWeeklyBarChartState();
}

class _FcPerformanceWeeklyBarChartState
    extends State<FcPerformanceWeeklyBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color barColor = isDark
        ? AppColors.secondaryDark.withValues(alpha: 0.6)
        : AppColors.secondaryLight.withValues(alpha: 0.5);
    final Color barColorToday =
        isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final Color labelColor = isDark
        ? AppColors.textPrimaryDark.withValues(alpha: 0.5)
        : AppColors.textPrimaryLight.withValues(alpha: 0.4);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return CustomPaint(
          painter: WeeklyBarChartPainter(
            dailyCounts: widget.dailyCounts,
            barColor: barColor,
            barColorToday: barColorToday,
            labelColor: labelColor,
            animationValue: _animation.value,
          ),
        );
      },
    );
  }
}
