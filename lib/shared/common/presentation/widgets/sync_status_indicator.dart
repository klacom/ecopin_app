import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/core/database/app_database.dart';

final pendingSyncCountProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);
  final reports = await db.getPendingReports();
  final taskUpdates = await db.getPendingTaskUpdates();
  return reports.length + taskUpdates.length;
});

class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(pendingSyncCountProvider);

    return pendingCount.when(
      data: (count) {
        if (count == 0) return const SizedBox.shrink();
        
        return Tooltip(
          message: '$count pending sync items',
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.cloud_upload_outlined, color: Colors.grey),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
