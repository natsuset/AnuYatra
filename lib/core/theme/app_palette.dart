import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';

/// `ThemeData` extension that exposes the full [AppPalette] alongside
/// Material's `ColorScheme`. Lets any widget read brand / semantic /
/// feature colours via `Theme.of(context).extension<AppPaletteThemeExtension>()`,
/// or — more conveniently — via the `context.palette` shorthand below.
///
/// This is the bridge that makes every screen react to live tinkerer
/// changes without each widget having to watch `paletteProvider` directly.
class AppPaletteThemeExtension
    extends ThemeExtension<AppPaletteThemeExtension> {
  final AppPalette palette;

  const AppPaletteThemeExtension({required this.palette});

  @override
  AppPaletteThemeExtension copyWith({AppPalette? palette}) =>
      AppPaletteThemeExtension(palette: palette ?? this.palette);

  @override
  AppPaletteThemeExtension lerp(
    ThemeExtension<AppPaletteThemeExtension>? other,
    double t,
  ) {
    // Discrete swap is fine — palette changes are user-initiated, not animated.
    if (other is! AppPaletteThemeExtension) return this;
    return t < 0.5 ? this : other;
  }
}

/// Shorthand: `context.palette.primary` instead of
/// `Theme.of(context).extension<AppPaletteThemeExtension>()!.palette.primary`.
extension PaletteOnContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPaletteThemeExtension>()?.palette ??
      AppPalette.defaultSaffron;
}

/// Immutable palette of every brand + semantic + neutral colour the app uses.
///
/// `AppTheme.lightTheme(palette)` / `AppTheme.darkTheme(palette)` project a
/// palette onto a full Material 3 `ThemeData`. The [paletteProvider]
/// (in `core/providers/palette_provider.dart`) exposes the active palette
/// at runtime; the debug-only theme tinkerer mutates it live.
///
/// **Convention.** `Color` values are stored as 32-bit ARGB (`.toARGB32()`)
/// to make JSON serialisation lossless across SDK versions.
@immutable
class AppPalette {
  // ── Brand ─────────────────────────────────────────────────
  final Color primary;
  final Color secondary;

  // ── Semantic ──────────────────────────────────────────────
  final Color success;
  final Color error;
  final Color warning;
  final Color info;

  // ── Feature accents (per-section colour, e.g. astrology, finance) ──
  final Color trustBlue;
  final Color meetingPurple;
  final Color financialGreen;

  // ── Light neutrals ────────────────────────────────────────
  final Color lightBackground;
  final Color lightSurface;
  final Color lightPrimaryText;
  final Color lightSecondaryText;
  final Color lightDivider;
  final Color lightBorder;

  // ── Dark neutrals ─────────────────────────────────────────
  final Color darkBackground;
  final Color darkSurface;
  final Color darkPrimaryText;
  final Color darkSecondaryText;
  final Color darkDivider;
  final Color darkBorder;

  const AppPalette({
    required this.primary,
    required this.secondary,
    required this.success,
    required this.error,
    required this.warning,
    required this.info,
    required this.trustBlue,
    required this.meetingPurple,
    required this.financialGreen,
    required this.lightBackground,
    required this.lightSurface,
    required this.lightPrimaryText,
    required this.lightSecondaryText,
    required this.lightDivider,
    required this.lightBorder,
    required this.darkBackground,
    required this.darkSurface,
    required this.darkPrimaryText,
    required this.darkSecondaryText,
    required this.darkDivider,
    required this.darkBorder,
  });

  /// The current production palette — exactly matches today's `AppColors`
  /// constants so the app looks identical until the user opens the tinkerer.
  static const AppPalette defaultSaffron = AppPalette(
    primary: AppColors.sacredSaffron,
    secondary: AppColors.deepMaroon,
    success: AppColors.success,
    error: AppColors.error,
    warning: AppColors.warning,
    info: AppColors.info,
    trustBlue: AppColors.trustBlue,
    meetingPurple: AppColors.meetingPurple,
    financialGreen: AppColors.successDark,
    lightBackground: AppColors.lightBackground,
    lightSurface: AppColors.lightSurface,
    lightPrimaryText: AppColors.lightPrimaryText,
    lightSecondaryText: AppColors.lightSecondaryText,
    lightDivider: AppColors.lightDivider,
    lightBorder: AppColors.lightBorder,
    darkBackground: AppColors.darkBackground,
    darkSurface: AppColors.darkSurface,
    darkPrimaryText: AppColors.darkPrimaryText,
    darkSecondaryText: AppColors.darkSecondaryText,
    darkDivider: AppColors.darkDivider,
    darkBorder: AppColors.darkBorder,
  );

