import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:ecopin_app/core/services/location_search_service.dart';
import 'package:ecopin_app/core/services/recent_searches_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'location_search_controller_test.dart' show place;

class SearchResponseAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  int status = 200;
  Object body = <dynamic>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'place search preserves endpoint, query, result limit and coordinate parsing',
    () async {
      final adapter = SearchResponseAdapter()
        ..body = [
          {'display_name': 'Ortigas, Pasig', 'lat': '14.58', 'lon': '121.08'},
        ];
      final dio = Dio(BaseOptions(validateStatus: (_) => true))
        ..httpClientAdapter = adapter;
      addTearDown(dio.close);
      final service = LocationSearchService(client: dio);
      final rows = await service.searchLocations(
        'Ortigas',
        city: 'Pasig',
        throwOnError: true,
      );
      final request = adapter.requests.single;
      expect(request.uri.host, 'nominatim.openstreetmap.org');
      expect(request.uri.path, '/search');
      expect(request.method, 'GET');
      expect(request.queryParameters, {
        'q': 'Ortigas, Pasig, Philippines',
        'format': 'json',
        'addressdetails': 1,
        'limit': 5,
      });
      expect(rows.single.displayName, 'Ortigas, Pasig');
      expect(rows.single.latLng.latitude, 14.58);
      expect(rows.single.latLng.longitude, 121.08);
    },
  );
  test(
    'strict UI errors differ from valid empty search and legacy fallback is preserved',
    () async {
      final adapter = SearchResponseAdapter();
      final dio = Dio(BaseOptions(validateStatus: (_) => true))
        ..httpClientAdapter = adapter;
      addTearDown(dio.close);
      final service = LocationSearchService(client: dio);
      expect(
        await service.searchLocations('Pasig', throwOnError: true),
        isEmpty,
      );
      adapter.status = 503;
      expect(await service.searchLocations('Pasig'), isEmpty);
      await expectLater(
        service.searchLocations('Pasig', throwOnError: true),
        throwsStateError,
      );
      adapter.status = 200;
      adapter.body = {'invalid': 'shape'};
      expect(await service.searchLocations('Pasig'), isEmpty);
      await expectLater(
        service.searchLocations('Pasig', throwOnError: true),
        throwsA(anything),
      );
    },
  );
  test(
    'recent history retains existing format, deduplication and ten-place limit',
    () async {
      SharedPreferences.setMockInitialValues({
        'recent_searches': jsonEncode(
          List.generate(10, (index) => place('Place $index').toJson()),
        ),
      });
      final service = RecentSearchesService();
      await service.saveSearch(place('New place'));
      var rows = await service.getRecentSearches(throwOnError: true);
      expect(rows, hasLength(10));
      expect(rows.first.displayName, 'New place');
      await service.saveSearch(place('Place 3'));
      rows = await service.getRecentSearches(throwOnError: true);
      expect(rows.first.displayName, 'Place 3');
      expect(rows.where((row) => row.displayName == 'Place 3'), hasLength(1));
      await service.removeSearch(rows.first);
      expect(await service.getRecentSearches(throwOnError: true), hasLength(9));
    },
  );
  test(
    'malformed history is reported without replacing the stored data',
    () async {
      const malformed = '{not-valid-history';
      SharedPreferences.setMockInitialValues({'recent_searches': malformed});
      final service = RecentSearchesService();
      expect(await service.getRecentSearches(), isEmpty);
      await expectLater(
        service.getRecentSearches(throwOnError: true),
        throwsFormatException,
      );
      await expectLater(
        service.saveSearch(place('New place')),
        throwsFormatException,
      );
      await expectLater(
        service.removeSearch(place('Old place')),
        throwsFormatException,
      );
      expect(
        (await SharedPreferences.getInstance()).getString('recent_searches'),
        malformed,
      );
    },
  );
}
