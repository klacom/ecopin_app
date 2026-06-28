import 'package:flutter/material.dart';

class ValidationBadge extends StatelessWidget {
  final String status;

  const ValidationBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'validated':
        color = Colors.green;
        label = 'AI OK';
        break;
      case 'manual_review':
        color = Colors.orange;
        label = 'REVIEW';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'INVALID';
        break;
      default:
        color = Colors.grey;
        label = 'PENDING';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
