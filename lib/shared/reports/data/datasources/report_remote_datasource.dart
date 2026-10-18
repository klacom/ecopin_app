import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportDataSource {
  final ApiClient _apiClient;
  final SupabaseClient _supabase = Supabase.instance.client;

  ReportDataSource(this._apiClient);

  Stream<List<ReportModel>> getReportsStream() {
    return _supabase
        .from('reports')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((data) => data.map((json) => ReportModel.fromJson(json)).toList());
  }

  Future<List<ReportModel>> getMyReports() async {
    final response = await _apiClient.getMyReports();
    final dynamic rawData = response.data;
    final List data = rawData is List ? rawData : [];
    return data.map((json) => ReportModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<ReportModel>> getPublicReports() async {
    final response = await _apiClient.getPublicReports();
    final dynamic rawData = response.data;
    final List data = rawData is List ? rawData : [];
    return data.map((json) => ReportModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<ReportModel> getReportById(String id) async {
    final response = await _apiClient.getReportById(id);
    return ReportModel.fromJson(response.data);
  }
}
