import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_inputs.dart';
import '../../../../core/widgets/language_selector.dart';
import 'package:hustle_halt/l10n/app_localizations.dart';
import '../../domain/state/auth_state.dart';

class AuthStepNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void decrement() => state--;
  void setStep(int step) => state = step;
}
final authStepProvider = NotifierProvider<AuthStepNotifier, int>(AuthStepNotifier.new);

class IsLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setLoading(bool loading) => state = loading;
}
final isLoadingProvider = NotifierProvider<IsLoadingNotifier, bool>(IsLoadingNotifier.new);

// Tracks whether GPS detection is in progress
final locationLoadingProvider = StateProvider<bool>((ref) => false);

// Form Controllers
final phoneControllerProvider = Provider((ref) => TextEditingController());
final emailControllerProvider = Provider((ref) => TextEditingController());
final passwordControllerProvider = Provider((ref) => TextEditingController());
final nameControllerProvider = Provider((ref) => TextEditingController());
final qCommerceProvider = StateProvider<String>((ref) => 'Zepto');
final zoneControllerProvider = StateProvider<int>((ref) => 1);

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(authStepProvider);

    // Auto-redirect if auth triggers in the background via auto-login
    ref.listen(authProvider, (previous, next) {
      if (next != null && context.mounted) {
        context.go('/dashboard');
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              if (step > 0 && step != 3)
                GestureDetector(
                  onTap: () => ref.read(authStepProvider.notifier).decrement(),
                  child: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
                ),
              const SizedBox(height: 24),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildStepContent(context, ref, step),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(BuildContext context, WidgetRef ref, int step) {
    switch (step) {
      case 0:
        return _PhoneInputStep(key: const ValueKey(0));
      case 1:
        return _ProfileSetupStep(key: const ValueKey(1));
      case 2:
        return _PremiumPreviewStep(key: const ValueKey(2));
      default:
        return const SizedBox();
    }
  }
}

class _PhoneInputStep extends ConsumerWidget {
  const _PhoneInputStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(isLoadingProvider);
    final phoneController = ref.watch(phoneControllerProvider);
    final passwordController = ref.watch(passwordControllerProvider);

    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.appName,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 32,
                      color: AppTheme.accent,
                    ),
                  ),
                  const LanguageSelector(),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.appDescription,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 48),
              CustomTextField(
                controller: phoneController,
                hintText: AppLocalizations.of(context)!.emailOrPhoneHint,
                prefixIcon: const Icon(LucideIcons.user, color: AppTheme.textSecondary, size: 20),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: passwordController,
                hintText: AppLocalizations.of(context)!.passwordHint,
                obscureText: true,
                prefixIcon: const Icon(LucideIcons.lock, color: AppTheme.textSecondary, size: 20),
              ),
              const Spacer(),
              const SizedBox(height: 24),
              CustomButton(
                text: AppLocalizations.of(context)!.loginButton,
                isLoading: isLoading,
                onPressed: () async {
                  if (phoneController.text.length < 5 || passwordController.text.length < 6) return;

                  ref.read(isLoadingProvider.notifier).setLoading(true);
                  try {
                    final success = await ref.read(authProvider.notifier).login(
                      phoneController.text,
                      passwordController.text,
                    );
                    if (success) {
                      ref.read(authStepProvider.notifier).setStep(2);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.invalidCredentials)),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  } finally {
                    ref.read(isLoadingProvider.notifier).setLoading(false);
                  }
                },
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    ref.read(authStepProvider.notifier).setStep(1);
                  },
                  child: Text(
                    AppLocalizations.of(context)!.registerPrompt,
                    style: const TextStyle(color: AppTheme.accent),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


class _ProfileSetupStep extends ConsumerStatefulWidget {
  const _ProfileSetupStep({super.key});

  @override
  ConsumerState<_ProfileSetupStep> createState() => _ProfileSetupStepState();
}

class _ProfileSetupStepState extends ConsumerState<_ProfileSetupStep> {
  bool _locationAttempted = false;

  @override
  void initState() {
    super.initState();
    // Kick off GPS detection as soon as this step appears
    WidgetsBinding.instance.addPostFrameCallback((_) => _detectLocation());
  }

  Future<void> _detectLocation() async {
    if (_locationAttempted) return;
    _locationAttempted = true;
    ref.read(locationLoadingProvider.notifier).state = true;
    await requestAndFetchLocation(ref);
    if (mounted) {
      ref.read(locationLoadingProvider.notifier).state = false;
      // Refresh nearby zones now that we have a position
      ref.invalidate(nearbyZonesProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nameController     = ref.watch(nameControllerProvider);
    final phoneController    = ref.watch(phoneControllerProvider);
    final emailController    = ref.watch(emailControllerProvider);
    final passwordController = ref.watch(passwordControllerProvider);
    final qCommercePlatform  = ref.watch(qCommerceProvider);
    final isLoading          = ref.watch(isLoadingProvider);
    final locationLoading    = ref.watch(locationLoadingProvider);
    final position           = ref.watch(locationProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.completeProfile,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
              ),
              const LanguageSelector(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.registerDescription,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 32),
          CustomTextField(
            controller: nameController,
            hintText: AppLocalizations.of(context)!.fullNameHint,
            prefixIcon: const Icon(LucideIcons.user, color: AppTheme.textSecondary, size: 20),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: phoneController,
            hintText: AppLocalizations.of(context)!.phoneHint,
            keyboardType: TextInputType.phone,
            prefixIcon: const Icon(LucideIcons.phone, color: AppTheme.textSecondary, size: 20),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: emailController,
            hintText: AppLocalizations.of(context)!.emailHint,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(LucideIcons.mail, color: AppTheme.textSecondary, size: 20),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: passwordController,
            hintText: AppLocalizations.of(context)!.passwordHint,
            obscureText: true,
            prefixIcon: const Icon(LucideIcons.lock, color: AppTheme.textSecondary, size: 20),
          ),
          const SizedBox(height: 16),
          // Platform dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<String>(
                value: qCommercePlatform,
                dropdownColor: AppTheme.surface,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(LucideIcons.shoppingBag, color: AppTheme.textSecondary, size: 20),
                ),
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                onChanged: (val) {
                  if (val != null) ref.read(qCommerceProvider.notifier).state = val;
                },
                items: ['Zepto', 'Blinkit', 'Zomato', 'Swiggy', 'Other'].map((p) =>
                  DropdownMenuItem(value: p, child: Text(p)),
                ).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── GPS-powered dark store selector ───────────────────────────────
          _buildZoneHeader(context, locationLoading, position),
          const SizedBox(height: 8),
          _buildZoneSelector(ref),

          const SizedBox(height: 32),
          CustomButton(
            text: AppLocalizations.of(context)!.registerButton,
            isLoading: isLoading,
            onPressed: () async {
              ref.read(isLoadingProvider.notifier).setLoading(true);
              try {
                await ref.read(authProvider.notifier).register(
                  name: nameController.text,
                  phone: phoneController.text,
                  email: emailController.text,
                  password: passwordController.text,
                  qCommercePlatform: qCommercePlatform,
                  zoneId: ref.read(zoneControllerProvider),
                );
                ref.read(authStepProvider.notifier).setStep(2);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              } finally {
                ref.read(isLoadingProvider.notifier).setLoading(false);
              }
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildZoneHeader(BuildContext context, bool locationLoading, dynamic position) {
    return Row(
      children: [
        Icon(
          position != null ? LucideIcons.mapPin : LucideIcons.mapPinOff,
          color: position != null ? AppTheme.success : AppTheme.textSecondary,
          size: 16,
        ),
        const SizedBox(width: 8),
        if (locationLoading)
          const Text(
            'Detecting your location…',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          )
        else if (position != null)
          Text(
            'Nearby dark stores (ranked by distance)',
            style: const TextStyle(color: AppTheme.success, fontSize: 13, fontWeight: FontWeight.w600),
          )
        else
          GestureDetector(
            onTap: () async {
              ref.read(locationLoadingProvider.notifier).state = true;
              await requestAndFetchLocation(ref);
              if (mounted) {
                ref.read(locationLoadingProvider.notifier).state = false;
                ref.invalidate(nearbyZonesProvider);
              }
            },
            child: const Text(
              'Tap to detect your location',
              style: TextStyle(
                color: AppTheme.accent,
                fontSize: 13,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        if (locationLoading) ...[
          const SizedBox(width: 8),
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2),
          ),
        ],
      ],
    );
  }

  Widget _buildZoneSelector(WidgetRef ref) {
    return ref.watch(nearbyZonesProvider).when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      error: (e, st) => Text('Error loading zones: $e', style: const TextStyle(color: Colors.red, fontSize: 12)),
      data: (zones) {
        final selectedZoneId = ref.watch(zoneControllerProvider);
        // Auto-select first zone if none selected or if current selection isn't in nearby list
        final zoneIds = zones.map((z) => z.id).toList();
        if (!zoneIds.contains(selectedZoneId) && zones.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(zoneControllerProvider.notifier).state = zones.first.id;
          });
        }

        return Column(
          children: zones.map((z) {
            final isSelected = z.id == selectedZoneId;
            return GestureDetector(
              onTap: () => ref.read(zoneControllerProvider.notifier).state = z.id,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.accent.withOpacity(0.1) : AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.accent : AppTheme.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.store,
                      size: 20,
                      color: isSelected ? AppTheme.accent : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            z.name,
                            style: TextStyle(
                              color: isSelected ? AppTheme.accent : AppTheme.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Pincode ${z.pincode}',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    // Show distance badge if available
                    if (z.distanceKm != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Text(
                          '${z.distanceKm!.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      const Icon(LucideIcons.checkCircle2, color: AppTheme.success, size: 18),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}


class _PremiumPreviewStep extends ConsumerWidget {
  const _PremiumPreviewStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worker = ref.watch(authProvider);
    if (worker == null) return const Center(child: CircularProgressIndicator());

    final asyncQuote = ref.watch(quoteProvider(worker.id));

    return asyncQuote.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error loading quote: $e', style: const TextStyle(color: Colors.red))),
      data: (quote) {
        final bool isHighRisk = quote.mWeather >= 2.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),

            // ── Weather alert banner (shown only when forecast is bad) ─────
            if (isHighRisk)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.cloudRain, color: Colors.orange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'High-Risk Week Detected',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Forecast: ${quote.weatherCondition}. '
                            'Your premium is slightly higher this week — and so is your compensation if a trigger fires.',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  const Icon(LucideIcons.shieldCheck, color: AppTheme.success, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.coverageEstimatedFor(worker.name),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  // Weather multiplier chip
                  if (isHighRisk)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '⛈ Weather risk: ${quote.mWeather.toStringAsFixed(1)}× multiplier active',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.perWeek(quote.premium.toStringAsFixed(0)),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppTheme.border),
                  const SizedBox(height: 16),
                  _buildFeatureRow('Up to ₹${quote.coverage.toStringAsFixed(0)} coverage this week'),
                  const SizedBox(height: 12),
                  if (isHighRisk)
                    _buildFeatureRow('Coverage increased due to severe forecast')
                  else
                    _buildFeatureRow('Standard coverage — clear forecast ahead'),
                  const SizedBox(height: 8),
                  _buildFeatureRow('Data: ${quote.weatherSource}'),
                ],
              ),
            ),
            const Spacer(),
            CustomButton(
              text: AppLocalizations.of(context)!.startCoverageButton,
              onPressed: () async {
                try {
                  await ref.read(enrollPolicyProvider(worker.id).future);
                  if (context.mounted) context.go('/dashboard');
                } catch (e) {
                  if (!context.mounted) return;
                  // Extract the backend's 'detail' message from DioException
                  String message = 'Something went wrong. Please try again.';
                  String title   = 'Enrollment Failed';
                  bool alreadyActive = false;

                  if (e is Exception) {
                    final raw = e.toString();
                    // Dio wraps backend 422/409 detail in the exception message
                    final detailMatch = RegExp(r'"?detail"?\s*:\s*"?([^"}\]]+)"?').firstMatch(raw);
                    if (detailMatch != null) {
                      message = detailMatch.group(1)!.trim();
                    } else if (raw.contains('already has an active policy') || raw.contains('active policy')) {
                      message = raw;
                    }
                    if (message.toLowerCase().contains('active policy')) {
                      title = 'Already Covered ✓';
                      alreadyActive = true;
                    }
                  }

                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppTheme.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      icon: Icon(
                        alreadyActive ? LucideIcons.shieldCheck : LucideIcons.alertCircle,
                        color: alreadyActive ? AppTheme.success : AppTheme.error,
                        size: 40,
                      ),
                      title: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: alreadyActive ? AppTheme.success : AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      content: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
                      ),
                      actionsAlignment: MainAxisAlignment.center,
                      actions: [
                        if (alreadyActive)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.success,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            icon: const Icon(LucideIcons.arrowRight, size: 16),
                            label: const Text('Go to Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              Navigator.pop(ctx);
                              context.go('/dashboard');
                            },
                          )
                        else ...[
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Close', style: TextStyle(color: AppTheme.textSecondary)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accent,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              context.go('/dashboard');
                            },
                            child: const Text('Go to Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: AppLocalizations.of(context)!.maybeLaterButton,
              isOutlined: true,
              onPressed: () {
                context.go('/dashboard');
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeatureRow(String text) {
    return Row(
      children: [
        const Icon(LucideIcons.checkCircle2, color: AppTheme.success, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(color: AppTheme.textPrimary))),
      ],
    );
  }
}
