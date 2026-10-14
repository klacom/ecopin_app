import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:ecopin_app/core/services/location_search_service.dart';
import 'package:ecopin_app/core/services/recent_searches_service.dart';
import 'location_voice_controller.dart';

class LocationSearchController extends ChangeNotifier {
  LocationSearchController({
    LocationSearchService? searchService,
    RecentSearchesService? recentSearches,
    LocationVoiceBackend? voiceBackend,
  }) : _search = searchService ?? LocationSearchService(),
       _recent = recentSearches ?? RecentSearchesService() {
    voice = LocationVoiceController(
      voiceBackend ?? DeviceLocationVoice(),
      (words) => search(words, fromVoice: true),
    );
    voice.addListener(_changed);
    unawaited(loadRecents());
  }
  final LocationSearchService _search;
  final RecentSearchesService _recent;
  late final LocationVoiceController voice;
  Timer? _debounce;
  int _generation = 0, _recentGeneration = 0;
  int? _activeRequest;
  bool _disposed = false;
  String query = '';
  bool isSearching = false, loadingRecents = true;
  String? searchError, recentError;
  List<LocationSuggestion> _suggestions = [], _recents = [];
  final Set<LocationSuggestion> removing = {};
  List<LocationSuggestion> get suggestions => List.unmodifiable(_suggestions);
  List<LocationSuggestion> get recents => List.unmodifiable(_recents);
  bool get hasQuery => query.trim().length >= 2;
  void _changed() {
    if (!_disposed) notifyListeners();
  }

  void search(String value, {bool fromVoice = false}) {
    if (_disposed) return;
    if (!fromVoice) voice.ignoreResults();
    query = value;
    _debounce?.cancel();
    _debounce = null;
    final generation = ++_generation;
    searchError = null;
    _suggestions = [];
    _activeRequest = null;
    isSearching = hasQuery;
    _changed();
    if (!hasQuery) return;
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _debounce = null;
      unawaited(_perform(query.trim(), generation));
    });
  }

  void searchNow() {
    if (!hasQuery || _disposed || _activeRequest == _generation) return;
    _debounce?.cancel();
    _debounce = null;
    unawaited(_perform(query.trim(), _generation));
  }

  Future<void> _perform(String value, int generation) async {
    _activeRequest = generation;
    isSearching = true;
    searchError = null;
    _changed();
    try {
      final rows = await _search.searchLocations(value, throwOnError: true);
      if (_disposed || generation != _generation) return;
      _suggestions = rows;
    } catch (_) {
      if (_disposed || generation != _generation) return;
      searchError =
          'Could not search for places. Check your connection and try again.';
    } finally {
      if (!_disposed && generation == _generation) {
        _activeRequest = null;
        isSearching = false;
        _changed();
      }
    }
  }

  Future<void> loadRecents() async {
    final generation = ++_recentGeneration;
    loadingRecents = true;
    recentError = null;
    _changed();
    try {
      final rows = await _recent.getRecentSearches(throwOnError: true);
      if (!_disposed && generation == _recentGeneration) _recents = rows;
    } catch (_) {
      if (!_disposed && generation == _recentGeneration) {
        recentError =
            'Recent places are unavailable. You can still search for a place.';
      }
    } finally {
      if (!_disposed && generation == _recentGeneration) {
        loadingRecents = false;
        _changed();
      }
    }
  }

  Future<void> removeRecent(LocationSuggestion suggestion) async {
    if (_disposed || removing.isNotEmpty) return;
    removing.add(suggestion);
    ++_recentGeneration;
    recentError = null;
    _changed();
    try {
      await _recent.removeSearch(suggestion);
      if (!_disposed) await loadRecents();
    } catch (_) {
      if (!_disposed) {
        recentError = 'Could not remove this recent place. Please try again.';
      }
    } finally {
      if (!_disposed) {
        removing.remove(suggestion);
        _changed();
      }
    }
  }

  Future<bool> remember(LocationSuggestion suggestion) async {
    try {
      await _recent.saveSearch(suggestion);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _recentGeneration++;
    _debounce?.cancel();
    voice.removeListener(_changed);
    voice.dispose();
    super.dispose();
  }
}
