import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

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
