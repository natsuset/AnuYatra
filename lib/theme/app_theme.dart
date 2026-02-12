import 'package:flutter/material.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';

/// Legacy AppTheme bridge — provides the same API that all screens import,
/// but text-color getters now adapt to the current theme (light / dark).
///
/// Brand colours (sacredSaffron, deepMaroon, status*) are truly constant
/// and stay as `static const`.  Text colours that must flip between light
/// and dark surfaces are provided via static helpers that read
/// `Theme.of(context)`.
class AppTheme {
  AppTheme._();

  // ============================================
  // BRAND COLORS — constant across themes
  // ============================================

  static const Color sacredSaffron = AppColors.sacredSaffron;
  static const Color deepMaroon = AppColors.deepMaroon;
  static const Color softOffWhite = AppColors.lightBackground;

  // WhatsApp-inspired colors
  static const Color whatsAppGreen = AppColors.chatGreen;
  static const Color whatsAppDarkGreen = AppColors.chatDarkGreen;
  static const Color whatsAppLightGreen = AppColors.chatLightGreen;
  static const Color whatsAppGray = AppColors.chatGray;
  static const Color whatsAppDarkGray = AppColors.chatDarkGray;

  // Status colors — constant across themes
  static const Color statusGreen = AppColors.chatGreen;
  static const Color statusRed = Color(0xFFE57373);
  static const Color statusAmber = Color(0xFFFFA726);

  // ------------------------------------------------------------------
  // TEXT COLORS — theme-aware
  //
  // DEPRECATED static constants kept temporarily so `const` widgets
  // using these still compile.  All non-const call-sites should migrate
  // to the context-aware helpers below.
  // ------------------------------------------------------------------

  /// @deprecated Use `AppTheme.primaryText(context)` instead.
  static const Color primaryTextColor = Color(0xFF1F2937);

  /// @deprecated Use `AppTheme.secondaryText(context)` instead.
  static const Color secondaryTextColor = Color(0xFF6B7280);

  /// @deprecated Use `AppTheme.tertiaryText(context)` instead.
  static const Color lightTextColor = Color(0xFF9CA3AF);

  // ============================================
  // THEME-AWARE TEXT COLOR HELPERS
  // ============================================

  /// Primary text colour that adapts to light / dark theme.
  static Color primaryText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkPrimaryText
        : AppColors.lightPrimaryText;
  }

  /// Secondary text colour that adapts to light / dark theme.
  static Color secondaryText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkSecondaryText
        : AppColors.lightSecondaryText;
  }

  /// Tertiary / light text colour that adapts to light / dark theme.
  static Color tertiaryText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTertiaryText
        : AppColors.lightTertiaryText;
  }

  /// Surface / card colour that adapts to light / dark theme.
  static Color cardSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkSurface
        : AppColors.lightSurface;
  }

  /// Background colour that adapts to light / dark theme.
  static Color background(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkBackground
        : AppColors.lightBackground;
  }

  /// Border colour that adapts to light / dark theme.
  static Color border(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkBorder
        : AppColors.lightBorder;
  }

  /// Divider colour that adapts to light / dark theme.
  static Color divider(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkDivider
        : AppColors.lightDivider;
  }

  /// AppBar background that adapts to light / dark theme.
  static Color appBarBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkSurface
        : deepMaroon;
  }

  /// Whether the current theme is dark.
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  // ============================================
  // STATUS / HELPER METHODS — unchanged
  // ============================================

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'interested':
      case 'mutual interest':
      case 'online':
        return statusGreen;
      case 'not match':
      case 'rejected':
        return statusRed;
      case 'saved':
      case 'awaiting response':
        return statusAmber;
      default:
        return secondaryTextColor;
    }
  }

  static Color getChatBubbleColor({
    required bool isSentByUser,
    bool isDark = false,
  }) {
    if (isSentByUser) {
      return isDark ? whatsAppDarkGreen : whatsAppLightGreen;
    }
    return isDark ? AppColors.darkSurface : Colors.white;
  }

  // Custom shadows
  static List<BoxShadow> cardShadow(BuildContext context) => [
    BoxShadow(
      color: Colors.black.withValues(
        alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05,
      ),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: sacredSaffron.withValues(alpha: 0.25),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
}
