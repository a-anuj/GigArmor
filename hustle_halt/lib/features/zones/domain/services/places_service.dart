import 'dart:math';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import '../models/zone_model.dart';
import '../models/place_autocomplete_model.dart';

class PlacesService {
  // Mock API key placeholder - user should update this
  static const String _apiKey = 'YOUR_GOOGLE_PLACES_API_KEY';

  final _dio = Dio();

  Future<List<PlaceAutocompleteSuggestion>> findAutocompletePredictions(
    String query, {
    String? sessionToken,
    Position? biasPosition,
  }) async {
    if (_apiKey == 'YOUR_GOOGLE_PLACES_API_KEY') {
      // Return empty or mock if no key
      return [];
    }

    try {
      final response = await _dio.post(
        'https://places.googleapis.com/v1/places:autocomplete',
        options: Options(
          headers: {
            'X-Goog-Api-Key': _apiKey,
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'input': query,
          if (sessionToken != null) 'sessionToken': sessionToken,
          if (biasPosition != null)
            'locationBias': {
              'circle': {
                'center': {
                  'latitude': biasPosition.latitude,
                  'longitude': biasPosition.longitude,
                },
                'radius': 10000.0,
              }
            },
        },
      );

      final List suggestions = response.data['suggestions'] ?? [];
      return suggestions
          .map((s) => PlaceAutocompleteSuggestion.fromJson(s))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<PlaceDetails?> getPlaceDetails(String placeId, {String? sessionToken}) async {
    if (_apiKey == 'YOUR_GOOGLE_PLACES_API_KEY') return null;

    try {
      final response = await _dio.get(
        'https://places.googleapis.com/v1/places/$placeId',
        queryParameters: {
          if (sessionToken != null) 'sessionToken': sessionToken,
          'fields': 'id,location,formattedAddress',
          'key': _apiKey,
        },
      );

      return PlaceDetails.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchNearbyHubs(Position pos) async {
    // In a real implementation, we would call Google Places API here.
    // For this task, we simulate "dark store hubs" around the user's location.
    
    await Future.delayed(const Duration(seconds: 2)); // Simulate network lag

    final List<Map<String, dynamic>> hubs = [];
    final random = Random();

    // Define some realistic area names based on general urban layouts
    final areas = [
      "Commercial Hub", "Tech Park", "City Center", "Industrial Estate", 
      "Residential Block A", "Suburban Plaza", "Metro Junction", "Old Town"
    ];

    // Generate 5-8 hubs within a 6km radius to allow for filtering
    for (int i = 0; i < 6 + random.nextInt(3); i++) {
      // Generate random offsets in latitude/longitude approx within 5-6km
      // 1 degree lat is ~111km, so 0.01 is ~1.1km
      final latOffset = (random.nextDouble() - 0.5) * 0.1; 
      final lonOffset = (random.nextDouble() - 0.5) * 0.1;

      final lat = pos.latitude + latOffset;
      final lon = pos.longitude + lonOffset;

      final distance = Geolocator.distanceBetween(pos.latitude, pos.longitude, lat, lon) / 1000;

      hubs.add({
        'id': 'ZN-${100 + i}',
        'name': '${areas[i % areas.length]} Hub',
        'locality': areas[i % areas.length],
        'latitude': lat,
        'longitude': lon,
        'distance': distance,
        // Higher density area = Higher risk usually in gig work context
        'risk': i % 3 == 0 ? RiskLevel.high : (i % 3 == 1 ? RiskLevel.medium : RiskLevel.low),
      });
    }

    return hubs;
  }
}
