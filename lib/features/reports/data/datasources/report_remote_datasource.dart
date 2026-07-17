import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/features/reports/data/models/report_model.dart';
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
    final List data = response.data;
    return data.map((json) => ReportModel.fromJson(json)).toList();
  }

  Future<List<ReportModel>> getPublicReports() async {
    final response = await _apiClient.getPublicReports();
    final List data = response.data;
    // log.info('data: $data');
    return data.map((json) => ReportModel.fromJson(json)).toList();
  }

  Future<ReportModel> getReportById(String id) async {
    final response = await _apiClient.getReportById(id);
    return ReportModel.fromJson(response.data);
  }
}
