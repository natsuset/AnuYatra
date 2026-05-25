import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/constants/app_typography.dart';

/// Main theme configuration for the app
/// Provides both light and dark themes with Material Design 3
class AppTheme {
  AppTheme._();

  // ============================================
  // BRAND COLOR ALIASES (kept for screens that reference `AppTheme.x`
  // directly; new code should prefer `AppColors.x`)
  // ============================================

  static const Color sacredSaffron = AppColors.sacredSaffron;
  static const Color deepMaroon = AppColors.deepMaroon;
  static const Color statusGreen = AppColors.chatGreen;
  static const Color whatsAppGray = AppColors.chatGray;

  // ============================================
  // THEME-AWARE HELPERS
  // ============================================

  /// Whether the current theme is dark.
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Primary text colour that adapts to light / dark theme.
  static Color primaryText(BuildContext context) => isDark(context)
      ? AppColors.darkPrimaryText
      : AppColors.lightPrimaryText;

  /// Secondary text colour that adapts to light / dark theme.
  static Color secondaryText(BuildContext context) => isDark(context)
      ? AppColors.darkSecondaryText
      : AppColors.lightSecondaryText;

  /// Tertiary text colour that adapts to light / dark theme.
  static Color tertiaryText(BuildContext context) => isDark(context)
      ? AppColors.darkTertiaryText
      : AppColors.lightTertiaryText;

  /// Surface / card colour that adapts to light / dark theme.
  static Color cardSurface(BuildContext context) =>
      isDark(context) ? AppColors.darkSurface : AppColors.lightSurface;

  /// Background colour that adapts to light / dark theme.
  static Color background(BuildContext context) =>
      isDark(context) ? AppColors.darkBackground : AppColors.lightBackground;

  /// Border colour that adapts to light / dark theme.
  static Color border(BuildContext context) =>
      isDark(context) ? AppColors.darkBorder : AppColors.lightBorder;

  /// Divider colour that adapts to light / dark theme.
  static Color divider(BuildContext context) =>
      isDark(context) ? AppColors.darkDivider : AppColors.lightDivider;

  /// AppBar background that adapts to light / dark theme.
  static Color appBarBackground(BuildContext context) =>
      isDark(context) ? AppColors.darkSurface : deepMaroon;

  // ============================================
  // LIGHT THEME
  // ============================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: AppColors.sacredSaffron,
        onPrimary: Colors.white,
        primaryContainer: AppColors.sacredSaffronLight,
        onPrimaryContainer: AppColors.lightPrimaryText,

        secondary: AppColors.deepMaroon,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.deepMaroonLight,
        onSecondaryContainer: AppColors.lightPrimaryText,

        tertiary: AppColors.info,
        onTertiary: Colors.white,

        error: AppColors.error,
        onError: Colors.white,
        errorContainer: AppColors.errorLight,
        onErrorContainer: AppColors.errorDark,

        surface: AppColors.lightSurface,
        onSurface: AppColors.lightPrimaryText,
        surfaceContainerHighest: AppColors.lightSurfaceVariant,

        outline: AppColors.lightBorder,
        outlineVariant: AppColors.lightDivider,

