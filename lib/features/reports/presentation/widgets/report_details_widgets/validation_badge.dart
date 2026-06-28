import 'package:flutter/material.dart';

class ValidationBadge extends StatelessWidget {
  final String status;

  const ValidationBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'automatically_valid':
        color = Colors.green;
        label = 'AI VALIDATED';
        icon = Icons.verified;
        break;
      case 'manual_review':
        color = Colors.orange;
        label = 'MANUAL REVIEW';
        icon = Icons.rate_review;
        break;
      case 'rejected':
        color = Colors.red;
        label = 'INVALID';
        icon = Icons.error_outline;
        break;
      default:
        color = Colors.grey;
        label = 'PENDING';
        icon = Icons.hourglass_empty;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
