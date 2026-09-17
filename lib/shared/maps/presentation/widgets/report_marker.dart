import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';

class ReportMarker extends StatelessWidget {
  final String status;

  const ReportMarker({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'resolved':
      case 'closed':
        color = AppColors.success;
        break;
      case 'in progress':
      case 'in_progress':
      case 'acknowledged':
      case 'waiting_for_feedback':
        color = AppColors.warning;
        break;
      case 'pending_owner_consent':
        color = AppColors.info;
        break;
      default:
        color = AppColors.error;
        break;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.6),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.location_on,
        color: Colors.black,
        size: 18,
      ),
    );
  }
}
