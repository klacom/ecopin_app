import 'dart:async';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/fc_local_photo_repository.dart';
import 'package:ecopin_app/features/field_crew/offline/fc_offline_package.dart';
import 'package:ecopin_app/features/field_crew/offline/fc_offline_package_notifier.dart';
import 'package:ecopin_app/features/field_crew/presentation/controllers/fc_sync_ui_providers.dart';
import 'package:ecopin_app/features/field_crew/presentation/screens/field_crew_prepare_offline_screen.dart';
import 'package:ecopin_app/features/field_crew/presentation/screens/field_crew_sync_center_screen.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_conflict_summary.dart';
import 'package:ecopin_app/features/field_crew/providers/fc_local_repository_provider.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_photo_sync_manager.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_gate.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_result.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_settings.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_trigger.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const pendingCrewWork = FcPendingSummary(
  mutationCount: 2,
  photoCount: 3,
  failedPhotoCount: 1,
  pendingDeleteCount: 1,
  estimatedBytes: 2048,
);
const crewRun = FcSyncRunResult(
  total: 4,
  succeeded: 1,
  merged: 1,
  conflicted: 1,
  retryable: 1,
  permanent: 1,
  results: [
    FcOpResult(operationId: 'synthetic-merge', status: FcOpStatus.merged),
    FcOpResult(
      operationId: 'synthetic-review',
      status: FcOpStatus.verificationRequired,
    ),
  ],
);
const crewPhotos = FcPhotoSyncRunResult(
  uploadAttempted: 3,
  uploadSucceeded: 2,
  uploadFailed: 1,
  deleteAttempted: 1,
  deleteSucceeded: 0,
  deleteFailed: 1,
);

class SyntheticCrewGate extends Fake implements FcSyncGate {
  FcPendingSummary summary = pendingCrewWork;
  bool failSummary = false;
  int reads = 0, checks = 0;
  FcGateDecision decision = FcGateDecision.allow(FcNetworkType.wifi);
  @override
  Future<FcPendingSummary> getPendingSummary() async {
    reads++;
    if (failSummary) throw StateError('Synthetic queue read failure');
    return summary;
  }

  @override
  Future<FcGateDecision> checkManualCommit() async {
    checks++;
    return decision;
  }
}

class SyntheticCrewTrigger extends Fake implements FcSyncTrigger {
  int commits = 0;
  final completion = Completer<FcSyncState?>();
  @override
  Future<FcSyncState?> manualCommit() {
    commits++;
    return completion.future;
  }
}

class SyntheticCrewPhotos extends Fake implements FcLocalPhotoRepository {
  int resets = 0;
  bool fail = true;
  Completer<void>? completion;
  @override
  Future<void> resetFailedPhotoRetries() async {
    resets++;
    if (fail) throw StateError('Synthetic reset failure');
    await completion?.future;
  }
}

class SyntheticCrewSettings extends FcSyncSettingsNotifier {
  SyntheticCrewSettings([
    this.initial = const FcSyncSettings(
      mode: FcSyncMode.manualCommit,
      syncOverMobileData: true,
    ),
  ]);
  final FcSyncSettings initial;
  bool fail = false;
  @override
  FcSyncSettings build() => initial;
  @override
  Future<void> setMode(FcSyncMode value) async {
    if (fail) throw StateError('Synthetic settings failure');
    state = state.copyWith(mode: value);
  }

  @override
  Future<void> setSyncOverWifi(bool value) async =>
      state = state.copyWith(syncOverWifi: value);
  @override
  Future<void> setSyncOverMobileData(bool value) async =>
      state = state.copyWith(syncOverMobileData: value);
}

class SyntheticCrewPackage extends FcOfflinePackageNotifier {
  SyntheticCrewPackage(this.initial);
  final FcOfflinePackageState initial;
  int prepares = 0;
  final completion = Completer<FcOfflinePackageState>();
  @override
  FcOfflinePackageState build() => initial;
  @override
  Future<void> prepare() async {
    if (state.isDownloading) return;
    prepares++;
    state = state.copyWith(phase: FcOfflinePackagePhase.downloading);
    state = await completion.future;
  }
}

