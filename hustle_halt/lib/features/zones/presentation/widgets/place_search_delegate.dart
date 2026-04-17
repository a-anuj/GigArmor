import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/place_autocomplete_model.dart';
import '../../domain/state/zone_provider.dart';

class PlaceSearchDelegate extends SearchDelegate<PlaceDetails?> {
  final WidgetRef ref;
  final String _sessionToken;

  PlaceSearchDelegate(this.ref) : _sessionToken = const Uuid().v4();

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(LucideIcons.arrowLeft),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.length < 3) {
      return _buildEmptyState();
    }
    return _buildSuggestions(context);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.search, size: 48, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text(
            query.isEmpty ? 'Search for your working area' : 'Type at least 3 characters',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions(BuildContext context) {
    final placesService = ref.read(placesServiceProvider);
    
    return FutureBuilder<List<PlaceAutocompleteSuggestion>>(
      future: placesService.findAutocompletePredictions(
        query, 
        sessionToken: _sessionToken,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No places found', style: TextStyle(color: AppTheme.textSecondary)),
          );
        }

        final suggestions = snapshot.data!;

        return ListView.separated(
          itemCount: suggestions.length,
          padding: const EdgeInsets.symmetric(vertical: 16),
          separatorBuilder: (context, index) => const Divider(color: AppTheme.border, indent: 70),
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.mapPin, color: AppTheme.accent, size: 20),
              ),
              title: Text(
                suggestion.mainText,
                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                suggestion.secondaryText,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              onTap: () async {
                final details = await placesService.getPlaceDetails(
                  suggestion.placeId, 
                  sessionToken: _sessionToken,
                );
                if (context.mounted) {
                  close(context, details);
                }
              },
            );
          },
        );
      },
    );
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: AppTheme.textSecondary),
        border: InputBorder.none,
      ),
    );
  }
}
