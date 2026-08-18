import 'package:flutter/material.dart';

class ClusterMarker extends StatelessWidget {
  final int reportCount;
  final String? severity;
  final String? issueType;
  final VoidCallback onTap;

  const ClusterMarker({
    super.key,
    required this.reportCount,
    this.severity,
    this.issueType,
    required this.onTap,
  });

  Color _getSeverityColor() {
    switch (severity?.toLowerCase()) {
      case 'high':
        return const Color(0xFFD32F2F); // Red
      case 'medium':
        return const Color(0xFFF57C00); // Orange
      case 'low':
        return const Color(0xFF388E3C); // Green
      default:
        return const Color(0xFF1976D2); // Blue (default)
    }
  }

  @override
  Widget build(BuildContext context) {
    final severityColor = _getSeverityColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: severityColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                reportCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (severity != null)
                Text(
                  severity!.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
