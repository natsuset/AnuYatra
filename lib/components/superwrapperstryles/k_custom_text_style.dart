// lib/superwrapper/typography/k_custom_text_style.dart
import 'package:flutter/material.dart';

class KCustomTextStyle {
  KCustomTextStyle._();

  static TextStyle _of(
    BuildContext context, {
    required double size,
    required FontWeight weight,
    required Color color,
    required String fontFamily,
    double? height,
    double? letterSpacing,
    bool scaleWithSystem = true,
  }) {
    final base = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final factor = MediaQuery.textScaleFactorOf(context).clamp(0.85, 1.30);
    final finalSize = scaleWithSystem ? size * factor : size;

    return base.copyWith(
      fontSize: finalSize,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontFamily: fontFamily,
    );
  }

  // Match your usage: kRegular / kMedium / kBold
  static TextStyle kRegular(
    BuildContext context,
    double size,
    Color color,
    String fontFamily, {
    double? height,
    double? letterSpacing,
  }) => _of(
    context,
    size: size,
    weight: FontWeight.w400,
    color: color,
    fontFamily: fontFamily,
    height: height,
    letterSpacing: letterSpacing,
  );

  static TextStyle kMedium(
    BuildContext context,
    double size,
    Color color,
    String fontFamily, {
    double? height,
    double? letterSpacing,
  }) => _of(
    context,
    size: size,
    weight: FontWeight.w600, // feel free to change to w500 if preferred
    color: color,
    fontFamily: fontFamily,
    height: height,
    letterSpacing: letterSpacing,
  );

  static TextStyle kBold(
    BuildContext context,
    double size,
    Color color,
    String fontFamily, {
    double? height,
    double? letterSpacing,
  }) => _of(
    context,
    size: size,
    weight: FontWeight.w700,
    color: color,
    fontFamily: fontFamily,
    height: height,
    letterSpacing: letterSpacing,
  );
}
