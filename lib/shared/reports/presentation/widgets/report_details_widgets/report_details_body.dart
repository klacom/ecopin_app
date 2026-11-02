import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/utils/csat_rating_scale.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/navigation_links.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/report_marker.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/reports/data/models/report_prefill_data.dart';
import 'package:ecopin_app/shared/reports/presentation/screens/satisfaction_rating_screen.dart';
import 'package:ecopin_app/shared/reports/providers/report_provider.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'package:ecopin_app/shared/widgets/private_media_image.dart';
import 'package:ecopin_app/shared/widgets/sliding_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import '../report_status_presentation.dart';
import '../reports_screen_widgets/validation_badge.dart';
import '../report_status_card.dart';
import '../verified_cleanup_proof.dart';
import 'fullscreen_image_view.dart';
import 'report_video_player.dart';

class ReportDetailsBody extends ConsumerStatefulWidget {
  const ReportDetailsBody({
    super.key,
    required this.report,
    required this.evidence,
    required this.isLoadingEvidence,
    this.evidenceFailed = false,
    this.onRetryEvidence,
    this.isOwner = false,
    this.proofRevision = 0,
    this.loadCleanupProof,
    this.tileProvider,
    this.videoControllerFactory,
    this.onWithdraw,
  });
  final ReportModel report;
  final List<dynamic> evidence;
  final bool isLoadingEvidence, evidenceFailed, isOwner;
  final VoidCallback? onRetryEvidence, onWithdraw;
  final int proofRevision;
  final Future<Map<String, dynamic>?> Function()? loadCleanupProof;
  final TileProvider? tileProvider;
  final VideoPlayerController Function(Uri source)? videoControllerFactory;
  @override
  ConsumerState<ReportDetailsBody> createState() => _ReportDetailsBodyState();
}

