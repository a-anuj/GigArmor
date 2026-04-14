import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import 'package:dio/dio.dart';

class WorkerModel {
  final int id;
  final String name;
  final String phone;
  final String? email;
  final int zoneId;
  final double trustScore;

  WorkerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.zoneId,
    required this.trustScore,
  });

  factory WorkerModel.fromJson(Map<String, dynamic> json) {
    return WorkerModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      phone: (json['phone'] ?? '') as String,
      email: json['email'] as String?,
      zoneId: (json['zone_id'] as num).toInt(),
      trustScore: (json['trust_baseline_score'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class AuthNotifier extends Notifier<WorkerModel?> {
  @override
  WorkerModel? build() => null;

  Future<bool> login(String identifier, String password) async {
    try {
      final response = await ApiClient.instance.post(
        '/api/v1/auth/login',
        data: {
          'identifier': identifier,
          'password': password,
        },
      );
      final token = response.data['access_token'];
      if (token != null) {
        ApiClient.accessToken = token;
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
      await _fetchProfile();
    }
  }

  Future<void> _fetchProfile() async {
    final response = await ApiClient.instance.get('/api/v1/auth/me');
    state = WorkerModel.fromJson(response.data);
  }

  void logout() {
    ApiClient.accessToken = null;
    state = null;
  }
}

final authProvider = NotifierProvider<AuthNotifier, WorkerModel?>(AuthNotifier.new);

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
