import 'package:flutter/material.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';

class ReportHeatmapLayer extends StatelessWidget {
  final List<ReportModel> reports;

  const ReportHeatmapLayer({
    super.key,
    required this.reports,
  });

  double _getWeightForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
      case 'closed':
        return 0.3;
      case 'in progress':
      case 'acknowledged':
      case 'waiting_for_feedback':
        return 0.6;
      case 'pending_owner_consent':
      case 'pending owner consent':
        return 0.8;
      default:
        return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return HeatMapLayer(
      heatMapDataSource: InMemoryHeatMapDataSource(
        data: reports.map((report) {
          final weight = _getWeightForStatus(report.status);
          return WeightedLatLng(report.location, weight);
        }).toList(),
      ),
      heatMapOptions: HeatMapOptions(
        radius: 50,
        minOpacity: 0.6,
      ),
    );
  }
}
