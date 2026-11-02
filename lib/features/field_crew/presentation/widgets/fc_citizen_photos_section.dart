import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import '../controllers/fc_task_detail_presentation.dart';
import 'fc_photo_gallery_card.dart';

/// Citizen evidence for the linked reports, collapsed so the work list stays
/// near the top. Opening it shows the existing gallery with its own loading,
/// failure and confirmed-empty states.
class FcCitizenPhotosSection extends StatefulWidget {
  const FcCitizenPhotosSection({
    super.key,
    required this.reports,
    required this.evidenceByReport,
    required this.isLoading,
    required this.error,
    required this.onRetry,
  });
  final List<ReportModel> reports;
  final Map<String, List<dynamic>> evidenceByReport;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;

  @override
  State<FcCitizenPhotosSection> createState() => _FcCitizenPhotosSectionState();
}

class _FcCitizenPhotosSectionState extends State<FcCitizenPhotosSection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final known = widget.reports.every(
      (r) => widget.evidenceByReport.containsKey(r.id),
    );
    final count = citizenPhotoCount(widget.reports, widget.evidenceByReport);
    final subtitle = widget.isLoading
        ? 'Loading'
        : widget.error != null
        ? 'Unavailable. Open to try again.'
        : !known
        ? 'Not loaded yet'
        : count == 0
        ? 'No citizen photos'
        : '$count ${count == 1 ? 'photo' : 'photos'}';
    final side = BorderSide(
      color: theme.dividerTheme.color ?? theme.dividerColor,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusCard),
            side: side,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppColors.radiusCard),
            onTap: () => setState(() => _open = !_open),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const ExcludeSemantics(
                      child: Icon(Icons.photo_library_outlined, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Semantics(
                        button: true,
                        expanded: _open,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Citizen photos',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              subtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ExcludeSemantics(
                      child: Icon(
                        _open ? Icons.expand_less : Icons.expand_more,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_open) ...[
          const SizedBox(height: 12),
          FcPhotoGalleryCard(
            reports: widget.reports,
            evidenceByReport: widget.evidenceByReport,
            isLoading: widget.isLoading,
            error: widget.error,
            onRetry: widget.onRetry,
          ),
        ],
      ],
    );
  }
}
