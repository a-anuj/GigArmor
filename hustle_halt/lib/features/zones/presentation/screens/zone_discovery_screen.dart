import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/state/zone_provider.dart';
import '../widgets/zone_card.dart';
import '../widgets/place_search_delegate.dart';
import '../../domain/models/place_autocomplete_model.dart';

class ZoneDiscoveryScreen extends ConsumerStatefulWidget {
  const ZoneDiscoveryScreen({super.key});

  @override
  ConsumerState<ZoneDiscoveryScreen> createState() => _ZoneDiscoveryScreenState();
}

class _ZoneDiscoveryScreenState extends ConsumerState<ZoneDiscoveryScreen> with SingleTickerProviderStateMixin {
  late AnimationController _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Auto-start discovery
    Future.microtask(() => ref.read(zoneDiscoveryProvider.notifier).discoverZones());
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final discoveryState = ref.watch(zoneDiscoveryProvider);
    final selectedZone = ref.watch(selectedZoneProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Zones'),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _buildMainContent(discoveryState, selectedZone),
            ),
            if (selectedZone != null && discoveryState.status == DiscoveryStatus.found)
              _buildConfirmButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(DiscoveryState state, dynamic selectedZone) {
    return switch (state.status) {
      DiscoveryStatus.idle || DiscoveryStatus.searching => _buildScanningView(),
      DiscoveryStatus.found => _buildZonesList(state.zones, selectedZone),
      DiscoveryStatus.permissionDenied => _buildErrorView(
          icon: LucideIcons.mapPinOff,
          title: 'Location Permission Denied',
          message: 'We need your location to find nearby dark store zones. Please enable it in settings or select a city manually.',
          showManualInput: true,
        ),
      DiscoveryStatus.error => _buildErrorView(
          icon: LucideIcons.alertCircle,
          title: 'Discovery Failed',
          message: state.errorMessage ?? 'An unexpected error occurred.',
          showRetry: true,
        ),
    };
  }

  Widget _buildScanningView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _scannerController,
                builder: (context, child) {
                  return Container(
                    width: 150 + (50 * _scannerController.value),
                    height: 150 + (50 * _scannerController.value),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.accent.withOpacity(1 - _scannerController.value),
                        width: 2,
                      ),
                    ),
                  );
                },
              ),
              const Icon(LucideIcons.mapPin, size: 48, color: AppTheme.accent),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Detecting nearby hubs...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Simulating dark store clusters in your area',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildZonesList(List<dynamic> zones, dynamic selectedZone) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Nearby Delivery Zones',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select your primary working hub for accurate premium calculation',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 24),
        ...zones.map((zone) => ZoneCard(
          zone: zone,
          isSelected: selectedZone?.id == zone.id,
          onTap: () => ref.read(selectedZoneProvider.notifier).state = zone,
        )),
        const SizedBox(height: 20),
        Center(
          child: TextButton.icon(
            onPressed: () => _openPlacePicker(context),
            icon: const Icon(LucideIcons.search, size: 16),
            label: const Text('Search in another area'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView({
    required IconData icon,
    required String title,
    required String message,
    bool showRetry = false,
    bool showManualInput = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (showRetry)
            ElevatedButton(
              onPressed: () => ref.read(zoneDiscoveryProvider.notifier).discoverZones(),
              child: const Text('Retry Discovery'),
            ),
          if (showManualInput)
            OutlinedButton(
              onPressed: () => _openPlacePicker(context),
              child: const Text('Search Area Manually'),
            ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: ElevatedButton(
        onPressed: () {
          // In a real app, we might call an API to update worker's zone
          // For now, we just pop back to dashboard which listens to selectedZoneProvider
          Navigator.of(context).pop();
        },
        child: const Text('Set as Active Zone'),
      ),
    );
  }

  Future<void> _openPlacePicker(BuildContext context) async {
    final PlaceDetails? result = await showSearch<PlaceDetails?>(
      context: context,
      delegate: PlaceSearchDelegate(ref),
    );

    if (result != null) {
      ref.read(zoneDiscoveryProvider.notifier).discoverZonesFromPosition(
        result.latitude,
        result.longitude,
      );
    }
  }
}
