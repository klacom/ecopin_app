import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:logging/logging.dart';

class LocationSuggestion {
  final String displayName;
  final LatLng latLng;

  LocationSuggestion({required this.displayName, required this.latLng});

  factory LocationSuggestion.fromJson(Map<String, dynamic> json) {
    return LocationSuggestion(
      displayName: json['display_name'] as String,
      latLng: LatLng(
        double.parse(json['lat'] as String),
        double.parse(json['lon'] as String),
      ),
    );
  }
}

class LocationSearchService {
  final Dio _dio;
  final String _baseUrl = 'https://nominatim.openstreetmap.org/search';
  final Logger locSearchLog = Logger("Location Search Service");

  LocationSearchService()
    : _dio = Dio(
        BaseOptions(
          headers: {
            'User-Agent':
                'EcoPin/1.0 (klarenzcobie99@gmail.com)', // TODO: Replace later official email
          },
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

  Future<List<LocationSuggestion>> searchLocations(
    String query, {
    String country = 'Philippines',
    String? city,
  }) async {
    try {
      // Build query parameters - NOTE: 'q' parameter format is important
      String searchQuery = query;

      // Add city to query if provided (better than separate parameter)
      if (city != null && city.isNotEmpty) {
        searchQuery = '$query, $city';
      }

      // Add country to query
      if (country.isNotEmpty) {
        searchQuery = '$searchQuery, $country';
      }

      final Map<String, dynamic> queryParams = {
        'q': searchQuery, // Format: "street, city, country"
        'format': 'json',
        'addressdetails': 1,
        'limit': 5,
      };

      // Optional: add a viewbox to prioritize Philippines results, but not strictly bound
      // if (country == 'Philippines') {
      //   queryParams['viewbox'] =
      //       '116.0,5.0,127.0,21.0'; // Entire Philippines
      // }

      // Debug: Print the actual URL being called
      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: queryParams.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );
      locSearchLog.finer('Requesting URL: $uri');

      final response = await _dio.get(_baseUrl, queryParameters: queryParams);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data as List<dynamic>
            : json.decode(response.data as String) as List<dynamic>;

        locSearchLog.finer('Received ${data.length} results');
        return data
            .map(
              (item) =>
                  LocationSuggestion.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }

      return [];
      
    } catch (e) {
      locSearchLog.severe('Error searching locations: $e');
      if (e is DioException) {
        locSearchLog.info('Request URL: ${e.requestOptions.uri}');
        locSearchLog.info('Request params: ${e.requestOptions.queryParameters}');
      }
      return [];
    }
  }
}
