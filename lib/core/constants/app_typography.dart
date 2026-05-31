import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography system following Material Design 3 type scale
/// Provides consistent text styles across the app
class AppTypography {
  AppTypography._();

  // ============================================
  // FONT FAMILIES
  // ============================================

  static String get primaryFont => GoogleFonts.inter().fontFamily!;
  static String get displayFont => GoogleFonts.poppins().fontFamily!;
  static String get monoFont => GoogleFonts.robotoMono().fontFamily!;

  // ============================================
  // DISPLAY STYLES - Large, expressive text
  // ============================================

  static TextStyle displayLarge({Color? color}) => GoogleFonts.poppins(
    fontSize: 57,
    fontWeight: FontWeight.w700,
    height: 1.12,
    letterSpacing: -0.25,
    color: color,
  );

  static TextStyle displayMedium({Color? color}) => GoogleFonts.poppins(
    fontSize: 45,
    fontWeight: FontWeight.w700,
    height: 1.16,
    color: color,
  );

  static TextStyle displaySmall({Color? color}) => GoogleFonts.poppins(
    fontSize: 36,
    fontWeight: FontWeight.w600,
    height: 1.22,
    color: color,
  );

  // ============================================
  // HEADLINE STYLES - High emphasis headings
  // ============================================

  static TextStyle headlineLarge({Color? color}) => GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: color,
  );

  static TextStyle headlineMedium({Color? color}) => GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.29,
    color: color,
  );

  static TextStyle headlineSmall({Color? color}) => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.33,
    color: color,
  );

  // ============================================
  // TITLE STYLES - Medium emphasis headings
  // ============================================

  static TextStyle titleLarge({Color? color}) => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.27,
    color: color,
  );

  static TextStyle titleMedium({Color? color}) => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.45,
    letterSpacing: 0.15,
    color: color,
  );

  static TextStyle titleSmall({Color? color}) => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.40,
    letterSpacing: 0.1,
    color: color,
  );

  // ============================================
  // BODY STYLES - Main content text
  // ============================================

  static TextStyle bodyLarge({Color? color}) => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.45,
    letterSpacing: 0.5,
    color: color,
  );

  static TextStyle bodyMedium({Color? color}) => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.43,
    letterSpacing: 0.25,
    color: color,
  );

  static TextStyle bodySmall({Color? color}) => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.38,
    letterSpacing: 0.4,
    color: color,
  );

  // ============================================
  // LABEL STYLES - UI elements, buttons
  // ============================================

  static TextStyle labelLarge({Color? color}) => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
    color: color,
  );

  static TextStyle labelMedium({Color? color}) => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.33,
    letterSpacing: 0.5,
    color: color,
  );

  static TextStyle labelSmall({Color? color}) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.45,
    letterSpacing: 0.5,
    color: color,
  );

  // ============================================
  // CUSTOM APP-SPECIFIC STYLES
  // ============================================

  /// Profile name style
  static TextStyle profileName({Color? color}) => GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: color,
  );

  /// Profile subtitle (age, location)
  static TextStyle profileSubtitle({Color? color}) => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: color,
  );

  /// Button text
  static TextStyle button({Color? color}) => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.0,
    letterSpacing: 0.5,
    color: color,
  );

  /// Caption with icon
  static TextStyle caption({Color? color}) => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.33,
    color: color,
  );

  /// Overline (all caps labels)
  static TextStyle overline({Color? color}) => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 1.6,
    letterSpacing: 1.5,
    color: color,
  );

  /// Badge/chip text
  static TextStyle badge({Color? color}) => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.0,
    letterSpacing: 0.5,
    color: color,
  );

  // ============================================
  // TEXT THEME BUILDER
  // ============================================

  /// Get complete Material TextTheme
  static TextTheme getTextTheme({Color? color}) {
    return TextTheme(
      displayLarge: displayLarge(color: color),
      displayMedium: displayMedium(color: color),
      displaySmall: displaySmall(color: color),
      headlineLarge: headlineLarge(color: color),
      headlineMedium: headlineMedium(color: color),
      headlineSmall: headlineSmall(color: color),
      titleLarge: titleLarge(color: color),
      titleMedium: titleMedium(color: color),
      titleSmall: titleSmall(color: color),
      bodyLarge: bodyLarge(color: color),
      bodyMedium: bodyMedium(color: color),
      bodySmall: bodySmall(color: color),
      labelLarge: labelLarge(color: color),
      labelMedium: labelMedium(color: color),
      labelSmall: labelSmall(color: color),
    );
  }
}
