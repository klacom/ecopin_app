import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/features/field_crew/data/models/agency_response_model.dart';
import '../controllers/fc_report_detail_presentation.dart';
import 'fc_offline_ui.dart';

/// Notes, status changes and photos logged for the report. Authors read as
/// “You” or “Team member”, never an ID fragment.
class FcActivityLog extends StatelessWidget {
  final List<AgencyResponse> responses;

  /// The signed-in crew member, so their own entries read “You”.
  final String? currentUserId;

  const FcActivityLog({super.key, required this.responses, this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FcOfflineCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text('Activity', style: theme.textTheme.titleMedium),
          ),
          const SizedBox(height: 12),
          if (responses.isEmpty)
            Text(
              'No activity yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (var i = 0; i < responses.length; i++) ...[
              if (i > 0) const Divider(height: 24),
              _item(context, responses[i]),
            ],
        ],
      ),
    );
  }

  Widget _item(BuildContext context, AgencyResponse res) {
    final theme = Theme.of(context);
    final status = theme.extension<AppStatusColors>();
    final (IconData icon, Color tone) = switch (res.actionType) {
      'status_update' => (
        Icons.sync,
        status?.info ?? theme.colorScheme.primary,
      ),
      'manual_note' => (
        Icons.sticky_note_2_outlined,
        status?.warning ?? theme.colorScheme.onSurface,
      ),
      'evidence_upload' => (
        Icons.photo_camera_outlined,
        theme.colorScheme.primary,
      ),
      _ => (Icons.history, theme.colorScheme.onSurfaceVariant),
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(child: Icon(icon, size: 24, color: tone)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${crewActivityActor(res.userId, currentUserId)} · ${crewActivityLabel(res.actionType)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                DateFormat.yMMMd().add_jm().format(res.createdAt.toLocal()),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (res.actionDetails != null &&
                  res.actionDetails!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(res.actionDetails!, style: theme.textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
