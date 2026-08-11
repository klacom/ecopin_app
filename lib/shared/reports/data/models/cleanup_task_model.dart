class CleanupTaskModel {
  final String id;
  final String? clusterId;
  final String title;
  final String? description;
  final String status;
  final String? beforePhotoUrl;
  final String? afterPhotoUrl;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isCustom;
  final List<String>? reportIds;
  final dynamic clusters;
  final dynamic profiles;

  CleanupTaskModel({
    required this.id,
    this.clusterId,
    required this.title,
    this.description,
    required this.status,
    this.beforePhotoUrl,
    this.afterPhotoUrl,
    required this.createdAt,
    this.completedAt,
    this.isCustom = false,
    this.reportIds,
    this.clusters,
    this.profiles,
  });

  factory CleanupTaskModel.fromJson(Map<String, dynamic> json) {
    return CleanupTaskModel(
      id: json['id']?.toString() ?? '',
      clusterId: json['cluster_id']?.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      beforePhotoUrl: json['before_photo_url']?.toString(),
      afterPhotoUrl: json['after_photo_url']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at']?.toString() ?? '') : null,
      isCustom: json['is_custom'] as bool? ?? false,
      reportIds: (json['report_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      clusters: json['clusters'],
      profiles: json['profiles'],
    );
  }
}
