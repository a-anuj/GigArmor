import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/state/auth_state.dart';
import '../../domain/state/dashboard_state.dart';
import '../../domain/state/activity_state.dart';
import '../../../../core/widgets/language_selector.dart';
import '../../../../core/providers/locale_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worker = ref.watch(authProvider);
    final l10n = ref.watch(appL10nProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          const LanguageSelector(),
          const SizedBox(width: 8),
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
            final w = ref.read(authProvider);
            if (w != null) ref.invalidate(weeklyActivityProvider(w.id));
          },
          color: AppTheme.accent,
          backgroundColor: AppTheme.surface,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreeting(context, worker, ref),
                const SizedBox(height: 24),
                _buildCoverageCard(context, ref),
                const SizedBox(height: 24),
                Text(l10n.liveEnvironment, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildEnvironmentGrid(context, ref),
                const SizedBox(height: 32),
                Text('Weekly Activity', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildActivityCard(context, ref),
                const SizedBox(height: 32),
                Text(l10n.loyaltyShieldCredits, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildLoyaltyCard(context, ref),
                const SizedBox(height: 32),
                Text(l10n.recentActivity, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildLastPayout(context, ref),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(BuildContext context, WorkerModel? worker, WidgetRef ref) {
    final l10n = ref.watch(appL10nProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.staySafe(worker?.name.split(' ').first ?? 'Partner'),
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
              worker?.zone?.name ?? l10n.assignedZone,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 12),
            const Icon(LucideIcons.shoppingBag, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(
              worker?.qCommercePlatform ?? l10n.platform,
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
    final l10n = ref.watch(appL10nProvider);

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
        error: (e, st) => Text(l10n.failedToLoadPolicy),
        data: (coverage) {
          final zoneRisk = coverage['zoneRisk'] as String? ?? 'LOW';
          final isHighRisk = zoneRisk == 'HIGH';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // High-risk weather banner
              if (isHighRisk) ...
                [
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.cloudLightning, color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            '⚠ High-risk week — premium and payout elevated by forecast',
                            style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.activeCoverage, style: Theme.of(context).textTheme.bodyMedium),
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
                          l10n.risk(coverage['zoneRisk'] as String),
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
                coverage['amount'] != null && (coverage['amount'] as num) > 0
                    ? '₹${coverage['amount']}'
                    : l10n.coverageStatusInactive,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: (coverage['amount'] as num? ?? 0) > 0 ? AppTheme.success : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              if ((coverage['amount'] as num? ?? 0) > 0) ...[  
                const Divider(color: AppTheme.border),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.weeklyPremium, style: Theme.of(context).textTheme.bodyMedium),
                    Text(
                      l10n.perWeekLabel(coverage['premium'].toString()),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              ] else ...[  
                const Divider(color: AppTheme.border),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => context.push('/quote'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.shield, color: AppTheme.accent, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'Get Quote & Enroll →',
                          style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildEnvironmentGrid(BuildContext context, WidgetRef ref) {
    final asyncEnv = ref.watch(environmentDataProvider);
    final l10n = ref.watch(appL10nProvider);

    return asyncEnv.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      error: (e, st) => Text(l10n.errorLoadingEnvironment, style: const TextStyle(color: AppTheme.error)),
      data: (env) => Row(
        children: [
          Expanded(
            child: _buildEnvCard(
              context,
              title: l10n.rainfall,
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
              title: l10n.aqi,
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
              title: l10n.temp,
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

  Widget _buildActivityCard(BuildContext context, WidgetRef ref) {
    final worker = ref.watch(authProvider);
    if (worker == null) return const SizedBox.shrink();

    final asyncActivity = ref.watch(weeklyActivityProvider(worker.id));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: asyncActivity.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
        error: (e, st) => Row(
          children: [
            const Icon(LucideIcons.activity, color: AppTheme.textSecondary, size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'No sessions logged yet this week',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
            ),
          ],
        ),
        data: (summary) {
          final levelColor = switch (summary.activityLevel) {
            'HIGH'   => AppTheme.success,
            'MEDIUM' => Colors.orange,
            'LOW'    => Colors.yellowAccent.shade700,
            _        => AppTheme.textSecondary,
          };

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'This Week',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: levelColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: levelColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      summary.activityLevel,
                      style: TextStyle(
                        color: levelColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Stat row
              Row(
                children: [
                  Expanded(child: _buildActivityStat(context, '${summary.totalOrders}', 'Orders', LucideIcons.shoppingCart)),
                  Expanded(child: _buildActivityStat(context, '${summary.totalHours.toStringAsFixed(1)}h', 'On Road', LucideIcons.clock)),
                  Expanded(child: _buildActivityStat(context, '${summary.activeDays}', 'Active Days', LucideIcons.calendarCheck)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                summary.claimContextNote,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActivityStat(BuildContext context, String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.accent, size: 20),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildLastPayout(BuildContext context, WidgetRef ref) {

    final asyncPayout = ref.watch(lastPayoutProvider);
    final l10n = ref.watch(appL10nProvider);

    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: asyncPayout.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
            error: (e, st) => Text(l10n.errorLoadingPayout),
            data: (payout) {
              if (payout == null) {
                return Text(l10n.noPayoutsYet, style: const TextStyle(color: AppTheme.textSecondary));
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
                          Text(l10n.payoutCredited, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
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
    final l10n = ref.watch(appL10nProvider);

    return asyncLoyalty.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      error: (e, st) => Text(l10n.errorLoadingEnvironment, style: const TextStyle(color: AppTheme.error)),
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
                     Text(l10n.shieldCreditsStatus, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
                     const SizedBox(height: 4),
                     if (eligible)
                        Text(l10n.eligibleForDiscount, style: const TextStyle(color: AppTheme.success, fontSize: 13, fontWeight: FontWeight.bold))
                     else
                        Text(
                          l10n.weeksUntilDiscount(
                            '${loyalty['consecutive_quiet_weeks']}',
                            '${loyalty['weeks_until_eligible']}',
                          ),
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
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
