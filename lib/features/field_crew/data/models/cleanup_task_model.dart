import 'package:ecopin_app/shared/reports/data/models/report_model.dart';

class CleanupTask {
  final String id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String location;
  final String? streetAddress;
  final String taskType;
  final bool isCustom;
  final String? clusterId;
  final List<String> reportIds;
  final List<String> assignedCrewIds;
  final String? crewRouteId;
  final String? beforePhotoUrl;
  final String? afterPhotoUrl;
  final List<String> reportSequence;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ReportModel>? reports;
  final String dispatchKind;
  final int fcVersion;
  final int assignmentGeneration;
  final String? assignedFieldCrewId;
  final Map<String, int> reportClaimGenerations;
  final List<String> satelliteReportIds;
  final num? bundleDetourMin;

  CleanupTask({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.location,
    this.streetAddress,
    required this.taskType,
    required this.isCustom,
    this.clusterId,
    required this.reportIds,
    required this.assignedCrewIds,
    this.crewRouteId,
    this.beforePhotoUrl,
    this.afterPhotoUrl,
    required this.reportSequence,
    required this.createdAt,
    required this.updatedAt,
    this.reports,
    this.dispatchKind = 'standard',
    this.fcVersion = 0,
    this.assignmentGeneration = 0,
    this.assignedFieldCrewId,
    this.reportClaimGenerations = const {},
    this.satelliteReportIds = const [],
    this.bundleDetourMin,
  });

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  static Map<String, int> _parseClaimGenerations(dynamic value) {
    if (value is! Map) return const {};
    return value.map((key, generation) => MapEntry(
      key.toString(), int.tryParse(generation.toString()) ?? 0,
    ));
  }

  factory CleanupTask.fromJson(Map<String, dynamic> json) {
    return CleanupTask(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Task',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      priority: json['priority']?.toString() ?? 'normal',
      location: json['location']?.toString() ?? 'Unknown Location',
      streetAddress: json['street_address']?.toString() ?? json['address']?.toString(),
      taskType: json['task_type']?.toString() ?? 'cleanup',
      isCustom: json['is_custom'] == true || json['is_custom'] == 'true',
      clusterId: json['cluster_id']?.toString(),
      reportIds: _parseStringList(json['report_ids']),
      assignedCrewIds: _parseStringList(json['assigned_crew_ids']),
      crewRouteId: json['crew_route_id']?.toString(),
      beforePhotoUrl: json['before_photo_url']?.toString(),
      afterPhotoUrl: json['after_photo_url']?.toString(),
      reportSequence: _parseStringList(json['report_sequence']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
      reports: (json['reports'] as List<dynamic>?)?.whereType<Map<String, dynamic>>().map((e) {
        try {
          return ReportModel.fromJson(e);
        } catch (err) {
          // Ignore individual report parse failures so the whole task doesn't crash
          return null;
        }
      }).whereType<ReportModel>().toList(),
      dispatchKind: json['dispatch_kind']?.toString() ?? 'standard',
      fcVersion: int.tryParse(json['fc_version']?.toString() ?? '') ?? 0,
      assignmentGeneration: int.tryParse(json['assignment_generation']?.toString() ?? '') ?? 0,
      assignedFieldCrewId: json['assigned_field_crew_id']?.toString(),
      reportClaimGenerations: _parseClaimGenerations(json['report_claim_generations']),
      satelliteReportIds: _parseStringList(json['satellite_report_ids']),
      bundleDetourMin: num.tryParse(json['bundle_detour_min']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'location': location,
      'street_address': streetAddress,
      'task_type': taskType,
      'is_custom': isCustom,
      'cluster_id': clusterId,
      'report_ids': reportIds,
      'assigned_crew_ids': assignedCrewIds,
      'crew_route_id': crewRouteId,
      'before_photo_url': beforePhotoUrl,
      'after_photo_url': afterPhotoUrl,
      'report_sequence': reportSequence,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (reports != null) 'reports': reports?.map((e) => e.toJson()).toList(),
      'dispatch_kind': dispatchKind,
      'fc_version': fcVersion,
      'assignment_generation': assignmentGeneration,
      'assigned_field_crew_id': assignedFieldCrewId,
      'report_claim_generations': reportClaimGenerations,
      'satellite_report_ids': satelliteReportIds,
      'bundle_detour_min': bundleDetourMin,
    };
  }
}
