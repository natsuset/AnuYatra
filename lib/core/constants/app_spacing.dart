import 'package:flutter/material.dart';

/// Spacing system following 4px baseline grid
/// Provides consistent spacing throughout the app
class AppSpacing {
  AppSpacing._();

  // ============================================
  // SPACING VALUES (4px baseline grid)
  // ============================================

  static const double xxxs = 2.0; // Hairline spacing
  static const double xxs = 4.0; // Micro spacing
  static const double xs = 8.0; // Extra small spacing
  static const double sm = 12.0; // Small spacing
  static const double md = 16.0; // Medium spacing (base)
  static const double lg = 24.0; // Large spacing
  static const double xl = 32.0; // Extra large spacing
  static const double xxl = 48.0; // Double extra large spacing
  static const double xxxl = 64.0; // Triple extra large spacing

  // ============================================
  // SEMANTIC SPACING
  // ============================================

  /// Spacing between sections
  static const double sectionSpacing = xl;

  /// Spacing between cards in a list
  static const double cardSpacing = md;

  /// Padding inside cards
  static const double cardPadding = md;

  /// Screen edge padding
  static const double screenPadding = md;

  /// Spacing between form fields
  static const double formSpacing = md;

  /// Spacing between icon and text
  static const double iconTextSpacing = xs;

  /// Bottom sheet padding
  static const double bottomSheetPadding = lg;

  /// Dialog padding
  static const double dialogPadding = lg;

  // ============================================
  // EDGE INSETS PRESETS
  // ============================================

  static const EdgeInsets allXxxs = EdgeInsets.all(xxxs);
  static const EdgeInsets allXxs = EdgeInsets.all(xxs);
  static const EdgeInsets allXs = EdgeInsets.all(xs);
  static const EdgeInsets allSm = EdgeInsets.all(sm);
  static const EdgeInsets allMd = EdgeInsets.all(md);
  static const EdgeInsets allLg = EdgeInsets.all(lg);
  static const EdgeInsets allXl = EdgeInsets.all(xl);
  static const EdgeInsets allXxl = EdgeInsets.all(xxl);

  static const EdgeInsets horizontalXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: xl);

  static const EdgeInsets verticalXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(vertical: xl);

  /// Screen safe area padding
  static const EdgeInsets screenHorizontal = EdgeInsets.symmetric(
    horizontal: screenPadding,
  );
  static const EdgeInsets screenAll = EdgeInsets.all(screenPadding);

  /// Card content padding
  static const EdgeInsets cardContent = EdgeInsets.all(cardPadding);

  /// List item padding
  static const EdgeInsets listItem = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );

  // ============================================
  // SIZE CONSTANTS
  // ============================================

  /// Icon sizes
  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;
  static const double iconXxl = 64.0;

  /// Avatar sizes
  static const double avatarSm = 32.0;
  static const double avatarMd = 48.0;
  static const double avatarLg = 64.0;
  static const double avatarXl = 96.0;
  static const double avatarXxl = 128.0;

  /// Button heights
  static const double buttonHeightSm = 36.0;
  static const double buttonHeightMd = 48.0;
  static const double buttonHeightLg = 56.0;

  /// Input field height
  static const double inputHeight = 48.0;

  /// App bar height
  static const double appBarHeight = 56.0;

  /// Bottom nav bar height
  static const double bottomNavHeight = 64.0;

  /// Divider thickness
  static const double dividerThickness = 1.0;

  // ============================================
  // BORDER RADIUS
  // ============================================

  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 24.0;
  static const double radiusFull = 999.0; // Pill shape

  static const Radius borderRadiusXs = Radius.circular(radiusXs);
  static const Radius borderRadiusSm = Radius.circular(radiusSm);
  static const Radius borderRadiusMd = Radius.circular(radiusMd);
  static const Radius borderRadiusLg = Radius.circular(radiusLg);
  static const Radius borderRadiusXl = Radius.circular(radiusXl);
  static const Radius borderRadiusXxl = Radius.circular(radiusXxl);
  static const Radius borderRadiusFull = Radius.circular(radiusFull);

  static const BorderRadius roundedXs = BorderRadius.all(borderRadiusXs);
  static const BorderRadius roundedSm = BorderRadius.all(borderRadiusSm);
  static const BorderRadius roundedMd = BorderRadius.all(borderRadiusMd);
  static const BorderRadius roundedLg = BorderRadius.all(borderRadiusLg);
  static const BorderRadius roundedXl = BorderRadius.all(borderRadiusXl);
  static const BorderRadius roundedXxl = BorderRadius.all(borderRadiusXxl);
  static const BorderRadius roundedFull = BorderRadius.all(borderRadiusFull);

  /// Semantic border radius
  static const BorderRadius cardRadius = roundedMd;
  static const BorderRadius buttonRadius = roundedFull;
  static const BorderRadius inputRadius = roundedMd;
  static const BorderRadius chipRadius = roundedFull;
  static const BorderRadius bottomSheetRadius = BorderRadius.vertical(
    top: borderRadiusXl,
  );
  static const BorderRadius dialogRadius = roundedLg;

  // ============================================
  // ELEVATION (SHADOWS)
  // ============================================

  static const double elevation0 = 0.0;
  static const double elevation1 = 1.0;
  static const double elevation2 = 2.0;
  static const double elevation3 = 3.0;
  static const double elevation4 = 4.0;
  static const double elevation6 = 6.0;
  static const double elevation8 = 8.0;
  static const double elevation12 = 12.0;
  static const double elevation16 = 16.0;
  static const double elevation24 = 24.0;

  /// Semantic elevation
  static const double cardElevation = elevation2;
  static const double buttonElevation = elevation0; // Flat by default
  static const double dialogElevation = elevation24;
  static const double bottomSheetElevation = elevation16;
  static const double appBarElevation = elevation0;

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Create custom EdgeInsets
  static EdgeInsets only({
    double top = 0,
    double right = 0,
    double bottom = 0,
    double left = 0,
  }) {
    return EdgeInsets.only(top: top, right: right, bottom: bottom, left: left);
  }

  /// Create symmetric EdgeInsets with custom values
  static EdgeInsets symmetric({double horizontal = 0, double vertical = 0}) {
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  }

  /// Get responsive spacing based on screen size
  static double responsive(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200 && desktop != null) return desktop;
    if (width >= 600 && tablet != null) return tablet;
    return mobile;
  }

  // ============================================
  // CONST GAP WIDGETS
  // ============================================

  static const SizedBox gapH4 = SizedBox(height: xxs);
  static const SizedBox gapH8 = SizedBox(height: xs);
  static const SizedBox gapH12 = SizedBox(height: sm);
  static const SizedBox gapH16 = SizedBox(height: md);
  static const SizedBox gapH24 = SizedBox(height: lg);
  static const SizedBox gapH32 = SizedBox(height: xl);
  static const SizedBox gapH48 = SizedBox(height: xxl);

  static const SizedBox gapW4 = SizedBox(width: xxs);
  static const SizedBox gapW8 = SizedBox(width: xs);
  static const SizedBox gapW12 = SizedBox(width: sm);
  static const SizedBox gapW16 = SizedBox(width: md);
  static const SizedBox gapW24 = SizedBox(width: lg);
  static const SizedBox gapW32 = SizedBox(width: xl);
}

/// Extension for adding vertical/horizontal spacing widgets
extension SpacingExtension on num {
  SizedBox get verticalSpace => SizedBox(height: toDouble());
  SizedBox get horizontalSpace => SizedBox(width: toDouble());
}
