import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/widgets/language_selector.dart';
import '../../../auth/domain/state/auth_state.dart';
import '../../domain/models/claim_model.dart';
import '../../domain/state/claims_state.dart';

class ClaimStatusScreen extends ConsumerWidget {
  const ClaimStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appL10nProvider);
    final claimsAsync = ref.watch(claimsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.claimsTitle),
        actions: const [LanguageSelector(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: claimsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
          error: (e, st) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.alertCircle, color: AppTheme.error, size: 48),
                  const SizedBox(height: 16),
                  Text(l10n.failedToLoadClaims(e.toString()),
                      textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.error)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(claimsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (result) {
            if (result.claims.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.shieldCheck, size: 64, color: AppTheme.textSecondary.withOpacity(0.4)),
                    const SizedBox(height: 16),
                    Text(l10n.noClaimsFound, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                    const SizedBox(height: 8),
                    const Text('No triggers have fired in your zone yet.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // ── Summary banner ─────────────────────────────────────
                if (result.totalPayout > 0)
                  _PayoutSummaryBanner(totalPayout: result.totalPayout, totalClaims: result.totalClaims),

                // ── Claims list ────────────────────────────────────────
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => ref.invalidate(claimsProvider),
                    color: AppTheme.accent,
                    backgroundColor: AppTheme.surface,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: result.claims.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _ClaimCard(claim: result.claims[index]);
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Payout Summary Banner ──────────────────────────────────────────────────────
class _PayoutSummaryBanner extends StatelessWidget {
  final double totalPayout;
  final int totalClaims;

  const _PayoutSummaryBanner({required this.totalPayout, required this.totalClaims});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.success.withOpacity(0.8), AppTheme.success.withOpacity(0.4)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.banknote, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Payouts Received', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text('₹${totalPayout.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Text('$totalClaims claims', style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Claim Card ─────────────────────────────────────────────────────────────────
class _ClaimCard extends ConsumerWidget {
  final ClaimModel claim;

  const _ClaimCard({required this.claim});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appL10nProvider);
    final worker = ref.watch(authProvider);

    // Status styling
    final (statusColor, statusIcon, statusText) = switch (claim.status) {
      'Auto-Approved' => (AppTheme.success, LucideIcons.checkCircle, l10n.statusAutoApproved),
      'Soft-Hold' => (Colors.orangeAccent, LucideIcons.clock, l10n.statusProcessingSoftHold),
      'Under-Appeal' => (Colors.blueAccent, LucideIcons.messageSquare, 'Under Appeal'),
      'Blocked' => (AppTheme.error, LucideIcons.xCircle, 'Blocked'),
      _ => (AppTheme.textSecondary, LucideIcons.alertCircle, claim.status),
    };

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('CLM-${claim.id}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                Text(
                  claim.createdAt.toLocal().toString().split(' ').first,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),

          // ── Event info ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatEventType(claim.eventType),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      if (claim.zoneName != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(LucideIcons.mapPin, size: 12, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text(claim.zoneName!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (claim.payoutAmount > 0)
                  Text(
                    '+₹${claim.payoutAmount.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.success),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Status & Payout % ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Row(
              children: [
                // Status pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 14),
                      const SizedBox(width: 6),
                      Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Payout % pill
                if (claim.payoutPercentage > 0 && claim.isAutoApproved)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.success.withOpacity(0.4)),
                    ),
                    child: Text(
                      '${claim.payoutPercentage.toStringAsFixed(0)}% payout',
                      style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),

                // Severity badge
                if (claim.eventSeverity != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(
                      claim.eventSeverity!,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 14),

          // ── Info rows ── always shown ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Column(
              children: [
                _infoRow(
                  LucideIcons.info,
                  claim.isAutoApproved ? l10n.autoProcessedNote : l10n.resolutionPending,
                ),
                const SizedBox(height: 8),
                _infoRow(
                  LucideIcons.creditCard,
                  claim.upiWebhookFired ? l10n.expectedCreditUPI : l10n.resolutionPending,
                ),
              ],
            ),
          ),

          // ── Appeal button for Blocked claims ─────────────────────────
          if (claim.canAppeal)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              child: _AppealSection(claim: claim, workerId: worker?.id ?? 0),
            )
          else
            const SizedBox(height: 18),
        ],
      ),
    );
  }

  String _formatEventType(String? eventType) {
    if (eventType == null) return 'System Event';
    return eventType
        .split('_')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppTheme.textSecondary),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4))),
      ],
    );
  }
}

// ── Appeal Section ─────────────────────────────────────────────────────────────
class _AppealSection extends ConsumerStatefulWidget {
  final ClaimModel claim;
  final int workerId;

  const _AppealSection({required this.claim, required this.workerId});

  @override
  ConsumerState<_AppealSection> createState() => _AppealSectionState();
}

class _AppealSectionState extends ConsumerState<_AppealSection> {
  bool _showForm = false;
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appealState = ref.watch(appealNotifierProvider);

    if (appealState.status == AppealStatus.success) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blueAccent.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.messageSquare, color: Colors.blueAccent, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(appealState.message ?? 'Appeal submitted!', style: const TextStyle(color: Colors.blueAccent, fontSize: 13))),
          ],
        ),
      );
    }

    if (!_showForm) {
      return OutlinedButton.icon(
        onPressed: () => setState(() => _showForm = true),
        icon: const Icon(LucideIcons.messageSquare, size: 16),
        label: const Text('Appeal This Decision'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.error,
          side: const BorderSide(color: AppTheme.error),
          padding: const EdgeInsets.symmetric(vertical: 12),
          minimumSize: const Size(double.infinity, 0),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.claim.appealDeadline != null) ...[
          Row(
            children: [
              const Icon(LucideIcons.clock, size: 14, color: Colors.orangeAccent),
              const SizedBox(width: 6),
              Text(
                'Appeal deadline: ${widget.claim.appealDeadline!.toLocal().toString().split('.').first}',
                style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          controller: _reasonController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Explain your reason for appeal (min 10 characters)…',
            hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            filled: true,
            fillColor: AppTheme.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
          ),
        ),
        if (appealState.status == AppealStatus.error) ...[
          const SizedBox(height: 8),
          Text(appealState.errorMessage ?? '', style: const TextStyle(color: AppTheme.error, fontSize: 12)),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _showForm = false),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: appealState.status == AppealStatus.loading
                    ? null
                    : () {
                        if (_reasonController.text.trim().length < 10) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter at least 10 characters.')),
                          );
                          return;
                        }
                        ref.read(appealNotifierProvider.notifier).appealClaim(
                          claimId: widget.claim.id,
                          workerId: widget.workerId,
                          reason: _reasonController.text.trim(),
                        );
                      },
                icon: appealState.status == AppealStatus.loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Icon(LucideIcons.send, size: 16, color: Colors.black),
                label: const Text('Submit', style: TextStyle(color: Colors.black)),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
