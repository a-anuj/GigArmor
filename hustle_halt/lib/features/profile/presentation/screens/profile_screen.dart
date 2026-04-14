import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_inputs.dart';
import '../../../../core/network/api_client.dart';
import '../../../dashboard/domain/state/dashboard_state.dart';
import '../../../auth/domain/state/auth_state.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worker = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildProfileHeader(context, worker),
              const SizedBox(height: 32),
              _buildMenuSection(
                context,
                title: 'Account Settings',
                items: [
                  _buildMenuItem(LucideIcons.user, 'Personal Information', () {}),
                  _buildMenuItem(LucideIcons.map, 'Work Zone (Koramangala)', () {}),
                  _buildMenuItem(LucideIcons.globe, 'Language (English)', () {}),
                ],
              ),
              const SizedBox(height: 24),
              _buildMenuSection(
                context,
                title: 'Payouts & Billing',
                items: [
                  _buildMenuItem(LucideIcons.creditCard, 'Payment Methods (UPI)', () {}),
                  _buildMenuItem(LucideIcons.fileText, 'Tax Details', () {}),
                ],
              ),
              const SizedBox(height: 24),
              _buildMenuSection(
                context,
                title: 'Developer Tools',
                items: [
                  _buildMenuItem(LucideIcons.zap, 'Trigger Mock Simulation', () {
                    _showSimulationDialog(context, ref);
                  }, isAccent: true),
                ],
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Log Out',
                isOutlined: true,
                color: AppTheme.error,
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  context.go('/login');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, WorkerModel? worker) {
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: AppTheme.surface,
          child: Text(
            worker?.name.isNotEmpty == true ? worker!.name[0].toUpperCase() : '?',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppTheme.accent),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              worker?.name ?? 'Guest Worker',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(LucideIcons.briefcase, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  worker != null ? 'Registered Partner' : 'Identity Not Verified',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        )
      ],
    );
  }

  Widget _buildMenuSection(BuildContext context, {required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {bool isAccent = false}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isAccent ? AppTheme.accent : AppTheme.textSecondary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: isAccent ? AppTheme.accent : AppTheme.textPrimary, fontSize: 16),
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 16, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  void _showSimulationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Run Simulation'),
        content: const Text('This will trigger a mock heavy rainfall event. The dashboard environmental stats will update and an auto-payout notification will appear.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
            onPressed: () async {
              Navigator.pop(context);
              
              // Call the actual GigArmor simulation API
              try {
                final response = await ApiClient.instance.post(
                   '/api/v1/admin/simulate-trigger',
                   data: {
                      "category": "WEATHER",
                      "intensity": "EXTREME",
                      "location_pincode": "560034" // Hardcoded Koramangala
                   }
                );
                
                // Immediately update env locally so user sees the change (or we could fetch from admin stats)
                ref.read(environmentDataProvider.notifier).updateEnvironment({
                  'rainfall': 22.5, 
                  'aqi': 65,
                  'temp': 24, 
                });
                
                // Invalidate future providers so they refetch immediately based on the new backend state
                ref.invalidate(activeCoverageProvider);
                ref.invalidate(lastPayoutProvider);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.success,
                    content: Row(
                      children: [
                        const Icon(LucideIcons.checkCircle, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(child: Text(response.data['message'] ?? 'Successfully simulated event', style: const TextStyle(color: Colors.white))),
                      ],
                    ),
                    duration: const Duration(seconds: 4),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text('Failed simulation: $e', style: const TextStyle(color: Colors.white)), backgroundColor: AppTheme.error),
                );
              }
            },
            child: const Text('Trigger Event', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
