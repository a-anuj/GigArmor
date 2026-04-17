import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/domain/state/auth_state.dart';
import 'package:hustle_halt/l10n/app_localizations.dart';
import '../../../../core/widgets/language_selector.dart';
import '../../../../core/providers/locale_provider.dart';

final mockClaimsProvider = FutureProvider<List<dynamic>>((ref) async {
  final worker = ref.watch(authProvider);
  if (worker == null) return [];

  final response = await ApiClient.instance.get('/api/v1/claims/worker/${worker.id}');
  return response.data['claims'] as List;
});

class ClaimStatusScreen extends ConsumerWidget {
  const ClaimStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appL10nProvider);
    final claimsAsync = ref.watch(mockClaimsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.claimsTitle),
        actions: const [LanguageSelector(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: claimsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
          error: (e, st) => Center(child: Text(l10n.failedToLoadClaims(e.toString()), style: const TextStyle(color: AppTheme.error))),
          data: (claims) {
            if (claims.isEmpty) {
               return Center(child: Text(l10n.noClaimsFound, style: const TextStyle(color: AppTheme.textSecondary)));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: claims.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return _buildClaimCard(context, claims[index]);
              },
            );
          }
        )
      ),
    );
  }

  Widget _buildClaimCard(BuildContext context, dynamic claim) {
    final l10n = AppLocalizations.of(context)!;
    Color statusColor;
    IconData statusIcon;
    String statusText;

    final status = claim['status'];
    switch (status) {
      case 'APPROVED':
        statusColor = AppTheme.success;
        statusIcon = LucideIcons.checkCircle;
        statusText = l10n.statusAutoApproved;
        break;
      case 'PROCESSING':
        statusColor = AppTheme.accent;
        statusIcon = LucideIcons.clock;
        statusText = l10n.statusProcessingSoftHold;
        break;
      default: // BLOCKED or REJECTED
        statusColor = AppTheme.error;
        statusIcon = LucideIcons.xCircle;
        statusText = status;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('CLM-${claim['id']}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              Text(claim['date'].toString().split('T').first, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                claim['trigger_description'] ?? l10n.systemEvent,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              if (claim['amount'] > 0)
                Text(
                  '₹${claim['amount']}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, color: statusColor, size: 16),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.border),
          const SizedBox(height: 12),
          _buildInfoRow(LucideIcons.info, claim['notes'] ?? l10n.autoProcessedNote),
          const SizedBox(height: 12),
          _buildInfoRow(
            LucideIcons.creditCard,
            status == 'APPROVED' ? l10n.expectedCreditUPI : l10n.resolutionPending,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.4)),
        ),
      ],
    );
  }
}
