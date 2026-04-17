import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/domain/state/auth_state.dart';
import '../models/claim_model.dart';

// ── Claims Providers ───────────────────────────────────────────────────────

/// Fetches all claims for the authenticated worker (real API, not mock).
/// GET /api/v1/claims/worker/{worker_id}
final claimsProvider = FutureProvider<ClaimsResult>((ref) async {
  final worker = ref.watch(authProvider);
  if (worker == null) {
    return ClaimsResult(workerId: 0, workerName: '', totalClaims: 0, totalPayout: 0, claims: []);
  }

  final response = await ApiClient.instance.get('/api/v1/claims/worker/${worker.id}');
  return ClaimsResult.fromJson(response.data as Map<String, dynamic>);
});

// ── Appeal Notifier ────────────────────────────────────────────────────────

enum AppealStatus { idle, loading, success, error }

class AppealState {
  final AppealStatus status;
  final String? message;
  final String? errorMessage;

  const AppealState({
    this.status = AppealStatus.idle,
    this.message,
    this.errorMessage,
  });

  AppealState copyWith({AppealStatus? status, String? message, String? errorMessage}) {
    return AppealState(
      status: status ?? this.status,
      message: message ?? this.message,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AppealNotifier extends Notifier<AppealState> {
  @override
  AppealState build() => const AppealState();

  /// POST /api/v1/claims/{claim_id}/appeal
  Future<void> appealClaim({
    required int claimId,
    required int workerId,
    required String reason,
  }) async {
    state = state.copyWith(status: AppealStatus.loading);
    try {
      final response = await ApiClient.instance.post(
        '/api/v1/claims/$claimId/appeal',
        data: {'worker_id': workerId, 'reason': reason},
      );
      final msg = response.data['message'] as String? ?? 'Appeal submitted.';
      state = state.copyWith(status: AppealStatus.success, message: msg);

      // Refresh claims list
      ref.invalidate(claimsProvider);
    } catch (e) {
      state = state.copyWith(status: AppealStatus.error, errorMessage: e.toString());
    }
  }

  void reset() => state = const AppealState();
}

final appealNotifierProvider = NotifierProvider<AppealNotifier, AppealState>(AppealNotifier.new);
