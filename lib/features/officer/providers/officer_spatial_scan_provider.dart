import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:ecopin_app/core/services/api_service.dart';

class SpatialScanState {
  final Map<String, dynamic>? currentPredictions;
  final Map<String, dynamic>? accuracyMetrics;
  final bool isLoading;
  final bool isGenerating;
  final String? error;

  SpatialScanState({
    this.currentPredictions,
    this.accuracyMetrics,
    this.isLoading = false,
    this.isGenerating = false,
    this.error,
  });

  SpatialScanState copyWith({
    Map<String, dynamic>? currentPredictions,
    Map<String, dynamic>? accuracyMetrics,
    bool? isLoading,
    bool? isGenerating,
    String? error,
  }) {
    return SpatialScanState(
      currentPredictions: currentPredictions ?? this.currentPredictions,
      accuracyMetrics: accuracyMetrics ?? this.accuracyMetrics,
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
    );
  }
}

class SpatialScanNotifier extends ChangeNotifier {
  final ApiClient _apiClient;
  SpatialScanState _state = SpatialScanState();
  
  SpatialScanState get state => _state;

  SpatialScanNotifier(this._apiClient);

  Future<void> loadCurrentPredictions(String horizon) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();
    try {
      final response = await _apiClient.getCurrentSpatialForecast(horizon);
      final accuracyResponse = await _apiClient.getSpatialForecastAccuracy(timeHorizon: horizon);
      
      _state = _state.copyWith(
        isLoading: false,
        currentPredictions: response.data['data'] as Map<String, dynamic>?,
        accuracyMetrics: accuracyResponse.data['data'] as Map<String, dynamic>?,
      );
    } catch (e) {
      _state = _state.copyWith(isLoading: false, error: e.toString());
    }
    notifyListeners();
  }

  Future<void> generateForecast(String horizon) async {
    _state = _state.copyWith(isGenerating: true, error: null);
    notifyListeners();
    try {
      final response = await _apiClient.generateSpatialForecast(timeHorizon: horizon);
      final accuracyResponse = await _apiClient.getSpatialForecastAccuracy(timeHorizon: horizon);
      
      _state = _state.copyWith(
        isGenerating: false,
        currentPredictions: response.data['data'] as Map<String, dynamic>?,
        accuracyMetrics: accuracyResponse.data['data'] as Map<String, dynamic>?,
      );
    } catch (e) {
      _state = _state.copyWith(isGenerating: false, error: e.toString());
    }
    notifyListeners();
  }
}

final spatialScanProvider = ChangeNotifierProvider<SpatialScanNotifier>((ref) {
  return SpatialScanNotifier(ref.watch(apiClientProvider));
});
