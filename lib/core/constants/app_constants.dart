import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// App Roles

enum UserRole { citizen, lgu, admin }

// Validation Status

enum ValidationStatus {
  automaticallyValid,
  manualReview,
  rejected,
  pending
}

extension ValidationStatusExtension on ValidationStatus {
  String get value {
    switch (this) {
      case ValidationStatus.automaticallyValid:
        return 'automatically_valid';
      case ValidationStatus.manualReview:
        return 'manual_review';
      case ValidationStatus.rejected:
        return 'rejected';
      case ValidationStatus.pending:
        return 'pending';
    }
  }

  static ValidationStatus fromString(String value) {
    return ValidationStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ValidationStatus.pending,
    );
  }
}

// Pasig Initial Center

final pasigInitialCenter = LatLng(14.575, 121.08);

// Pasig Bounds

LatLngBounds get pasigBounds =>
    LatLngBounds(LatLng(14.540, 121.050), LatLng(14.620, 121.130));