  /// Material 3 "Quick Mode" — generate a complete palette from a single
  /// seed colour using `ColorScheme.fromSeed`. Semantic + feature accents
  /// keep the defaults; only the neutrals and primary/secondary derive
  /// from the seed.
  factory AppPalette.fromSeed(Color seed) {
    final light = ColorScheme.fromSeed(seedColor: seed);
    final dark = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );
    return AppPalette(
      primary: light.primary,
      secondary: light.secondary,
      success: defaultSaffron.success,
      error: light.error,
      warning: defaultSaffron.warning,
      info: defaultSaffron.info,
      trustBlue: defaultSaffron.trustBlue,
      meetingPurple: defaultSaffron.meetingPurple,
      financialGreen: defaultSaffron.financialGreen,
      lightBackground: light.surface,
      lightSurface: light.surfaceContainerLowest,
      lightPrimaryText: light.onSurface,
      lightSecondaryText: light.onSurfaceVariant,
      lightDivider: light.outlineVariant,
      lightBorder: light.outline,
      darkBackground: dark.surface,
      darkSurface: dark.surfaceContainerLowest,
      darkPrimaryText: dark.onSurface,
      darkSecondaryText: dark.onSurfaceVariant,
      darkDivider: dark.outlineVariant,
      darkBorder: dark.outline,
    );
  }

  AppPalette copyWith({
    Color? primary,
    Color? secondary,
    Color? success,
    Color? error,
    Color? warning,
    Color? info,
    Color? trustBlue,
    Color? meetingPurple,
    Color? financialGreen,
    Color? lightBackground,
    Color? lightSurface,
    Color? lightPrimaryText,
    Color? lightSecondaryText,
    Color? lightDivider,
    Color? lightBorder,
    Color? darkBackground,
    Color? darkSurface,
    Color? darkPrimaryText,
    Color? darkSecondaryText,
    Color? darkDivider,
    Color? darkBorder,
  }) {
    return AppPalette(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      success: success ?? this.success,
      error: error ?? this.error,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      trustBlue: trustBlue ?? this.trustBlue,
      meetingPurple: meetingPurple ?? this.meetingPurple,
      financialGreen: financialGreen ?? this.financialGreen,
      lightBackground: lightBackground ?? this.lightBackground,
      lightSurface: lightSurface ?? this.lightSurface,
      lightPrimaryText: lightPrimaryText ?? this.lightPrimaryText,
      lightSecondaryText: lightSecondaryText ?? this.lightSecondaryText,
      lightDivider: lightDivider ?? this.lightDivider,
      lightBorder: lightBorder ?? this.lightBorder,
      darkBackground: darkBackground ?? this.darkBackground,
      darkSurface: darkSurface ?? this.darkSurface,
      darkPrimaryText: darkPrimaryText ?? this.darkPrimaryText,
      darkSecondaryText: darkSecondaryText ?? this.darkSecondaryText,
      darkDivider: darkDivider ?? this.darkDivider,
      darkBorder: darkBorder ?? this.darkBorder,
    );
  }

  Map<String, int> toJson() => {
        'primary': primary.toARGB32(),
        'secondary': secondary.toARGB32(),
        'success': success.toARGB32(),
        'error': error.toARGB32(),
        'warning': warning.toARGB32(),
        'info': info.toARGB32(),
        'trustBlue': trustBlue.toARGB32(),
        'meetingPurple': meetingPurple.toARGB32(),
        'financialGreen': financialGreen.toARGB32(),
        'lightBackground': lightBackground.toARGB32(),
        'lightSurface': lightSurface.toARGB32(),
        'lightPrimaryText': lightPrimaryText.toARGB32(),
        'lightSecondaryText': lightSecondaryText.toARGB32(),
        'lightDivider': lightDivider.toARGB32(),
        'lightBorder': lightBorder.toARGB32(),
        'darkBackground': darkBackground.toARGB32(),
        'darkSurface': darkSurface.toARGB32(),
        'darkPrimaryText': darkPrimaryText.toARGB32(),
        'darkSecondaryText': darkSecondaryText.toARGB32(),
        'darkDivider': darkDivider.toARGB32(),
        'darkBorder': darkBorder.toARGB32(),
      };

  factory AppPalette.fromJson(Map<String, dynamic> json) {
    Color read(String key, Color fallback) {
      final raw = json[key];
      return raw is int ? Color(raw) : fallback;
    }

    return AppPalette(
      primary: read('primary', defaultSaffron.primary),
      secondary: read('secondary', defaultSaffron.secondary),
      success: read('success', defaultSaffron.success),
      error: read('error', defaultSaffron.error),
      warning: read('warning', defaultSaffron.warning),
      info: read('info', defaultSaffron.info),
      trustBlue: read('trustBlue', defaultSaffron.trustBlue),
      meetingPurple: read('meetingPurple', defaultSaffron.meetingPurple),
      financialGreen: read('financialGreen', defaultSaffron.financialGreen),
      lightBackground: read('lightBackground', defaultSaffron.lightBackground),
      lightSurface: read('lightSurface', defaultSaffron.lightSurface),
      lightPrimaryText: read('lightPrimaryText', defaultSaffron.lightPrimaryText),
      lightSecondaryText:
          read('lightSecondaryText', defaultSaffron.lightSecondaryText),
      lightDivider: read('lightDivider', defaultSaffron.lightDivider),
      lightBorder: read('lightBorder', defaultSaffron.lightBorder),
      darkBackground: read('darkBackground', defaultSaffron.darkBackground),
      darkSurface: read('darkSurface', defaultSaffron.darkSurface),
      darkPrimaryText: read('darkPrimaryText', defaultSaffron.darkPrimaryText),
      darkSecondaryText:
          read('darkSecondaryText', defaultSaffron.darkSecondaryText),
      darkDivider: read('darkDivider', defaultSaffron.darkDivider),
      darkBorder: read('darkBorder', defaultSaffron.darkBorder),
    );
  }

  /// Encode as a compact JSON string for export / clipboard sharing.
  String toJsonString() => jsonEncode(toJson());

  static AppPalette? tryParseJsonString(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return AppPalette.fromJson(decoded.cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }
}

