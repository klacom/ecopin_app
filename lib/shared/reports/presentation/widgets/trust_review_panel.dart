import 'package:dio/dio.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/shared/reports/providers/citizen_trust_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class TrustReviewPanel extends ConsumerStatefulWidget {
  const TrustReviewPanel({super.key, required this.reportId});
  final String reportId;
  @override
  ConsumerState<TrustReviewPanel> createState() => _TrustReviewPanelState();
}

class _TrustReviewPanelState extends ConsumerState<TrustReviewPanel> {
  final _reason = TextEditingController();
  String? _outcome;
  String _operationId = const Uuid().v4();
  bool _saving = false;
  String? _error;
  @override
  void didUpdateWidget(covariant TrustReviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reportId != widget.reportId) {
      _reason.clear();
      _outcome = null;
      _error = null;
      _saving = false;
      _operationId = const Uuid().v4();
    }
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || _outcome == null || _reason.text.trim().length < 3) return;
    final outcome = _outcome!;
    final reportId = widget.reportId;
    final reason = _reason.text.trim();
    final operationId = _operationId;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (outcome == 'false_urgency') {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            scrollable: true,
            title: const Text('Confirm proven false urgency?'),
            content: const Text(
              'Use this only when the urgency claim is proven false. It removes 30 trust points and locks Urgent for at least 7 days plus 3 consecutive verified-valid reports. A rejected report or declined urgency alone is not a false claim.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm false claim'),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted || widget.reportId != reportId) {
          return;
        }
      }
      await ref
          .read(apiClientProvider)
          .recordCitizenTrustReview(
            reportId,
            outcome: outcome,
            reason: reason,
            operationId: operationId,
          );
      if (mounted && widget.reportId == reportId) {
        ref.invalidate(reportTrustReviewProvider(widget.reportId));
        ref.invalidate(citizenTrustProvider);
      }
    } on DioException catch (e) {
      if (mounted && widget.reportId == reportId) {
        setState(
          () => _error =
              e.response?.data is Map && e.response?.data['message'] is String
              ? e.response?.data['message']
              : 'Review was not confirmed. Connect and retry; your reason is still here.',
        );
      }
    } catch (_) {
      if (mounted && widget.reportId == reportId) {
        setState(
          () => _error =
              'Review was not confirmed. Connect and retry; your reason is still here.',
        );
      }
    } finally {
      if (mounted && widget.reportId == reportId) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final review = ref.watch(reportTrustReviewProvider(widget.reportId));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Citizen trust review',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (review.isLoading)
              const LinearProgressIndicator(
                semanticsLabel: 'Loading trust review',
              ),
            if (review.hasError) ...[
              Text(
                review.error is DioException &&
                        (review.error as DioException).response?.statusCode ==
                            403
                    ? 'Trust review requires SWMO access or an active, ready task assigned to your crew. Ask SWMO to review a completed task.'
                    : 'Trust review is unavailable. Connect and refresh to check your permission and the saved decision.',
              ),
              TextButton(
                onPressed: () =>
                    ref.invalidate(reportTrustReviewProvider(widget.reportId)),
                child: const Text('Retry trust review'),
              ),
            ],
            if (!review.isLoading && review.asData != null)
              ..._content(review.asData!.value),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(Map<String, dynamic> data) {
    final decision = data['decision'];
    const labels = {
      'valid': 'Verified valid',
      'neutral': 'Unconfirmed / neutral',
      'false_urgency': 'Proven false urgency',
      'withdrawn': 'Review withdrawn',
    };
    if (decision is Map) {
      return [
        Text(labels[decision['outcome']] ?? 'Review recorded'),
        Text(decision['reason']?.toString() ?? ''),
        const Text(
          'This review is recorded. An administrator can correct an erroneous decision.',
        ),
      ];
    }
    if (data['reviewable'] == false) {
      return [const Text('Trust reviews apply to citizen reports only.')];
    }
    return [
      Text(
        data['submitted_priority'] == 'urgent'
            ? 'Submitted priority: Urgent'
            : 'Submitted priority: Non-urgent / unspecified',
      ),
      const Text(
        'Record a human verification. AI approval, rejection and routine urgency decline do not change trust.',
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        itemHeight: null,
        initialValue: _outcome,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Verification outcome'),
        items: [
          const DropdownMenuItem(
            value: 'valid',
            child: Text('Verified valid (+10)'),
          ),
          const DropdownMenuItem(
            value: 'neutral',
            child: Text('Unconfirmed / neutral (no points)'),
          ),
          if (data['submitted_priority'] == 'urgent')
            const DropdownMenuItem(
              value: 'false_urgency',
              child: Text('Proven false urgency (−30)'),
            ),
        ],
        onChanged: _saving
            ? null
            : (value) => setState(() {
                _outcome = value;
                _operationId = const Uuid().v4();
              }),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _reason,
        enabled: !_saving,
        maxLength: 1000,
        minLines: 2,
        maxLines: 4,
        decoration: const InputDecoration(
          labelText: 'Verification reason (required)',
        ),
        onChanged: (_) => setState(() => _operationId = const Uuid().v4()),
      ),
      if (_error != null)
        Semantics(
          liveRegion: true,
          child: Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      if (_error != null)
        TextButton(
          onPressed: () =>
              ref.invalidate(reportTrustReviewProvider(widget.reportId)),
          child: const Text('Refresh saved review'),
        ),
      FilledButton(
        onPressed: _saving || _outcome == null || _reason.text.trim().length < 3
            ? null
            : _save,
        child: Text(_saving ? 'Saving review…' : 'Save trust review'),
      ),
      const Text(
        'Online only. A retry of the same review does not change trust twice.',
      ),
    ];
  }
}
