import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:ecopin_app/core/services/api_service.dart';

class OptimizationState {
  final List<dynamic> runs;
  final bool isLoading;
  final bool isGenerating;
  final String? error;

  OptimizationState({
    this.runs = const [],
    this.isLoading = false,
    this.isGenerating = false,
    this.error,
  });

  OptimizationState copyWith({
    List<dynamic>? runs,
    bool? isLoading,
    bool? isGenerating,
    String? error,
  }) {
    return OptimizationState(
      runs: runs ?? this.runs,
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
    );
  }
}

class OptimizationNotifier extends ChangeNotifier {
  final ApiClient _apiClient;
  OptimizationState _state = OptimizationState();
  
  OptimizationState get state => _state;

  OptimizationNotifier(this._apiClient) {
    loadRuns();
  }

  Future<void> loadRuns() async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();
    try {
      final response = await _apiClient.getOptimizationRuns();
      final data = response.data['data'] as List<dynamic>? ?? [];
      _state = _state.copyWith(isLoading: false, runs: data);
    } catch (e) {
      _state = _state.copyWith(isLoading: false, error: e.toString());
    }
    notifyListeners();
  }

  Future<void> runOptimization(Map<String, dynamic> params) async {
    _state = _state.copyWith(isGenerating: true, error: null);
    notifyListeners();
    try {
      await _apiClient.runOptimization(params);
      await loadRuns();
    } catch (e) {
      _state = _state.copyWith(isGenerating: false, error: e.toString());
    } finally {
      _state = _state.copyWith(isGenerating: false);
      notifyListeners();
    }
  }

  Future<void> approveRun(String id) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();
    try {
      await _apiClient.approveOptimization(id);
      await loadRuns();
    } catch (e) {
      _state = _state.copyWith(isLoading: false, error: e.toString());
      notifyListeners();
    }
  }

  Future<void> discardRun(String id) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();
    try {
      await _apiClient.discardOptimization(id);
      await loadRuns();
    } catch (e) {
      _state = _state.copyWith(isLoading: false, error: e.toString());
      notifyListeners();
    }
  }
}

final optimizationProvider = ChangeNotifierProvider<OptimizationNotifier>((ref) {
  return OptimizationNotifier(ref.watch(apiClientProvider));
});
