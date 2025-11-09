import 'package:flutter/material.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';

/// Shadow and elevation system
/// Provides consistent shadows across the app
class AppShadows {
  AppShadows._();

  // ============================================
  // SHADOW DEFINITIONS
  // ============================================

  /// No shadow
  static const List<BoxShadow> none = [];

  /// Subtle shadow for slight elevation
  static final List<BoxShadow> sm = [
    BoxShadow(
      color: AppColors.overlay(0.05),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  /// Default shadow for cards and surfaces
  static final List<BoxShadow> md = [
    BoxShadow(
      color: AppColors.overlay(0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: AppColors.overlay(0.04),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  /// Prominent shadow for elevated elements
  static final List<BoxShadow> lg = [
    BoxShadow(
      color: AppColors.overlay(0.12),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: AppColors.overlay(0.06),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  /// Strong shadow for floating elements
  static final List<BoxShadow> xl = [
    BoxShadow(
      color: AppColors.overlay(0.16),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: AppColors.overlay(0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Maximum shadow for dialogs and modals
  static final List<BoxShadow> xxl = [
    BoxShadow(
      color: AppColors.overlay(0.20),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: AppColors.overlay(0.12),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  // ============================================
  // SEMANTIC SHADOWS
  // ============================================

  /// Shadow for cards
  static List<BoxShadow> get card => md;

  /// Shadow for buttons (when elevated)
  static List<BoxShadow> get button => sm;

  /// Shadow for floating action button
  static List<BoxShadow> get fab => lg;

  /// Shadow for app bar
  static List<BoxShadow> get appBar => sm;

  /// Shadow for bottom sheet
  static List<BoxShadow> get bottomSheet => xxl;

  /// Shadow for dialog
  static List<BoxShadow> get dialog => xxl;

  /// Shadow for dropdown menu
  static List<BoxShadow> get dropdown => lg;

  // ============================================
  // COLORED SHADOWS
  // ============================================

  /// Shadow with primary brand color (for buttons)
  static List<BoxShadow> get primary => [
    BoxShadow(
      color: AppColors.sacredSaffron.withValues(alpha: 0.25),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Shadow with secondary brand color
  static List<BoxShadow> get secondary => [
    BoxShadow(
      color: AppColors.deepMaroon.withValues(alpha: 0.25),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Success shadow
  static List<BoxShadow> get success => [
    BoxShadow(
      color: AppColors.success.withValues(alpha: 0.25),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Error shadow
  static List<BoxShadow> get error => [
    BoxShadow(
      color: AppColors.error.withValues(alpha: 0.25),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // ============================================
  // INNER SHADOWS (using Container decoration)
  // ============================================

  /// Inner shadow effect (simulated with gradient)
  static BoxDecoration innerShadow({required Color backgroundColor}) {
    return BoxDecoration(
      color: backgroundColor,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.black.withValues(alpha: 0.02), Colors.transparent],
        stops: const [0.0, 0.1],
      ),
    );
  }

  // ============================================
  // GLOW EFFECTS
  // ============================================

  /// Glow effect for active/focused elements
  static List<BoxShadow> glow({required Color color, double intensity = 0.3}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: intensity),
        blurRadius: 16,
        spreadRadius: 2,
      ),
    ];
  }

  /// Soft glow for verification badges, premium features
  static List<BoxShadow> get softGlow =>
      glow(color: AppColors.sacredSaffron, intensity: 0.2);
}
