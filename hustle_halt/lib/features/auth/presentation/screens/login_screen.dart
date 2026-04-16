import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_inputs.dart';
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
final phoneControllerProvider = Provider((ref) => TextEditingController(text: '9876543210'));
final emailControllerProvider = Provider((ref) => TextEditingController(text: 'arjun@example.com'));
final passwordControllerProvider = Provider((ref) => TextEditingController(text: 'strongPass123!'));
final nameControllerProvider = Provider((ref) => TextEditingController(text: 'Arjun Delivery'));
final upiControllerProvider = Provider((ref) => TextEditingController(text: 'arjun@upi'));
final zoneControllerProvider = StateProvider<int>((ref) => 1); // Default to Koramangala (1)

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(authStepProvider);
    
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
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HustleHalt',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontSize: 32,
            color: AppTheme.accent,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Income protection for the modern delivery partner.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 48),
        CustomTextField(
          controller: phoneController,
          hintText: 'Email or Mobile Number',
          prefixIcon: const Icon(LucideIcons.user, color: AppTheme.textSecondary, size: 20),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: passwordController,
          hintText: 'Password',
          obscureText: true,
          prefixIcon: const Icon(LucideIcons.lock, color: AppTheme.textSecondary, size: 20),
        ),
        const Spacer(),
        CustomButton(
          text: 'Login',
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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid credentials.')));
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
            child: const Text('Don\'t have an account? Register', style: TextStyle(color: AppTheme.accent)),
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
          Text(
            'Complete Profile',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
          ),
          const SizedBox(height: 8),
          Text(
            'Looks like you are new! Register to see your premium.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 32),
          CustomTextField(
            controller: nameController,
            hintText: 'Full Name',
            prefixIcon: const Icon(LucideIcons.user, color: AppTheme.textSecondary, size: 20),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: phoneController,
            hintText: 'Phone Number',
            keyboardType: TextInputType.phone,
            prefixIcon: const Icon(LucideIcons.phone, color: AppTheme.textSecondary, size: 20),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: emailController,
            hintText: 'Email Address',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(LucideIcons.mail, color: AppTheme.textSecondary, size: 20),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: passwordController,
            hintText: 'Password',
            obscureText: true,
            prefixIcon: const Icon(LucideIcons.lock, color: AppTheme.textSecondary, size: 20),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: upiController,
            hintText: 'UPI ID',
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
            text: 'Register & Calculate Risk',
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
                    'Coverage Estimated for ${worker.name}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${quote.premium.toStringAsFixed(0)} / week',
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
              text: 'Start Coverage',
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
              text: 'Maybe Later',
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