FcOfflinePackageState crewPackage({
  bool partial = true,
  bool receiptOnly = false,
}) => FcOfflinePackageState(
  phase: FcOfflinePackagePhase.ready,
  taskCount: 2,
  reportCount: 8,
  evidenceCount: 12,
  noteCount: 3,
  routeCount: 1,
  taskTitles: const ['Saved cleanup task'],
  reportTitles: const ['Saved assigned report'],
  preparedAt: DateTime.utc(2026, 10, 14, 1, 30),
  estimatedBytes: 102400,
  steps: receiptOnly
      ? []
      : buildInitialSteps()
            .map(
              (step) => step.copyWith(
                completed: true,
                error: partial && step.label == FcOfflineStepLabel.notes
                    ? 'Network timed out'
                    : null,
              ),
            )
            .toList(),
);

Future<ProviderContainer> mountCrew(
  WidgetTester tester,
  Widget screen, {
  SyntheticCrewGate? gate,
  SyntheticCrewTrigger? trigger,
  SyntheticCrewPhotos? photos,
  SyntheticCrewSettings? settings,
  SyntheticCrewPackage? package,
  bool dark = false,
  double scale = 2,
  Size size = const Size(320, 700),
  FcNetworkType network = FcNetworkType.wifi,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        fcPendingWritesProvider.overrideWith((ref) => Stream.value([])),
        fcSyncGateProvider.overrideWithValue(gate ?? SyntheticCrewGate()),
        fcSyncTriggerProvider.overrideWithValue(
          trigger ?? SyntheticCrewTrigger(),
        ),
        fcLocalPhotoRepositoryProvider.overrideWithValue(
          photos ?? SyntheticCrewPhotos(),
        ),
        fcSyncNetworkProvider.overrideWith((ref) => Stream.value(network)),
        fcSyncSettingsProvider.overrideWith(
          () => settings ?? SyntheticCrewSettings(),
        ),
        fcOfflinePackageNotifierProvider.overrideWith(
          () => package ?? SyntheticCrewPackage(crewPackage()),
        ),
      ],
      child: MaterialApp(
        theme: dark ? AppTheme.dark : AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            padding: const EdgeInsets.only(bottom: 24),
          ),
          child: RepaintBoundary(
            key: const Key('crew-offline-preview'),
            child: child!,
          ),
        ),
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(
    tester.element(find.byType(screen.runtimeType)),
  );
}

