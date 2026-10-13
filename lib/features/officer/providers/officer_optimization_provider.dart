import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:ecopin_app/core/services/api_service.dart';

String formatOperationalReason(String? reason) {
  switch (reason) {
    case 'insufficient_capacity':
    case 'cap_time':
    case 'shift_exceeded':
      return 'Shift capacity full · queued for next shift';
    case 'cap_volume':
    case 'capacity_volume':
      return 'Vehicle volume full · queued for next shift';
    case 'cap_weight':
    case 'capacity_weight':
      return 'Vehicle weight full · queued for next shift';
    case 'outside_buffer':
      return 'Outside route cluster radius';
    case 'cap_detour':
      return 'Detour limit reached · queued for next shift';
    case 'hazard_review':
      return 'Requires safety/hazard review';
    case 'no_capable_crew':
      return 'No qualified crew available on shift';
    case 'unknown_load':
      return 'Awaiting vehicle assignment · queued for next shift';
    case 'deferred_by_compute_limit':
      return 'Queued in backlog';
    default:
      return 'Retained in backlog for next shift';
  }
}

class OptimizationState {
  final List<dynamic> runs;
  final List<dynamic> templates;
  final bool isLoading;
  final bool isGenerating;
  final bool isCommitting;
  final bool isDisassembling;
  final int solverProgress;
  final String solverMessage;
  final Map<String, dynamic>? draftPlan;
  final List<dynamic> proposedRoutes;
  final Map<String, dynamic>? capacity;
  final List<dynamic> rejectedBundles;
  final String? error;

  OptimizationState({
    this.runs = const [],
    this.templates = const [],
    this.isLoading = false,
    this.isGenerating = false,
    this.isCommitting = false,
    this.isDisassembling = false,
    this.solverProgress = 0,
    this.solverMessage = '',
    this.draftPlan,
    this.proposedRoutes = const [],
    this.capacity,
    this.rejectedBundles = const [],
    this.error,
  });

  OptimizationState copyWith({
    List<dynamic>? runs,
    List<dynamic>? templates,
    bool? isLoading,
    bool? isGenerating,
    bool? isCommitting,
    bool? isDisassembling,
    int? solverProgress,
    String? solverMessage,
    Map<String, dynamic>? draftPlan,
    bool clearDraftPlan = false,
    List<dynamic>? proposedRoutes,
    Map<String, dynamic>? capacity,
    List<dynamic>? rejectedBundles,
    String? error,
  }) {
    return OptimizationState(
      runs: runs ?? this.runs,
      templates: templates ?? this.templates,
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      isCommitting: isCommitting ?? this.isCommitting,
      isDisassembling: isDisassembling ?? this.isDisassembling,
      solverProgress: solverProgress ?? this.solverProgress,
      solverMessage: solverMessage ?? this.solverMessage,
      draftPlan: clearDraftPlan ? null : (draftPlan ?? this.draftPlan),
      proposedRoutes: clearDraftPlan ? const [] : (proposedRoutes ?? this.proposedRoutes),
      capacity: clearDraftPlan ? null : (capacity ?? this.capacity),
      rejectedBundles: clearDraftPlan ? const [] : (rejectedBundles ?? this.rejectedBundles),
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
    loadTemplates();
  }

  Future<void> loadRuns() async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();
    try {
      final response = await _apiClient.getOptimizationRuns();
      final dynamic raw = response.data;
      List<dynamic> data = [];
      if (raw is Map<String, dynamic>) {
        data = raw['data'] as List<dynamic>? ?? raw['runs'] as List<dynamic>? ?? [];
      } else if (raw is List<dynamic>) {
        data = raw;
      }
      _state = _state.copyWith(isLoading: false, runs: data);
    } catch (e) {
      _state = _state.copyWith(isLoading: false, error: e.toString());
    }
    notifyListeners();
  }

