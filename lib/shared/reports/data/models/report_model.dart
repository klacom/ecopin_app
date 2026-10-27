import 'package:latlong2/latlong.dart';
import 'package:geobase/geobase.dart';
import 'package:logging/logging.dart';

class ReportModel {
  final String id;
  final String? userId;
  final String title;
  final String? description;
  final String? issueType;
  final LatLng location;
  final String locationPrecision;
  final String validationStatus;
  final String status;
  final String? clusterId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userFullName;
  final bool onPrivateProperty;
  final String propertyOwnerConsentStatus;
  final int? satisfactionRating;
  final DateTime? lguResolvedAt;
  final DateTime? citizenClosedAt;
  final bool isOverdue;
  final String? beforePhotoUrl;
  final List<Map<String, dynamic>> beforePhotos;
  final String? afterPhotoUrl;
  final List<Map<String, dynamic>> afterPhotos;
  final String? rejectionReason;
  final DateTime? rejectedAt;
  final String scaleLevel;
  final String obstructionLevel;
  final int? severityScore;
  final String? severityLevel;
  final Map<String, dynamic>? severityFactors;
  final String? lifecycleStage;
  final String? lifecycleState;
  final DateTime? breachedAt;
  final DateTime? slaStartedAt;
  final DateTime? deadlineAt;
  final String? slaBreachDuration;
  final int fcVersion;
  final int reportClaimGeneration;
  final String? locationVerificationStatus;
  final double? photoDistanceMeters;
  final String? cleanupTaskId;
  final String? notes;

  ReportModel({
    required this.id,
    this.userId,
    required this.title,
    this.description,
    this.issueType,
    required this.location,
    this.locationPrecision = 'exact',
    required this.validationStatus,
    required this.status,
    this.clusterId,
    required this.createdAt,
    required this.updatedAt,
    this.userFullName,
    this.onPrivateProperty = false,
    this.propertyOwnerConsentStatus = 'not_required',
    this.satisfactionRating,
    this.lguResolvedAt,
    this.citizenClosedAt,
    this.isOverdue = false,
    this.beforePhotoUrl,
    this.beforePhotos = const [],
    this.afterPhotoUrl,
    this.afterPhotos = const [],
    this.notes,
    this.rejectionReason,
    this.rejectedAt,
    this.scaleLevel = 'medium',
    this.obstructionLevel = 'none',
    this.severityScore,
    this.severityLevel,
    this.severityFactors,
    this.lifecycleStage,
    this.lifecycleState,
    this.breachedAt,
    this.slaStartedAt,
    this.deadlineAt,
    this.slaBreachDuration,
    this.fcVersion = 0,
    this.reportClaimGeneration = 0,
    this.locationVerificationStatus,
    this.photoDistanceMeters,
    this.cleanupTaskId,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    LatLng latLng;
    final Logger log = Logger("Report Model");

    // 1. Try direct latitude/longitude (from reports_view)
    if (json.containsKey('latitude') &&
        json.containsKey('longitude') &&
        json['latitude'] != null) {
      latLng = LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      );
    }
    // 2. Try GeoJSON location (from updated reports_view)
    else if (json['location'] != null &&
        json['location'] is Map &&
        json['location']['type'] == 'Point') {
      final coords = json['location']['coordinates'] as List;
      latLng = LatLng(coords[1].toDouble(), coords[0].toDouble());
    }
    // 3. Fallback for raw POINT string
    else if (json['location'] != null &&
        json['location'] is String &&
        json['location'].startsWith('POINT')) {
      final parts = json['location']
          .replaceAll('POINT(', '')
          .replaceAll(')', '')
          .split(' ');
      latLng = LatLng(double.parse(parts[1]), double.parse(parts[0]));
    }
    // 4. Handle EWKB hex string (common in Supabase Realtime stream)
    else if (json['location'] != null && json['location'] is String) {
      try {
        final point = Point.decodeHex(json['location'], format: WKB.geometry);
        // _log.info('point: $point');
        latLng = LatLng(point.position.y, point.position.x);
      } catch (e, stackTrace) {
        log.severe('Error parsing EWKB: $e', stackTrace);
        latLng = const LatLng(0, 0);
      }
    } else {
      latLng = const LatLng(0, 0);
    }

    // _log.finer('JSON: $json');
    // _log.info('LAT & LONG: $latLng');

    return ReportModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      title: json['title']?.toString() ?? 'Untitled Report',
      description: json['description']?.toString(),
      issueType: json['issue_type']?.toString(),
      location: latLng,
      locationPrecision: json['location_precision']?.toString() ?? 'exact',
      validationStatus:
          json['validation_status']?.toString() ?? 'pending_ai_validation',
      status: json['status']?.toString() ?? 'unresolved',
      clusterId: json['cluster_id']?.toString(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      userFullName: json['profiles']?['full_name']?.toString(),
      onPrivateProperty: json['on_private_property'] ?? false,
      propertyOwnerConsentStatus:
          json['property_owner_consent_status']?.toString() ?? 'not_required',
      satisfactionRating: json['satisfaction_rating'] as int?,
      lguResolvedAt: json['lgu_resolved_at'] != null
          ? DateTime.tryParse(
              json['lgu_resolved_at']?.toString() ?? '',
            )?.toLocal()
          : null,
      citizenClosedAt: json['citizen_closed_at'] != null
          ? DateTime.tryParse(
              json['citizen_closed_at']?.toString() ?? '',
            )?.toLocal()
          : null,
      isOverdue: json['is_overdue'] ?? false,
      beforePhotos: (json['before_photos'] as List? ?? [])
          .whereType<Map>()
          .map((p) => Map<String, dynamic>.from(p))
          .toList(),
      beforePhotoUrl: json['before_photo_url']?.toString(),
      afterPhotos: (json['after_photos'] as List? ?? [])
          .whereType<Map>()
          .map((p) => Map<String, dynamic>.from(p))
          .toList(),
      afterPhotoUrl: json['after_photo_url']?.toString(),
      notes: json['notes']?.toString(),
      rejectionReason: () {
        final explicitReason = json['rejection_reason']?.toString().trim();
        if (explicitReason != null && explicitReason.isNotEmpty) {
          return explicitReason;
        }
        final rawNotes = json['notes']?.toString();
        if (rawNotes != null && rawNotes.isNotEmpty) {
          if (rawNotes.contains('Officer rejection reason:')) {
            final parts = rawNotes.split('Officer rejection reason:');
            final extracted = parts.last.trim();
            if (extracted.isNotEmpty) return extracted;
          }
          if (json['validation_status'] == 'rejected' &&
              !rawNotes.startsWith('Reporter requested manual review:')) {
            return rawNotes.trim();
          }
        }
        return null;
      }(),
      rejectedAt: json['rejected_at'] != null
          ? DateTime.tryParse(json['rejected_at']?.toString() ?? '')?.toLocal()
          : (json['validation_status'] == 'rejected'
                ? DateTime.tryParse(
                    json['updated_at']?.toString() ?? '',
                  )?.toLocal()
                : null),
      scaleLevel: json['scale_level']?.toString() ?? 'medium',
      obstructionLevel: json['obstruction_level']?.toString() ?? 'none',
      severityScore: json['severity_score'] as int?,
      severityLevel: json['severity_level']?.toString(),
      severityFactors: json['severity_factors'] as Map<String, dynamic>?,
      lifecycleStage: (json['stage'] ?? json['lifecycle_stage'])?.toString(),
      lifecycleState: json['lifecycle_state']?.toString(),
      breachedAt: DateTime.tryParse(
        json['breached_at']?.toString() ?? '',
      )?.toLocal(),
      slaBreachDuration: json['sla_breach_duration']?.toString(),
      slaStartedAt: DateTime.tryParse(json['sla_started_at']?.toString() ?? ''),
      deadlineAt: DateTime.tryParse(json['deadline_at']?.toString() ?? ''),
      fcVersion: int.tryParse(json['fc_version']?.toString() ?? '') ?? 0,
      reportClaimGeneration:
          int.tryParse(json['report_claim_generation']?.toString() ?? '') ?? 0,
      locationVerificationStatus: json['location_verification_status']
          ?.toString(),
      photoDistanceMeters: (json['photo_distance_meters'] as num?)?.toDouble(),
      cleanupTaskId: json['cleanup_task_id']?.toString(),
    );
  }

