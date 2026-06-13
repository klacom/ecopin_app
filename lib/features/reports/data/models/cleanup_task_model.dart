class CleanupTaskModel {
  final String id;
  final String clusterId;
  final String title;
  final String? description;
  final String status;
  final String? beforePhotoUrl;
  final String? afterPhotoUrl;
  final DateTime createdAt;
  final DateTime? completedAt;

  CleanupTaskModel({
    required this.id,
    required this.clusterId,
    required this.title,
    this.description,
    required this.status,
    this.beforePhotoUrl,
    this.afterPhotoUrl,
    required this.createdAt,
    this.completedAt,
  });

  factory CleanupTaskModel.fromJson(Map<String, dynamic> json) {
    return CleanupTaskModel(
      id: json['id']?.toString() ?? '',
      clusterId: json['cluster_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      beforePhotoUrl: json['before_photo_url']?.toString(),
      afterPhotoUrl: json['after_photo_url']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at']?.toString() ?? '') : null,
    );
  }
}
