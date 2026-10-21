import 'package:ecopin_app/shared/reports/data/datasources/public_report_map_cache.dart';
import 'package:ecopin_app/shared/reports/data/datasources/public_report_map_datasource.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

ReportViewport area(
  double west,
  double east, {
  double south = 14,
  double north = 15,
}) => ReportViewport(south: south, north: north, west: west, east: east);
ReportModel report(String id, double latitude, double longitude) => ReportModel(
  id: id,
  title: id,
  location: LatLng(latitude, longitude),
  status: 'unresolved',
  validationStatus: 'approved',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  test(
    'complete larger areas serve only reports inside a smaller viewport',
    () {
      final cache = PublicReportMapCache();
      cache.put(
        area(120, 122),
        ReportMapPage(
          reports: [
            report('inside', 14.5, 121),
            report('outside', 14.1, 120.1),
          ],
          hasMore: false,
        ),
      );
      final page = cache.get(area(120.5, 121.5, south: 14.4, north: 14.6))!;
      expect(page.reports.map((r) => r.id), ['inside']);
      expect(page.hasMore, isFalse);
      expect(cache.get(area(125, 126)), isNull);
    },
  );
  test('truncated areas can only serve their exact viewport', () {
    final cache = PublicReportMapCache();
    final bounds = area(120, 122);
    final page = ReportMapPage(
      reports: [report('one', 14.5, 121)],
      hasMore: true,
    );
    cache.put(bounds, page);
    expect(cache.get(area(120.5, 121.5)), isNull);
    expect(cache.get(bounds), same(page));
  });
  test('cached areas expire after 60 seconds even when repeatedly read', () {
    var now = DateTime.utc(2026);
    final cache = PublicReportMapCache(now: () => now);
    final bounds = area(120, 122);
    cache.put(bounds, ReportMapPage(reports: [], hasMore: false));
    now = now.add(const Duration(seconds: 59));
    expect(cache.get(bounds), isNotNull);
    now = now.add(const Duration(seconds: 1));
    expect(cache.get(bounds), isNull);
  });
  test('only six areas are retained and refresh can clear them', () {
    final cache = PublicReportMapCache();
    for (var i = 0; i < 6; i++) {
      cache.put(
        area(i * 10, i * 10 + 1),
        ReportMapPage(reports: [], hasMore: false),
      );
    }
    expect(cache.get(area(0, 1)), isNotNull);
    cache.put(area(60, 61), ReportMapPage(reports: [], hasMore: false));
    expect(cache.get(area(10, 11)), isNull);
    expect(cache.get(area(0, 1)), isNotNull);
    cache.clear();
    expect(cache.get(area(0, 1)), isNull);
  });
  test(
    'cached containment and filtering handle date-line and wrapped worlds',
    () {
      final cache = PublicReportMapCache();
      final page = ReportMapPage(
        reports: [
          report('east', 14.5, 179),
          report('west', 14.5, -179),
          report('other', 14.5, 0),
        ],
        hasMore: false,
      );
      cache.put(area(170, -170), page);
      expect(cache.get(area(175, -175))!.reports.map((r) => r.id), [
        'east',
        'west',
      ]);
      expect(cache.get(area(-5, 5)), isNull);
      cache.clear();
      cache.put(area(530, 550), page);
      expect(cache.get(area(175, -175))!.reports.map((r) => r.id), [
        'east',
        'west',
      ]);
    },
  );
}
