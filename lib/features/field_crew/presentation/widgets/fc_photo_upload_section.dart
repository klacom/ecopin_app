import 'package:ecopin_app/shared/widgets/private_media_image.dart';
import 'dart:io';
import '../controllers/fc_task_detail_presentation.dart';
import 'package:flutter/material.dart';
import 'package:ecopin_app/core/database/app_database.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/report_details_widgets/fullscreen_image_view.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/report_details_widgets/report_video_player.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model passed into the widget
// ─────────────────────────────────────────────────────────────────────────────

/// Represents a single before/after photo slot as seen by the UI.
///
/// The widget receives these for the before and after slots rather than raw
/// URL strings.  The caller (detail screen) is responsible for resolving which
/// source — remote URL from [ReportModel] or a local [FcLocalPhoto] row — to
/// show.
class FcPhotoSlot {
  /// Remote CDN URL (non-null once the photo has been synced).
  final String? remoteUrl;
  final String? remoteId;

  /// Absolute local filesystem path (non-null for pending/failed photos).
  final String? localPath;

  /// Stable local photo ID from [FcLocalPhotos].  Null when the only known
  /// source is the legacy [ReportModel] URL string (pre-Phase-3 data).
  final String? localPhotoId;

  /// Current sync state from [FcLocalPhotoSyncStatus].  Null for legacy data.
  final int? syncStatus;

  const FcPhotoSlot({
    this.remoteUrl,
    this.remoteId,
    this.localPath,
    this.localPhotoId,
    this.syncStatus,
  });

  /// True when this slot has any displayable image (local or remote).
  bool get hasPhoto => remoteUrl != null || localPath != null;

  /// True when the photo is still being uploaded (pending or in-flight).
  bool get isPending =>
      syncStatus == FcLocalPhotoSyncStatus.pending ||
      syncStatus == FcLocalPhotoSyncStatus.inFlight;

  /// True when the last upload attempt failed and it is awaiting retry.
  bool get isFailed => syncStatus == FcLocalPhotoSyncStatus.failed;

  /// True when the photo is fully synced to the server.
  bool get isSynced => syncStatus == FcLocalPhotoSyncStatus.synced;

  /// Convenience: the best display URL — prefers remote, falls back to local.
  String? get displayPath => remoteUrl ?? localPath;
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────────────────────

/// Photo upload/display section shown on Field Crew report and task detail
/// screens.
///
/// Supports both **offline** photos (local file, pending upload) and **synced**
/// remote photos.  The caller provides [FcPhotoSlot] objects for each slot so
/// the widget stays free of repository logic.
///
/// Callbacks:
///  • [onUpload]    — called after the user picks an image; receives the [File]
///                    and the slot type ('before' | 'after').
///  • [onDelete]    — called when the user confirms deletion; receives the
///                    [FcPhotoSlot] that should be deleted.
class FcPhotoUploadSection extends StatefulWidget {
  final List<dynamic> evidencePhotos;
  final String? evidenceError;
  final VideoPlayerController Function(Uri)? videoControllerFactory;

  /// Current state of the before-photo slot.  Pass `null` when there is no
  /// photo for that slot.
  final FcPhotoSlot? beforeSlot;
  final List<FcPhotoSlot> beforeSlots;

  /// Current state of the after-photo slot.
  final FcPhotoSlot? afterSlot;
  final List<FcPhotoSlot> afterSlots;

  final bool isAssigned;
  final bool isBeforeEnabled;
  final bool isAfterEnabled;

  /// Optional action widget (status indicator message + action buttons)
  /// displayed directly below the Before and After photo slots so the crew
  /// does not have to scroll back up after uploading photos.
  final Widget? actionSection;

  /// Called when the user picks a new image.  Receives the picked [File] and
  /// the slot type string ('before' | 'after').
  final Future<void> Function(File file, String type) onUpload;

  /// Called when the user confirms deletion.  Receives the slot being deleted.
  final Future<void> Function(FcPhotoSlot slot, String type) onDelete;

