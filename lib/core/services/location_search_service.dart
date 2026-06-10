import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

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

  LocationSearchService()
    : _dio = Dio(
        BaseOptions(
          headers: {
            'User-Agent':
                'EcoPin/1.0 (klarenzcobie99@gmail.com)', // Replace with your actual info
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

      // Add viewbox properly - format: "left,top,right,bottom"
      // For Metro Manila area
      if (country == 'Philippines') {
        queryParams['viewbox'] =
            '120.9,14.8,121.2,14.3'; // Wider area around Manila
        queryParams['bounded'] = 1;
      }

      // Debug: Print the actual URL being called
      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: queryParams.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );
      print('Requesting URL: $uri');

      final response = await _dio.get(_baseUrl, queryParameters: queryParams);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data as List<dynamic>
            : json.decode(response.data as String) as List<dynamic>;

        print('Received ${data.length} results');
        return data
            .map(
              (item) =>
                  LocationSuggestion.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }
      return [];
    } catch (e) {
      print('Error searching locations: $e');
      if (e is DioException) {
        print('Request URL: ${e.requestOptions.uri}');
        print('Request params: ${e.requestOptions.queryParameters}');
      }
      return [];
    }
  }
}
