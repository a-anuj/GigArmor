import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../models/zone_model.dart';
import '../../data/repositories/zone_repository.dart';
import '../services/places_service.dart';
import '../services/location_service.dart';

// Services
final locationServiceProvider = Provider((ref) => LocationService());
final placesServiceProvider = Provider((ref) => PlacesService());
final zoneRepositoryProvider = Provider((ref) => ZoneRepository(ref.watch(placesServiceProvider)));

// User Location
final userLocationProvider = StateProvider<Position?>((ref) => null);

// Discovery State
enum DiscoveryStatus { idle, searching, found, error, permissionDenied }

class DiscoveryState {
  final DiscoveryStatus status;
  final List<DarkStoreZone> zones;
  final String? errorMessage;

  const DiscoveryState({
    this.status = DiscoveryStatus.idle,
    this.zones = const [],
    this.errorMessage,
  });

  DiscoveryState copyWith({DiscoveryStatus? status, List<DarkStoreZone>? zones, String? errorMessage}) {
    return DiscoveryState(
      status: status ?? this.status,
      zones: zones ?? this.zones,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ZoneDiscoveryNotifier extends StateNotifier<DiscoveryState> {
  final ZoneRepository _repository;
  final LocationService _locationService;

  ZoneDiscoveryNotifier(this._repository, this._locationService) : super(const DiscoveryState());

  Future<void> discoverZones() async {
    state = state.copyWith(status: DiscoveryStatus.searching);
    
    try {
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        state = state.copyWith(status: DiscoveryStatus.permissionDenied);
        return;
      }
      await _fetchAndSetZones(position);
    } catch (e) {
      state = state.copyWith(status: DiscoveryStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> discoverZonesFromPosition(double lat, double lon) async {
    state = state.copyWith(status: DiscoveryStatus.searching);
    try {
      final position = Position(
        latitude: lat,
        longitude: lon,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );
      await _fetchAndSetZones(position);
    } catch (e) {
      state = state.copyWith(status: DiscoveryStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> _fetchAndSetZones(Position position) async {
    final zones = await _repository.getNearbyZones(position);
    if (zones.isEmpty) {
      state = state.copyWith(status: DiscoveryStatus.found, zones: _repository.getFallbackZones('Local Hubs'));
    } else {
      state = state.copyWith(status: DiscoveryStatus.found, zones: zones);
    }
  }

  void setManualCity(String city) {
    state = state.copyWith(
      status: DiscoveryStatus.found, 
      zones: _repository.getFallbackZones(city)
    );
  }
}

final zoneDiscoveryProvider = StateNotifierProvider<ZoneDiscoveryNotifier, DiscoveryState>((ref) {
  return ZoneDiscoveryNotifier(
    ref.watch(zoneRepositoryProvider),
    ref.watch(locationServiceProvider),
  );
});

// Selected Zone State
final selectedZoneProvider = StateProvider<DarkStoreZone?>((ref) => null);