  const FcPhotoUploadSection({
    super.key,
    required this.evidencePhotos,
    this.evidenceError,
    this.videoControllerFactory,
    this.beforeSlot,
    this.beforeSlots = const [],
    this.afterSlot,
    this.afterSlots = const [],
    required this.isAssigned,
    this.isBeforeEnabled = true,
    this.isAfterEnabled = true,
    this.actionSection,
    required this.onUpload,
    required this.onDelete,
  });

  @override
  State<FcPhotoUploadSection> createState() => _FcPhotoUploadSectionState();
}

class _FcPhotoUploadSectionState extends State<FcPhotoUploadSection> {
  // Reports allow five Before photos and five After photos.
  List<FcPhotoSlot> get _beforePhotos => widget.beforeSlots.isNotEmpty
      ? widget.beforeSlots
      : [if (widget.beforeSlot?.hasPhoto == true) widget.beforeSlot!];
  List<FcPhotoSlot> get _afterPhotos => widget.afterSlots.isNotEmpty
      ? widget.afterSlots
      : [if (widget.afterSlot?.hasPhoto == true) widget.afterSlot!];
  int _limit(String type) => 5;

  // Per-slot upload-in-progress flags to prevent double-taps.
  bool _uploadingBefore = false;
  bool _uploadingAfter = false;

  // ── Image picking ─────────────────────────────────────────────────────────

  Future<void> _pickImage(BuildContext context, String type) async {
    final isUploading = type == 'before' ? _uploadingBefore : _uploadingAfter;
    if (isUploading) return;

    final currentCount =
        type == 'before' ? _beforePhotos.length : _afterPhotos.length;
    if (currentCount >= _limit(type)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum number of photos reached.')),
        );
      }
      return;
    }

    // Show source picker: camera or gallery.
    final source = await _showSourcePicker(context);
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;
    if (!context.mounted) return;

    setState(() {
      if (type == 'before') {
        _uploadingBefore = true;
      } else {
        _uploadingAfter = true;
      }
    });

