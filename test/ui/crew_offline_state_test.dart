import 'dart:async';
import 'package:ecopin_app/features/field_crew/offline/fc_offline_package.dart';
import 'package:ecopin_app/features/field_crew/offline/fc_offline_package_notifier.dart';
import 'package:ecopin_app/features/field_crew/offline/fc_offline_package_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyntheticPackageService extends Fake implements FcOfflinePackageService {
  bool estimateFails = false;
  int downloads = 0;
  final completion = Completer<FcOfflinePackageState>();
  @override
  Future<int> estimateBytes() async {
    if (estimateFails) throw StateError('Synthetic estimate failure');
    return 2048;
  }

  @override
  Future<FcOfflinePackageState> download({
    required StepProgressCallback onStepProgress,
    required CountCallback onCountUpdate,
  }) {
    downloads++;
    onStepProgress(FcOfflineStepLabel.tasks, completed: true);
    onStepProgress(
      FcOfflineStepLabel.notes,
      completed: true,
      error: 'Network timed out',
    );
    return completion.future;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'completed preparation retains actual section failures and guards repeated preparation',
    () async {
      final service = SyntheticPackageService();
      final container = ProviderContainer(
        overrides: [fcOfflinePackageServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(
        fcOfflinePackageNotifierProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final pending = notifier.prepare();
      await Future<void>.delayed(Duration.zero);
      await notifier.prepare();
      expect(service.downloads, 1);
      service.completion.complete(
        FcOfflinePackageState(
          phase: FcOfflinePackagePhase.ready,
          taskCount: 2,
          preparedAt: DateTime(2026, 10, 14),
          steps: buildInitialSteps()
              .map((step) => step.copyWith(completed: true))
              .toList(),
        ),
      );
      await pending;
      final state = container.read(fcOfflinePackageNotifierProvider);
      expect(state.taskCount, 2);
      expect(
        state.steps
            .singleWhere((step) => step.label == FcOfflineStepLabel.notes)
            .error,
        'Network timed out',
      );
      expect(state.estimatedBytes, 2048);
    },
  );
  test(
    'failed estimation leaves a retryable failure instead of a locked preparation',
    () async {
      final service = SyntheticPackageService()..estimateFails = true;
      final container = ProviderContainer(
        overrides: [fcOfflinePackageServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(
        fcOfflinePackageNotifierProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      await notifier.prepare();
      final state = container.read(fcOfflinePackageNotifierProvider);
      expect(state.phase, FcOfflinePackagePhase.failed);
      expect(state.isDownloading, false);
      expect(state.errorMessage, isNot(contains('StateError')));
    },
  );
}
