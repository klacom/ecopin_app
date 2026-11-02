import 'package:dio/dio.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'cleanup_photo_carousel.dart';
import 'cleanup_proof_photo.dart';

class VerifiedCleanupProof extends StatefulWidget {
  const VerifiedCleanupProof({
    super.key,
    required this.reportId,
    this.revision = 0,
    this.loadProof,
    this.isOwner = false,
  });
  final String reportId;
  final int revision;
  final Future<Map<String, dynamic>?> Function()? loadProof;
  final bool isOwner;
  @override
  State<VerifiedCleanupProof> createState() => _VerifiedCleanupProofState();
}

class _VerifiedCleanupProofState extends State<VerifiedCleanupProof> {
  final _client = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );
  late Future<Map<String, dynamic>?> _proof = _load();
  Future<Map<String, dynamic>?> _load() async {
    if (widget.loadProof != null) return widget.loadProof!();
    final client = widget.isOwner
        ? (_ownerClient ??= ApiClient()).dioClient
        : _client;
    final response = await client.get(
      Uri.parse(ApiClient.baseUrl)
          .resolve(
            '/api/reports/${Uri.encodeComponent(widget.reportId)}/cleanup-proof/${widget.isOwner ? 'owner' : 'public'}',
          )
          .toString(),
      options: widget.isOwner
          ? Options(extra: {'requiresSession': true})
          : null,
    );
    final proof = response.data['proof'];
    return proof == null ? null : Map<String, dynamic>.from(proof as Map);
  }

  ApiClient? _ownerClient;

  @override
  void didUpdateWidget(covariant VerifiedCleanupProof oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reportId != widget.reportId ||
        oldWidget.revision != widget.revision ||
        oldWidget.isOwner != widget.isOwner) {
      _proof = _load();
    }
  }

  @override
  void dispose() {
    _client.close(force: true);
    _ownerClient?.dioClient.close(force: true);
    super.dispose();
  }

  void _reload() => setState(() {
    _proof = _load();
  });

  // Original URLs never enter the gallery; owner delivery checks ownership per request.
  // A slot is either one `<slot>_url` or a `<slot>_urls` list whose items end in
  // their position, for example `.../before/1`. Every item must pass the same
  // origin and path checks.
  List<String> _photoUrls(Map<String, dynamic> proof, String slot) {
    if (proof['id'] is! String) return const [];
    final list = proof['${slot}_urls'];
    if (list is List) {
      return [
        for (var i = 0; i < list.length; i++)
          ?_checkedUrl(proof, slot, list[i], i),
      ];
    }
    final single = _checkedUrl(proof, slot, proof['${slot}_url'], null);
    return single == null ? const [] : [single];
  }

  String? _checkedUrl(
    Map<String, dynamic> proof,
    String slot,
    Object? raw,
    int? index,
  ) {
    if (raw is! String || raw.isEmpty) return null;
    final base = Uri.parse(ApiClient.baseUrl);
    final parsed = Uri.tryParse(raw);
    if (parsed == null) return null;
    final url = base.resolveUri(parsed);
    final ownerOnly = widget.isOwner && proof['owner_only'] == true;
    final root = ownerOnly
        ? '/api/reports/${Uri.encodeComponent(widget.reportId)}/cleanup-proof/owner/$slot'
        : '/api/reports/${Uri.encodeComponent(widget.reportId)}/cleanup-proof/public/${Uri.encodeComponent(proof['id'] as String)}/$slot';
    final path = index == null ? root : '$root/$index';
    if (url.scheme != base.scheme ||
        url.host != base.host ||
        url.port != base.port ||
        url.path != path ||
        url.hasQuery ||
        url.hasFragment ||
        url.userInfo.isNotEmpty) {
      return null;
    }
    return url.toString();
  }

  String? _dateOrNull(dynamic value) {
    final date = value is String ? DateTime.tryParse(value) : null;
    return date == null
        ? null
        : DateFormat.yMMMd().add_jm().format(date.toLocal());
  }

  String _date(dynamic value) => _dateOrNull(value) ?? 'Date not provided';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final small = theme.textTheme.bodySmall;
    return FutureBuilder<Map<String, dynamic>?>(
      future: _proof,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState != ConnectionState.done;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (loading) ...[
              Semantics(
                liveRegion: true,
                label: 'Loading cleanup photos',
                child: const LinearProgressIndicator(),
              ),
              const SizedBox(height: 12),
              Text('Checking for cleanup photos…', style: small),
            ] else if (snapshot.hasError) ...[
              Semantics(
                liveRegion: true,
                child: Text(
                  'We couldn’t load the cleanup update.',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your report is still here. Check your connection and try again.',
                style: small,
              ),
              AppButton(
                text: 'Try again',
                variant: ButtonVariant.link,
                onPressed: _reload,
              ),
            ] else if (snapshot.data == null) ...[
              const SizedBox(height: 12),
              const Icon(Icons.photo_library_outlined, size: 32),
              const SizedBox(height: 12),
              Text(
                'No cleanup photos to show yet',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(
                widget.isOwner
                    ? 'No cleanup photos are available for your report yet.'
                    : 'Before and After photos will appear here if SWMO clears them for sharing.',
                style: small,
              ),
              AppButton(
                text: 'Check for photos',
                variant: ButtonVariant.link,
                onPressed: _reload,
              ),
            ] else
              ..._published(snapshot.data!, small),
          ],
        );
      },
    );
  }

  List<Widget> _published(Map<String, dynamic> proof, TextStyle? small) {
    final ownerOnly = widget.isOwner && proof['owner_only'] == true;
    final before = _photoUrls(proof, 'before');
    final after = _photoUrls(proof, 'after');
    String name(String slot, int count, int i) => count == 1
        ? '$slot cleanup'
        : '$slot cleanup, photo ${i + 1} of $count';
    // One viewer pages through every photo, Before first, so zoom works across both.
    final gallery = [
      for (var i = 0; i < before.length; i++)
        (label: name('Before', before.length, i), url: before[i]),
      for (var i = 0; i < after.length; i++)
        (label: name('After', after.length, i), url: after[i]),
    ];
    void open(int index) => Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CleanupProofPhotoViewer(
          ownerOnly: ownerOnly,
          photos: gallery,
          initialIndex: index,
        ),
      ),
    );
    Widget slot(String label, List<String> urls, int offset) => urls.isEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'The $label photo is not available to view.',
              style: small,
            ),
          )
        : CleanupPhotoCarousel(
            label: label,
            urls: urls,
            ownerOnly: ownerOnly,
            onOpen: (i) => open(offset + i),
          );
    final completed = _dateOrNull(proof['completed_at']);
    return [
      const SizedBox(height: 4),
      slot('Before', before, 0),
      const SizedBox(height: 12),
      slot('After', after, before.length),
      if (proof['public_notes'] is String &&
          (proof['public_notes'] as String).trim().isNotEmpty) ...[
        const SizedBox(height: 20),
        Text(proof['public_notes'] as String),
      ],
      const SizedBox(height: 8),
      Row(
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              completed == null
                  ? 'Completion date not provided'
                  : 'Completed $completed',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          IconButton(
            tooltip: 'Check for cleanup updates',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: const Text('About this cleanup'),
        children: [
          Text(
            ownerOnly
                ? 'These cleanup photos are available to you as the report owner. Public sharing requires a separate SWMO review.'
                : 'These copies were checked by SWMO before sharing. Private crew photos are not shown here.',
            style: small,
          ),
          if (!ownerOnly) ...[
            const SizedBox(height: 8),
            Text('Checked: ${_date(proof['verified_at'])}', style: small),
          ],
        ],
      ),
    ];
  }
}
