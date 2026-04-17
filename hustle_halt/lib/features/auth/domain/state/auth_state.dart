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
  final double distanceKm;

  ZoneModel({
    required this.id,
    required this.name,
    required this.pincode,
    required this.riskMultiplier,
    this.distanceKm = 0.0,
  });

  factory ZoneModel.fromJson(Map<String, dynamic> json) {
    return ZoneModel(
      id: json['id'] as int,
      name: json['name'] as String,
      pincode: json['pincode'] as String,
      riskMultiplier: (json['base_risk_multiplier'] as num).toDouble(),
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
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

// Updated zonesProvider to fetch nearby zones using Geolocator
final zonesProvider = FutureProvider<List<ZoneModel>>((ref) async {
  double lat = 12.9716; // default Bangalore latitude
  double lon = 77.5946; // default Bangalore longitude
  
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (serviceEnabled) {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        lat = position.latitude;
        lon = position.longitude;
      }
    }
  } catch (e) {
    print('Location error: $e'); // Ignore and fallback
  }

  final response = await ApiClient.instance.get('/api/v1/zones/nearby?lat=$lat&lon=$lon');
  final list = response.data as List;
  return list.map((z) => ZoneModel.fromJson(z)).toList();
});

// Added quote model for PremiumPreview
class QuoteModel {
  final double premium;
  final double coverage;
  final String message;

  QuoteModel({required this.premium, required this.coverage, required this.message});

  factory QuoteModel.fromJson(Map<String, dynamic> json) {
    return QuoteModel(
      premium: (json['premium'] as num).toDouble(),
      coverage: (json['coverage_amount'] as num).toDouble(),
      message: json['message'] as String,
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

