import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/language_selector.dart';
import '../../../auth/domain/state/auth_state.dart';
import '../../domain/models/policy_model.dart';
import '../../domain/state/policy_state.dart';

class PremiumQuoteScreen extends ConsumerWidget {
  const PremiumQuoteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appL10nProvider);
    final worker = ref.watch(authProvider);
    final quoteAsync = ref.watch(premiumQuoteProvider);
    final enrollState = ref.watch(enrollNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.weeklyPremium.replaceAll(':', '')),
        actions: const [LanguageSelector(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: quoteAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
          error: (e, st) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.alertCircle, color: AppTheme.error, size: 48),
                  const SizedBox(height: 16),
                  Text(e.toString(), textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.error)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(premiumQuoteProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (quote) => SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header card ───────────────────────────────────────────
                _PremiumHeroCard(quote: quote),
                const SizedBox(height: 24),

                // ── Breakdown header ──────────────────────────────────────
                Text(
                  'How Your Premium is Calculated',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // ── Multiplier breakdown ──────────────────────────────────
                _MultiplierCard(
                  icon: LucideIcons.mapPin,
                  color: AppTheme.accent,
                  label: 'Zone Base Risk',
                  value: '${quote.baseRiskMultiplier}×',
                  subtitle: quote.zoneName,
                ),
                const SizedBox(height: 10),
                _MultiplierCard(
                  icon: LucideIcons.cloudRain,
                  color: _weatherColor(quote.mWeather),
                  label: 'Weather Multiplier',
                  value: '${quote.mWeather.toStringAsFixed(2)}×',
                  subtitle: quote.weatherCondition,
                ),
                const SizedBox(height: 10),
                _MultiplierCard(
                  icon: LucideIcons.users,
                  color: Colors.purpleAccent,
                  label: 'Social Disruption',
                  value: '${quote.mSocial.toStringAsFixed(2)}×',
                  subtitle: quote.socialCondition,
                ),
                if (quote.coldStartActive) ...[
                  const SizedBox(height: 10),
                  _MultiplierCard(
                    icon: LucideIcons.zap,
                    color: Colors.orangeAccent,
                    label: 'Cold-Start (First 2 Weeks)',
                    value: '${quote.mColdstart.toStringAsFixed(1)}×',
                    subtitle: 'New partner bonus period',
                  ),
                ],

                const SizedBox(height: 24),

                // ── Premium breakdown ─────────────────────────────────────
                _PremiumBreakdownCard(quote: quote),
                const SizedBox(height: 24),

                // ── Shield Credits ────────────────────────────────────────
                _ShieldCreditsCard(quote: quote),
                const SizedBox(height: 32),

                // ── Enroll Button ─────────────────────────────────────────
                if (enrollState.status == EnrollStatus.success)
                  _EnrollSuccessBanner(result: enrollState.result!)
                else
                  _EnrollButton(
                    quote: quote,
                    workerId: worker?.id ?? 0,
                    isLoading: enrollState.status == EnrollStatus.loading,
                    errorMessage: enrollState.status == EnrollStatus.error
                        ? enrollState.errorMessage
                        : null,
                  ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _weatherColor(double m) {
    if (m >= 2.5) return AppTheme.error;
    if (m >= 1.5) return Colors.orangeAccent;
    return AppTheme.success;
  }
}

// ── Premium Hero Card ──────────────────────────────────────────────────────────
class _PremiumHeroCard extends StatelessWidget {
  final PremiumQuoteModel quote;
  const _PremiumHeroCard({required this.quote});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.accent.withOpacity(0.9), AppTheme.accent.withOpacity(0.4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppTheme.accent.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('This Week\'s Premium', style: TextStyle(color: Colors.white70, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  quote.coldStartActive ? '🆕 Cold Start' : '✅ Standard',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${quote.premium.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold, height: 1),
          ),
          const SizedBox(height: 4),
          Text('/ week', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16)),
          const SizedBox(height: 16),
          const Divider(color: Colors.white30),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _heroStat('Coverage', '₹${quote.coverageAmount.toStringAsFixed(0)}/day'),
              _heroStat('Zone', quote.zoneName),
              _heroStat('Worker', quote.workerName.split(' ').first),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ── Multiplier Row Card ────────────────────────────────────────────────────────
class _MultiplierCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String? subtitle;

  const _MultiplierCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                if (subtitle != null)
                  Text(subtitle!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

// ── Premium Breakdown Card ────────────────────────────────────────────────────
class _PremiumBreakdownCard extends StatelessWidget {
  final PremiumQuoteModel quote;
  const _PremiumBreakdownCard({required this.quote});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Premium Calculation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          _rowLine('Raw premium (formula)', '₹${quote.rawPremium.toStringAsFixed(2)}'),
          _rowLine('After ₹19–₹99 clamp', '₹${quote.premiumBeforeDiscount.toStringAsFixed(2)}'),
          if (quote.shieldCreditsApplied) ...[
            _rowLine('Shield Credits discount (-20%)', '-₹${quote.discountAmount.toStringAsFixed(2)}', color: AppTheme.success),
          ],
          const Divider(color: AppTheme.border, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Final Premium', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
              Text('₹${quote.premium.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.accent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rowLine(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          Text(value, style: TextStyle(color: color ?? AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Shield Credits Card ────────────────────────────────────────────────────────
class _ShieldCreditsCard extends StatelessWidget {
  final PremiumQuoteModel quote;
  const _ShieldCreditsCard({required this.quote});

  @override
  Widget build(BuildContext context) {
    final eligible = quote.shieldCreditsApplied;
    final color = eligible ? AppTheme.success : AppTheme.accent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(eligible ? LucideIcons.shieldCheck : LucideIcons.shield, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eligible ? '🛡️ Shield Credits Active!' : 'Shield Credits Progress',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  eligible
                      ? '${quote.consecutiveQuietWeeks} quiet weeks — 20% discount applied!'
                      : '${quote.consecutiveQuietWeeks}/4 quiet weeks. ${4 - quote.consecutiveQuietWeeks} more for 50% discount!',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EnrollButton extends ConsumerStatefulWidget {
  final PremiumQuoteModel quote;
  final int workerId;
  final bool isLoading;
  final String? errorMessage;

  const _EnrollButton({required this.quote, required this.workerId, required this.isLoading, this.errorMessage});

  @override
  ConsumerState<_EnrollButton> createState() => _EnrollButtonState();
}

class _EnrollButtonState extends ConsumerState<_EnrollButton> {
  late Razorpay _razorpay;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (!mounted) return;
    ref.read(enrollNotifierProvider.notifier).enroll(
      widget.workerId,
      response.paymentId ?? '',
      response.orderId ?? '',
      response.signature ?? '',
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  Future<void> _handleEnroll(BuildContext context) async {
    setState(() => _isInitializing = true);
    try {
      final res = await ApiClient.instance.post('/api/v1/policies/create-order/${widget.workerId}');
      final orderId = res.data['order_id'] as String;
      
      var options = {
        'key': 'rzp_test_SeRpQpOTDyHEkk',
        'amount': (widget.quote.premium * 100).toInt(),
        'name': 'GigArmor',
        'description': 'Weekly Premium Cover',
        'order_id': orderId,
        'prefill': {
          'contact': '9876543210',
          'email': 'worker@gigarmor.com'
        },
        'theme': {
           'color': '#00ADB5'
        }
      };
      
      _razorpay.open(options);
    } catch (e) {
      if (mounted) {
         String errMessage = e.toString();
         if (e is DioException) {
            errMessage = e.response?.data?['detail']?.toString() ?? e.message ?? 'Unknown checkout error';
         }
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errMessage)));
      }
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showLoading = widget.isLoading || _isInitializing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.error.withOpacity(0.4)),
            ),
            child: Text(widget.errorMessage!, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: showLoading || widget.workerId == 0 ? null : () => _handleEnroll(context),
            icon: showLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                : const Icon(LucideIcons.shield, color: Colors.black),
            label: Text(
              showLoading ? 'Initializing Gateway...' : 'Enroll via Razorpay for ₹${widget.quote.premium.toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Coverage active immediately post-payment · Auto-approved on trigger',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

// ── Enroll Success Banner ──────────────────────────────────────────────────────
class _EnrollSuccessBanner extends StatelessWidget {
  final EnrollResult result;
  const _EnrollSuccessBanner({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.success.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.success.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.checkCircle, color: AppTheme.success, size: 40),
          const SizedBox(height: 12),
          const Text('Enrolled Successfully!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.success)),
          const SizedBox(height: 8),
          Text(result.message, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          Text(
            'Policy #${result.policy.id} · Valid until ${result.policy.endDate.toLocal().toString().split(' ').first}',
            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
