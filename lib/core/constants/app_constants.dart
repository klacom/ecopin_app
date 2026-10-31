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

// SWMO depot (Pasig City Hall area); fallback map center for crew routes.
// Keep in sync with ecopin-web/lib/map/pasigMapConstants.js.

const LatLng pasigSwmoDepot = LatLng(14.561433, 121.075636);

// Pasig Bounds (same box as web PASIG_BOUNDS)

LatLngBounds get pasigBounds =>
    LatLngBounds(LatLng(14.52, 121.03), LatLng(14.64, 121.14));

// Enforced on every Pasig-wide map via MapOptions.cameraConstraint.
// Pair with minZoom: pasigMinZoom so the bounds always cover the viewport.

const double pasigMinZoom = 11;

CameraConstraint get pasigCameraConstraint =>
    CameraConstraint.contain(bounds: pasigBounds);

// To Globally show snackbars.

final messengerKey = GlobalKey<ScaffoldMessengerState>();

// Notification variables

final int itemsPerPage = 10;
int displayedItems = 10;

// Report Filters
// Values must match the canonical status strings stored by the backend.
// Backend writes 'in_progress' (underscore) via updateLifecycleStage.

const List<String> reportFilters = [
  'All',
  'unresolved',
  'in_progress',
  'resolved',
  'rejected',
];

// Human-readable labels for report status filter chips and display.
const Map<String, String> reportStatusLabels = {
  'All': 'All',
  'unresolved': 'Unresolved',
  'in_progress': 'In Progress',
  'resolved': 'Resolved',
  'rejected': 'Rejected',
  'pending_owner_consent': 'Awaiting Consent',
  'waiting_for_feedback': 'Waiting for Feedback',
  'closed': 'Closed',
};

// Create Report Fun Facts - Notice: May get removed after image validation logic change.

const List<String> funFacts = [
  "Did you know? A single tree can absorb up to 48 lbs of CO2 per year!",
  "Fun fact: Recycling one glass bottle saves enough energy to power a 100W bulb for 4 hours!",
  "Every year, over 8 million tons of plastic ends up in our oceans.",
  "A plastic bottle can take up to 450 years to decompose!",
  "Planting native species helps local wildlife thrive!",
  "Turning off tap while brushing teeth saves up to 200 gallons/month!",
  "Recycling one ton of paper saves 17 mature trees and 7,000 gallons of water.",
  "Only about 9% of all plastic ever made has likely been recycled.",
  "A single reusable bag can replace up to 600 plastic bags over its lifetime.",
  "Composting organic waste reduces methane emissions from landfills.",
  "It takes 2,700 liters of water to make one cotton shirt—enough for one person to drink for 2.5 years!",
  "Switching to LED bulbs uses 75% less energy and lasts 25 times longer than incandescent lighting.",
  "Up to 40% of all food produced in the world goes uneaten. Reduce food waste to help the planet!",
  "E-waste is the fastest-growing waste stream in the world. Always recycle electronics properly.",
  "Fun Fact: Pasig was established by Augustinian missionaries in 1572, making it one of the oldest towns in the Philippines!",
  "Did you know? Pasig served as the capital of the province of Rizal prior to the formation of Metro Manila in 1975.",
  "The name 'Pasig' is believed to come from the Sanskrit word 'passis', or Tagalog 'mabagsik', meaning a river flowing from one body of water to another.",
  "The Pasig Cathedral (Immaculate Conception Cathedral) is one of the oldest structures in the city, dating back to the Spanish colonial era.",
  "Pasig City is known as a 'Green City' for its various environmental initiatives and eco-friendly programs.",
];

// Create Report Issue Types - Notice: Kapag naging dynamic yung issue types sa suapbase, baka mapalitan.

// Keys are the backend `report_issue_type` values; keep in sync with ecopin-web ISSUE_TYPES.

const Map<String, String> issueTypeLabels = {
  'waste': 'Waste',
  'flooding': 'Flooding',
  'pollution': 'Pollution',
  'infrastructure': 'Infrastructure',
  'illegal_logging': 'Illegal Logging',
  'others': 'Others',
};

// Report photo constraints

const int reportMinPhotos = 1;
const int reportMaxPhotos = 5;
const int reportTotalPhotosSize = 10 * 1024 * 1024; // 10MB

// Report video constraints
const int reportMaxVideos = 1;
