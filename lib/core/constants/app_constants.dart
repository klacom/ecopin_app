import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

// App Roles

enum UserRole { citizen, officer, fieldCrew, admin }

// Validation Status

enum ValidationStatus {
  pendingAiValidation,
  approved,
  manualReview,
  rejected,
  archived,
}

extension ValidationStatusExtension on ValidationStatus {
  String get value {
    switch (this) {
      case ValidationStatus.pendingAiValidation:
        return 'pending_ai_validation';
      case ValidationStatus.approved:
        return 'approved';
      case ValidationStatus.manualReview:
        return 'manual_review';
      case ValidationStatus.rejected:
        return 'rejected';
      case ValidationStatus.archived:
        return 'archived';
    }
  }

  static ValidationStatus fromString(String value) {
    return ValidationStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ValidationStatus.pendingAiValidation,
    );
  }
}

// Pasig Initial Center

final pasigInitialCenter = LatLng(14.575, 121.08);

// Pasig Bounds

LatLngBounds get pasigBounds =>
    LatLngBounds(LatLng(14.540, 121.050), LatLng(14.620, 121.130));

// To Globally show snackbars.

final messengerKey = GlobalKey<ScaffoldMessengerState>();

// Notification variables

final int itemsPerPage = 10;
int displayedItems = 10;

// Report Filters

const List<String> reportFilters = [
  'All',
  'unresolved',
  'in progress',
  'resolved',
  'rejected',
];

// Create Report Fun Facts - Notice: May get removed after image validation logic change.

const List<String> funFacts = [
  "Did you know? A single tree can absorb up to 48 lbs of CO2 per year!",
  "Fun fact: Recycling one glass bottle saves enough energy to power a 100W bulb for 4 hours!",
  "Every year, over 8 million tons of plastic ends up in our oceans.",
  "A plastic bottle can take up to 450 years to decompose!",
  "Planting native species helps local wildlife thrive!",
  "Turning off tap while brushing teeth saves up to 200 gallons/month!",
];

// Create Report Issue Types - Notice: Kapag naging dynamic yung issue types sa suapbase, baka mapalitan.

const List<String> issueTypes = [
  'Waste',
  'Flooding',
  'Pollution',
  'Illegal Logging',
  'Others',
];

// Report photo constraints

const int reportMinPhotos = 1;
const int reportMaxPhotos = 5;
const int reportTotalPhotosSize = 10 * 1024 * 1024; // 10MB
