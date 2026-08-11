import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/shared/reports/data/datasources/report_remote_datasource.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final reportDataSourceProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReportDataSource(apiClient);
});

final myReportsProvider = FutureProvider<List<ReportModel>>((ref) async {
  final dataSource = ref.watch(reportDataSourceProvider);
  return dataSource.getMyReports();
});

final publicReportsProvider = FutureProvider<List<ReportModel>>((ref) async {
  final dataSource = ref.watch(reportDataSourceProvider);
  return dataSource.getPublicReports();
});

final reportsStreamProvider = StreamProvider<List<ReportModel>>((ref) {
  final dataSource = ref.watch(reportDataSourceProvider);
  return dataSource.getReportsStream();
});

final reportDetailsProvider = FutureProvider.family<ReportModel, String>((ref, id) async {
  final dataSource = ref.watch(reportDataSourceProvider);
  return dataSource.getReportById(id);
});
