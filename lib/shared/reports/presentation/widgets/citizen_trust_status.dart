import 'package:ecopin_app/shared/reports/providers/citizen_trust_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CitizenTrustStatus extends ConsumerWidget {
  const CitizenTrustStatus({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(citizenTrustProvider);
    final trust = status.asData?.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!compact)
          Text('Citizen trust', style: Theme.of(context).textTheme.titleMedium),
        if (status.isLoading)
          const LinearProgressIndicator(
            semanticsLabel: 'Checking Urgent eligibility',
          ),
        if (status.hasError)
          const Text(
            'Trust status is unavailable. Non-urgent reporting is still available.',
          ),
        if (!status.isLoading && trust != null) ...[
          Text('Trust score: ${trust.score}/100'),
          Text(
            trust.urgentAllowed
                ? 'Urgent is available.'
                : trust.score < trust.threshold
                ? 'Urgent is locked. Reach ${trust.threshold} trust points to use it.'
                : 'Urgent is locked until the remaining recovery requirements are met.',
          ),
          if (!trust.urgentAllowed &&
              trust.lockedUntil != null &&
              trust.lockedUntil!.isAfter(DateTime.now()))
            Text(
              'Minimum lock ends: ${DateFormat('MMM d, yyyy, h:mm a').format(trust.lockedUntil!.toLocal())}',
            ),
          if (!trust.urgentAllowed && trust.recoveryReportsRemaining > 0)
            Text(
              '${trust.recoveryReportsRemaining} consecutive verified-valid reports still needed for recovery.',
            ),
        ],
        if (!compact)
          const Text(
            'Human-verified valid reports add 10 points. Proven false urgency removes 30 points and locks Urgent for at least 7 days plus 3 consecutive verified-valid reports. Waiting alone does not restore trust.',
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: status.isLoading
                ? null
                : () => ref.invalidate(citizenTrustProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh trust status'),
          ),
        ),
      ],
    );
  }
}
