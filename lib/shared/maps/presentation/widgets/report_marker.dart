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
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white, 
          width: 2
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowCard,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