void main() {
  testWidgets('queue failure has recovery and never presents an empty queue', (
    tester,
  ) async {
    final gate = SyntheticCrewGate()..failSummary = true;
    await mountCrew(tester, const FieldCrewSyncCenterScreen(), gate: gate);
    expect(find.text('No local items waiting to sync.'), findsNothing);
    expect(
      tester
          .widget<AppButton>(find.widgetWithText(AppButton, 'Commit changes'))
          .onPressed,
      isNull,
    );
    gate.failSummary = false;
    await tester.ensureVisible(find.text('Retry queue counts'));
    await tester.tap(find.text('Retry queue counts'));
    await tester.pumpAndSettle();
    expect(gate.reads, 2);
    expect(find.text('Items waiting to sync'), findsOneWidget);
    expect(find.text('Photo removals'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'mobile commit asks permission, retains cancel, and locks repeated commits',
    (tester) async {
      final gate = SyntheticCrewGate()
        ..decision = FcGateDecision.allow(FcNetworkType.mobile, confirm: true);
      final trigger = SyntheticCrewTrigger();
      await mountCrew(
        tester,
        const FieldCrewSyncCenterScreen(),
        gate: gate,
        trigger: trigger,
        network: FcNetworkType.mobile,
      );
      await tester.ensureVisible(find.text('Commit changes'));
      await tester.tap(find.text('Commit changes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(trigger.commits, 0);
      await tester.tap(find.text('Commit changes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.ensureVisible(find.text('Use mobile data'));
      await tester.tap(find.text('Use mobile data'));
      await tester.pump();
      expect(trigger.commits, 1);
      expect(
        tester.widget<AppButton>(find.byType(AppButton).last).onPressed,
        isNull,
      );
      trigger.completion.complete(
        const FcSyncState(phase: FcSyncPhase.success),
      );
      await tester.pumpAndSettle();
      expect(trigger.commits, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'photo retry failure remains visible and successful reset does not claim upload',
    (tester) async {
      final photos = SyntheticCrewPhotos();
      await mountCrew(
        tester,
        const FieldCrewSyncCenterScreen(),
        photos: photos,
      );
      await tester.ensureVisible(find.text('Reset failed photo retries'));
      await tester.tap(find.text('Reset failed photo retries'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Photo retries could not reset. No upload has been confirmed. Please try again.',
        ),
        findsOneWidget,
      );
      photos.fail = false;
      photos.completion = Completer<void>();
      await tester.ensureVisible(find.text('Reset failed photo retries'));
      await tester.tap(find.text('Reset failed photo retries'));
      await tester.pump();
      expect(photos.resets, 2);
      expect(
        tester.widget<AppButton>(find.byType(AppButton).first).onPressed,
        isNull,
      );
      photos.completion!.complete();
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Photo retries reset. The photos remain queued until a sync runs on an allowed connection.',
        ),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'partial run includes photos and review messages remain until dismissed',
    (tester) async {
      final container = await mountCrew(
        tester,
        const FieldCrewSyncCenterScreen(),
        dark: true,
      );
      container
          .read(fcSyncStateProvider.notifier)
          .setResult(crewRun, crewPhotos);
      await tester.pumpAndSettle();
      expect(find.text('Photos uploaded'), findsOneWidget);
      expect(find.text('Photo removals that failed'), findsOneWidget);
      expect(find.text('All changes synced'), findsNothing);
      await tester.ensureVisible(find.byType(FcResponseUpdates));
      await tester.pump(const Duration(seconds: 20));
      expect(find.text('Response updates'), findsOneWidget);
      final dismiss = find.byTooltip('Dismiss response updates');
      await tester.ensureVisible(dismiss);
      expect(tester.getSize(dismiss).width, greaterThanOrEqualTo(48));
      await tester.tap(dismiss);
      await tester.pumpAndSettle();
      expect(find.byType(FcResponseUpdates), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'settings failure retains prior mode and offline mode explains the blocked commit',
    (tester) async {
      final settings = SyntheticCrewSettings()..fail = true;
      final container = await mountCrew(
        tester,
        const FieldCrewSyncCenterScreen(),
        settings: settings,
      );
      await tester.ensureVisible(find.text('Offline Only'));
      await tester.tap(find.text('Offline Only'));
      await tester.pumpAndSettle();
      expect(
        container.read(fcSyncSettingsProvider).mode,
        FcSyncMode.manualCommit,
      );
      expect(
        find.text(
          'Sync preferences could not save. Your previous setting remains. Please try again.',
        ),
        findsOneWidget,
      );
      settings.fail = false;
      await tester.tap(find.text('Offline Only'));
      await tester.pumpAndSettle();
      expect(
        container.read(fcSyncSettingsProvider).mode,
        FcSyncMode.offlineOnly,
      );
      expect(
        tester
            .widget<AppButton>(find.widgetWithText(AppButton, 'Commit changes'))
            .onPressed,
        isNull,
      );
      expect(
        find.text(
          'Offline Only pauses syncing. Change mode below before committing queued work.',
        ),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'preparation gaps and explicit download scope remain clear at 320px/2x',
    (tester) async {
      final package = SyntheticCrewPackage(crewPackage());
      await mountCrew(
        tester,
        const FieldCrewPrepareOfflineScreen(),
        package: package,
      );
      expect(find.text('Prepared with gaps'), findsOneWidget);
      expect(find.text('Evidence metadata records cached'), findsOneWidget);
      await tester.ensureVisible(find.text('Update offline package'));
      await tester.tap(find.text('Update offline package'));
      await tester.pump();
      expect(package.prepares, 1);
      expect(
        tester.widget<AppButton>(find.byType(AppButton).first).onPressed,
        isNull,
      );
      package.completion.complete(crewPackage(partial: false));
      await tester.pumpAndSettle();
      expect(find.text('Offline data prepared'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'saved offline inventory lists actual prepared tasks and reports',
    (tester) async {
      await mountCrew(
        tester,
        const FieldCrewPrepareOfflineScreen(),
        package: SyntheticCrewPackage(crewPackage(partial: false)),
      );
      await tester.ensureVisible(find.text('Saved on this device'));
      await tester.tap(find.text('Saved on this device'));
      await tester.pumpAndSettle();
      expect(find.text('Saved cleanup task'), findsOneWidget);
      expect(find.text('Saved assigned report'), findsOneWidget);
      expect(find.text('Routes cached'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'restored receipt does not claim all preparation steps were verified',
    (tester) async {
      await mountCrew(
        tester,
        const FieldCrewPrepareOfflineScreen(),
        package: SyntheticCrewPackage(crewPackage(receiptOnly: true)),
      );
      expect(find.text('Previously cached work'), findsOneWidget);
      expect(find.text('Offline data prepared'), findsNothing);
      expect(
        find.textContaining('earlier preparation receipt'),
        findsOneWidget,
      );
    },
  );
}
