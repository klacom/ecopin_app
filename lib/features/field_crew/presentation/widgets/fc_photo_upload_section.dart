import 'package:ecopin_app/shared/widgets/private_media_image.dart';
import 'dart:io';
import '../controllers/fc_task_detail_presentation.dart';
import 'package:flutter/material.dart';
import 'package:ecopin_app/core/database/app_database.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/report_details_widgets/fullscreen_image_view.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/report_details_widgets/report_video_player.dart';
import 'fc_offline_ui.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model passed into the widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Represents a single before/after photo as seen by the UI.
///
/// The caller resolves which source to show: the remote URL from the report or
/// a local [FcLocalPhoto] row waiting to upload.
class FcPhotoSlot {
  /// Remote CDN URL (non-null once the photo has been synced).
  final String? remoteUrl;
  final String? remoteId;

  /// Absolute local filesystem path (non-null for pending/failed photos).
  final String? localPath;

  /// Stable local photo ID from [FcLocalPhotos]. Null when the only known
  /// source is the legacy report URL string.
  final String? localPhotoId;

  /// Current sync state from [FcLocalPhotoSyncStatus]. Null for legacy data.
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

  /// The best display URL: prefers remote, falls back to local.
  String? get displayPath => remoteUrl ?? localPath;
}

// ─────────────────────────────────────────────────────────────────────────────
// Before / After photo strip
// ─────────────────────────────────────────────────────────────────────────────

/// Thumbnails and the Add photo tile for one photo type ('before' | 'after').
///
/// Up to five photos per type. The caller supplies resolved [FcPhotoSlot]s so
/// the widget stays free of repository logic; [onUpload] receives the picked
/// file and [onDelete] the slot the crew member confirmed deleting.
class FcPhotoStrip extends StatefulWidget {
  const FcPhotoStrip({
    super.key,
    required this.type,
    required this.slots,
    required this.isAssigned,
    required this.isEnabled,
    required this.onUpload,
    required this.onDelete,
  });
  static const maxPhotos = 5;
  final String type;
  final List<FcPhotoSlot> slots;
  final bool isAssigned, isEnabled;
  final Future<void> Function(File file, String type) onUpload;
  final Future<void> Function(FcPhotoSlot slot, String type) onDelete;

  @override
  State<FcPhotoStrip> createState() => _FcPhotoStripState();
}

class _FcPhotoStripState extends State<FcPhotoStrip> {
  static const _tile = 88.0;
  bool _uploading = false;

  String get _typeLabel => widget.type == 'before' ? 'Before' : 'After';

