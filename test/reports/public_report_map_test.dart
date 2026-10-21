import 'dart:convert';
import 'package:ecopin_app/shared/reports/data/datasources/public_report_map_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final viewport = ReportViewport(
    south: 14.5,
    north: 14.7,
    west: 121,
    east: 121.2,
  );
  final fixture = <String, dynamic>{
    'id': 'synthetic-report',
    'title': 'Synthetic map report',
    'validation_status': 'approved',
    'latitude': 14.6,
    'longitude': 121.1,
    'created_at': '2026-10-11T00:00:00Z',
    'updated_at': '2026-10-11T00:00:00Z',
    'location_precision': 'approximate',
  };
  SupabaseClient clientFor(
    Future<http.Response> Function(http.Request) handler,
  ) {
    final client = SupabaseClient(
      'https://synthetic.invalid',
      'synthetic-anon-key',
      httpClient: MockClient((request) async {
        final response = await handler(request);
        return http.Response(
          response.body,
          response.statusCode,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.dispose);
    return client;
  }

  test('public list pages across all areas using only public fields', () async {
    late Uri request;
    final client = clientFor((r) async {
      request = r.url;
      return http.Response(
        jsonEncode([
          fixture,
          {...fixture, 'id': 'second'},
          {...fixture, 'id': 'sentinel'},
        ]),
        200,
      );
    });
    final page = await PublicReportMapDataSource(
      client,
    ).getFeedPage(offset: 20, limit: 2);
    expect(page.reports.map((r) => r.id), ['synthetic-report', 'second']);
    expect(page.hasMore, isTrue);
    expect(request.path, '/rest/v1/public_reports');
    expect(request.queryParameters['select'], PublicReportMapDataSource.fields);
    expect(request.queryParameters.containsKey('latitude'), isFalse);
    expect(request.queryParameters.containsKey('longitude'), isFalse);
    expect(request.queryParameters['offset'], '20');
    expect(request.queryParameters['limit'], '3');
    expect(
      request.queryParameters['order'],
      'created_at.desc.nullslast,id.desc.nullslast',
    );
  });

  test(
    'public map requests safe viewport fields and one truncation sentinel',
    () async {
      late Uri request;
      final client = clientFor((r) async {
        request = r.url;
        return http.Response(
          jsonEncode([
            fixture,
            {...fixture, 'id': 'second'},
            {...fixture, 'id': 'sentinel'},
          ]),
          200,
        );
      });
      final page = await PublicReportMapDataSource(
        client,
      ).getPage(viewport, limit: 2);
      expect(page.reports.map((r) => r.id), ['synthetic-report', 'second']);
      expect(page.hasMore, isTrue);
      expect(page.reports.first.location.latitude, 14.6);
      expect(page.reports.first.userId, isNull);
      expect(page.reports.first.beforePhotoUrl, isNull);
      expect(page.reports.first.locationPrecision, 'approximate');
      expect(request.path, '/rest/v1/public_reports');
      final fields = request.queryParameters['select']!.split(',');
      for (final excluded in [
        '*',
        'notes',
        'user_id',
        'before_photo_url',
        'ml_probabilities',
        'idempotency_key',
      ]) {
        expect(fields, isNot(contains(excluded)));
      }
      expect(request.queryParametersAll['latitude'], ['gte.14.5', 'lte.14.7']);
      expect(request.queryParametersAll['longitude'], [
        'gte.121.0',
        'lte.121.2',
      ]);
      expect(
        request.queryParameters['order'],
        'created_at.desc.nullslast,id.desc.nullslast',
      );
      expect(request.queryParameters['limit'], '3');
      expect(client.realtime.getChannels(), isEmpty);
    },
  );
  test(
    'a short page is complete and an empty page is a valid result',
    () async {
      final client = clientFor((_) async => http.Response('[]', 200));
      final page = await PublicReportMapDataSource(client).getPage(viewport);
      expect(page.reports, isEmpty);
      expect(page.hasMore, isFalse);
    },
  );
  test(
    'database failures propagate instead of becoming an empty map',
    () async {
      final client = clientFor(
        (_) async => http.Response(
          '{"code":"42501","message":"permission denied"}',
          401,
        ),
      );
      await expectLater(
        PublicReportMapDataSource(client).getPage(viewport),
        throwsA(isA<PostgrestException>()),
      );
    },
  );
  test('invalid page limits are rejected before an HTTP request', () async {
    var count = 0;
    final client = clientFor((_) async {
      count++;
      return http.Response('[]', 200);
    });
    for (final limit in [0, -1, 501]) {
      await expectLater(
        PublicReportMapDataSource(client).getPage(viewport, limit: limit),
        throwsRangeError,
      );
    }
    expect(count, 0);
  });
  test(
    'invalid viewports are rejected and equal viewports share provider identity',
    () {
      expect(
        () =>
            ReportViewport(south: double.nan, north: 14, west: 121, east: 122),
        throwsRangeError,
      );
      expect(
        () => ReportViewport(south: 15, north: 14, west: 121, east: 122),
        throwsRangeError,
      );
      expect(
        () => ReportViewport(south: 14, north: 91, west: 121, east: 122),
        throwsRangeError,
      );
      expect(
        viewport,
        ReportViewport(south: 14.5, north: 14.7, west: 121, east: 121.2),
      );
      expect(
        viewport.hashCode,
        ReportViewport(
          south: 14.5,
          north: 14.7,
          west: 121,
          east: 121.2,
        ).hashCode,
      );
    },
  );
  test('dateline bounds request both longitude ranges', () async {
    late Uri request;
    final client = clientFor((r) async {
      request = r.url;
      return http.Response('[]', 200);
    });
    await PublicReportMapDataSource(
      client,
    ).getPage(ReportViewport(south: 14, north: 15, west: 170, east: 190));
    expect(
      request.queryParameters['or'],
      '(longitude.gte.170.0,longitude.lte.-170.0)',
    );
  });
  test('world viewport does not exclude wrapped longitudes', () async {
    late Uri request;
    final client = clientFor((r) async {
      request = r.url;
      return http.Response('[]', 200);
    });
    await PublicReportMapDataSource(
      client,
    ).getPage(ReportViewport(south: 14, north: 15, west: -200, east: 200));
    expect(request.queryParameters.containsKey('longitude'), isFalse);
    expect(request.queryParameters.containsKey('or'), isFalse);
  });
}
