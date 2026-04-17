import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:geolocator/geolocator.dart';

class ZoneModel {
  final int id;
  final String name;
  final String pincode;
  final double riskMultiplier;
  final double? latitude;
  final double? longitude;
  final double? distanceKm; // populated when fetched via /zones/nearby

  ZoneModel({
    required this.id,
    required this.name,
    required this.pincode,
    required this.riskMultiplier,
    this.latitude,
    this.longitude,
    this.distanceKm,
  });

  factory ZoneModel.fromJson(Map<String, dynamic> json, {double? distanceKm}) {
    return ZoneModel(
      id: json['id'] as int,
      name: json['name'] as String,
      pincode: json['pincode'] as String,
      riskMultiplier: (json['base_risk_multiplier'] as num).toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      distanceKm: distanceKm,
    );
  }
}

class WorkerModel {
  final int id;
  final String name;
  final String phone;
  final String? email;
  final String qCommercePlatform;
  final String? upiId;
  final int zoneId;
  final ZoneModel? zone;
  final String status;
  final double trustScore;
  final bool coldStartActive;

  WorkerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.qCommercePlatform,
    this.upiId,
    required this.zoneId,
    this.zone,
    this.status = 'Active',
    required this.trustScore,
    this.coldStartActive = false,
  });

  factory WorkerModel.fromJson(Map<String, dynamic> json) {
    return WorkerModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      phone: (json['phone'] ?? '') as String,
      email: json['email'] as String?,
      qCommercePlatform: json['q_commerce_platform'] as String? ?? 'Zomato',
      upiId: json['upi_id'] as String?,
      zoneId: (json['zone_id'] as num).toInt(),
      zone: json['zone'] != null ? ZoneModel.fromJson(json['zone']) : null,
      status: json['status'] as String? ?? 'Active',
      trustScore: (json['trust_baseline_score'] as num?)?.toDouble() ?? 1.0,
      coldStartActive: json['cold_start_active'] as bool? ?? false,
    );
  }
}

class AuthNotifier extends Notifier<WorkerModel?> {
  bool _initialized = false;

  @override
  WorkerModel? build() {
    if (!_initialized) {
      _initialized = true;
      Future.microtask(_attemptAutoLogin);
    }
    return null;
  }

  Future<void> _attemptAutoLogin() async {
    final token = Hive.box('auth').get('access_token');
    if (token != null) {
      ApiClient.accessToken = token;
      try {
        await _fetchProfile();
      } catch (e) {
        logout(); // Token invalid or expired
      }
    }
  }

  Future<bool> login(String identifier, String password) async {
    try {
      final response = await ApiClient.instance.post(
        '/api/v1/auth/login',
        data: {
          'identifier': identifier, // Backend accepts email OR phone
          'password': password,
        },
      );
      final token = response.data['access_token'];
      if (token != null) {
        ApiClient.accessToken = token;
        Hive.box('auth').put('access_token', token);
        await _fetchProfile();
        return true;
      }
      return false;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        return false; // Unauthorized
      }
      rethrow;
    }
  }

  Future<void> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String qCommercePlatform,
    String upiId = 'pending@upi',
    required int zoneId,
  }) async {
    final response = await ApiClient.instance.post(
      '/api/v1/auth/register',
      data: {
        'name': name,
        'phone': phone,
        'email': email,
        'password': password,
        'q_commerce_platform': qCommercePlatform,
        'upi_id': upiId,
        'zone_id': zoneId,
      },
    );
    final token = response.data['access_token'];
    if (token != null) {
      ApiClient.accessToken = token;
      Hive.box('auth').put('access_token', token);
      await _fetchProfile();
    }
  }

  Future<void> _fetchProfile() async {
    final response = await ApiClient.instance.get('/api/v1/auth/me');
    state = WorkerModel.fromJson(response.data);
  }

  Future<void> updateZone(int zoneId) async {
    if (state == null) return;
    await ApiClient.instance.patch(
      '/api/v1/workers/${state!.id}/zone',
      data: {'zone_id': zoneId},
    );
    await _fetchProfile(); // Refresh profile to get updated zone and reset state
  }

  Future<void> updateProfile({String? name, String? qCommercePlatform, String? upiId}) async {
    if (state == null) return;
    final Map<String, dynamic> data = {};
    if (name != null && name.isNotEmpty) data['name'] = name;
    if (qCommercePlatform != null && qCommercePlatform.isNotEmpty) data['q_commerce_platform'] = qCommercePlatform;
    if (upiId != null && upiId.isNotEmpty) data['upi_id'] = upiId;
    
    if (data.isEmpty) return;
    
    await ApiClient.instance.patch(
      '/api/v1/workers/${state!.id}',
      data: data,
    );
    await _fetchProfile();
  }

  void logout() {
    ApiClient.accessToken = null;
    Hive.box('auth').delete('access_token');
    state = null;
  }
}

