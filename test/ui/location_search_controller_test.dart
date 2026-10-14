import 'dart:async';
import 'package:ecopin_app/core/services/location_search_service.dart';
import 'package:ecopin_app/core/services/recent_searches_service.dart';
import 'package:ecopin_app/shared/maps/presentation/controllers/location_search_controller.dart';
import 'package:ecopin_app/shared/maps/presentation/controllers/location_voice_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

class SyntheticPlaces extends LocationSearchService {
  final queries = <String>[];
  final strictRequests = <bool>[];
  final pending = <Completer<List<LocationSuggestion>>>[];
  @override
  Future<List<LocationSuggestion>> searchLocations(
    String query, {
    String country = 'Philippines',
    String? city,
    bool throwOnError = false,
  }) {
    strictRequests.add(throwOnError);
    queries.add(query);
    final response = Completer<List<LocationSuggestion>>();
    pending.add(response);
    return response.future;
  }
}

class SyntheticRecents extends RecentSearchesService {
  bool loadFails = false, removeFails = false, saveFails = false;
  int removals = 0;
  int saves = 0;
  Completer<void>? pendingSave;
  final rows = <LocationSuggestion>[];
  @override
  Future<List<LocationSuggestion>> getRecentSearches({
    bool throwOnError = false,
  }) async {
    if (loadFails) throw StateError('Synthetic history failure');
    return List.of(rows);
  }

  @override
  Future<void> removeSearch(LocationSuggestion suggestion) async {
    removals++;
    if (removeFails) throw StateError('Synthetic removal failure');
    rows.remove(suggestion);
  }

  @override
  Future<void> saveSearch(LocationSuggestion suggestion) async {
    saves++;
    if (saveFails) throw StateError('Synthetic storage failure');
    if (pendingSave != null) await pendingSave!.future;
    rows.insert(0, suggestion);
  }
}

class SyntheticVoice implements LocationVoiceBackend {
  VoiceAvailability availability = VoiceAvailability.ready;
  int preparations = 0, listens = 0, cancellations = 0;
  bool stopFails = false;
  void Function(String)? words, status;
  void Function(String, bool)? error;
  @override
  Future<VoiceAvailability> prepare({
    required void Function(String) onStatus,
    required void Function(String, bool) onError,
  }) async {
    preparations++;
    status = onStatus;
    error = onError;
    return availability;
  }

  @override
  Future<void> listen(void Function(String) onWords) async {
    listens++;
    words = onWords;
  }

  @override
  Future<void> stop() async {
    if (stopFails) throw StateError('Synthetic stop failure');
    status?.call('done');
  }

  @override
  Future<void> release() async {
    cancellations++;
  }
}

LocationSuggestion place(String name) =>
    LocationSuggestion(displayName: name, latLng: const LatLng(14.58, 121.08));

void main() {
  testWidgets(
    'one 300ms debounce, request ordering and clear invalidate older results',
    (tester) async {
      final api = SyntheticPlaces(), recents = SyntheticRecents();
      final model = LocationSearchController(
        searchService: api,
        recentSearches: recents,
        voiceBackend: SyntheticVoice(),
      );
      addTearDown(model.dispose);
      model.search('Pasig');
      expect(model.hasQuery, isTrue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 299));
      expect(api.queries, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      expect(api.queries, ['Pasig']);
      expect(api.strictRequests, [true]);
      model.search('Rosario');
      await tester.pump(const Duration(milliseconds: 300));
      api.pending[1].complete([place('New Rosario result')]);
      await tester.pump();
      api.pending[0].complete([place('Old Pasig result')]);
      await tester.pump();
      expect(model.suggestions.single.displayName, 'New Rosario result');
      model.search('Kapitolyo');
      await tester.pump(const Duration(milliseconds: 300));
      model.search('');
      api.pending.last.complete([place('Cleared result')]);
      await tester.pump();
      expect(model.suggestions, isEmpty);
      expect(model.isSearching, isFalse);
    },
  );
  testWidgets(
    'failure is recoverable without pretending no results or adding a retry delay',
    (tester) async {
      final api = SyntheticPlaces();
      final model = LocationSearchController(
        searchService: api,
        recentSearches: SyntheticRecents(),
        voiceBackend: SyntheticVoice(),
      );
      addTearDown(model.dispose);
      model.search('Ortigas');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      api.pending.last.completeError(StateError('Synthetic search failure'));
      await tester.pump();
      expect(model.searchError, isNotNull);
      expect(model.query, 'Ortigas');
      model.searchNow();
      expect(api.queries.length, 2);
      model.searchNow();
      expect(api.queries.length, 2);
      api.pending.last.complete([]);
      await tester.pump();
      expect(model.searchError, isNull);
      expect(model.suggestions, isEmpty);
    },
  );
  testWidgets('history errors retain records and have a working retry', (
    tester,
  ) async {
    final recent = SyntheticRecents()..loadFails = true;
    final model = LocationSearchController(
      searchService: SyntheticPlaces(),
      recentSearches: recent,
      voiceBackend: SyntheticVoice(),
    );
    addTearDown(model.dispose);
    await tester.pump();
    expect(model.recentError, isNotNull);
    recent.loadFails = false;
    recent.rows.add(place('Pasig City Hall'));
    await model.loadRecents();
    expect(model.recents, hasLength(1));
    recent.removeFails = true;
    await model.removeRecent(model.recents.first);
    expect(model.recents, hasLength(1));
    expect(model.recentError, isNotNull);
    recent.saveFails = true;
    expect(await model.remember(place('New place')), isFalse);
  });
  testWidgets(
    'voice asks only on explicit use and denied access keeps typed search available',
    (tester) async {
      final voice = SyntheticVoice()
        ..availability = VoiceAvailability.permissionDenied;
      final model = LocationSearchController(
        searchService: SyntheticPlaces(),
        recentSearches: SyntheticRecents(),
        voiceBackend: voice,
      );
      addTearDown(model.dispose);
      await tester.pump();
      expect(voice.preparations, 0);
      await model.voice.toggle();
      expect(voice.preparations, 1);
      expect(model.voice.listening, isFalse);
      expect(model.voice.canOpenSettings, isTrue);
      expect(model.voice.error, isNotNull);
      model.search('Pasig');
      expect(model.query, 'Pasig');
      model.search('');
    },
  );
  testWidgets(
    'voice updates use the same debounce and stop failure remains honest',
    (tester) async {
      final api = SyntheticPlaces(), voice = SyntheticVoice();
      final model = LocationSearchController(
        searchService: api,
        recentSearches: SyntheticRecents(),
        voiceBackend: voice,
      );
      await model.voice.toggle();
      expect(model.voice.listening, isTrue);
      voice.words!('Pasig Palengke');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 299));
      expect(api.queries, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      expect(api.queries, ['Pasig Palengke']);
      voice.stopFails = true;
      await model.voice.toggle();
      expect(model.voice.listening, isTrue);
      expect(model.voice.error, isNotNull);
      model.dispose();
      voice.words!('A late result');
      await tester.pump();
      expect(voice.cancellations, 1);
      api.pending.single.complete([]);
      await tester.pump();
    },
  );
}