  /// Whether this report can be withdrawn/deleted by the citizen before triage/dispatch.
  bool get canBeWithdrawn {
    if (cleanupTaskId != null && cleanupTaskId!.isNotEmpty) return false;
    final stage = (lifecycleStage ?? '').toLowerCase().trim();
    if (stage == 'assigned' ||
        stage == 'in_progress' ||
        stage == 'resolved' ||
        stage == 'closed') {
      return false;
    }
    final lifeState = (lifecycleState ?? '').toLowerCase().trim();
    if (lifeState == 'dispatched' || lifeState == 'closed') {
      return false;
    }
    final stat = status.toLowerCase().trim();
    if (stat == 'in_progress' || stat == 'resolved' || stat == 'closed') {
      return false;
    }
    return true;
  }

  /// If the report was submitted with a manual review request, returns the citizen's explanation.
  String? get manualReviewRequestReason {
    final rawNotes = notes;
    if (rawNotes == null || !rawNotes.startsWith('Reporter requested manual review:')) {
      return null;
    }
    final afterPrefix = rawNotes.substring('Reporter requested manual review:'.length);
    if (afterPrefix.contains('Officer rejection reason:')) {
      return afterPrefix.split('Officer rejection reason:').first.trim();
    }
    return afterPrefix.trim();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'issue_type': issueType,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'location_precision': locationPrecision,
      'on_private_property': onPrivateProperty,
      'property_owner_consent_status': propertyOwnerConsentStatus,
      'satisfaction_rating': satisfactionRating,
      'lgu_resolved_at': lguResolvedAt?.toIso8601String(),
      'citizen_closed_at': citizenClosedAt?.toIso8601String(),
      'is_overdue': isOverdue,
      'notes': notes,
      'rejection_reason': rejectionReason,
      'rejected_at': rejectedAt?.toIso8601String(),
      'scale_level': scaleLevel,
      'obstruction_level': obstructionLevel,
      'severity_score': severityScore,
      'severity_level': severityLevel,
      'severity_factors': severityFactors,
      'lifecycle_stage': lifecycleStage,
      'stage': lifecycleStage,
      'lifecycle_state': lifecycleState,
      'breached_at': breachedAt?.toIso8601String(),
      'sla_started_at': slaStartedAt?.toUtc().toIso8601String(),
      'deadline_at': deadlineAt?.toUtc().toIso8601String(),
      'sla_breach_duration': slaBreachDuration,
      'fc_version': fcVersion,
      'report_claim_generation': reportClaimGeneration,
      'cleanup_task_id': cleanupTaskId,
      'before_photos': beforePhotos,
      'after_photos': afterPhotos,
    };
  }
}