/// Built-in palette presets users can switch between or remix.
class AppPalettePresets {
  AppPalettePresets._();

  static const Map<String, AppPalette> all = {
    'Default Saffron': AppPalette.defaultSaffron,
    'Cool Indigo': _coolIndigo,
    'Forest Green': _forestGreen,
    'Deep Plum': _deepPlum,
  };

  static const AppPalette _coolIndigo = AppPalette(
    primary: Color(0xFF4F46E5),
    secondary: Color(0xFF0EA5E9),
    success: Color(0xFF10B981),
    error: Color(0xFFEF4444),
    warning: Color(0xFFF59E0B),
    info: Color(0xFF3B82F6),
    trustBlue: Color(0xFF1E40AF),
    meetingPurple: Color(0xFF7C3AED),
    financialGreen: Color(0xFF059669),
    lightBackground: Color(0xFFF8FAFC),
    lightSurface: Color(0xFFFFFFFF),
    lightPrimaryText: Color(0xFF0F172A),
    lightSecondaryText: Color(0xFF475569),
    lightDivider: Color(0xFFE2E8F0),
    lightBorder: Color(0xFFCBD5E1),
    darkBackground: Color(0xFF0B1220),
    darkSurface: Color(0xFF111827),
    darkPrimaryText: Color(0xFFF1F5F9),
    darkSecondaryText: Color(0xFFCBD5E1),
    darkDivider: Color(0xFF1F2937),
    darkBorder: Color(0xFF374151),
  );

  static const AppPalette _forestGreen = AppPalette(
    primary: Color(0xFF15803D),
    secondary: Color(0xFF92400E),
    success: Color(0xFF16A34A),
    error: Color(0xFFDC2626),
    warning: Color(0xFFCA8A04),
    info: Color(0xFF0284C7),
    trustBlue: Color(0xFF1D4ED8),
    meetingPurple: Color(0xFF6D28D9),
    financialGreen: Color(0xFF15803D),
    lightBackground: Color(0xFFFAFAF9),
    lightSurface: Color(0xFFFFFFFF),
    lightPrimaryText: Color(0xFF1C1917),
    lightSecondaryText: Color(0xFF57534E),
    lightDivider: Color(0xFFE7E5E4),
    lightBorder: Color(0xFFD6D3D1),
    darkBackground: Color(0xFF0C1A0F),
    darkSurface: Color(0xFF14241A),
    darkPrimaryText: Color(0xFFF5F5F4),
    darkSecondaryText: Color(0xFFD6D3D1),
    darkDivider: Color(0xFF1F362A),
    darkBorder: Color(0xFF44403C),
  );

  static const AppPalette _deepPlum = AppPalette(
    primary: Color(0xFF7E22CE),
    secondary: Color(0xFFDB2777),
    success: Color(0xFF10B981),
    error: Color(0xFFE11D48),
    warning: Color(0xFFEAB308),
    info: Color(0xFF6366F1),
    trustBlue: Color(0xFF4338CA),
    meetingPurple: Color(0xFF7E22CE),
    financialGreen: Color(0xFF059669),
    lightBackground: Color(0xFFFAF5FF),
    lightSurface: Color(0xFFFFFFFF),
    lightPrimaryText: Color(0xFF18181B),
    lightSecondaryText: Color(0xFF52525B),
    lightDivider: Color(0xFFE4E4E7),
    lightBorder: Color(0xFFD4D4D8),
    darkBackground: Color(0xFF1A0B26),
    darkSurface: Color(0xFF2A1438),
    darkPrimaryText: Color(0xFFFAFAFA),
    darkSecondaryText: Color(0xFFD4D4D8),
    darkDivider: Color(0xFF3F1D5C),
    darkBorder: Color(0xFF52525B),
  );
}
