import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import 'package:ecopin_app/features/field_crew/data/models/agency_response_model.dart';
import 'package:intl/intl.dart';

class FcActivityLog extends StatelessWidget {
  final List<AgencyResponse> responses;

  const FcActivityLog({super.key, required this.responses});

  @override
  Widget build(BuildContext context) {
    if (responses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppColors.spaceLG),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(AppColors.radiusCard),
          border: Border.all(color: AppColors.dividerDark),
        ),
        child: Center(
          child: Text('No activity logged yet.', style: AppTypography.body.copyWith(color: Colors.grey)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppColors.spaceLG),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Activity Log', style: AppTypography.h5.copyWith(color: AppColors.textPrimaryDark)),
          const SizedBox(height: AppColors.spaceLG),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: responses.length,
            separatorBuilder: (context, index) => const Divider(color: AppColors.dividerDark, height: 24),
            itemBuilder: (context, index) {
              final response = responses[index];
              return _buildLogItem(response);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(AgencyResponse res) {
    IconData icon;
    Color iconColor;
    switch (res.actionType) {
      case 'status_update':
        icon = Icons.sync;
        iconColor = AppColors.info;
        break;
      case 'manual_note':
        icon = Icons.note;
        iconColor = AppColors.warning;
        break;
      case 'evidence_upload':
        icon = Icons.camera_alt;
        iconColor = AppColors.primaryDark;
        break;
      default:
        icon = Icons.history;
        iconColor = Colors.grey;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: AppColors.spaceMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'User ${res.userId.substring(0, 5)}', // Fallback display for userId
                    style: AppTypography.label.copyWith(color: AppColors.textPrimaryDark),
                  ),
                  Text(
                    DateFormat.yMMMd().add_jm().format(res.createdAt),
                    style: AppTypography.caption.copyWith(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                res.actionType.toUpperCase().replaceAll('_', ' '),
                style: AppTypography.caption.copyWith(color: iconColor),
              ),
              if (res.actionDetails != null && res.actionDetails!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  res.actionDetails!,
                  style: AppTypography.body.copyWith(color: AppColors.textPrimaryDark),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
