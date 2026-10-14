import 'dart:async';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/search_overlay.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/location_search_content.dart';
import 'package:ecopin_app/shared/maps/presentation/controllers/location_voice_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'location_search_controller_test.dart';

class RecordingSearchMap implements MapController {
  final moves = <(LatLng, double)>[];
  @override
  bool move(
    LatLng center,
    double zoom, {
    Offset offset = Offset.zero,
    String? id,
  }) {
    moves.add((center, zoom));
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> openSearch(
  WidgetTester tester, {
  required SyntheticPlaces places,
  required SyntheticRecents recents,
  required SyntheticVoice voice,
  RecordingSearchMap? map,
  bool large = false,
  Future<bool> Function()? settings,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(large ? 2 : 1)),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SearchOverlay(
                    mapController: map ?? RecordingSearchMap(),
                    searchService: places,
                    recentSearches: recents,
                    voiceBackend: voice,
                    openSettings: settings,
                  ),
                ),
              ),
              child: const Text('Open place search'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open place search'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'search failure, retry and clear keep query and recent places usable',
    (tester) async {
      final api = SyntheticPlaces(),
          recent = SyntheticRecents()..rows.add(place('Pasig City Hall'));
      final voice = SyntheticVoice();
      await openSearch(tester, places: api, recents: recent, voice: voice);
      expect(voice.preparations, 0);
      await tester.enterText(find.byType(TextField), 'Rosario');
      await tester.pump(const Duration(milliseconds: 300));
      api.pending.single.completeError(StateError('Synthetic offline search'));
      await tester.pumpAndSettle();
      expect(find.text('Place search unavailable'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Rosario',
      );
      await tester.ensureVisible(find.text('Retry search'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retry search'));
      await tester.pump();
      expect(api.queries.length, 2);
      api.pending.last.complete([]);
      await tester.pumpAndSettle();
      expect(find.text('No places found'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Clear place search'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Clear place search'));
      await tester.pumpAndSettle();
      expect(find.text('Pasig City Hall'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      expect(voice.cancellations, 1);
    },
  );
  testWidgets(
    'selection centers once and still opens the map if saving history fails',
    (tester) async {
      final recent = SyntheticRecents()
        ..rows.add(place('Pasig City Hall'))
        ..pendingSave = Completer<void>();
      final map = RecordingSearchMap();
      await openSearch(
        tester,
        places: SyntheticPlaces(),
        recents: recent,
        voice: SyntheticVoice(),
        map: map,
      );
      await tester.tap(find.text('Pasig City Hall'));
      await tester.pump();
      expect(map.moves, [(const LatLng(14.58, 121.08), 16.0)]);
      expect(recent.saves, 1);
      expect(
        tester
            .widget<LocationSearchPlaceRow>(find.byType(LocationSearchPlaceRow))
            .onSelect,
        isNull,
      );
      recent.pendingSave!.completeError(
        StateError('Synthetic storage failure'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Open place search'), findsOneWidget);
      expect(
        find.text(
          'Map opened. This place could not be saved to recent searches.',
        ),
        findsOneWidget,
      );
    },
  );
  testWidgets('history removal failure retains the place and can be retried', (
    tester,
  ) async {
    final recent = SyntheticRecents()
      ..rows.add(place('Pasig City Hall'))
      ..removeFails = true;
    await openSearch(
      tester,
      places: SyntheticPlaces(),
      recents: recent,
      voice: SyntheticVoice(),
    );
    await tester.tap(
      find.byTooltip('Remove Pasig City Hall from recent places'),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Could not remove this recent place. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Pasig City Hall'), findsOneWidget);
    recent.removeFails = false;
    await tester.ensureVisible(
      find.byTooltip('Remove Pasig City Hall from recent places'),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byTooltip('Remove Pasig City Hall from recent places'),
    );
    await tester.pumpAndSettle();
    expect(recent.removals, 2);
    expect(find.text('Pasig City Hall'), findsNothing);
  });
  testWidgets(
    'voice permission and settings recovery fit 320px/2x above the keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final voice = SyntheticVoice()
        ..availability = VoiceAvailability.permissionDenied;
      await openSearch(
        tester,
        places: SyntheticPlaces(),
        recents: SyntheticRecents(),
        voice: voice,
        large: true,
        settings: () async => false,
      );
      await tester.ensureVisible(find.text('Use voice search'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use voice search'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Microphone or speech access is denied. Type a place or check device permissions.',
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Open device settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open device settings'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Device settings could not open. You can still type a place.',
        ),
        findsOneWidget,
      );
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
