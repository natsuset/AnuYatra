import 'package:flutter/material.dart';

/// App color palette following Material Design 3 principles
/// Uses semantic naming for better maintainability
class AppColors {
  AppColors._();

  // ============================================
  // BRAND COLORS - Primary Identity
  // ============================================

  /// Sacred Saffron - Primary brand color representing Indian culture
  static const Color sacredSaffron = Color(0xFFFF8C42);
  static const Color sacredSaffronLight = Color(0xFFFFB580);
  static const Color sacredSaffronDark = Color(0xFFE67A31);

  /// Deep Maroon - Secondary brand color representing tradition
  static const Color deepMaroon = Color(0xFF8B2635);
  static const Color deepMaroonLight = Color(0xFFA84655);
  static const Color deepMaroonDark = Color(0xFF6B1A27);

  // ============================================
  // LIGHT THEME COLORS
  // ============================================

  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF5F5F5);

  static const Color lightPrimaryText = Color(0xFF1F2937);
  static const Color lightSecondaryText = Color(0xFF6B7280);
  static const Color lightTertiaryText = Color(0xFF9CA3AF);

  static const Color lightDivider = Color(0xFFE5E7EB);
  static const Color lightBorder = Color(0xFFD1D5DB);

  // ============================================
  // DARK THEME COLORS
  // ============================================

  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceVariant = Color(0xFF334155);

  static const Color darkPrimaryText = Color(0xFFF1F5F9);
  static const Color darkSecondaryText = Color(0xFFCBD5E1);
  static const Color darkTertiaryText = Color(0xFF94A3B8);

  static const Color darkDivider = Color(0xFF334155);
  static const Color darkBorder = Color(0xFF475569);

  // ============================================
  // SEMANTIC COLORS - Status & Feedback
  // ============================================

  /// Success - Positive actions, mutual interest, verified
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color successDark = Color(0xFF059669);

  /// Error - Errors, rejections, warnings
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);
  static const Color errorDark = Color(0xFFDC2626);

  /// Warning - Pending actions, awaiting response
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color warningDark = Color(0xFFD97706);

  /// Info - Information, new features
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF60A5FA);
  static const Color infoDark = Color(0xFF2563EB);

  // ============================================
  // WHATSAPP-INSPIRED COLORS - Chat Interface
  // ============================================

  static const Color chatGreen = Color(0xFF25D366);
  static const Color chatDarkGreen = Color(0xFF128C7E);
  static const Color chatLightGreen = Color(0xFFDCF8C6);
  static const Color chatGray = Color(0xFFECE5DD);
  static const Color chatDarkGray = Color(0xFF8696A0);

  // ============================================
  // OVERLAY COLORS
  // ============================================

  static Color overlay(double opacity) =>
      Colors.black.withValues(alpha: opacity);
  static const Color scrim = Color(0x80000000);
  static const Color barrier = Color(0xCC000000);

  // ============================================
  // GRADIENT DEFINITIONS
  // ============================================

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [sacredSaffron, deepMaroon],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [successLight, success],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient surfaceGradient(bool isDark) => LinearGradient(
    colors: isDark
        ? [darkSurface, darkSurfaceVariant]
        : [lightSurface, lightSurfaceVariant],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Get appropriate text color for background
  static Color getTextColorForBackground(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? lightPrimaryText : darkPrimaryText;
  }

  /// Get status color based on profile status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'interested':
      case 'mutual interest':
      case 'verified':
      case 'online':
        return success;
      case 'not match':
      case 'rejected':
        return error;
      case 'saved':
      case 'awaiting response':
      case 'pending':
        return warning;
      default:
        return info;
    }
  }

  /// Get chat bubble color
  static Color getChatBubbleColor({
    required bool isSentByUser,
    required bool isDark,
  }) {
    if (isSentByUser) {
      return isDark ? chatDarkGreen : chatLightGreen;
    }
    return isDark ? darkSurface : Colors.white;
  }
}
