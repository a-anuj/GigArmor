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

// Form Controllers
final phoneControllerProvider = Provider((ref) => TextEditingController());
final emailControllerProvider = Provider((ref) => TextEditingController());
final passwordControllerProvider = Provider((ref) => TextEditingController());
final nameControllerProvider = Provider((ref) => TextEditingController());
final upiControllerProvider = Provider((ref) => TextEditingController());
final zoneControllerProvider = StateProvider<int>((ref) => 1); // Default to Koramangala (1)

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
              const SizedBox(height: 24), // Added a small spacing for keyboard
              CustomButton(
                text: AppLocalizations.of(context)!.loginButton,
                isLoading: isLoading,
                onPressed: () async {
                  if (phoneController.text.length < 5 || passwordController.text.length < 6) return;
                  
                  ref.read(isLoadingProvider.notifier).setLoading(true);
                  try {
                    final success = await ref.read(authProvider.notifier).login(phoneController.text, passwordController.text);
                    if (success) {
                      // If login works, jump straight to quote or dashboard
                      ref.read(authStepProvider.notifier).setStep(2); 
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.invalidCredentials)));
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
                  child: Text(AppLocalizations.of(context)!.registerPrompt, style: const TextStyle(color: AppTheme.accent)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


class _ProfileSetupStep extends ConsumerWidget {
  const _ProfileSetupStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = ref.watch(nameControllerProvider);
    final phoneController = ref.watch(phoneControllerProvider);
    final emailController = ref.watch(emailControllerProvider);
    final passwordController = ref.watch(passwordControllerProvider);
    final upiController = ref.watch(upiControllerProvider);
    final isLoading = ref.watch(isLoadingProvider);

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
          CustomTextField(
            controller: upiController,
            hintText: AppLocalizations.of(context)!.upiIdHint,
            prefixIcon: const Icon(LucideIcons.creditCard, color: AppTheme.textSecondary, size: 20),
          ),
          const SizedBox(height: 16),
          // Dynamic Zone Selection
          ref.watch(zonesProvider).when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
            error: (e, st) => Text('Error loading zones: $e', style: const TextStyle(color: Colors.red, fontSize: 12)),
            data: (zones) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<int>(
                    value: ref.watch(zoneControllerProvider),
                    dropdownColor: AppTheme.surface,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      prefixIcon: Icon(LucideIcons.mapPin, color: AppTheme.textSecondary, size: 20),
                    ),
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(zoneControllerProvider.notifier).state = val;
                      }
                    },
                    items: zones.map((z) => DropdownMenuItem(
                      value: z.id,
                      child: Text(z.name),
                    )).toList(),
                  ),
                ),
              );
            },
          ),

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
                  upiId: upiController.text,
                  zoneId: ref.read(zoneControllerProvider),
                );
                ref.read(authStepProvider.notifier).setStep(2);
              } catch (e) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),
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
                  _buildFeatureRow('Up to ₹${quote.coverage.toStringAsFixed(0)} coverage'),
                  const SizedBox(height: 12),
                  _buildFeatureRow(quote.message),
                ],
              ),
            ),
            const Spacer(),
            CustomButton(
              text: AppLocalizations.of(context)!.startCoverageButton,
              onPressed: () async {
                 try {
                   await ref.read(enrollPolicyProvider(worker.id).future);
                 } catch (e) {
                   // Pass anyway for demo if it errors (e.g. already enrolled)
                 }
                 if (context.mounted) {
                   context.go('/dashboard');
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
      }
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
