import 'dart:math' as math;

import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/shared/reports/data/models/citizen_trust.dart';
import 'package:ecopin_app/shared/reports/providers/citizen_trust_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Server-reported trust. The full form is a profile card with a score ring and
/// the rules; [compact] keeps the short text status used while reporting.
class CitizenTrustStatus extends ConsumerWidget {
  const CitizenTrustStatus({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(citizenTrustProvider);
    final trust = status.asData?.value;
    if (!compact) return _TrustCard(status: status, trust: trust);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
          Text(_summary(trust)),
          if (_lockEnds(trust) != null)
            Text('Minimum lock ends: ${_lockEnds(trust)}'),
          if (!trust.urgentAllowed && trust.recoveryReportsRemaining > 0)
            Text(_remaining(trust)),
        ],
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

String _summary(CitizenTrust trust) => trust.urgentAllowed
    ? 'Urgent is available.'
    : trust.score < trust.threshold
    ? 'Urgent is locked. Reach ${trust.threshold} trust points to use it.'
    : 'Urgent is locked until the remaining recovery requirements are met.';

String? _lockEnds(CitizenTrust trust) =>
    !trust.urgentAllowed &&
        trust.lockedUntil != null &&
        trust.lockedUntil!.isAfter(DateTime.now())
    ? DateFormat('MMM d, yyyy, h:mm a').format(trust.lockedUntil!.toLocal())
    : null;

String _remaining(CitizenTrust trust) =>
    '${trust.recoveryReportsRemaining} consecutive verified-valid reports still needed for recovery.';

class _TrustCard extends ConsumerWidget {
  const _TrustCard({required this.status, required this.trust});
  final AsyncValue<CitizenTrust> status;
  final CitizenTrust? trust;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = theme.extension<AppStatusColors>();
    final loaded = !status.isLoading && trust != null;
    final t = trust;
    final tone = t != null && t.urgentAllowed
        ? colors?.success ?? scheme.primary
        : scheme.primary;
    final lockEnds = t == null ? null : _lockEnds(t);
    final gap = t == null ? 0 : math.max(0, t.threshold - t.score);
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.dividerTheme.color ?? scheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      'Citizen trust',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh trust status',
                  onPressed: status.isLoading
                      ? null
                      : () => ref.invalidate(citizenTrustProvider),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            if (status.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: LinearProgressIndicator(
                  semanticsLabel: 'Checking Urgent eligibility',
                ),
              ),
            if (status.hasError && !loaded)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Trust status is unavailable. Non-urgent reporting is still available.',
                ),
              ),
            if (loaded && t != null) ...[
              const SizedBox(height: 8),
              Center(
                child: Semantics(
                  label:
                      'Trust score ${t.score} of 100. Urgent unlocks at ${t.threshold}.',
                  excludeSemantics: true,
                  child: SizedBox(
                    width: 168,
                    height: 168,
                    child: CustomPaint(
                      painter: _TrustRingPainter(
                        score: t.score,
                        threshold: t.threshold,
                        progress: tone,
                        track: scheme.onSurface.withValues(alpha: .12),
                        notch: scheme.onSurface,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${t.score}',
                              style: theme.textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'of 100',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                t.urgentAllowed ? 'Urgent is available' : 'Urgent is locked',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                t.urgentAllowed
                    ? 'You can mark reports Urgent.'
                    : t.score < t.threshold
                    ? 'Reach ${t.threshold} trust points to use it. You need $gap more.'
                    : 'Urgent stays locked until the remaining recovery requirements are met.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (lockEnds != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Minimum lock ends: $lockEnds',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              if (!t.urgentAllowed && t.recoveryReportsRemaining > 0) ...[
                const SizedBox(height: 4),
                Text(
                  _remaining(t),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ],
            const Divider(height: 32),
            _Rule(
              title: 'How you earn points',
              body: 'A human-verified valid report adds 10 points.',
            ),
            const SizedBox(height: 12),
            _Rule(
              title: 'What loses them',
              body:
                  'Proven false urgency removes 30 points and locks Urgent for at least 7 days, plus 3 consecutive verified-valid reports. Waiting alone does not restore trust.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.title, required this.body});
  final String title, body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          body,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _TrustRingPainter extends CustomPainter {
  _TrustRingPainter({
    required this.score,
    required this.threshold,
    required this.progress,
    required this.track,
    required this.notch,
  });
  final int score, threshold;
  final Color progress, track, notch;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 12.0;
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke * 2) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    final fraction = (score / 100).clamp(0.0, 1.0);
    if (fraction > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * fraction,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = progress,
      );
    }
    // A notch on the ring marks the score that unlocks Urgent.
    final angle =
        -math.pi / 2 + 2 * math.pi * (threshold / 100).clamp(0.0, 1.0);
    final inner = radius - stroke;
    final outer = radius + stroke;
    canvas.drawLine(
      center + Offset(math.cos(angle), math.sin(angle)) * inner,
      center + Offset(math.cos(angle), math.sin(angle)) * outer,
      Paint()
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = notch,
    );
  }

  @override
  bool shouldRepaint(_TrustRingPainter old) =>
      old.score != score ||
      old.threshold != threshold ||
      old.progress != progress ||
      old.track != track ||
      old.notch != notch;
}
