import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/domain/state/auth_state.dart';
import 'package:hustle_halt/l10n/app_localizations.dart';
import '../../../../core/widgets/language_selector.dart';
import '../../../../core/providers/locale_provider.dart';

final mockPoliciesProvider = FutureProvider<List<dynamic>>((ref) async {
  final worker = ref.watch(authProvider);
  if (worker == null) return [];

  final response = await ApiClient.instance.get('/api/v1/policies/worker/${worker.id}');
  return response.data['policies'] as List;
});

class PolicyHistoryScreen extends ConsumerWidget {
  const PolicyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appL10nProvider);
    final policiesAsync = ref.watch(mockPoliciesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.policyHistoryTitle),
        actions: const [LanguageSelector(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: policiesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
          error: (e, st) => Center(child: Text(l10n.failedToLoadPolicies(e.toString()), style: const TextStyle(color: AppTheme.error))),
          data: (policies) {
            if (policies.isEmpty) {
              return Center(child: Text(l10n.noPoliciesFound, style: const TextStyle(color: AppTheme.textSecondary)));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: policies.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return _buildPolicyCard(context, policies[index]);
              },
            );
          }
        )
      ),
    );
  }

  Widget _buildPolicyCard(BuildContext context, dynamic policy) {
    final l10n = AppLocalizations.of(context)!;
    final isActive = policy['status'] == 'ACTIVE';

    final startStr = policy['start_date'].toString().split('T').first;
    final endStr = policy['end_date'].toString().split('T').first;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        backgroundColor: AppTheme.surface,
        collapsedBackgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.border),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.border),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.success.withOpacity(0.2) : AppTheme.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: isActive ? AppTheme.success : AppTheme.border),
                  ),
                  child: Text(
                    isActive ? l10n.statusActive : policy['status'],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isActive ? AppTheme.success : AppTheme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('POL-${policy['id']}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.weekOf(startStr),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.validThrough(endStr),
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
        trailing: Text(
          '₹${policy['premium_amount']}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppTheme.textPrimary,
          ),
        ),
        childrenPadding: const EdgeInsets.all(20).copyWith(top: 0),
        children: [
          const Divider(color: AppTheme.border),
          const SizedBox(height: 16),
          _buildDetailRow(l10n.coverageAmount, l10n.coverageAmountValue(policy['coverage_amount'].toString())),
          const SizedBox(height: 12),
          _buildDetailRow(l10n.policyType, l10n.parametricIncomeProtection),
          const SizedBox(height: 12),
          _buildDetailRow(l10n.claimsCount, l10n.notAvailable),
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
        Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
