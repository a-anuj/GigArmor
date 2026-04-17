import 'package:geolocator/geolocator.dart';
import '../../domain/models/zone_model.dart';
import '../../domain/services/places_service.dart';
import '../../../../core/network/api_client.dart';

class ZoneRepository {
  final PlacesService _placesService;

  ZoneRepository(this._placesService);

  Future<List<DarkStoreZone>> getNearbyZones(Position pos) async {
    // 1. Fetch real administrative zones from backend
    List<Map<String, dynamic>> backendZones = [];
    try {
      final response = await ApiClient.instance.get('/api/v1/zones');
      backendZones = List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      // Fallback to empty if backend is down
    }

    // 2. Fetch simulated/nearby hubs via Places API
    final rawHubs = await _placesService.fetchNearbyHubs(pos);

    final List<DarkStoreZone> zones = rawHubs.map((h) {
      // Find the closest backend administrative zone ID
      int? mappedZoneId;
      double minDistance = double.infinity;

      for (var bz in backendZones) {
        if (bz['latitude'] != null && bz['longitude'] != null) {
          final dist = Geolocator.distanceBetween(
            h['latitude'], h['longitude'],
            bz['latitude'], bz['longitude']
          );
          if (dist < minDistance) {
            minDistance = dist;
            mappedZoneId = bz['id'];
          }
        }
      }

      // If no mapping found (e.g. no zones in DB), default to 1 as catch-all
      mappedZoneId ??= 1;

      return DarkStoreZone(
        id: h['id'],
        name: h['name'],
        backendZoneId: mappedZoneId,
        distanceKm: h['distance'],
        riskLevel: h['risk'],
        locality: h['locality'],
        latitude: h['latitude'],
        longitude: h['longitude'],
      );
    }).toList();

    // 3. FILTER BY RADIUS
    final filteredZones = zones.where((z) => z.distanceKm <= 5.0).toList();
    filteredZones.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    return filteredZones;
  }

  /// Simulation for fallback zones if no hubs are found or location is denied
  List<DarkStoreZone> getFallbackZones(String city) {
    return [
      DarkStoreZone.mock('ZN-FB1', '$city Central Hub', 0.0, RiskLevel.medium, 'Main City Center', backendZoneId: 1),
      DarkStoreZone.mock('ZN-FB2', '$city North Hub', 4.2, RiskLevel.low, 'Residential Hub', backendZoneId: 2),
      DarkStoreZone.mock('ZN-FB3', '$city West Hub', 5.8, RiskLevel.high, 'Industrial Hub', backendZoneId: 3),
    ];
  }
}