  Future<void> loadTemplates() async {
    try {
      final response = await _apiClient.getOptimizationTemplates();
      final data = response.data is List ? response.data as List<dynamic> : [];
      _state = _state.copyWith(templates: data);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> startPlanningJob(Map<String, dynamic> settings) async {
    _state = _state.copyWith(
      isGenerating: true,
      solverProgress: 20,
      solverMessage: 'Planning job queued...',
      error: null,
      clearDraftPlan: true,
    );
    notifyListeners();

    try {
      final queueResp = await _apiClient.generatePlan(settings);
      final queueData = queueResp.data as Map<String, dynamic>? ?? {};
      final jobId = queueData['jobId']?.toString();
      if (jobId == null) throw Exception('Planning solver returned no Job ID');

      var status = queueData['status']?.toString() ?? 'queued';
      String? planId;

      while (status != 'completed' && status != 'failed') {
        await Future.delayed(const Duration(seconds: 2));
        final jobResp = await _apiClient.getPlanJob(jobId);
        final jobData = jobResp.data as Map<String, dynamic>? ?? {};
        status = jobData['status']?.toString() ?? 'queued';
        planId = jobData['planId']?.toString();

        if (status == 'running') {
          _state = _state.copyWith(
            solverProgress: 65,
            solverMessage: 'Solver is building routes...',
          );
        } else {
          _state = _state.copyWith(
            solverProgress: 35,
            solverMessage: 'Solver processing queue...',
          );
        }
        notifyListeners();
      }

      if (status == 'failed') {
        throw Exception('Planning solver failed to build an optimal route.');
      }

      if (planId == null) {
        throw Exception('Completed planning job contains no draft plan ID.');
      }

      _state = _state.copyWith(
        solverProgress: 90,
        solverMessage: 'Retrieving draft dispatch plan...',
      );
      notifyListeners();

      final planResp = await _apiClient.getDispatchPlan(planId);
      final planData = planResp.data as Map<String, dynamic>? ?? {};

      final proposedRoutes = planData['proposedRoutes'] as List<dynamic>? ?? [];
      final capacity = planData['capacity'] as Map<String, dynamic>?;
      final rejectedBundles = planData['rejectedBundles'] as List<dynamic>? ?? [];

      _state = _state.copyWith(
        isGenerating: false,
        solverProgress: 100,
        solverMessage: 'Draft plan generated successfully',
        draftPlan: planData['plan'] as Map<String, dynamic>?,
        proposedRoutes: proposedRoutes,
        capacity: capacity,
        rejectedBundles: rejectedBundles,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isGenerating: false,
        solverProgress: 0,
        solverMessage: '',
        error: e.toString(),
      );
      notifyListeners();
    }
  }

  Future<bool> commitDraft(String planId) async {
    _state = _state.copyWith(isCommitting: true, error: null);
    notifyListeners();
    try {
      await _apiClient.commitPlan(planId);
      _state = _state.copyWith(
        isCommitting: false,
        clearDraftPlan: true,
      );
      await loadRuns();
      return true;
    } catch (e) {
      _state = _state.copyWith(isCommitting: false, error: e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<bool> disassemble(String runOrPlanId, [String? reason]) async {
    _state = _state.copyWith(isDisassembling: true, error: null);
    notifyListeners();
    try {
      await _apiClient.disassemblePlan(
        runOrPlanId,
        {'reason': reason ?? 'Disassembled via mobile officer command'},
      );
      _state = _state.copyWith(
        isDisassembling: false,
        clearDraftPlan: true,
      );
      await loadRuns();
      return true;
    } catch (e) {
      _state = _state.copyWith(isDisassembling: false, error: e.toString());
      notifyListeners();
      return false;
    }
  }

  void clearDraft() {
    _state = _state.copyWith(clearDraftPlan: true);
    notifyListeners();
  }
}

final optimizationProvider =
    ChangeNotifierProvider<OptimizationNotifier>((ref) {
  return OptimizationNotifier(ref.watch(apiClientProvider));
});
