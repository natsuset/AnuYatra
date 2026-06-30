import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testing_flutter/core/theme/app_palette.dart';

/// SharedPreferences key for the persisted active palette.
const _kPaletteStorageKey = 'debug_palette_v1';

/// SharedPreferences key for the persisted user-saved presets
/// (map of `presetName → AppPalette.toJson`).
const _kUserPresetsStorageKey = 'debug_palette_presets_v1';

/// The active [AppPalette] driving the app's theme.
///
/// Defaults to [AppPalette.defaultSaffron] (today's production scheme).
/// The debug-only `ThemeTinkererScreen` mutates this; overrides persist
/// to SharedPreferences so the chosen palette survives app restarts.
///
/// In release builds the palette is read-only — the tinkerer screen is
/// gated behind `kDebugMode` so users never see the editor. Persisted
/// values still apply, which lets a designer pick a palette in debug,
/// then ship that palette as the new `defaultSaffron`.
final paletteProvider =
    StateNotifierProvider<PaletteNotifier, AppPalette>((ref) {
  return PaletteNotifier();
});

/// Notifier that owns the active palette and the user-saved preset map.
class PaletteNotifier extends StateNotifier<AppPalette> {
  PaletteNotifier() : super(AppPalette.defaultSaffron) {
    _restore();
  }

  Map<String, AppPalette> _userPresets = {};

  /// Snapshot of user-saved presets (names → palettes). Read-only copy.
  Map<String, AppPalette> get userPresets => Map.unmodifiable(_userPresets);

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kPaletteStorageKey);
      if (raw != null) {
        final restored = AppPalette.tryParseJsonString(raw);
        if (restored != null) state = restored;
      }
      final rawPresets = prefs.getString(_kUserPresetsStorageKey);
      if (rawPresets != null) {
        final decoded = jsonDecode(rawPresets);
        if (decoded is Map) {
          _userPresets = decoded.map((name, json) => MapEntry(
                name as String,
                AppPalette.fromJson((json as Map).cast<String, dynamic>()),
              ));
        }
      }
    } catch (e) {
      debugPrint('PaletteNotifier: failed to restore — $e');
    }
  }

  /// Replace the active palette and persist it.
  Future<void> setPalette(AppPalette palette) async {
    state = palette;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPaletteStorageKey, palette.toJsonString());
    } catch (e) {
      debugPrint('PaletteNotifier: failed to persist palette — $e');
    }
  }

  /// Reset the active palette to the production default.
  Future<void> reset() => setPalette(AppPalette.defaultSaffron);

  /// Save the current palette under [name]. Overwrites if the name exists.
  Future<void> saveUserPreset(String name) async {
    _userPresets = {..._userPresets, name: state};
    await _persistUserPresets();
  }

  /// Delete a user-saved preset.
  Future<void> deleteUserPreset(String name) async {
    final next = Map<String, AppPalette>.from(_userPresets)..remove(name);
    _userPresets = next;
    await _persistUserPresets();
  }

  Future<void> _persistUserPresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(
        _userPresets.map((name, palette) => MapEntry(name, palette.toJson())),
      );
      await prefs.setString(_kUserPresetsStorageKey, encoded);
    } catch (e) {
      debugPrint('PaletteNotifier: failed to persist user presets — $e');
    }
  }
}
