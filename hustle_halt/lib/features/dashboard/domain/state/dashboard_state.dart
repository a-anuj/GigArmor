import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/domain/state/auth_state.dart';

// Current active policy FutureProvider
final activeCoverageProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final worker = ref.watch(authProvider);
  if (worker == null) throw Exception('Not logged in');

  final response = await ApiClient.instance.get('/api/v1/policies/worker/${worker.id}');
  final policies = response.data['policies'] as List;
  
  if (policies.isEmpty) {
    return {
      'amount': 0,
       'premium': 0,
       'zoneRisk': 'UNKNOWN',
       'zoneRiskColor': AppTheme.textSecondary,
    };
  }

  // Find active
  final activePol = policies.firstWhere((p) => p['status'] == 'ACTIVE', orElse: () => policies.first);
  
  // Hard code risk color calculation for now based on score
  final isHighRisk = worker.trustScore < 0.8;
  
  return {
    'amount': activePol['coverage_amount'],
    'premium': activePol['premium_amount'],
    'zoneRisk': isHighRisk ? 'HIGH' : 'LOW', 
    'zoneRiskColor': isHighRisk ? AppTheme.error : AppTheme.success,
  };
});

// Mock environment provider that can be overridden by simulator
class EnvironmentDataNotifier extends Notifier<Map<String, dynamic>> {
  @override
  Map<String, dynamic> build() {
    return {
      'rainfall': 0.0, // mm/hr
      'aqi': 65,
      'temp': 28, // Celsius
    };
  }

  void updateEnvironment(Map<String, dynamic> newEnv) {
    state = newEnv;
  }
}

final environmentDataProvider = NotifierProvider<EnvironmentDataNotifier, Map<String, dynamic>>(EnvironmentDataNotifier.new);

// Last payout based on actual claims API
final lastPayoutProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final worker = ref.watch(authProvider);
  if (worker == null) return null;

  final response = await ApiClient.instance.get('/api/v1/claims/worker/${worker.id}');
  final claims = response.data['claims'] as List;
  
  if (claims.isEmpty) return null;
  
  final latestClaim = claims.first; // Assuming ordered
  
  return {
    'amount': latestClaim['amount'],
    'reason': latestClaim['trigger_description'] ?? 'System Event',
    'timestamp': 'Recent'
  };
});
