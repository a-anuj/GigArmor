import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/domain/state/auth_state.dart';
import '../models/policy_model.dart';

// ── Policy Service ─────────────────────────────────────────────────────────

/// Fetches the live premium quote for the authenticated worker.
/// GET /api/v1/policies/quote/{worker_id}
final premiumQuoteProvider = FutureProvider<PremiumQuoteModel>((ref) async {
  final worker = ref.watch(authProvider);
  if (worker == null) throw Exception('Not authenticated');

  final response = await ApiClient.instance.get('/api/v1/policies/quote/${worker.id}');
  return PremiumQuoteModel.fromJson(response.data as Map<String, dynamic>);
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

  Future<void> enroll(int workerId) async {
    state = state.copyWith(status: EnrollStatus.loading);
    try {
      final response = await ApiClient.instance.post(
        '/api/v1/policies/enroll',
        data: {'worker_id': workerId},
      );
      final result = EnrollResult.fromJson(response.data as Map<String, dynamic>);
      state = state.copyWith(status: EnrollStatus.success, result: result);

      // Invalidate policy history so the list refreshes
      ref.invalidate(policyHistoryProvider);
    } catch (e) {
      state = state.copyWith(status: EnrollStatus.error, errorMessage: e.toString());
    }
  }

  void reset() => state = const EnrollState();
}

final enrollNotifierProvider = NotifierProvider<EnrollNotifier, EnrollState>(EnrollNotifier.new);
