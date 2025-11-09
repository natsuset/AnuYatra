import 'package:flutter/material.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/constants/app_typography.dart';

/// Extension on BuildContext for easy access to theme properties
/// Usage: context.colors, context.textTheme, context.spacing
extension ThemeContext on BuildContext {
  // Theme Data
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;

  // Screen Dimensions
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  EdgeInsets get padding => MediaQuery.of(this).padding;
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;

  // Responsive Breakpoints
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1200;
  bool get isDesktop => screenWidth >= 1200;

  // Device Info
  bool get isDarkMode => theme.brightness == Brightness.dark;
  bool get isLightMode => !isDarkMode;
  Brightness get brightness => theme.brightness;

  // Semantic Colors
  Color get primaryColor => colors.primary;
  Color get secondaryColor => colors.secondary;
  Color get backgroundColor => colors.surface;
  Color get surfaceColor => colors.surface;
  Color get errorColor => colors.error;

  // Text Colors based on theme
  Color get primaryTextColor =>
      isDarkMode ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
  Color get secondaryTextColor =>
      isDarkMode ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
  Color get tertiaryTextColor =>
      isDarkMode ? AppColors.darkTertiaryText : AppColors.lightTertiaryText;

  // Border and Divider Colors
  Color get borderColor =>
      isDarkMode ? AppColors.darkBorder : AppColors.lightBorder;
  Color get dividerColor =>
      isDarkMode ? AppColors.darkDivider : AppColors.lightDivider;

  // Navigation
  void pop<T>([T? result]) => Navigator.of(this).pop(result);
  Future<T?> push<T>(Widget page) =>
      Navigator.of(this).push<T>(MaterialPageRoute(builder: (_) => page));
  Future<T?> pushReplacement<T, TO>(Widget page) => Navigator.of(
    this,
  ).pushReplacement<T, TO>(MaterialPageRoute(builder: (_) => page));

  // Snackbar
  void showSnackBar(
    String message, {
    Duration? duration,
    Color? backgroundColor,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? const Duration(seconds: 3),
        backgroundColor: backgroundColor,
      ),
    );
  }

  void showErrorSnackBar(String message) {
    showSnackBar(message, backgroundColor: errorColor);
  }

  void showSuccessSnackBar(String message) {
    showSnackBar(message, backgroundColor: AppColors.success);
  }

  // Focus
  void unfocus() => FocusScope.of(this).unfocus();

  // Show Dialog
  Future<T?> showAppDialog<T>({
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: this,
      barrierDismissible: barrierDismissible,
      builder: (context) => child,
    );
  }

  // Show Bottom Sheet
  Future<T?> showAppBottomSheet<T>({
    required Widget child,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: this,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => child,
    );
  }
}

/// Extension for responsive sizing
extension ResponsiveContext on BuildContext {
  /// Get responsive value based on screen size
  T responsive<T>({required T mobile, T? tablet, T? desktop}) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }

  /// Get responsive spacing
  double responsiveSpacing({
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return responsive(mobile: mobile, tablet: tablet, desktop: desktop);
  }

  /// Get responsive font size
  double responsiveFontSize({
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return responsive(mobile: mobile, tablet: tablet, desktop: desktop);
  }

  /// Calculate percentage of screen width
  double widthPercent(double percent) => screenWidth * (percent / 100);

  /// Calculate percentage of screen height
  double heightPercent(double percent) => screenHeight * (percent / 100);
}

/// Extension for custom app typography
extension TypographyContext on BuildContext {
  // Display Styles
  TextStyle get displayLarge =>
      AppTypography.displayLarge(color: primaryTextColor);
  TextStyle get displayMedium =>
      AppTypography.displayMedium(color: primaryTextColor);
  TextStyle get displaySmall =>
      AppTypography.displaySmall(color: primaryTextColor);

  // Headline Styles
  TextStyle get headlineLarge =>
      AppTypography.headlineLarge(color: primaryTextColor);
  TextStyle get headlineMedium =>
      AppTypography.headlineMedium(color: primaryTextColor);
  TextStyle get headlineSmall =>
      AppTypography.headlineSmall(color: primaryTextColor);

  // Title Styles
  TextStyle get titleLarge => AppTypography.titleLarge(color: primaryTextColor);
  TextStyle get titleMedium =>
      AppTypography.titleMedium(color: primaryTextColor);
  TextStyle get titleSmall => AppTypography.titleSmall(color: primaryTextColor);

  // Body Styles
  TextStyle get bodyLarge => AppTypography.bodyLarge(color: primaryTextColor);
  TextStyle get bodyMedium => AppTypography.bodyMedium(color: primaryTextColor);
  TextStyle get bodySmall => AppTypography.bodySmall(color: secondaryTextColor);

  // Label Styles
  TextStyle get labelLarge => AppTypography.labelLarge(color: primaryTextColor);
  TextStyle get labelMedium =>
      AppTypography.labelMedium(color: secondaryTextColor);
  TextStyle get labelSmall =>
      AppTypography.labelSmall(color: tertiaryTextColor);

  // Custom App Styles
  TextStyle get profileName =>
      AppTypography.profileName(color: primaryTextColor);
  TextStyle get profileSubtitle =>
      AppTypography.profileSubtitle(color: secondaryTextColor);
  TextStyle get button => AppTypography.button(color: primaryTextColor);
  TextStyle get caption => AppTypography.caption(color: secondaryTextColor);
  TextStyle get overline => AppTypography.overline(color: tertiaryTextColor);
  TextStyle get badge => AppTypography.badge(color: primaryTextColor);
}

/// Extension for app spacing
extension SpacingContext on BuildContext {
  // Direct spacing access
  double get xxxs => AppSpacing.xxxs;
  double get xxs => AppSpacing.xxs;
  double get xs => AppSpacing.xs;
  double get sm => AppSpacing.sm;
  double get md => AppSpacing.md;
  double get lg => AppSpacing.lg;
  double get xl => AppSpacing.xl;
  double get xxl => AppSpacing.xxl;
  double get xxxl => AppSpacing.xxxl;

  // Edge Insets
  EdgeInsets get paddingXs => AppSpacing.allXs;
  EdgeInsets get paddingSm => AppSpacing.allSm;
  EdgeInsets get paddingMd => AppSpacing.allMd;
  EdgeInsets get paddingLg => AppSpacing.allLg;
  EdgeInsets get paddingXl => AppSpacing.allXl;

  EdgeInsets get paddingHorizontalMd => AppSpacing.horizontalMd;
  EdgeInsets get paddingVerticalMd => AppSpacing.verticalMd;

  EdgeInsets get screenPadding => AppSpacing.screenAll;
  EdgeInsets get cardPadding => AppSpacing.cardContent;
  EdgeInsets get listItemPadding => AppSpacing.listItem;

  // Border Radius
  BorderRadius get roundedSm => AppSpacing.roundedSm;
  BorderRadius get roundedMd => AppSpacing.roundedMd;
  BorderRadius get roundedLg => AppSpacing.roundedLg;
  BorderRadius get roundedFull => AppSpacing.roundedFull;

  BorderRadius get cardRadius => AppSpacing.cardRadius;
  BorderRadius get buttonRadius => AppSpacing.buttonRadius;
  BorderRadius get inputRadius => AppSpacing.inputRadius;
}