    try {
      await widget.onUpload(File(picked.path), type);
    } catch (e) {
      if (context.mounted) {
        final msg = _friendlyError(e);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) {
        setState(() {
          if (type == 'before') {
            _uploadingBefore = false;
          } else {
            _uploadingAfter = false;
          }
        });
      }
    }
  }

  Future<ImageSource?> _showSourcePicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? AppColors.textPrimaryDark : Colors.black87;

    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: AppColors.primaryDark,
              ),
              title: Text(
                'Take a photo',
                style: AppTypography.body.copyWith(color: textColor),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppColors.primaryDark,
              ),
              title: Text(
                'Choose from gallery',
                style: AppTypography.body.copyWith(color: textColor),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Delete confirmation ───────────────────────────────────────────────────

  void _confirmDelete(BuildContext context, FcPhotoSlot slot, String type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? AppColors.textPrimaryDark : Colors.black87;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(
          'Delete Photo?',
          style: AppTypography.h5.copyWith(color: textColor),
        ),
        content: Text(
          'Are you sure you want to delete this $type photo? '
          'This action cannot be undone.',
          style: AppTypography.body.copyWith(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await widget.onDelete(slot, type);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade100;
    final textColor = isDark ? AppColors.textPrimaryDark : Colors.black87;
    final dividerColor = isDark ? Colors.white10 : Colors.grey.shade200;

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
          Text(
            'Evidence & Documentation',
            style: AppTypography.h5.copyWith(color: textColor),
          ),
          const SizedBox(height: AppColors.spaceLG),

          _buildCitizenEvidence(),

          Divider(color: dividerColor, height: AppColors.spaceXL * 2),

          const Text(
            'If you will clean this site: take Before photo(s) before starting and press Mark as Acknowledged, then take After photo(s) when finished and press Mark as Complete.\n\n'
            'Already clear when you arrive? Take one current photo in After Photos. A Before photo is not required for this observation. Do not upload the same photo twice. Return to Task Details and select Already clear on arrival; this records an observation, not cleanup credit.',
          ),
          const SizedBox(height: AppColors.spaceLG),

          _buildFieldCrewPhotoSection(
            context,
            'before',
            widget.beforeSlot,
            _uploadingBefore,
          ),
          const SizedBox(height: AppColors.spaceLG),

          _buildFieldCrewPhotoSection(
            context,
            'after',
            widget.afterSlot,
            _uploadingAfter,
          ),

          if (widget.actionSection != null) ...[
            const SizedBox(height: AppColors.spaceLG),
            Divider(color: dividerColor, height: AppColors.spaceLG),
            widget.actionSection!,
          ],
        ],
      ),
    );
  }

  // ── Citizen evidence section ──────────────────────────────────────────────

  Widget _buildCitizenEvidence() {
    final colors = Theme.of(context).colorScheme;
    final media = widget.evidencePhotos
        .where((row) => citizenEvidenceUrl(row) != null)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Citizen Evidence', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (widget.evidenceError != null || media.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppColors.radiusCard),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.perm_media_outlined,
                  size: 32,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  'Citizen evidence unavailable',
                  style: Theme.of(context).textTheme.titleSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.evidenceError ??
                      'Submitted photos or videos could not be found. Refresh this report to try again.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: media.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final url = citizenEvidenceUrl(media[index])!;
                final video = citizenEvidenceIsVideo(media[index]);
                return SizedBox(
                  width: 110,
                  child: Material(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppColors.radiusCard),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => video
                              ? Scaffold(
                                  appBar: AppBar(
                                    title: const Text('Citizen video'),
                                  ),
                                  body: Center(
                                    child: ReportVideoPlayer(
                                      videoUrl: url,
                                      extent:
                                          MediaQuery.sizeOf(
                                            context,
                                          ).shortestSide -
                                          32,
                                      createController:
                                          widget.videoControllerFactory,
                                    ),
                                  ),
                                )
                              : FullScreenImageView(imageUrl: url),
                        ),
                      ),
                      child: Semantics(
                        button: true,
                        label: video
                            ? 'View citizen video ${index + 1}'
                            : 'View citizen photo ${index + 1}',
                        child: ExcludeSemantics(
                          child: video
                              ? const Center(
                                  child: Icon(
                                    Icons.play_circle_outline,
                                    size: 48,
                                  ),
                                )
                              : PrivateMediaImage(
                                  url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Center(
                                    child: Icon(Icons.broken_image_outlined),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // ── Field crew photo section ──────────────────────────────────────────────

  Widget _buildFieldCrewPhotoSection(
    BuildContext context,
    String type,
    FcPhotoSlot? slot,
    bool isUploading,
  ) {
    final title = type == 'before' ? 'Before Photos' : 'After Photos';
    final photos = type == 'before' ? _beforePhotos : _afterPhotos;
    final count = photos.length;
    final maxPerSlot = _limit(type);
    final bool isEnabled = type == 'before'
        ? widget.isBeforeEnabled
        : widget.isAfterEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            Text(
              '$title ($count/$maxPerSlot)',
              style: AppTypography.label.copyWith(color: Colors.grey),
            ),
            if (widget.isAssigned && count < maxPerSlot && isEnabled)
              Text(
                '${maxPerSlot - count} slot remaining',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primaryDark,
                ),
              ),
            if (widget.isAssigned && count < maxPerSlot && !isEnabled)
              Text(
                'Acknowledge report first',
                style: AppTypography.caption.copyWith(color: Colors.grey),
              ),
          ],
        ),
        const SizedBox(height: AppColors.spaceSM),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Show existing photo thumbnails.
              for (final photo in photos)
                _buildPhotoThumbnail(context, photo, type, isEnabled),
              // Show add button if slot has capacity and user is assigned.
              if (count < maxPerSlot && widget.isAssigned && isEnabled)
                isUploading
                    ? _buildUploadingIndicator()
                    : _buildAddButton(context, type),
            ],
          ),
        ),
      ],
    );
  }

  // ── Photo thumbnail with sync badge ──────────────────────────────────────

  Widget _buildPhotoThumbnail(
    BuildContext context,
    FcPhotoSlot slot,
    String type,
    bool isEnabled,
  ) {
    final displayPath = slot.displayPath;

    return Container(
      margin: const EdgeInsets.only(right: AppColors.spaceSM),
      width: 120,
      height: 120,
      child: Stack(
        children: [
          // Image
          GestureDetector(
            onTap: displayPath != null ? () => _openPhoto(context, slot) : null,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppColors.radiusCard),
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.surfaceDark
                    : Colors.grey.shade100,
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildImageWidget(slot),
            ),
          ),

          // Sync status badge (top-left)
          if (slot.syncStatus != null && !slot.isSynced)
            Positioned(
              top: 4,
              left: 4,
              child: _SyncBadge(syncStatus: slot.syncStatus!),
            ),

          // Delete button (top-right) — only shown when assigned and enabled.
          if (widget.isAssigned && isEnabled)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _confirmDelete(context, slot, type),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the correct image widget depending on whether the photo is local
  /// or remote.
  Widget _buildImageWidget(FcPhotoSlot slot) {
    // Prefer remote URL for synced photos; otherwise show local file.
    if (slot.remoteUrl != null) {
      return PrivateMediaImage(
        slot.remoteUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryDark,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stack) => const Center(
          child: Icon(Icons.broken_image, color: Colors.grey, size: 28),
        ),
      );
    }

    if (slot.localPath != null) {
      final file = File(slot.localPath!);
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => const Center(
          child: Icon(Icons.broken_image, color: Colors.grey, size: 28),
        ),
      );
    }

    return const Center(
      child: Icon(Icons.image_not_supported, color: Colors.grey, size: 28),
    );
  }

  void _openPhoto(BuildContext context, FcPhotoSlot slot) async {
    if (slot.remoteUrl != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => FullScreenImageView(imageUrl: slot.remoteUrl!),
        ),
      );
      return;
    }
    // Fallback: show local file in a full-screen dialog.
    if (slot.localPath != null && context.mounted) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.black,
          child: InteractiveViewer(
            child: Image.file(File(slot.localPath!), fit: BoxFit.contain),
          ),
        ),
      );
    }
  }

  // ── Add button ────────────────────────────────────────────────────────────

  Widget _buildAddButton(BuildContext context, String type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final slotFill = isDark ? AppColors.surfaceDark : Colors.grey.shade100;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade300;

    return InkWell(
      onTap: () => _pickImage(context, type),
      borderRadius: BorderRadius.circular(AppColors.radiusCard),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: slotFill,
          borderRadius: BorderRadius.circular(AppColors.radiusCard),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo, color: AppColors.primaryDark),
            const SizedBox(height: AppColors.spaceSM),
            Text(
              'Add Photo',
              style: AppTypography.caption.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadingIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final slotFill = isDark ? AppColors.surfaceDark : Colors.grey.shade100;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade300;

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: slotFill,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        border: Border.all(color: borderColor),
      ),
      child: const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primaryDark,
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _friendlyError(Object e) {
    final str = e.toString();
    if (str.contains('FcPhotoSlotOccupiedException')) {
      return 'Maximum 5 photos reached for this section. Delete an existing photo first.';
    }
    if (str.contains('FcPhotoDuplicateException')) {
      return 'This photo has already been added.';
    }
    return 'Failed to save photo: $e';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sync status badge
// ─────────────────────────────────────────────────────────────────────────────

/// Small overlay chip shown on photo thumbnails that are not yet synced.
class _SyncBadge extends StatelessWidget {
  final int syncStatus;

  const _SyncBadge({required this.syncStatus});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (syncStatus) {
      FcLocalPhotoSyncStatus.pending => ('Pending', AppColors.warning),
      FcLocalPhotoSyncStatus.inFlight => ('Uploading', AppColors.primaryDark),
      FcLocalPhotoSyncStatus.failed => ('Failed', AppColors.error),
      _ => ('', Colors.transparent),
    };

    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
