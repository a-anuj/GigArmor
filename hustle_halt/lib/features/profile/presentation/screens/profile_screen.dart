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
                  _buildMenuItem(
                    LucideIcons.map, 
                    'Work Zone (${worker?.zone?.name ?? 'Loading...'})', 
                    () => _showZoneSelection(context, ref)
                  ),
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

  void _showZoneSelection(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Switch Work Zone',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
              ),
              const SizedBox(height: 16),
              ref.watch(zonesProvider).when(
                loading: () => const Center(child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: AppTheme.accent),
                )),
                error: (e, st) => Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text('Error loading zones: $e', style: const TextStyle(color: AppTheme.error)),
                ),
                data: (zones) => Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: zones.length,
                    itemBuilder: (context, index) {
                      final zone = zones[index];
                      final isCurrent = zone.id == ref.read(authProvider)?.zoneId;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isCurrent ? AppTheme.accent.withOpacity(0.1) : AppTheme.border.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            LucideIcons.mapPin, 
                            size: 18, 
                            color: isCurrent ? AppTheme.accent : AppTheme.textSecondary
                          ),
                        ),
                        title: Text(
                          zone.name, 
                          style: TextStyle(
                            color: isCurrent ? AppTheme.accent : AppTheme.textPrimary,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          )
                        ),
                        subtitle: Text('${zone.pincode} • ${zone.riskMultiplier}x Base Risk', style: const TextStyle(fontSize: 12)),
                        trailing: isCurrent ? const Icon(LucideIcons.checkCircle2, color: AppTheme.accent, size: 20) : null,
                        onTap: () async {
                          Navigator.pop(context);
                          if (isCurrent) return;
                          
                          try {
                            await ref.read(authProvider.notifier).updateZone(zone.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Zone switched to ${zone.name}'),
                                  backgroundColor: AppTheme.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                             if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed: $e'), backgroundColor: AppTheme.error),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
                ref.read(dashboardDataProvider.notifier).patchEnvironment({
                  'rainfall_mm_hr': 22.5, 
                  'aqi': 65,
                  'temperature_c': 24, 
                });
                
                // Active options will automatically extract from the dashboard data so invalidating it forces a full refetch
                ref.invalidate(dashboardDataProvider);
                
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
