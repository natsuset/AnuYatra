import 'package:flutter/material.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/constants/app_typography.dart';

/// Reusable loading indicator component
class AppLoadingIndicator extends StatelessWidget {
  final double? size;
  final Color? color;
  final double? strokeWidth;
  final String? message;

  const AppLoadingIndicator({
    super.key,
    this.size,
    this.color,
    this.strokeWidth,
    this.message,
  });

  /// Small loading indicator
  factory AppLoadingIndicator.small({Color? color}) {
    return AppLoadingIndicator(
      size: AppSpacing.iconSm,
      strokeWidth: 2,
      color: color,
    );
  }

  /// Large loading indicator with message
  factory AppLoadingIndicator.large({String? message, Color? color}) {
    return AppLoadingIndicator(
      size: AppSpacing.iconXl,
      strokeWidth: 3,
      message: message,
      color: color,
    );
  }

  /// Fullscreen loading overlay
  factory AppLoadingIndicator.fullscreen({String? message}) {
    return AppLoadingIndicator(
      size: AppSpacing.iconXl,
      strokeWidth: 3,
      message: message ?? 'Loading...',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? AppColors.sacredSaffron;

    Widget indicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth ?? 3,
        valueColor: AlwaysStoppedAnimation(effectiveColor),
      ),
    );

    if (message != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          indicator,
          AppSpacing.md.verticalSpace,
          Text(
            message!,
            style: AppTypography.bodyMedium(
              color: theme.brightness == Brightness.dark
                  ? AppColors.darkSecondaryText
                  : AppColors.lightSecondaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return indicator;
  }
}

/// Fullscreen loading overlay
class AppLoadingOverlay extends StatelessWidget {
  final String? message;

  const AppLoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: AppSpacing.allXl,
          child: Padding(
            padding: AppSpacing.allXl,
            child: AppLoadingIndicator.large(message: message),
          ),
        ),
      ),
    );
  }
}
