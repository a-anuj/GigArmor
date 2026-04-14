import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import 'package:dio/dio.dart';

class WorkerModel {
  final int id;
  final String name;
  final String phone;
  final int zoneId;
  final double trustScore;

  WorkerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.zoneId,
    required this.trustScore,
  });

  factory WorkerModel.fromJson(Map<String, dynamic> json) {
    return WorkerModel(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      zoneId: json['zone_id'],
      trustScore: json['trust_baseline_score'] ?? 1.0,
    );
  }
}

class AuthNotifier extends Notifier<WorkerModel?> {
  @override
  WorkerModel? build() => null;

  Future<bool> login(String phone) async {
    try {
      final response = await ApiClient.instance.post(
        '/api/v1/workers/login',
        data: {'phone': phone},
      );
      state = WorkerModel.fromJson(response.data);
      return true;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        return false; // Worker not found
      }
      rethrow;
    }
  }

  Future<void> register({
    required String name,
    required String phone,
    required String upiId,
    required int zoneId,
  }) async {
    final response = await ApiClient.instance.post(
      '/api/v1/workers/register',
      data: {
        'name': name,
        'phone': phone,
        'upi_id': upiId,
        'zone_id': zoneId,
      },
    );
    state = WorkerModel.fromJson(response.data);
  }

  void logout() {
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
      premium: json['premium'],
      coverage: json['coverage_amount'],
      message: json['message'],
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
