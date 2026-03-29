import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the user-selected app locale.
///
/// - `null`  → follow system locale (default)
/// - non-null → user explicitly chose a language
///
/// Uses Riverpod [Notifier] (not the deprecated StateNotifier).
class LocaleNotifier extends Notifier<Locale?> {
  static const _key = 'app_locale';

  @override
  Locale? build() {
    _loadLocale();
    return null; // default: system locale
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null) {
      state = Locale(code);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }

  Future<void> useSystemLocale() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);