        shadow: Colors.black,
        scrim: Colors.black,
      ),

      // Global card color (Material2 compatibility, used by some widgets)
      cardColor: AppColors.lightSurface,

      // Typography
      textTheme: AppTypography.getTextTheme(color: AppColors.lightPrimaryText),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.deepMaroon,
        foregroundColor: Colors.white,
        elevation: AppSpacing.appBarElevation,
        centerTitle: false,
        titleTextStyle: AppTypography.titleLarge(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: AppSpacing.cardElevation,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.cardRadius),
        margin: EdgeInsets.zero,
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.sacredSaffron,
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
          foregroundColor: AppColors.sacredSaffron,
          side: const BorderSide(color: AppColors.sacredSaffron, width: 1.5),
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
          foregroundColor: AppColors.sacredSaffron,
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
          backgroundColor: AppColors.deepMaroon,
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

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        contentPadding: AppSpacing.allMd,
        border: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: const BorderSide(
            color: AppColors.sacredSaffron,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: AppTypography.bodyMedium(
          color: AppColors.lightSecondaryText,
        ),
        hintStyle: AppTypography.bodyMedium(color: AppColors.lightTertiaryText),
        errorStyle: AppTypography.bodySmall(color: AppColors.error),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.sacredSaffron,
        unselectedItemColor: AppColors.lightSecondaryText,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppTypography.labelSmall(),
        unselectedLabelStyle: AppTypography.labelSmall(),
      ),

      // Navigation Bar Theme (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        indicatorColor: AppColors.sacredSaffronLight,
        elevation: 8,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.labelSmall(color: AppColors.sacredSaffron);
          }
          return AppTypography.labelSmall(color: AppColors.lightSecondaryText);
        }),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurfaceVariant,
        labelStyle: AppTypography.labelMedium(
          color: AppColors.lightPrimaryText,
        ),
        padding: AppSpacing.allSm,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.chipRadius),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.lightDivider,
        thickness: AppSpacing.dividerThickness,
        space: AppSpacing.dividerThickness,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        elevation: AppSpacing.dialogElevation,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.dialogRadius),
        titleTextStyle: AppTypography.headlineSmall(
          color: AppColors.lightPrimaryText,
        ),
        contentTextStyle: AppTypography.bodyMedium(
          color: AppColors.lightSecondaryText,
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        elevation: AppSpacing.bottomSheetElevation,
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.bottomSheetRadius,
        ),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.lightPrimaryText,
        contentTextStyle: AppTypography.bodyMedium(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
      ),

      // FloatingActionButton Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.sacredSaffron,
        foregroundColor: Colors.white,
        elevation: AppSpacing.elevation6,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
      ),

      // IconButton Theme
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.lightSecondaryText,
        ),
      ),

      // ListTile Theme
      listTileTheme: ListTileThemeData(
        contentPadding: AppSpacing.listItem,
        titleTextStyle: AppTypography.bodyLarge(
          color: AppColors.lightPrimaryText,
        ),
        subtitleTextStyle: AppTypography.bodyMedium(
          color: AppColors.lightSecondaryText,
        ),
      ),

      // Scaffold Background
      scaffoldBackgroundColor: AppColors.lightBackground,

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.lightSecondaryText,
        size: AppSpacing.iconMd,
      ),

      // Primary Icon Theme (for AppBar, etc.)
      primaryIconTheme: const IconThemeData(
        color: Colors.white,
        size: AppSpacing.iconMd,
      ),
    );
  }

  // ============================================
  // DARK THEME
  // ============================================

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color Scheme
      colorScheme: ColorScheme.dark(
        primary: AppColors.sacredSaffron,
        onPrimary: Colors.black,
        primaryContainer: AppColors.sacredSaffronDark,
        onPrimaryContainer: AppColors.darkPrimaryText,

        secondary: AppColors.deepMaroonLight,
        onSecondary: Colors.black,
        secondaryContainer: AppColors.deepMaroon,
        onSecondaryContainer: AppColors.darkPrimaryText,

        tertiary: AppColors.infoLight,
        onTertiary: Colors.black,

        error: AppColors.errorLight,
        onError: Colors.black,
        errorContainer: AppColors.errorDark,
        onErrorContainer: AppColors.darkPrimaryText,

        surface: AppColors.darkSurface,
        onSurface: AppColors.darkPrimaryText,
        surfaceContainerHighest: AppColors.darkSurfaceVariant,

        outline: AppColors.darkBorder,
        outlineVariant: AppColors.darkDivider,

        shadow: Colors.black,
        scrim: Colors.black,
      ),

      // Global card color (Material2 compatibility, used by some widgets)
      cardColor: AppColors.darkSurface,

      // Typography
      textTheme: AppTypography.getTextTheme(color: AppColors.darkPrimaryText),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkPrimaryText,
        elevation: AppSpacing.appBarElevation,
        centerTitle: false,
        titleTextStyle: AppTypography.titleLarge(
          color: AppColors.darkPrimaryText,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: AppSpacing.cardElevation,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.cardRadius),
        margin: EdgeInsets.zero,
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.sacredSaffron,
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
          foregroundColor: AppColors.sacredSaffron,
          side: const BorderSide(color: AppColors.sacredSaffron, width: 1.5),
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
          foregroundColor: AppColors.sacredSaffron,
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
          backgroundColor: AppColors.deepMaroonLight,
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

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        contentPadding: AppSpacing.allMd,
        border: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: const BorderSide(
            color: AppColors.sacredSaffron,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: const BorderSide(color: AppColors.errorLight),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: const BorderSide(color: AppColors.errorLight, width: 2),
        ),
        labelStyle: AppTypography.bodyMedium(
          color: AppColors.darkSecondaryText,
        ),
        hintStyle: AppTypography.bodyMedium(color: AppColors.darkTertiaryText),
        errorStyle: AppTypography.bodySmall(color: AppColors.errorLight),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.sacredSaffron,
        unselectedItemColor: AppColors.darkSecondaryText,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppTypography.labelSmall(),
        unselectedLabelStyle: AppTypography.labelSmall(),
      ),

      // Navigation Bar Theme (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: AppColors.sacredSaffronDark,
        elevation: 8,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.labelSmall(color: AppColors.sacredSaffron);
          }
          return AppTypography.labelSmall(color: AppColors.darkSecondaryText);
        }),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        labelStyle: AppTypography.labelMedium(color: AppColors.darkPrimaryText),
        padding: AppSpacing.allSm,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.chipRadius),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: AppSpacing.dividerThickness,
        space: AppSpacing.dividerThickness,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: AppSpacing.dialogElevation,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.dialogRadius),
        titleTextStyle: AppTypography.headlineSmall(
          color: AppColors.darkPrimaryText,
        ),
        contentTextStyle: AppTypography.bodyMedium(
          color: AppColors.darkSecondaryText,
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: AppSpacing.bottomSheetElevation,
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.bottomSheetRadius,
        ),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        contentTextStyle: AppTypography.bodyMedium(
          color: AppColors.darkPrimaryText,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
      ),

      // FloatingActionButton Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.sacredSaffron,
        foregroundColor: Colors.black,
        elevation: AppSpacing.elevation6,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
      ),

      // IconButton Theme
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.darkSecondaryText,
        ),
      ),

      // ListTile Theme
      listTileTheme: ListTileThemeData(
        contentPadding: AppSpacing.listItem,
        titleTextStyle: AppTypography.bodyLarge(
          color: AppColors.darkPrimaryText,
        ),
        subtitleTextStyle: AppTypography.bodyMedium(
          color: AppColors.darkSecondaryText,
        ),
      ),

      // Scaffold Background
      scaffoldBackgroundColor: AppColors.darkBackground,

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.darkSecondaryText,
        size: AppSpacing.iconMd,
      ),

      // Primary Icon Theme (for AppBar, etc.)
      primaryIconTheme: const IconThemeData(
        color: AppColors.darkPrimaryText,
        size: AppSpacing.iconMd,
      ),
    );
  }
}
