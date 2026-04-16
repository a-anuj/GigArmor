import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/domain/state/auth_state.dart';

class DashboardDataNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() async {
    final worker = ref.watch(authProvider);
    if (worker == null) throw Exception('Not logged in');
    
    final response = await ApiClient.instance.get('/api/v1/workers/${worker.id}/dashboard');
    return response.data;
  }

  void patchEnvironment(Map<String, dynamic> envDiff) {
    if (state.value != null) {
      final current = Map<String, dynamic>.from(state.value!);
      final currentEnv = Map<String, dynamic>.from(current['live_weather'] ?? {});
      currentEnv.addAll(envDiff);
      current['live_weather'] = currentEnv;
      state = AsyncData(current);
    }
  }
}

final dashboardDataProvider = AsyncNotifierProvider<DashboardDataNotifier, Map<String, dynamic>>(DashboardDataNotifier.new);

// Current active policy maps from unified dashboard
final activeCoverageProvider = Provider<AsyncValue<Map<String, dynamic>>>((ref) {
  final dashboardAsync = ref.watch(dashboardDataProvider);

  return dashboardAsync.whenData((dashboard) {
    final activePolicy = dashboard['active_policy'];
    final zoneRisk = dashboard['zone']?['risk_level'] ?? 'LOW';
    
    // Determine color from risk level (not exposing exact score)
    Color riskColor = AppTheme.success;
    if (zoneRisk == 'HIGH') riskColor = AppTheme.error;
    if (zoneRisk == 'MEDIUM') riskColor = Colors.orange;

    if (activePolicy == null) {
      return {
        'amount': 0,
        'premium': 0,
        'zoneRisk': zoneRisk,
        'zoneRiskColor': riskColor,
      };
    }

    return {
      'amount': activePolicy['coverage_amount'],
      'premium': activePolicy['premium_paid'],
      'zoneRisk': zoneRisk, 
      'zoneRiskColor': riskColor,
    };
  });
});

// Environment provider extracts from unified dashboard
final environmentDataProvider = Provider<AsyncValue<Map<String, dynamic>>>((ref) {
  final dashboardAsync = ref.watch(dashboardDataProvider);

  return dashboardAsync.whenData((dashboard) {
    final env = dashboard['live_weather'] ?? {};
    return {
      'rainfall': env['rainfall_mm_hr'] ?? 0.0,
      'aqi': env['aqi'] ?? 65,
      'temp': env['temperature_c'] ?? 28.0,
    };
  });
});

// Last payout maps from unified dashboard
final lastPayoutProvider = Provider<AsyncValue<Map<String, dynamic>?>>((ref) {
  final dashboardAsync = ref.watch(dashboardDataProvider);

  return dashboardAsync.whenData((dashboard) {
    final lastClaim = dashboard['last_claim'];
    if (lastClaim == null) return null;
    
    return {
      'amount': lastClaim['payout_amount'],
      'reason': lastClaim['event_type'] ?? 'System Event',
      'timestamp': 'Recent'
    };
  });
});

// Loyalty mapping from unified dashboard
final loyaltyProvider = Provider<AsyncValue<Map<String, dynamic>?>>((ref) {
  final dashboardAsync = ref.watch(dashboardDataProvider);

  return dashboardAsync.whenData((dashboard) {
    return dashboard['loyalty'];
  });
});
