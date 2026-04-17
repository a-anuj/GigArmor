import 'package:google_fonts/google_fonts.dart';

enum RiskLevel { 
  low, medium, high;

  String get label => name.toUpperCase();
}

class DarkStoreZone {
  final String id;
  final String name;
  final int? backendZoneId; // Maps to the real administrative zone in DB
  final double distanceKm;
  final RiskLevel riskLevel;
  final String description;
  final double? latitude;
  final double? longitude;
  final String locality;

  const DarkStoreZone({
    required this.id,
    required this.name,
    this.backendZoneId,
    required this.distanceKm,
    required this.riskLevel,
    this.description = 'High delivery activity area',
    this.latitude,
    this.longitude,
    required this.locality,
  });

  factory DarkStoreZone.mock(String id, String name, double distance, RiskLevel risk, String locality, {int? backendZoneId}) {
    return DarkStoreZone(
      id: id,
      name: name,
      backendZoneId: backendZoneId,
      distanceKm: distance,
      riskLevel: risk,
      locality: locality,
    );
  }
}
