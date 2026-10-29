import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/core/services/api_service.dart';

final myCrewPerformanceProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  try {
    final client = ref.watch(apiClientProvider);
    final response = await client.getMyCrewPerformance();
    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
  } catch (_) {
    // Offline or network error gracefully handled
  }
  return {};
});
