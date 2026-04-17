import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/widgets/language_selector.dart';
import '../../domain/models/policy_model.dart';
import '../../domain/state/policy_state.dart';

class PolicyHistoryScreen extends ConsumerWidget {
  const PolicyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appL10nProvider);
    final policiesAsync = ref.watch(policyHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.policyHistoryTitle),
        actions: const [LanguageSelector(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: policiesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
          error: (e, st) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.alertCircle, color: AppTheme.error, size: 48),
                  const SizedBox(height: 16),
                  Text(l10n.failedToLoadPolicies(e.toString()),
                      textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.error)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(policyHistoryProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (policies) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(policyHistoryProvider),
            color: AppTheme.accent,
            backgroundColor: AppTheme.surface,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Get a quote CTA (always shown at top) ─────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _GetQuoteCTA(),
                  ),
                ),

                if (policies.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.fileText, size: 64, color: AppTheme.textSecondary.withOpacity(0.4)),
                          const SizedBox(height: 16),
                          Text(l10n.noPoliciesFound, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                        ],
                      ),
                    ),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Text(
                        l10n.policyHistoryTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final gap = index < policies.length - 1 ? const SizedBox(height: 14) : const SizedBox.shrink();
                          return Column(
                            children: [
                              _PolicyCard(policy: policies[index]),
                              gap,
                            ],
                          );
                        },
                        childCount: policies.length,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Get-a-Quote CTA ────────────────────────────────────────────────────────────
class _GetQuoteCTA extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/quote'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.accent.withOpacity(0.85), AppTheme.accent.withOpacity(0.4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppTheme.accent.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Icon(LucideIcons.shield, color: Colors.white, size: 32),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Get This Week\'s Quote', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('See your personalized premium & enroll', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

// ── Policy Card ────────────────────────────────────────────────────────────────
class _PolicyCard extends ConsumerWidget {
  final PolicyModel policy;
  const _PolicyCard({required this.policy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appL10nProvider);
    final isActive = policy.isActive;
    final startStr = _formatDate(policy.startDate);
    final endStr = _formatDate(policy.endDate);

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        backgroundColor: AppTheme.surface,
        collapsedBackgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isActive ? AppTheme.accent.withOpacity(0.5) : AppTheme.border),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isActive ? AppTheme.accent.withOpacity(0.5) : AppTheme.border),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.success.withOpacity(0.15) : AppTheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isActive ? AppTheme.success : AppTheme.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isActive) ...[
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        isActive ? l10n.statusActive : policy.status,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? AppTheme.success : AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text('POL-${policy.id}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Text(l10n.weekOf(startStr), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
            const SizedBox(height: 3),
            Text(l10n.validThrough(endStr), style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${policy.premiumAmount.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary),
            ),
            const Text('premium', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          const Divider(color: AppTheme.border),
          const SizedBox(height: 12),
          _detailRow(l10n.coverageAmount, '₹${policy.coverageAmount.toStringAsFixed(0)}/day max'),
          const SizedBox(height: 10),
          _detailRow(l10n.policyType, l10n.parametricIncomeProtection),
          const SizedBox(height: 10),
          _detailRow('Premium Paid', '₹${policy.premiumAmount.toStringAsFixed(2)}'),
          const SizedBox(height: 10),
          _detailRow('Valid From', startStr),
          const SizedBox(height: 10),
          _detailRow('Valid Until', endStr),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(LucideIcons.download, size: 16),
              label: Text(l10n.downloadPolicyDocument),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accent,
                side: const BorderSide(color: AppTheme.border),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  String _formatDate(DateTime dt) => dt.toLocal().toString().split(' ').first;
}