final authProvider = NotifierProvider<AuthNotifier, WorkerModel?>(AuthNotifier.new);

// All dark stores (flat list, no location awareness — used as fallback)
final zonesProvider = FutureProvider<List<ZoneModel>>((ref) async {
  final response = await ApiClient.instance.get('/api/v1/zones');
  final list = response.data as List;
  return list.map((z) => ZoneModel.fromJson(z)).toList();
});

// GPS location state — null means not yet acquired / permission denied
final locationProvider = StateProvider<Position?>((ref) => null);

// Nearby zones by GPS — calls /api/v1/zones/nearby?lat=&lon=
// Sorted by distance and includes distanceKm on each zone.
final nearbyZonesProvider = FutureProvider<List<ZoneModel>>((ref) async {
  final position = ref.watch(locationProvider);
  if (position == null) {
    // Fallback to flat list if GPS isn't available yet
    return ref.watch(zonesProvider.future);
  }
  final response = await ApiClient.instance.get(
    '/api/v1/zones/nearby',
    queryParameters: {
      'lat': position.latitude,
      'lon': position.longitude,
    },
  );
  final list = response.data as List;
  return list.map((z) => ZoneModel.fromJson(z)).toList();
});

/// Requests GPS permission and updates [locationProvider].
/// Returns true if location was successfully obtained.
Future<bool> requestAndFetchLocation(ref) async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low, // Save battery — we only need city-level precision
        timeLimit: Duration(seconds: 8),
      ),
    );
    ref.read(locationProvider.notifier).state = position;
    return true;
  } catch (_) {
    return false;
  }
}

// Added quote model for PremiumPreview
class QuoteModel {
  final double premium;
  final double coverage;
  final String message;
  final double mWeather;
  final String weatherCondition;
  final String weatherSource;

  QuoteModel({
    required this.premium,
    required this.coverage,
    required this.message,
    this.mWeather = 1.0,
    this.weatherCondition = 'Clear',
    this.weatherSource = 'mock',
  });

  factory QuoteModel.fromJson(Map<String, dynamic> json) {
    return QuoteModel(
      premium: (json['premium'] as num).toDouble(),
      coverage: (json['coverage_amount'] as num).toDouble(),
      message: json['message'] as String? ?? '',
      mWeather: (json['m_weather'] as num?)?.toDouble() ?? 1.0,
      weatherCondition: json['weather_condition'] as String? ?? 'Clear',
      weatherSource: json['weather_source'] as String? ?? 'mock',
    );
  }
}

final quoteProvider = FutureProvider.family<QuoteModel, int>((ref, workerId) async {
  final response = await ApiClient.instance.get('/api/v1/policies/quote/$workerId');
  return QuoteModel.fromJson(response.data);
});

final enrollPolicyProvider = FutureProvider.family<void, int>((ref, workerId) async {
  await ApiClient.instance.post('/api/v1/policies/enroll', data: {'worker_id': workerId});
});

