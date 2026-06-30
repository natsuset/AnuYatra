import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/constants/app_typography.dart';
import 'package:testing_flutter/core/theme/app_palette.dart';

Color _lighten(Color base, double amount) =>
    Color.lerp(base, Colors.white, amount.clamp(0.0, 1.0))!;
Color _darken(Color base, double amount) =>
    Color.lerp(base, Colors.black, amount.clamp(0.0, 1.0))!;

/// Main theme configuration for the app
/// Provides both light and dark themes with Material Design 3
class AppTheme {
  AppTheme._();

  // ============================================
  // BRAND COLOR ALIASES (kept for screens that reference `AppTheme.x`
  // directly; new code should prefer reading from `Theme.of(context)`).
  //
  // These remain hardcoded to the production-default values for
  // backward compatibility with screens that haven't migrated yet. The
  // tinkerer's live changes flow through the `colorScheme` instead.
  // ============================================

  static const Color sacredSaffron = AppColors.sacredSaffron;
  static const Color deepMaroon = AppColors.deepMaroon;
  static const Color statusGreen = AppColors.chatGreen;
  static const Color whatsAppGray = AppColors.chatGray;

  // ============================================
  // THEME-AWARE HELPERS
  //
  // These now read from `Theme.of(context).colorScheme` (Material 3 slots)
  // so live palette changes through the tinkerer propagate automatically.
  // ============================================

