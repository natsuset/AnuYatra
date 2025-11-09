import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode notifier for managing light/dark theme
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _loadThemeMode();
  }

  static const String _key = 'theme_mode';

  /// Load theme mode from shared preferences
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeString = prefs.getString(_key);
      if (themeModeString != null) {
        state = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == themeModeString,
          orElse: () => ThemeMode.light,
        );
      }
    } catch (e) {
      // If there's an error, default to light mode
      state = ThemeMode.light;
    }
  }

  /// Save theme mode to shared preferences
  Future<void> _saveThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.toString());
    } catch (e) {
      // Handle error silently
    }
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    state = newMode;
    await _saveThemeMode(newMode);
  }

  /// Set specific theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (state != mode) {
      state = mode;
      await _saveThemeMode(mode);
    }
  }

  /// Set to light mode
  Future<void> setLightMode() => setThemeMode(ThemeMode.light);

  /// Set to dark mode
  Future<void> setDarkMode() => setThemeMode(ThemeMode.dark);

  /// Set to system mode
  Future<void> setSystemMode() => setThemeMode(ThemeMode.system);

  /// Check if currently in dark mode
  bool isDarkMode(BuildContext context) {
    if (state == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return state == ThemeMode.dark;
  }
}

/// Provider for theme mode
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

/// Provider to check if dark mode is active
final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeModeProvider);
  // Note: This won't detect system theme changes
  // For that, you'd need to watch MediaQuery in the widget
  return themeMode == ThemeMode.dark;
});
