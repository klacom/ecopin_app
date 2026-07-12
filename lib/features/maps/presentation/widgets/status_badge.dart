import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String displayText;
    switch (status.toLowerCase()) {
      case 'resolved':
        color = Colors.green;
        displayText = 'Resolved';
        break;
      case 'closed':
        color = Colors.green;
        displayText = 'Closed';
        break;
      case 'in progress':
        color = Colors.orange;
        displayText = 'In Progress';
        break;
      case 'acknowledged':
        color = Colors.orange;
        displayText = 'Acknowledged';
        break;
      case 'waiting_for_feedback':
        color = Colors.orange;
        displayText = 'Waiting for Feedback';
        break;
      case 'pending_owner_consent':
        color = Colors.yellow;
        displayText = 'Pending Owner Consent';
        break;
      default:
        color = Colors.red;
        displayText = status.toUpperCase();
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}