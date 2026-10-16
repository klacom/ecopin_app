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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade100;
    final textColor = isDark ? AppColors.textPrimaryDark : Colors.black87;
    final dividerColor = isDark ? Colors.white10 : Colors.grey.shade200;

    if (responses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppColors.spaceLG),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppColors.radiusCard),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: Text('No activity logged yet.', style: AppTypography.body.copyWith(color: Colors.grey)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppColors.spaceLG),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Activity Log', style: AppTypography.h5.copyWith(color: textColor)),
          const SizedBox(height: AppColors.spaceLG),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: responses.length,
            separatorBuilder: (context, index) => Divider(color: dividerColor, height: 24),
            itemBuilder: (context, index) {
              final response = responses[index];
              return _buildLogItem(response, textColor);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(AgencyResponse res, Color textColor) {
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
                    style: AppTypography.label.copyWith(color: textColor),
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
                  style: AppTypography.body.copyWith(color: textColor),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
