import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';

class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: locale.languageCode,
        dropdownColor: AppTheme.surface,
        icon: const Icon(Icons.language, color: AppTheme.textSecondary, size: 20),
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        onChanged: (String? newLocale) {
          if (newLocale != null) {
            ref.read(localeProvider.notifier).setLocale(Locale(newLocale));
          }
        },
        items: const [
          DropdownMenuItem(
            value: 'en',
            child: Text('English'),
          ),
          DropdownMenuItem(
            value: 'hi',
            child: Text('हिंदी'),
          ),
          DropdownMenuItem(
            value: 'ta',
            child: Text('தமிழ்'),
          ),
          DropdownMenuItem(
            value: 'te',
            child: Text('తెలుగు'),
          ),
          DropdownMenuItem(
            value: 'mr',
            child: Text('मराठी'),
          ),
        ],
      ),
    );
  }
}
