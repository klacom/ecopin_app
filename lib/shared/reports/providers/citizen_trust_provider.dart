import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/shared/reports/data/models/citizen_trust.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/core/database/app_database.dart';

final blockedUrgentReportsProvider =
    StreamProvider.autoDispose<List<OfflineReport>>((ref) {
      final ownerId = ref.watch(apiClientProvider).currentUserId;
      if (ownerId == null) return Stream.value([]);
      return ref.watch(databaseProvider).watchBlockedUrgentReports(ownerId);
    });

final citizenTrustProvider = FutureProvider.autoDispose<CitizenTrust>((
  ref,
) async {
  final response = await ref.watch(apiClientProvider).getCitizenTrust();
  final trust = CitizenTrust.fromJson(Map<String, dynamic>.from(response.data));
  // Keep a successful status between screens for offline drafts; auth clears it.
  ref.keepAlive();
  return trust;
});

final reportTrustReviewProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, id) async {
      final response = await ref
          .watch(apiClientProvider)
          .getCitizenTrustReview(id);
      return Map<String, dynamic>.from(response.data);
    });
