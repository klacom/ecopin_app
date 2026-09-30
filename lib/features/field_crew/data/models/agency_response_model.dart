class AgencyResponse {
  final String id;
  final String reportId;
  final String actionType;
  final String? actionDetails;
  final DateTime createdAt;
  final String userId;

  AgencyResponse({
    required this.id,
    required this.reportId,
    required this.actionType,
    this.actionDetails,
    required this.createdAt,
    required this.userId,
  });

  factory AgencyResponse.fromJson(Map<String, dynamic> json) {
    return AgencyResponse(
      id: json['id']?.toString() ?? '',
      reportId: json['report_id']?.toString() ?? '',
      actionType: json['action_type']?.toString() ?? '',
      actionDetails: json['action_details']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      userId: json['user_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'report_id': reportId,
      'action_type': actionType,
      'action_details': actionDetails,
      'created_at': createdAt.toIso8601String(),
      'user_id': userId,
    };
  }
}
