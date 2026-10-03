import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:ecopin_app/core/services/location_search_service.dart';

final addressProvider = FutureProvider.family<String?, LatLng>((ref, location) async {
  final searchService = LocationSearchService();
  return searchService.getAddressFromCoordinates(location.latitude, location.longitude);
});