  /// Whether the current theme is dark.
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Primary text colour that adapts to the active theme.
  static Color primaryText(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  /// Secondary text colour that adapts to the active theme.
  static Color secondaryText(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  /// Tertiary text colour that adapts to the active theme.
  static Color tertiaryText(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7);

  /// Surface / card colour that adapts to the active theme.
  static Color cardSurface(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  /// Background colour that adapts to the active theme.
  static Color background(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  /// Border colour that adapts to the active theme.
  static Color border(BuildContext context) =>
      Theme.of(context).colorScheme.outline;

  /// Divider colour that adapts to the active theme.
  static Color divider(BuildContext context) =>
      Theme.of(context).colorScheme.outlineVariant;

  /// AppBar background that adapts to the active theme.
  static Color appBarBackground(BuildContext context) =>
      Theme.of(context).appBarTheme.backgroundColor ??
      Theme.of(context).colorScheme.surface;

  // ============================================
  // LIGHT THEME
  // ============================================

  static ThemeData lightTheme(AppPalette palette) {
    final tertiaryText = palette.lightSecondaryText.withValues(alpha: 0.7);
    final surfaceVariant = _darken(palette.lightSurface, 0.04);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: ColorScheme.light(
        primary: palette.primary,
        onPrimary: Colors.white,
        primaryContainer: _lighten(palette.primary, 0.35),
        onPrimaryContainer: palette.lightPrimaryText,
        secondary: palette.secondary,
        onSecondary: Colors.white,
        secondaryContainer: _lighten(palette.secondary, 0.2),
        onSecondaryContainer: palette.lightPrimaryText,
        tertiary: palette.info,
        onTertiary: Colors.white,
        error: palette.error,
        onError: Colors.white,
        errorContainer: _lighten(palette.error, 0.2),
        onErrorContainer: _darken(palette.error, 0.15),
        surface: palette.lightSurface,
        onSurface: palette.lightPrimaryText,
        surfaceContainerHighest: surfaceVariant,
        outline: palette.lightBorder,
        outlineVariant: palette.lightDivider,
        shadow: Colors.black,
        scrim: Colors.black,
      ),

      extensions: [AppPaletteThemeExtension(palette: palette)],

      cardColor: palette.lightSurface,
      textTheme: AppTypography.getTextTheme(color: palette.lightPrimaryText),

      // Clean, modern AppBar — matches scaffold background (no heavy band),
      // dark text/icons, no elevation, subtle 1px bottom divider via surfaceTint.
      appBarTheme: AppBarTheme(
        backgroundColor: palette.lightBackground,
        foregroundColor: palette.lightPrimaryText,
        surfaceTintColor: palette.lightBackground,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: palette.lightDivider,
        centerTitle: false,
        titleTextStyle:
            AppTypography.titleLarge(color: palette.lightPrimaryText),
        iconTheme: IconThemeData(color: palette.lightPrimaryText),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        color: palette.lightSurface,
        elevation: AppSpacing.cardElevation,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.cardRadius),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: Colors.white,
          elevation: AppSpacing.buttonElevation,
          padding: AppSpacing.horizontalLg.copyWith(
            top: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.buttonRadius),
          textStyle: AppTypography.button(),
          minimumSize: const Size(88, AppSpacing.buttonHeightMd),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.primary,
          side: BorderSide(color: palette.primary, width: 1.5),
          padding: AppSpacing.horizontalLg.copyWith(
            top: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.buttonRadius),
          textStyle: AppTypography.button(),
          minimumSize: const Size(88, AppSpacing.buttonHeightMd),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primary,
          padding: AppSpacing.horizontalMd.copyWith(
            top: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          textStyle: AppTypography.button(),
          minimumSize: const Size(64, AppSpacing.buttonHeightMd),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.secondary,
          foregroundColor: Colors.white,
          padding: AppSpacing.horizontalLg.copyWith(
            top: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.buttonRadius),
          textStyle: AppTypography.button(),
          minimumSize: const Size(88, AppSpacing.buttonHeightMd),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.lightSurface,
        contentPadding: AppSpacing.allMd,
        border: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: BorderSide(color: palette.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: BorderSide(color: palette.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: BorderSide(color: palette.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: BorderSide(color: palette.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: BorderSide(color: palette.error, width: 2),
        ),
        labelStyle: AppTypography.bodyMedium(color: palette.lightSecondaryText),
        hintStyle: AppTypography.bodyMedium(color: tertiaryText),
        errorStyle: AppTypography.bodySmall(color: palette.error),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: palette.lightSurface,
        selectedItemColor: palette.primary,
        unselectedItemColor: palette.lightSecondaryText,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppTypography.labelSmall(),
        unselectedLabelStyle: AppTypography.labelSmall(),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.lightSurface,
        indicatorColor: _lighten(palette.primary, 0.35),
        elevation: 8,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.labelSmall(color: palette.primary);
          }
          return AppTypography.labelSmall(color: palette.lightSecondaryText);
        }),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        labelStyle:
            AppTypography.labelMedium(color: palette.lightPrimaryText),
        padding: AppSpacing.allSm,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.chipRadius),
      ),

      dividerTheme: DividerThemeData(
        color: palette.lightDivider,
        thickness: AppSpacing.dividerThickness,
        space: AppSpacing.dividerThickness,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: palette.lightSurface,
        elevation: AppSpacing.dialogElevation,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.dialogRadius),
        titleTextStyle:
            AppTypography.headlineSmall(color: palette.lightPrimaryText),
        contentTextStyle:
            AppTypography.bodyMedium(color: palette.lightSecondaryText),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.lightSurface,
        elevation: AppSpacing.bottomSheetElevation,
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.bottomSheetRadius,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.lightPrimaryText,
        contentTextStyle: AppTypography.bodyMedium(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.primary,
        foregroundColor: Colors.white,
        elevation: AppSpacing.elevation6,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
      ),

      iconButtonTheme: IconButtonThemeData(
        style:
            IconButton.styleFrom(foregroundColor: palette.lightSecondaryText),
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: AppSpacing.listItem,
        titleTextStyle:
            AppTypography.bodyLarge(color: palette.lightPrimaryText),
        subtitleTextStyle:
            AppTypography.bodyMedium(color: palette.lightSecondaryText),
      ),

      scaffoldBackgroundColor: palette.lightBackground,

      iconTheme: IconThemeData(
        color: palette.lightSecondaryText,
        size: AppSpacing.iconMd,
      ),

      primaryIconTheme: IconThemeData(
        color: palette.lightPrimaryText,
        size: AppSpacing.iconMd,
      ),
    );
  }

  // ============================================
  // DARK THEME
  // ============================================

  static ThemeData darkTheme(AppPalette palette) {
    final tertiaryText = palette.darkSecondaryText.withValues(alpha: 0.7);
    final surfaceVariant = _lighten(palette.darkSurface, 0.06);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: ColorScheme.dark(
        primary: palette.primary,
        onPrimary: Colors.black,
        primaryContainer: _darken(palette.primary, 0.25),
        onPrimaryContainer: palette.darkPrimaryText,
        secondary: _lighten(palette.secondary, 0.15),
        onSecondary: Colors.black,
        secondaryContainer: palette.secondary,
        onSecondaryContainer: palette.darkPrimaryText,
        tertiary: _lighten(palette.info, 0.15),
        onTertiary: Colors.black,
        error: _lighten(palette.error, 0.15),
        onError: Colors.black,
        errorContainer: _darken(palette.error, 0.25),
        onErrorContainer: palette.darkPrimaryText,
        surface: palette.darkSurface,
        onSurface: palette.darkPrimaryText,
        surfaceContainerHighest: surfaceVariant,
        outline: palette.darkBorder,
        outlineVariant: palette.darkDivider,
        shadow: Colors.black,
        scrim: Colors.black,
      ),

      extensions: [AppPaletteThemeExtension(palette: palette)],

      cardColor: palette.darkSurface,
      textTheme: AppTypography.getTextTheme(color: palette.darkPrimaryText),

      // Clean dark AppBar — matches scaffold background, no heavy band.
      appBarTheme: AppBarTheme(
        backgroundColor: palette.darkBackground,
        foregroundColor: palette.darkPrimaryText,
        surfaceTintColor: palette.darkBackground,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: palette.darkDivider,
        centerTitle: false,
        titleTextStyle:
            AppTypography.titleLarge(color: palette.darkPrimaryText),
        iconTheme: IconThemeData(color: palette.darkPrimaryText),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      cardTheme: CardThemeData(
        color: palette.darkSurface,
        elevation: AppSpacing.cardElevation,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.cardRadius),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: Colors.black,
          elevation: AppSpacing.buttonElevation,
          padding: AppSpacing.horizontalLg.copyWith(
            top: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.buttonRadius),
          textStyle: AppTypography.button(),
          minimumSize: const Size(88, AppSpacing.buttonHeightMd),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.primary,
          side: BorderSide(color: palette.primary, width: 1.5),
          padding: AppSpacing.horizontalLg.copyWith(
            top: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.buttonRadius),
          textStyle: AppTypography.button(),
          minimumSize: const Size(88, AppSpacing.buttonHeightMd),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primary,
          padding: AppSpacing.horizontalMd.copyWith(
            top: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          textStyle: AppTypography.button(),
          minimumSize: const Size(64, AppSpacing.buttonHeightMd),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _lighten(palette.secondary, 0.15),
          foregroundColor: Colors.black,
          padding: AppSpacing.horizontalLg.copyWith(
            top: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.buttonRadius),
          textStyle: AppTypography.button(),
          minimumSize: const Size(88, AppSpacing.buttonHeightMd),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding: AppSpacing.allMd,
        border: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: BorderSide(color: palette.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: BorderSide(color: palette.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: BorderSide(color: palette.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: BorderSide(color: _lighten(palette.error, 0.15)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide:
              BorderSide(color: _lighten(palette.error, 0.15), width: 2),
        ),
        labelStyle: AppTypography.bodyMedium(color: palette.darkSecondaryText),
        hintStyle: AppTypography.bodyMedium(color: tertiaryText),
        errorStyle:
            AppTypography.bodySmall(color: _lighten(palette.error, 0.15)),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: palette.darkSurface,
        selectedItemColor: palette.primary,
        unselectedItemColor: palette.darkSecondaryText,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppTypography.labelSmall(),
        unselectedLabelStyle: AppTypography.labelSmall(),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.darkSurface,
        indicatorColor: _darken(palette.primary, 0.25),
        elevation: 8,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.labelSmall(color: palette.primary);
          }
          return AppTypography.labelSmall(color: palette.darkSecondaryText);
        }),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        labelStyle:
            AppTypography.labelMedium(color: palette.darkPrimaryText),
        padding: AppSpacing.allSm,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.chipRadius),
      ),

      dividerTheme: DividerThemeData(
        color: palette.darkDivider,
        thickness: AppSpacing.dividerThickness,
        space: AppSpacing.dividerThickness,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: palette.darkSurface,
        elevation: AppSpacing.dialogElevation,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.dialogRadius),
        titleTextStyle:
            AppTypography.headlineSmall(color: palette.darkPrimaryText),
        contentTextStyle:
            AppTypography.bodyMedium(color: palette.darkSecondaryText),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.darkSurface,
        elevation: AppSpacing.bottomSheetElevation,
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.bottomSheetRadius,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceVariant,
        contentTextStyle:
            AppTypography.bodyMedium(color: palette.darkPrimaryText),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.primary,
        foregroundColor: Colors.black,
        elevation: AppSpacing.elevation6,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
      ),

      iconButtonTheme: IconButtonThemeData(
        style:
            IconButton.styleFrom(foregroundColor: palette.darkSecondaryText),
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: AppSpacing.listItem,
        titleTextStyle:
            AppTypography.bodyLarge(color: palette.darkPrimaryText),
        subtitleTextStyle:
            AppTypography.bodyMedium(color: palette.darkSecondaryText),
      ),

      scaffoldBackgroundColor: palette.darkBackground,

      iconTheme: IconThemeData(
        color: palette.darkSecondaryText,
        size: AppSpacing.iconMd,
      ),

      primaryIconTheme: IconThemeData(
        color: palette.darkPrimaryText,
        size: AppSpacing.iconMd,
      ),
    );
  }
}
