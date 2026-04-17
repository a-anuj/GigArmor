import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_inputs.dart';
import '../../../../core/network/api_client.dart';
import '../../../dashboard/domain/state/dashboard_state.dart';
import '../../../auth/domain/state/auth_state.dart';
import 'package:hustle_halt/l10n/app_localizations.dart';
import '../../../../core/widgets/language_selector.dart';
import '../../../../core/providers/locale_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use appL10nProvider so this rebuilds immediately when language changes.
    // This bypasses AppLocalizations.of(context) which is broken in GoRouter shells.
    final l10n = ref.watch(appL10nProvider);
    final worker = ref.watch(authProvider);

    final zonesAsync = ref.watch(zonesProvider);

    // Resolve the current zone name since auth/me doesn't populate the nested zone object
    String currentZoneName = l10n.loading;
    if (zonesAsync is AsyncData) {
      final matchingZone = zonesAsync.value?.where((z) => z.id == worker?.zoneId).firstOrNull;
      if (matchingZone != null) currentZoneName = matchingZone.name;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        actions: const [LanguageSelector(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildProfileHeader(context, worker, l10n),
              const SizedBox(height: 32),
              _buildMenuSection(
                context,
                title: l10n.accountSettings,
                items: [
                  _buildMenuItem(LucideIcons.user, l10n.personalInformation, () {
                    _showPersonalInfoDialog(context, worker);
                  }),
                  _buildMenuItem(
                    LucideIcons.map,
                    l10n.workZone(currentZoneName),
                    () => _showZoneSelection(context, ref, l10n),
                  ),

                ],
              ),
              const SizedBox(height: 24),
              _buildMenuSection(
                context,
                title: l10n.payoutsBilling,
                items: [
                  _buildMenuItem(LucideIcons.creditCard, l10n.paymentMethods, () {}),
                  _buildMenuItem(LucideIcons.fileText, l10n.taxDetails, () {}),
                ],
              ),
              const SizedBox(height: 24),
              _buildMenuSection(
                context,
                title: l10n.developerTools,
                items: [
                  _buildMenuItem(LucideIcons.zap, l10n.triggerMockSimulation, () {
                    _showSimulationDialog(context, ref, l10n);
                  }, isAccent: true),
                ],
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: l10n.logOut,
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

  Widget _buildProfileHeader(BuildContext context, WorkerModel? worker, AppLocalizations l10n) {
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
              worker?.name ?? l10n.guestWorker,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(LucideIcons.briefcase, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  worker != null ? l10n.workerStatus(worker.status) : l10n.identityNotVerified,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.success,
                    fontWeight: FontWeight.bold,
                  ),
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

  void _showZoneSelection(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        // Reuse the l10n passed in from the parent (already resolved via appL10nProvider)
        final sheetL10n = l10n;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  sheetL10n.switchWorkZone,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
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
                  child: Text(sheetL10n.errorLoadingZones(e.toString()), style: const TextStyle(color: AppTheme.error)),
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
                            color: isCurrent ? AppTheme.accent : AppTheme.textSecondary,
                          ),
                        ),
                        title: Text(
                          zone.name,
                          style: TextStyle(
                            color: isCurrent ? AppTheme.accent : AppTheme.textPrimary,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          '${zone.pincode} • ${sheetL10n.baseRiskMultiplier(zone.riskMultiplier.toString())}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: isCurrent ? const Icon(LucideIcons.checkCircle2, color: AppTheme.accent, size: 20) : null,
                        onTap: () async {
                          Navigator.pop(context);
                          if (isCurrent) return;

                          try {
                            await ref.read(authProvider.notifier).updateZone(zone.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(sheetL10n.zoneSwitched(zone.name)),
                                  backgroundColor: AppTheme.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(sheetL10n.failedGeneric(e.toString())),
                                  backgroundColor: AppTheme.error,
                                ),
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

  void _showSimulationDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) {
        // Reuse the l10n passed in from the parent (already resolved via appL10nProvider)
        final dialogL10n = l10n;
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text(dialogL10n.runSimulation),
          content: Text(dialogL10n.simulationDescription),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(dialogL10n.cancel, style: const TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
              onPressed: () async {
                Navigator.pop(context);

                try {
                  final response = await ApiClient.instance.post(
                     '/api/v1/admin/simulate-trigger',
                     data: {
                        "category": "WEATHER",
                        "intensity": "EXTREME",
                        "location_pincode": "560034"
                     }
                  );

                  ref.read(dashboardDataProvider.notifier).patchEnvironment({
                    'rainfall_mm_hr': 22.5,
                    'aqi': 65,
                    'temperature_c': 24,
                  });

                  ref.invalidate(dashboardDataProvider);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppTheme.success,
                        content: Row(
                          children: [
                            const Icon(LucideIcons.checkCircle, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(child: Text(response.data['message'] ?? l10n.profileUpdatedSuccess, style: const TextStyle(color: Colors.white))),
                          ],
                        ),
                        duration: const Duration(seconds: 4),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(
                         content: Text(l10n.failedSimulation(e.toString()), style: const TextStyle(color: Colors.white)),
                         backgroundColor: AppTheme.error,
                       ),
                    );
                  }
                }
              },
              child: Text(dialogL10n.triggerEvent, style: const TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  void _showPersonalInfoDialog(BuildContext context, WorkerModel? worker) {
    if (worker == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: _EditableProfileSheet(worker: worker),
        );
      },
    );
  }
}

class _EditableProfileSheet extends ConsumerStatefulWidget {
  final WorkerModel worker;
  const _EditableProfileSheet({required this.worker});

  @override
  ConsumerState<_EditableProfileSheet> createState() => _EditableProfileSheetState();
}

class _EditableProfileSheetState extends ConsumerState<_EditableProfileSheet> {
  late TextEditingController _nameController;
  late TextEditingController _upiController;
  late String _qCommercePlatform;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.worker.name);
    _upiController = TextEditingController(text: widget.worker.upiId ?? '');
    _qCommercePlatform = widget.worker.qCommercePlatform;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _handleSave(AppLocalizations l10n) async {
    setState(() => _isSaving = true);
    try {
      await ref.read(authProvider.notifier).updateProfile(
        name: _nameController.text.trim(),
        qCommercePlatform: _qCommercePlatform,
        upiId: _upiController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profileUpdatedSuccess), backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToUpdate(e.toString())), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(appL10nProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.personalInformation,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              if (_isSaving) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: 24),
          Text(l10n.fullNameHint, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _nameController,
            prefixIcon: const Icon(LucideIcons.user, color: AppTheme.textSecondary, size: 20),
            hintText: l10n.enterYourName,
          ),
          const SizedBox(height: 16),
          _buildStaticRow(LucideIcons.phone, l10n.phoneHint, widget.worker.phone),
          const SizedBox(height: 16),
          _buildStaticRow(LucideIcons.mail, l10n.emailHint, widget.worker.email ?? l10n.notProvided),
          const SizedBox(height: 16),
          Text(l10n.qCommercePlatform, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<String>(
                value: _qCommercePlatform,
                dropdownColor: AppTheme.surface,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(LucideIcons.shoppingBag, color: AppTheme.textSecondary, size: 20),
                ),
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _qCommercePlatform = val);
                  }
                },
                items: ['Zomato', 'Swiggy', 'Zepto', 'Blinkit', 'Other'].map((p) => DropdownMenuItem(
                  value: p,
                  child: Text(p),
                )).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.upiIdLabel, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _upiController,
            prefixIcon: const Icon(LucideIcons.wallet, color: AppTheme.textSecondary, size: 20),
            hintText: 'e.g., yourname@upi',
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: l10n.saveChanges,
              onPressed: _isSaving ? null : () => _handleSave(l10n),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
              ],
            ),
          ),
          const Icon(LucideIcons.lock, color: AppTheme.textSecondary, size: 14),
        ],
      ),
    );
  }
}
