import 'package:ecopin_app/core/database/app_database.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/core/services/sync_service.dart';
import 'package:ecopin_app/shared/reports/providers/citizen_trust_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BlockedUrgentReports extends ConsumerStatefulWidget {
  const BlockedUrgentReports({super.key});
  @override
  ConsumerState<BlockedUrgentReports> createState() =>
      _BlockedUrgentReportsState();
}

class _BlockedUrgentReportsState extends ConsumerState<BlockedUrgentReports> {
  bool _busy = false;
  String? _error;
  Future<void> _retry(OfflineReport draft, bool asNonUrgent) async {
    if (_busy) return;
    final ownerId = ref.read(apiClientProvider).currentUserId;
    if (ownerId == null || draft.ownerId != ownerId) return;
    setState(() => _busy = true);
    try {
      if (asNonUrgent) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            scrollable: true,
            title: const Text('Send as Non-urgent?'),
            content: const Text(
              'Keep your report and photos, and remove the urgency request. Your report will be queued for submission as Non-urgent.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Use Non-urgent'),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
      }
      final queued = await ref
          .read(databaseProvider)
          .retryBlockedUrgentReport(
            draft.id,
            ownerId,
            asNonUrgent: asNonUrgent,
          );
      if (!queued) throw StateError('Draft no longer available');
      await ref.read(syncServiceProvider).syncAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Draft queued for sync. Check My reports for server confirmation.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'The draft could not be retried. Your saved report is still here.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final drafts = ref.watch(blockedUrgentReportsProvider);
    final trust = ref.watch(citizenTrustProvider);
    if (drafts.hasError) {
      return const Text(
        'Saved reports are unavailable. Refresh Profile and try again.',
      );
    }
    final saved = drafts.asData?.value ?? <OfflineReport>[];
    if (saved.isEmpty) return const SizedBox.shrink();
    final ownerId = ref.watch(apiClientProvider).currentUserId;
    final rows = saved
        .where((draft) => ownerId != null && draft.ownerId == ownerId)
        .toList();
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Saved reports needing attention',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (_error != null) Text(_error!),
        for (final draft in rows)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    draft.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Text(
                    'Urgent was blocked. Your report and evidence remain on this device.',
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => _retry(draft, true),
                    child: const Text('Send as Non-urgent'),
                  ),
                  TextButton(
                    onPressed:
                        _busy ||
                            trust.isLoading ||
                            trust.asData?.value.urgentAllowed != true
                        ? null
                        : () => _retry(draft, false),
                    child: const Text('Retry Urgent'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
