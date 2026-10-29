import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:ecopin_app/core/services/api_service.dart';

class VerifiedCleanupProof extends StatefulWidget {
  const VerifiedCleanupProof({super.key, required this.reportId});
  final String reportId;
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
    final response = await _client.get(
      '${ApiClient.baseUrl}/api/reports/${Uri.encodeComponent(widget.reportId)}/cleanup-proof/public',
    );
    final proof = response.data['proof'];
    return proof == null ? null : Map<String, dynamic>.from(proof as Map);
  }

  @override
  void didUpdateWidget(covariant VerifiedCleanupProof oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reportId != widget.reportId) _proof = _load();
  }

  @override
  void dispose() {
    _client.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verified cleanup proof',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        FutureBuilder<Map<String, dynamic>?>(
          future: _proof,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cleanup proof could not load.'),
                  TextButton(
                    onPressed: () => setState(() => _proof = _load()),
                    child: const Text('Retry cleanup proof'),
                  ),
                ],
              );
            }
            if (snapshot.connectionState != ConnectionState.done) {
              return const Text('Loading cleanup proof…');
            }
            final proof = snapshot.data;
            if (proof == null) {
              return const Text(
                'No officer-approved public cleanup proof is available yet.',
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(proof['public_notes'] as String? ?? ''),
                for (final slot in ['before', 'after']) ...[
                  const SizedBox(height: 12),
                  Text(slot == 'before' ? 'Before cleanup' : 'After cleanup'),
                  Image.network(
                    '${ApiClient.baseUrl}${proof['${slot}_url']}',
                    semanticLabel: '$slot cleanup, privacy reviewed',
                    errorBuilder: (_, _, _) => const Text(
                      'Verified image unavailable. Refresh the proof.',
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Completed: ${DateTime.parse(proof['completed_at'] as String).toLocal()}. Verified: ${DateTime.parse(proof['verified_at'] as String).toLocal()}.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Text(
                  'Sensitive details are covered in these public copies.',
                ),
              ],
            );
          },
        ),
      ],
    ),
  );
}
