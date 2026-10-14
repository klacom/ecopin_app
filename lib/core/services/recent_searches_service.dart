import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecopin_app/core/services/location_search_service.dart';

class RecentSearchesService {
  static const String _key = 'recent_searches';
  static const int _maxSearches = 10;

  Future<List<LocationSuggestion>> getRecentSearches({
    bool throwOnError = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final String? searchesJson = prefs.getString(_key);

    if (searchesJson == null) {
      return [];
    }

    try {
      final List<dynamic> decoded = json.decode(searchesJson);
      return decoded
          .map(
            (item) => LocationSuggestion.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (throwOnError) rethrow;
      return [];
    }
  }

  Future<void> saveSearch(LocationSuggestion suggestion) async {
    final prefs = await SharedPreferences.getInstance();
    final List<LocationSuggestion> currentSearches = await getRecentSearches(
      throwOnError: true,
    );

    // Remove if already exists to move it to the top
    currentSearches.removeWhere(
      (s) =>
          s.displayName == suggestion.displayName &&
          s.latLng.latitude == suggestion.latLng.latitude &&
          s.latLng.longitude == suggestion.latLng.longitude,
    );

    // Add to the beginning
    currentSearches.insert(0, suggestion);

    // Keep only the most recent N items
    if (currentSearches.length > _maxSearches) {
      currentSearches.removeRange(_maxSearches, currentSearches.length);
    }

    final String encoded = json.encode(
      currentSearches.map((s) => s.toJson()).toList(),
    );
    if (!await prefs.setString(_key, encoded)) {
      throw StateError('Recent search was not saved');
    }
  }

  Future<void> removeSearch(LocationSuggestion suggestion) async {
    final prefs = await SharedPreferences.getInstance();
    final List<LocationSuggestion> currentSearches = await getRecentSearches(
      throwOnError: true,
    );

    currentSearches.removeWhere(
      (s) =>
          s.displayName == suggestion.displayName &&
          s.latLng.latitude == suggestion.latLng.latitude &&
          s.latLng.longitude == suggestion.latLng.longitude,
    );

    final String encoded = json.encode(
      currentSearches.map((s) => s.toJson()).toList(),
    );
    if (!await prefs.setString(_key, encoded)) {
      throw StateError('Recent search was not removed');
    }
  }
}
