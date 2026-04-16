import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/state/auth_state.dart';
import '../../domain/state/dashboard_state.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worker = ref.watch(authProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('HustleHalt'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.bell),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardDataProvider);
          },
          color: AppTheme.accent,
          backgroundColor: AppTheme.surface,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreeting(context, worker),
                const SizedBox(height: 24),
                _buildCoverageCard(context, ref),
                const SizedBox(height: 24),
                Text('Live Environment', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildEnvironmentGrid(context, ref),
                const SizedBox(height: 32),
                Text('Loyalty & Shield Credits', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildLoyaltyCard(context, ref),
                const SizedBox(height: 32),
                Text('Recent Activity', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildLastPayout(context, ref),
                const SizedBox(height: 48), // Padding for scroll
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(BuildContext context, WorkerModel? worker) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stay Safe, ${worker?.name.split(' ').first ?? 'Partner'}',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(LucideIcons.mapPin, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(
              worker?.zone?.name ?? 'Assigned Zone',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 12),
            const Icon(LucideIcons.shoppingBag, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(
              worker?.qCommercePlatform ?? 'Platform',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14,
              ),
            ),
          ],
        )
      ],
    );
  }


  Widget _buildCoverageCard(BuildContext context, WidgetRef ref) {
    final asyncCoverage = ref.watch(activeCoverageProvider);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: asyncCoverage.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
        error: (e, st) => Text('Failed to load active policy. Have you registered?'),
        data: (coverage) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Active Coverage', style: Theme.of(context).textTheme.bodyMedium),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (coverage['zoneRiskColor'] as Color).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: coverage['zoneRiskColor'] as Color),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.alertTriangle, size: 12, color: coverage['zoneRiskColor']),
                      const SizedBox(width: 4),
                      Text(
                        '${coverage['zoneRisk']} RISK', 
                        style: TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.bold,
                          color: coverage['zoneRiskColor'],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '₹${coverage['amount']}',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppTheme.border),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Weekly Premium:', style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  '₹${coverage['premium']} / week', 
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  )
                ),
              ],
            )
          ],
        )
      )
    );
  }

  Widget _buildEnvironmentGrid(BuildContext context, WidgetRef ref) {
    final asyncEnv = ref.watch(environmentDataProvider);
    
    return asyncEnv.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      error: (e, st) => const Text('Error loading environment data', style: TextStyle(color: AppTheme.error)),
      data: (env) => Row(
        children: [
          Expanded(
            child: _buildEnvCard(
              context,
              title: 'Rainfall',
              value: '${env['rainfall']}',
              unit: 'mm/hr',
              icon: LucideIcons.cloudRain,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildEnvCard(
              context,
              title: 'AQI',
              value: '${env['aqi']}',
              unit: 'Index',
              icon: LucideIcons.wind,
              color: env['aqi'] > 100 ? AppTheme.error : AppTheme.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildEnvCard(
              context,
              title: 'Temp',
              value: '${env['temp']}',
              unit: '°C',
              icon: LucideIcons.thermometer,
              color: AppTheme.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvCard(BuildContext context, {required String title, required String value, required String unit, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(width: 4),
              Text(unit, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLastPayout(BuildContext context, WidgetRef ref) {
    final asyncPayout = ref.watch(lastPayoutProvider);
    
    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: asyncPayout.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
            error: (e, st) => const Text('Error loading payout history.'),
            data: (payout) {
              if (payout == null) {
                return const Text('No payouts credited yet.', style: TextStyle(color: AppTheme.textSecondary));
              }

              return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.banknote, color: AppTheme.success),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Payout Credited', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
                          const SizedBox(height: 4),
                          Text(payout['reason'], style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 2),
                          Text(payout['timestamp'], style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '+₹${payout['amount']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.success,
                      ),
                    ),
                  ],
               );
            }
        ),
    );
  }

  Widget _buildLoyaltyCard(BuildContext context, WidgetRef ref) {
    final asyncLoyalty = ref.watch(loyaltyProvider);
    
    return asyncLoyalty.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      error: (e, st) => const Text('Error loading loyalty data', style: TextStyle(color: AppTheme.error)),
      data: (loyalty) {
        if (loyalty == null) return const SizedBox.shrink();
        
        final eligible = loyalty['shield_credits_eligible'] == true;
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
               Container(
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(
                   color: AppTheme.accent.withOpacity(0.1),
                   shape: BoxShape.circle,
                 ),
                 child: Icon(eligible ? LucideIcons.shieldCheck : LucideIcons.shield, color: AppTheme.accent),
               ),
               const SizedBox(width: 16),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const Text('Shield Credits Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
                     const SizedBox(height: 4),
                     if (eligible)
                        const Text('Eligible for 50% discount on next premium!', style: TextStyle(color: AppTheme.success, fontSize: 13, fontWeight: FontWeight.bold))
                     else
                        Text('${loyalty['consecutive_quiet_weeks']} weeks maintained. ${loyalty['weeks_until_eligible']} more until discount.', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                   ]
                 )
               )
            ]
          )
        );
      }
    );
  }
}
