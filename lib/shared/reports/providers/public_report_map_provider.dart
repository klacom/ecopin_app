import 'package:ecopin_app/shared/reports/data/datasources/public_report_map_datasource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final publicReportMapDataSourceProvider = Provider<PublicReportMapDataSource>(
  (ref) => PublicReportMapDataSource(Supabase.instance.client),
);

final publicReportMapProvider = FutureProvider.autoDispose
    .family<ReportMapPage, ReportViewport>(
      (ref, viewport) =>
          ref.watch(publicReportMapDataSourceProvider).getPage(viewport),
    );
