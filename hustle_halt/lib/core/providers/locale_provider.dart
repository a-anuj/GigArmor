import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hustle_halt/l10n/app_localizations.dart';

class LocaleNotifier extends Notifier<Locale> {
  static const String _localeKey = 'app_locale';
  late Box _settingsBox;

  @override
  Locale build() {
    _settingsBox = Hive.box('settings');
    final storedLocale = _settingsBox.get(_localeKey);
    if (storedLocale != null) {
      return Locale(storedLocale);
    }
    return const Locale('en'); // default locale
  }

  void setLocale(Locale locale) {
    state = locale;
    _settingsBox.put(_localeKey, locale.languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

/// Provides the correct [AppLocalizations] instance directly from Riverpod.
/// Use `ref.watch(appL10nProvider)` instead of `AppLocalizations.of(context)!`
/// to guarantee translation updates when language changes, regardless of
/// Flutter's Localizations context chain.
final appL10nProvider = Provider<AppLocalizations>((ref) {
  final locale = ref.watch(localeProvider);
  return lookupAppLocalizations(locale);
});