  Future<void> _pick(BuildContext context) async {
    if (_uploading) return;
    if (widget.slots.length >= FcPhotoStrip.maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum number of photos reached.')),
      );
      return;
    }
    final source = await _pickSource(context);
    if (source == null) return;
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
    );
    if (picked == null || !context.mounted) return;
    setState(() => _uploading = true);
    try {
      await widget.onUpload(File(picked.path), widget.type);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_friendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<ImageSource?> _pickSource(BuildContext context) =>
      showModalBottomSheet<ImageSource>(
        context: context,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppColors.radiusDialog),
          ),
        ),
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                minTileHeight: 56,
                leading: Icon(Icons.camera_alt_outlined, color: fcAccent(ctx)),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                minTileHeight: 56,
                leading: Icon(
                  Icons.photo_library_outlined,
                  color: fcAccent(ctx),
                ),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );

  void _confirmDelete(BuildContext context, FcPhotoSlot slot) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${_typeLabel.toLowerCase()} photo?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await widget.onDelete(slot, widget.type);
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'The photo could not be deleted. Try again.',
                      ),
                    ),
                  );
                }
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canAdd =
        widget.isAssigned &&
        widget.isEnabled &&
        widget.slots.length < FcPhotoStrip.maxPhotos;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        for (var i = 0; i < widget.slots.length; i++)
          _thumbnail(context, widget.slots[i], i + 1),
        if (canAdd) _uploading ? _busyTile(context) : _addTile(context),
      ],
    );
  }

  Widget _thumbnail(BuildContext context, FcPhotoSlot slot, int number) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppStatusColors>();
    final (String? note, IconData? noteIcon, Color noteColor) = slot.isFailed
        ? (
            'Did not send',
            Icons.sync_problem,
            colors?.error ?? theme.colorScheme.error,
          )
        : slot.syncStatus == FcLocalPhotoSyncStatus.inFlight
        ? ('Sending', Icons.sync, colors?.info ?? theme.colorScheme.primary)
        : slot.isPending
        ? (
            'Waiting to send',
            Icons.schedule,
            colors?.warning ?? theme.colorScheme.onSurface,
          )
        : (null, null, theme.colorScheme.onSurface);
    return SizedBox(
      width: _tile,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _tile,
            height: _tile,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Semantics(
                  button: true,
                  label: 'Open $_typeLabel photo $number',
                  child: GestureDetector(
                    onTap: slot.displayPath != null
                        ? () => _open(context, slot)
                        : null,
                    child: Container(
                      width: _tile,
                      height: _tile,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppColors.radiusInput,
                        ),
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ExcludeSemantics(child: _image(slot)),
                    ),
                  ),
                ),
                if (widget.isAssigned && widget.isEnabled)
                  Positioned(
                    top: -10,
                    right: -10,
                    child: Semantics(
                      button: true,
                      label: 'Delete $_typeLabel photo $number',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _confirmDelete(context, slot),
                        // 48dp target around the 28dp visual button.
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Center(
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: Color(0xCC000000),
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
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Icon(noteIcon, size: 14, color: noteColor),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    note,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: noteColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _image(FcPhotoSlot slot) {
    if (slot.remoteUrl != null) {
      return PrivateMediaImage(
        slot.remoteUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
        errorBuilder: (context, error, stack) =>
            const Center(child: Icon(Icons.broken_image_outlined, size: 28)),
      );
    }
    if (slot.localPath != null) {
      return Image.file(
        File(slot.localPath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) =>
            const Center(child: Icon(Icons.broken_image_outlined, size: 28)),
      );
    }
    return const Center(
      child: Icon(Icons.image_not_supported_outlined, size: 28),
    );
  }

  void _open(BuildContext context, FcPhotoSlot slot) {
    if (slot.remoteUrl != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => FullScreenImageView(imageUrl: slot.remoteUrl!),
        ),
      );
      return;
    }
    if (slot.localPath != null) {
      showDialog<void>(
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

  BoxDecoration _tileDecoration(BuildContext context) => BoxDecoration(
    color: Theme.of(context).brightness == Brightness.dark
        ? AppColors.quietSurfaceDark
        : AppColors.quietSurfaceLight,
    borderRadius: BorderRadius.circular(AppColors.radiusInput),
    border: Border.all(
      color:
          Theme.of(context).dividerTheme.color ??
          Theme.of(context).dividerColor,
    ),
  );

  Widget _addTile(BuildContext context) => Semantics(
    button: true,
    label: 'Add $_typeLabel photo',
    child: InkWell(
      onTap: () => _pick(context),
      borderRadius: BorderRadius.circular(AppColors.radiusInput),
      child: Container(
        width: _tile,
        constraints: const BoxConstraints(minHeight: _tile),
        padding: const EdgeInsets.all(8),
        decoration: _tileDecoration(context),
        child: ExcludeSemantics(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, color: fcAccent(context)),
              const SizedBox(height: 4),
              Text(
                'Add photo',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: fcAccent(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _busyTile(BuildContext context) => Semantics(
    liveRegion: true,
    label: 'Saving photo',
    child: Container(
      width: _tile,
      height: _tile,
      decoration: _tileDecoration(context),
      child: const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    ),
  );

  String _friendlyError(Object e) {
    final str = e.toString();
    if (str.contains('FcPhotoSlotOccupiedException')) {
      return 'Maximum 5 photos reached for this section. Delete an existing photo first.';
    }
    if (str.contains('FcPhotoDuplicateException')) {
      return 'This photo has already been added.';
    }
    return 'The photo could not be saved. Try again.';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Citizen evidence
// ─────────────────────────────────────────────────────────────────────────────

/// Citizen photos and videos for the report, opened in the app. Empty or
/// failed evidence shows a placeholder with refresh guidance, never a claim
/// that the citizen sent nothing.
class FcCitizenEvidence extends StatelessWidget {
  const FcCitizenEvidence({
    super.key,
    required this.evidencePhotos,
    this.evidenceError,
    this.videoControllerFactory,
  });
  final List<dynamic> evidencePhotos;
  final String? evidenceError;
  final VideoPlayerController Function(Uri)? videoControllerFactory;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final media = evidencePhotos
        .where((row) => citizenEvidenceUrl(row) != null)
        .toList();
    if (evidenceError != null || media.isEmpty) {
      return Container(
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
              evidenceError ??
                  'Submitted photos or videos could not be found. Refresh this report to try again.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var index = 0; index < media.length; index++)
          _item(context, media[index], index),
      ],
    );
  }

  Widget _item(BuildContext context, dynamic row, int index) {
    final colors = Theme.of(context).colorScheme;
    final url = citizenEvidenceUrl(row)!;
    final video = citizenEvidenceIsVideo(row);
    return SizedBox(
      width: 96,
      height: 96,
      child: Material(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppColors.radiusInput),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => video
                  ? Scaffold(
                      appBar: AppBar(title: const Text('Citizen video')),
                      body: Center(
                        child: ReportVideoPlayer(
                          videoUrl: url,
                          extent: MediaQuery.sizeOf(context).shortestSide - 32,
                          createController: videoControllerFactory,
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
                      child: Icon(Icons.play_circle_outline, size: 48),
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
  }
}

/// Collapsed row that opens [FcCitizenEvidence], so the work steps stay near
/// the top of the screen.
class FcCitizenEvidenceSection extends StatefulWidget {
  const FcCitizenEvidenceSection({
    super.key,
    required this.evidencePhotos,
    this.evidenceError,
    this.videoControllerFactory,
  });
  final List<dynamic> evidencePhotos;
  final String? evidenceError;
  final VideoPlayerController Function(Uri)? videoControllerFactory;

  @override
  State<FcCitizenEvidenceSection> createState() =>
      _FcCitizenEvidenceSectionState();
}

class _FcCitizenEvidenceSectionState extends State<FcCitizenEvidenceSection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = widget.evidencePhotos
        .where((row) => citizenEvidenceUrl(row) != null)
        .toList();
    final videos = media.where(citizenEvidenceIsVideo).length;
    final photos = media.length - videos;
    final subtitle = widget.evidenceError != null
        ? 'Unavailable. Open for details.'
        : media.isEmpty
        ? 'None available yet. Open for guidance.'
        : [
            if (photos > 0) '$photos ${photos == 1 ? 'photo' : 'photos'}',
            if (videos > 0) '$videos ${videos == 1 ? 'video' : 'videos'}',
          ].join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusCard),
            side: BorderSide(
              color: theme.dividerTheme.color ?? theme.dividerColor,
            ),
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
          FcCitizenEvidence(
            evidencePhotos: widget.evidencePhotos,
            evidenceError: widget.evidenceError,
            videoControllerFactory: widget.videoControllerFactory,
          ),
        ],
      ],
    );
  }
}
