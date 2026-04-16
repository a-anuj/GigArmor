import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import 'package:dio/dio.dart';

class ZoneModel {
  final int id;
  final String name;
  final String pincode;
  final double riskMultiplier;

  ZoneModel({
    required this.id,
    required this.name,
    required this.pincode,
    required this.riskMultiplier,
  });

  factory ZoneModel.fromJson(Map<String, dynamic> json) {
    return ZoneModel(
      id: json['id'] as int,
      name: json['name'] as String,
      pincode: json['pincode'] as String,
      riskMultiplier: (json['base_risk_multiplier'] as num).toDouble(),
    );
  }
}

class WorkerModel {
  final int id;
  final String name;
  final String phone;
  final String? email;
  final int zoneId;
  final ZoneModel? zone;
  final double trustScore;
  final bool coldStartActive;

  WorkerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.zoneId,
    this.zone,
    required this.trustScore,
    this.coldStartActive = false,
  });

  factory WorkerModel.fromJson(Map<String, dynamic> json) {
    return WorkerModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      phone: (json['phone'] ?? '') as String,
      email: json['email'] as String?,
      zoneId: (json['zone_id'] as num).toInt(),
      zone: json['zone'] != null ? ZoneModel.fromJson(json['zone']) : null,
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
    required String upiId,
    required int zoneId,
  }) async {
    final response = await ApiClient.instance.post(
      '/api/v1/auth/register',
      data: {
        'name': name,
        'phone': phone,
        'email': email,
        'password': password,
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

  void logout() {
    ApiClient.accessToken = null;
    Hive.box('auth').delete('access_token');
    state = null;
  }
}

final authProvider = NotifierProvider<AuthNotifier, WorkerModel?>(AuthNotifier.new);

// Added zonesProvider to fetch all dark stores
final zonesProvider = FutureProvider<List<ZoneModel>>((ref) async {
  final response = await ApiClient.instance.get('/api/v1/zones');
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

