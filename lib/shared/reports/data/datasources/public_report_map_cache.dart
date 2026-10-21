import 'public_report_map_datasource.dart';

/// Short-lived, screen-owned public areas; never reuse a truncated page for a
/// smaller viewport because unseen reports may have been excluded by the limit.
class PublicReportMapCache {
  PublicReportMapCache({DateTime Function()? now}) : _now = now ?? DateTime.now;
  final DateTime Function() _now;
  final _areas = <ReportViewport, ({ReportMapPage page, DateTime loadedAt})>{};

  void clear() => _areas.clear();

  void put(ReportViewport bounds, ReportMapPage page) {
    _areas.remove(bounds);
    _areas[bounds] = (page: page, loadedAt: _now());
    if (_areas.length > 6) _areas.remove(_areas.keys.first);
  }

  ReportMapPage? get(ReportViewport bounds) {
    final now = _now();
    _areas.removeWhere(
      (_, entry) =>
          now.difference(entry.loadedAt) >= const Duration(seconds: 60),
    );
    for (final entry in _areas.entries.toList().reversed) {
      final exact = entry.key == bounds;
      if (!exact && (entry.value.page.hasMore || !_covers(entry.key, bounds))) {
        continue;
      }
      // Touch the entry without extending its freshness.
      _areas.remove(entry.key);
      _areas[entry.key] = entry.value;
      if (exact) return entry.value.page;
      return ReportMapPage(
        reports: entry.value.page.reports
            .where(
              (report) =>
                  report.location.latitude >= bounds.south &&
                  report.location.latitude <= bounds.north &&
                  _longitudeOffset(report.location.longitude - bounds.west) <=
                      _longitudeSpan(bounds),
            )
            .toList(),
        hasMore: false,
      );
    }
    return null;
  }

  static double _longitudeOffset(double value) => (value % 360 + 360) % 360;
  static double _longitudeSpan(ReportViewport bounds) =>
      (bounds.east - bounds.west).abs() >= 360
      ? 360
      : _longitudeOffset(bounds.east - bounds.west);

  static bool _covers(ReportViewport outer, ReportViewport inner) =>
      outer.south <= inner.south &&
      outer.north >= inner.north &&
      (_longitudeSpan(outer) == 360 ||
          _longitudeOffset(inner.west - outer.west) + _longitudeSpan(inner) <=
              _longitudeSpan(outer));
}
