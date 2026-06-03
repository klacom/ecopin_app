import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// App Roles

enum UserRole { citizen, lgu, admin }

// Pasig Initial Center

final pasigInitialCenter = LatLng(14.575, 121.08);

// Pasig Bounds

LatLngBounds get pasigBounds =>
    LatLngBounds(LatLng(14.540, 121.050), LatLng(14.620, 121.130));
