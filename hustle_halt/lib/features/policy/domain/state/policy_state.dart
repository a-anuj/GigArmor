import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/domain/state/auth_state.dart';
import '../../../zones/domain/models/zone_model.dart';
import '../../../zones/domain/state/zone_provider.dart';
import '../models/policy_model.dart';

// ── Policy Service ─────────────────────────────────────────────────────────

/// Fetches the live premium quote for the authenticated worker.
/// GET /api/v1/policies/quote/{worker_id}
final premiumQuoteProvider = FutureProvider<PremiumQuoteModel>((ref) async {
  final worker = ref.watch(authProvider);
  if (worker == null) throw Exception('Not authenticated');

  final selectedZone = ref.watch(selectedZoneProvider);

  final response = await ApiClient.instance.get('/api/v1/policies/quote/${worker.id}');
  var quote = PremiumQuoteModel.fromJson(response.data as Map<String, dynamic>);

  // SIMULATION: Recalculate based on dynamic zone selection
  if (selectedZone != null) {
    double multiplier = switch (selectedZone.riskLevel) {
      RiskLevel.low => 0.8,
      RiskLevel.medium => 1.0,
      RiskLevel.high => 1.5,
    };

    // Calculate new premium and coverage
    double newPremium = (quote.rawPremium * multiplier).clamp(19.0, 149.0);
    double newCoverage = selectedZone.riskLevel == RiskLevel.high ? 2500.0 : 1200.0;

    // Return a modified quote object (using mock data for simulation)
    // Note: In real production, this logic would happen on the backend.
    return PremiumQuoteModel(
      workerId: quote.workerId,
      workerName: quote.workerName,
      zoneId: int.tryParse(selectedZone.id.split('-').last) ?? quote.zoneId,
      zoneName: selectedZone.name,
      rBase: quote.rBase,
      mWeather: quote.mWeather,
      mSocial: quote.mSocial,
      mColdstart: quote.mColdstart,
      hExpected: quote.hExpected,
      baseRiskMultiplier: multiplier,
      rawPremium: quote.rawPremium,
      premiumBeforeDiscount: newPremium,
      premium: newPremium,
      weatherCondition: quote.weatherCondition,
      socialCondition: quote.socialCondition,
      coldStartActive: quote.coldStartActive,
      consecutiveQuietWeeks: quote.consecutiveQuietWeeks,
      shieldCreditsApplied: quote.shieldCreditsApplied,
      discountAmount: quote.discountAmount,
      coverageAmount: newCoverage,
      message: 'Zone Adjusted Premium (${selectedZone.riskLevel.label} Risk)',
      liveRainfallMmHr: quote.liveRainfallMmHr,
      liveTemperatureC: quote.liveTemperatureC,
      liveHumidityPct: quote.liveHumidityPct,
    );
  }

  return quote;
});

/// Fetches full policy history for the authenticated worker.
/// GET /api/v1/policies/worker/{worker_id}
final policyHistoryProvider = FutureProvider<List<PolicyModel>>((ref) async {
  final worker = ref.watch(authProvider);
  if (worker == null) return [];

  final response = await ApiClient.instance.get('/api/v1/policies/worker/${worker.id}');
  final list = response.data['policies'] as List;
  return list.map((p) => PolicyModel.fromJson(p as Map<String, dynamic>)).toList();
});

// ── Enroll Notifier ────────────────────────────────────────────────────────

enum EnrollStatus { idle, loading, success, error }

class EnrollState {
  final EnrollStatus status;
  final EnrollResult? result;
  final String? errorMessage;

  const EnrollState({
    this.status = EnrollStatus.idle,
    this.result,
    this.errorMessage,
  });

  EnrollState copyWith({EnrollStatus? status, EnrollResult? result, String? errorMessage}) {
    return EnrollState(
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class EnrollNotifier extends Notifier<EnrollState> {
  @override
  EnrollState build() => const EnrollState();

  Future<void> enroll(int workerId, String paymentId, String orderId, String signature) async {
    state = state.copyWith(status: EnrollStatus.loading);
    try {
      final response = await ApiClient.instance.post(
        '/api/v1/policies/enroll',
        data: {
          'worker_id': workerId,
          'razorpay_payment_id': paymentId,
          'razorpay_order_id': orderId,
          'razorpay_signature': signature,
        },
      );
      final result = EnrollResult.fromJson(response.data as Map<String, dynamic>);
      state = state.copyWith(status: EnrollStatus.success, result: result);

      // Invalidate policy history so the list refreshes
      ref.invalidate(policyHistoryProvider);
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? e.message;
      state = state.copyWith(status: EnrollStatus.error, errorMessage: msg.toString());
    } catch (e) {
      state = state.copyWith(status: EnrollStatus.error, errorMessage: e.toString());
    }
  }

  void reset() => state = const EnrollState();
}

final enrollNotifierProvider = NotifierProvider<EnrollNotifier, EnrollState>(EnrollNotifier.new);
