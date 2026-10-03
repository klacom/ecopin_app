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
  });

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
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
    };
  }
}
