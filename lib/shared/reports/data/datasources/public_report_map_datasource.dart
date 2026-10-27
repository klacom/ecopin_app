import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportViewport {
  final double south, north, west, east;

  ReportViewport({
    required this.south,
    required this.north,
    required this.west,
    required this.east,
  }) {
    if (![south, north, west, east].every((value) => value.isFinite) ||
        south < -90 ||
        north > 90 ||
        south > north) {
      throw RangeError('A valid map viewport is required');
    }
  }

  @override
  bool operator ==(Object other) =>
      other is ReportViewport &&
      south == other.south &&
      north == other.north &&
      west == other.west &&
      east == other.east;
  @override
  int get hashCode => Object.hash(south, north, west, east);
}

class ReportMapPage {
  final List<ReportModel> reports;
  final bool hasMore;
  ReportMapPage({required List<ReportModel> reports, required this.hasMore})
    : reports = List.unmodifiable(reports);
}

class PublicReportMapDataSource {
  final SupabaseClient _client;
  PublicReportMapDataSource(this._client);

  static const fields =
      'id,title,description,issue_type,status,cluster_id,created_at,updated_at,stage,is_overdue,severity_score,severity_level,lifecycle_state,breached_at,validation_status,location,latitude,longitude,location_precision,sla_started_at,deadline_at';

  Future<ReportMapPage> getFeedPage({int offset = 0, int limit = 30}) async {
    if (offset < 0) throw RangeError.value(offset, 'offset');
    if (limit < 1 || limit > 100) {
      throw RangeError.range(limit, 1, 100, 'limit');
    }
    final rows = await _client
        .from('public_reports')
        .select(fields)
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(offset, offset + limit);
    return ReportMapPage(
      reports: rows
          .take(limit)
          .map(ReportModel.fromJson)
          .toList(growable: false),
      hasMore: rows.length > limit,
    );
  }

  Future<ReportMapPage> getPage(
    ReportViewport bounds, {
    int limit = 200,
  }) async {
    if (limit < 1 || limit > 500) {
      throw RangeError.range(limit, 1, 500, 'limit');
    }
    var query = _client
        .from('public_reports')
        .select(fields)
        .gte('latitude', bounds.south)
        .lte('latitude', bounds.north);
    if ((bounds.east - bounds.west).abs() < 360) {
      double wrap(double longitude) => longitude >= -180 && longitude <= 180
          ? longitude
          : ((longitude + 180) % 360 + 360) % 360 - 180;
      final west = wrap(bounds.west), east = wrap(bounds.east);
      query = west > east
          ? query.or('longitude.gte.$west,longitude.lte.$east')
          : query.gte('longitude', west).lte('longitude', east);
    }
    final rows = await query
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(limit + 1);
    return ReportMapPage(
      reports: rows
          .take(limit)
          .map(ReportModel.fromJson)
          .toList(growable: false),
      hasMore: rows.length > limit,
    );
  }
}
