import 'dart:async';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportDataSource {
  final ApiClient _apiClient;
  final SupabaseClient _supabase;

  ReportDataSource(this._apiClient, {SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  // Operational views cannot use table CDC. Poll the masked, authorized view instead.
  Stream<List<ReportModel>> getReportsStream({
    Duration refreshInterval = const Duration(seconds: 15),
  }) {
    if (refreshInterval <= Duration.zero) {
      throw ArgumentError.value(refreshInterval, 'refreshInterval');
    }
    late final StreamController<List<ReportModel>> controller;
    Timer? timer;
    var stopped = false;
    var loading = false;
    Future<void> refresh() async {
      if (stopped || loading) return;
      loading = true;
      try {
        final reports = <ReportModel>[];
        const size = 500;
        for (var offset = 0; !stopped; offset += size) {
          final rows = await _supabase
              .from('reports_view')
              .select()
              .order('created_at')
              .order('id')
              .range(offset, offset + size - 1);
          if (stopped) return;
          reports.addAll(rows.map(ReportModel.fromJson));
          if (rows.length < size) break;
        }
        if (!stopped) controller.add(reports);
      } catch (error, stack) {
        if (!stopped) controller.addError(error, stack);
      } finally {
        loading = false;
      }
    }

    controller = StreamController<List<ReportModel>>(
      onListen: () {
        timer = Timer.periodic(refreshInterval, (_) => unawaited(refresh()));
        unawaited(refresh());
      },
      onCancel: () {
        stopped = true;
        timer?.cancel();
        unawaited(controller.close());
      },
    );
    return controller.stream;
  }

  Future<List<ReportModel>> getMyReports() async {
    final response = await _apiClient.getMyReports();
    final dynamic rawData = response.data;
    final List data = rawData is List ? rawData : [];
    return data
        .map((json) => ReportModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<ReportModel>> getPublicReports() async {
    final response = await _apiClient.getPublicReports();
    final dynamic rawData = response.data;
    final List data = rawData is List ? rawData : [];
    return data
        .map((json) => ReportModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ReportModel> getReportById(String id) async {
    final response = await _apiClient.getReportById(id);
    return ReportModel.fromJson(response.data);
  }

  Future<void> withdrawReport(String id) async {
    await _apiClient.withdrawReport(id);
  }
}