class _ReportDetailsBodyState extends ConsumerState<ReportDetailsBody> {
  bool get _completed => [
    'resolved',
    'waiting_for_feedback',
    'closed',
  ].contains(reportStatusKey(widget.report.status));
  bool get _rejected =>
      reportStatusKey(widget.report.status) == 'rejected' ||
      widget.report.validationStatus.toLowerCase() == 'rejected';
  late int _tab = _completed && !_rejected ? 1 : 0;
  @override
  void didUpdateWidget(covariant ReportDetailsBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.report.id != widget.report.id) {
      _tab = _completed && !_rejected ? 1 : 0;
    }
  }

  void _resubmit() {
    ref.invalidate(myReportsProvider);
    context.push(
      ProtectedAppRoutes.createReport,
      extra: ReportPrefillData(
        location: widget.report.location,
        title: widget.report.title,
        hideIdentity: widget.report.hideIdentity,
        description: widget.report.description,
        citizenLandmark: widget.report.citizenLandmark,
      ),
    );
  }

  Widget _heading(String title) => Semantics(
    header: true,
    child: Text(title, style: Theme.of(context).textTheme.titleMedium),
  );
  Widget _panel(String title, List<Widget> children) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColors.quietSurfaceDark
          : AppColors.quietSurfaceLight,
      borderRadius: BorderRadius.circular(AppColors.radiusCard),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(title),
        for (final child in children) ...[const SizedBox(height: 12), child],
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final theme = Theme.of(context);
    final small = theme.textTheme.bodySmall!.copyWith(
      color: theme.brightness == Brightness.dark
          ? AppColors.textSecondaryDark
          : AppColors.textSecondaryLight,
    );
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        24,
        16,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(report.title, style: theme.textTheme.titleLarge),
          ),
          const SizedBox(height: 16),
          ReportStatusCard(report: report, isOwner: widget.isOwner),
          const SizedBox(height: 16),
          SlidingSwitch(
            options: [
              SlidingSwitchOption(
                label: widget.isOwner ? 'Your report' : 'Report',
              ),
              const SlidingSwitchOption(label: 'Cleanup'),
            ],
            selectedIndex: _tab,
            onChanged: (value) => setState(() => _tab = value),
          ),
          const SizedBox(height: 8),
          if (_tab == 0)
            ..._reportContent(small)
          else
            ..._cleanupContent(small),
          if (widget.onWithdraw != null && report.canBeWithdrawn) ...[
            const SizedBox(height: 24),
            _panel('Need to take this report back?', [
              Text(
                'You can withdraw this report before SWMO starts handling it.',
                style: small,
              ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: widget.onWithdraw,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                    minimumSize: const Size(48, 48),
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text(
                    'Withdraw report',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  List<Widget> _reportContent(TextStyle small) {
    final report = widget.report;
    final colors = Theme.of(context).extension<AppStatusColors>()!;
    final priority = switch (report.citizenPriority?.trim().toLowerCase()) {
      'non_urgent' => 'Non-urgent',
      'urgent' => 'Urgent',
      _ => 'Not specified',
    };
    return [
      if (_rejected) ...[
        _panel('Review note', [
          Text(
            report.rejectionReason?.trim().isNotEmpty == true
                ? report.rejectionReason!
                : 'You can send a new report with clearer photos or updated details.',
          ),
          if (report.manualReviewRequestReason != null) ...[
            Text('Your request for a review', style: small),
            Text(report.manualReviewRequestReason!),
          ],
          if (report.rejectedAt != null)
            Text(
              'Reviewed ${DateFormat.yMMMd().add_jm().format(report.rejectedAt!.toLocal())}',
              style: small,
            ),
          if (widget.isOwner)
            AppButton(text: 'Send an updated report', onPressed: _resubmit),
          if (widget.isOwner)
            Text(
              'Check your details and add new photos before sending.',
              style: small,
            ),
        ]),
        const SizedBox(height: 24),
      ],
      _sectionLabel('What you reported'),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          report.description?.trim().isNotEmpty == true
              ? report.description!
              : 'No description was provided.',
        ),
      ),
      const SizedBox(height: 4),
      if (widget.isLoadingEvidence)
        Semantics(
          label: 'Loading submitted photos and video',
          liveRegion: true,
          child: const LinearProgressIndicator(),
        ),
      if (widget.evidenceFailed) ...[
        Text(
          widget.evidence.isEmpty
              ? 'We couldn’t load the photos and video.'
              : 'The update failed. Previously loaded photos and video are shown.',
          style: small,
        ),
        if (widget.onRetryEvidence != null)
          AppButton(
            text: 'Try again',
            variant: ButtonVariant.link,
            onPressed: widget.isLoadingEvidence ? null : widget.onRetryEvidence,
          ),
      ],
      if (widget.evidence.isEmpty &&
          !widget.evidenceFailed &&
          !widget.isLoadingEvidence)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('No photos or video were submitted.', style: small),
        ),
      if (widget.evidence.isNotEmpty) ...[
        _sectionLabel(
          widget.isOwner
              ? 'Your photos and video'
              : 'Submitted photos and video',
        ),
        _evidenceStrip(),
      ],
      _sectionLabel('Location'),
      _locationCard(small),
      const SizedBox(height: 16),
      Material(
        color: Theme.of(context).colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusCard),
          side: BorderSide(
            color:
                Theme.of(context).dividerTheme.color ??
                Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: ExpansionTile(
          key: PageStorageKey('report-information-${report.id}'),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          title: const Text('More details'),
          children: [
            if (report.citizenPriority != null)
              _informationRow(
                'Priority you chose',
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.quietSurfaceDark
                        : AppColors.quietSurfaceLight,
                    borderRadius: BorderRadius.circular(AppColors.radiusChip),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        size: 18,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.linkDark
                            : AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          priority,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                small,
              ),
            _informationRow(
              'Report check',
              ValidationBadge(status: report.validationStatus),
              small,
            ),
            _informationRow(
              'Sent on',
              Text(
                DateFormat.yMMMd().add_jm().format(report.createdAt.toLocal()),
              ),
              small,
            ),
            if (report.issueType != null)
              _informationRow('Concern', Text(report.issueType!), small),
            if (report.severityScore != null)
              _informationRow(
                'SWMO assessment',
                Text(
                  '${report.severityLevel ?? 'Not provided'} · ${report.severityScore}/100',
                  style: small.copyWith(
                    color:
                        [
                          'critical',
                          'high',
                        ].contains(report.severityLevel?.toLowerCase())
                        ? colors.error
                        : report.severityLevel?.toLowerCase() == 'moderate'
                        ? colors.warning
                        : colors.success,
                  ),
                ),
                small,
              ),
            if (report.severityFactors?['explanation'] is String)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  report.severityFactors!['explanation'] as String,
                  style: small,
                ),
              ),
            if (report.locationVerificationStatus != null)
              _informationRow(
                'Location check',
                Text(
                  report.locationVerificationStatus!.replaceAll('_', ' ') +
                      (report.photoDistanceMeters == null
                          ? ''
                          : ' (${report.photoDistanceMeters!.toStringAsFixed(0)} m)'),
                ),
                small,
              ),
            if (report.onPrivateProperty) ...[
              const SizedBox(height: 16),
              _heading('Private property'),
              const SizedBox(height: 8),
              Text(
                [
                      'obtained',
                      'granted',
                    ].contains(report.propertyOwnerConsentStatus)
                    ? 'The property owner has allowed cleanup crews to enter.'
                    : report.propertyOwnerConsentStatus == 'denied'
                    ? 'The property owner has not allowed entry. Crews cannot enter the property.'
                    : 'SWMO must review the site and obtain the property owner’s consent before crews can enter.',
              ),
              Text(
                'Consent: ${report.propertyOwnerConsentStatus.replaceAll('_', ' ')}',
                style: small,
              ),
            ],
            if (report.locationPrecision != 'approximate') ...[
              const SizedBox(height: 20),
              Text('Exact location', style: small),
              const SizedBox(height: 8),
              SelectableText(
                key: PageStorageKey('report-coordinates-${report.id}'),
                '${report.location.latitude.toStringAsFixed(6)}, ${report.location.longitude.toStringAsFixed(6)}',
                style: small,
              ),
            ],
          ],
        ),
      ),
    ];
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  );

  void _openEvidenceSheet() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => SizedBox(
      height: MediaQuery.sizeOf(sheetContext).height * .65,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _heading(
              widget.isOwner
                  ? 'Your photos and video'
                  : 'Submitted photos and video',
            ),
            const SizedBox(height: 16),
            _evidenceGallery(),
          ],
        ),
      ),
    ),
  );

  /// Up to three thumbnails and a "View all" tile; any of them opens the full gallery.
  Widget _evidenceStrip() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shown = widget.evidence.take(3).toList();
    Widget tile(Widget child, String label) => Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        width: 72,
        height: 72,
        child: Material(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: _openEvidenceSheet, child: child),
        ),
      ),
    );
    return SizedBox(
      height: 72,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: [
          for (var i = 0; i < shown.length; i++) ...[
            () {
              final item = shown[i];
              final url = item is Map ? item['url'] ?? item['file_url'] : null;
              final video = item is Map && item['resource_type'] == 'video';
              final label = 'Open photos and video, item ${i + 1}';
              if (video || url is! String || url.isEmpty) {
                return tile(
                  Icon(
                    video
                        ? Icons.videocam_outlined
                        : Icons.image_not_supported_outlined,
                    color: scheme.onSurfaceVariant,
                  ),
                  label,
                );
              }
              return tile(
                PrivateMediaImage(
                  url,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.image_not_supported_outlined,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                label,
              );
            }(),
            const SizedBox(width: 10),
          ],
          tile(
            Center(
              child: Text(
                widget.evidence.length > shown.length
                    ? '+${widget.evidence.length - shown.length}\nView all'
                    : 'View all',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            'View all photos and video, ${widget.evidence.length} items',
          ),
        ],
      ),
    );
  }

  Widget _locationCard(TextStyle small) {
    final report = widget.report;
    final theme = Theme.of(context);
    final exact = report.locationPrecision != 'approximate';
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        side: BorderSide(
          color: theme.dividerTheme.color ?? theme.colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _locationPreview(),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 12, 0, 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.streetAddress != null ||
                                  report.barangay != null
                              ? report.formattedAddress
                              : 'The pin on the map shows this location.',
                        ),
                        if (report.citizenLandmark?.trim().isNotEmpty ==
                            true) ...[
                          const SizedBox(height: 6),
                          Text(report.citizenLandmark!, style: small),
                        ],
                        if (!exact) ...[
                          const SizedBox(height: 6),
                          Text(
                            'This report shows an approximate location.',
                            style: small,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (exact)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: DirectionsMenuButton(destination: report.location),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _informationRow(String label, Widget value, TextStyle small) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            Text(label, style: small),
            value,
          ],
        ),
      );

  Widget _locationPreview() {
    final report = widget.report;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppColors.radiusCard),
      child: SizedBox(
        height: 180,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: report.location,
            initialZoom: 17,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              tileProvider: widget.tileProvider,
              urlTemplate: Theme.of(context).brightness == Brightness.dark
                  ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png?key=${dotenv.env['CARTO_API_KEY'] ?? ''}'
                  : 'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png?key=${dotenv.env['CARTO_API_KEY'] ?? ''}',
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'dev.ecopinas.ecopin_app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: report.location,
                  width: ReportPinFrame.width,
                  height: ReportPinFrame.height,
                  alignment: Alignment.topCenter,
                  child: ReportMarker(
                    status: report.status,
                    title: report.title,
                    issueType: report.issueType,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _evidenceGallery() => SizedBox(
    height: 200,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: widget.evidence.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final item = widget.evidence[index];
        final url = item is Map ? item['url'] ?? item['file_url'] : null;
        if (url is! String || url.isEmpty) {
          return const SizedBox(
            width: 200,
            child: Center(child: Text('This media is unavailable.')),
          );
        }
        return SizedBox(
          width: 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppColors.radiusInput),
            child: item['resource_type'] == 'video'
                ? ReportVideoPlayer(
                    videoUrl: url,
                    createController: widget.videoControllerFactory,
                  )
                : Semantics(
                    button: true,
                    label: 'Open submitted photo ${index + 1}',
                    child: InkWell(
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => FullScreenImageView(imageUrl: url),
                        ),
                      ),
                      child: PrivateMediaImage(
                        url,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Center(
                          child: Text(
                            'This photo couldn’t load. Try refreshing the report.',
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        );
      },
    ),
  );

  List<Widget> _cleanupContent(TextStyle small) => [
    if (!_rejected)
      VerifiedCleanupProof(
        reportId: widget.report.id,
        isOwner: widget.isOwner,
        revision: widget.proofRevision,
        loadProof: widget.loadCleanupProof,
      )
    else
      _panel('No cleanup update to show', [
        Text(
          'This report wasn’t accepted. See the review note in the report tab.',
          style: small,
        ),
      ]),
    if (widget.isOwner &&
        !_rejected &&
        [
          'resolved',
          'waiting_for_feedback',
        ].contains(reportStatusKey(widget.report.status))) ...[
      const SizedBox(height: 24),
      AppButton(
        text: 'Rate the service',
        onPressed: () => Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => SatisfactionRatingScreen(
              reportId: widget.report.id,
              report: widget.report,
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Text('Sending your rating closes this report.', style: small),
    ],
    if (widget.isOwner &&
        widget.report.status.toLowerCase() == 'closed' &&
        widget.report.satisfactionRating != null) ...[
      const SizedBox(height: 24),
      _panel('Your service rating', [
        Text(
          '${CsatRatingScale.emoji(widget.report.satisfactionRating!)} ${CsatRatingScale.label(widget.report.satisfactionRating!)}',
          semanticsLabel:
              '${widget.report.satisfactionRating} of 5. ${CsatRatingScale.label(widget.report.satisfactionRating!)}',
        ),
      ]),
    ],
  ];
}
