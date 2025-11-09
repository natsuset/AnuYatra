import 'package:flutter/material.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/constants/app_typography.dart';
import 'package:testing_flutter/core/constants/app_shadows.dart';

/// Reusable button component with multiple variants
/// Follows atomic design principles - ATOM level
enum AppButtonVariant {
  primary, // Elevated button with primary color
  secondary, // Filled button with secondary color
  outline, // Outlined button
  text, // Text button
  danger, // Error/delete actions
}

enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final Widget? icon;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final Color? customColor;
  final bool showShadow;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
    this.leadingIcon,
    this.trailingIcon,
    this.customColor,
    this.showShadow = false,
  });

  /// Primary button (most common)
  factory AppButton.primary({
    required String label,
    required VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    bool isLoading = false,
    bool isFullWidth = false,
    IconData? leadingIcon,
    IconData? trailingIcon,
    bool showShadow = false,
  }) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      variant: AppButtonVariant.primary,
      size: size,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      showShadow: showShadow,
    );
  }

  /// Secondary button
  factory AppButton.secondary({
    required String label,
    required VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    bool isLoading = false,
    bool isFullWidth = false,
    IconData? leadingIcon,
    IconData? trailingIcon,
  }) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      variant: AppButtonVariant.secondary,
      size: size,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
    );
  }

  /// Outline button
  factory AppButton.outline({
    required String label,
    required VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    bool isLoading = false,
    bool isFullWidth = false,
    IconData? leadingIcon,
    IconData? trailingIcon,
  }) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      variant: AppButtonVariant.outline,
      size: size,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
    );
  }

  /// Text button (minimal)
  factory AppButton.text({
    required String label,
    required VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    bool isFullWidth = false,
    IconData? leadingIcon,
    IconData? trailingIcon,
  }) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      variant: AppButtonVariant.text,
      size: size,
      isFullWidth: isFullWidth,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
    );
  }

  /// Danger button (for destructive actions)
  factory AppButton.danger({
    required String label,
    required VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    bool isLoading = false,
    bool isFullWidth = false,
    IconData? leadingIcon,
    IconData? trailingIcon,
  }) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      variant: AppButtonVariant.danger,
      size: size,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
    );
  }

  /// Icon button (icon only)
  factory AppButton.icon({
    required Widget icon,
    required VoidCallback? onPressed,
    AppButtonVariant variant = AppButtonVariant.primary,
    AppButtonSize size = AppButtonSize.medium,
    bool isLoading = false,
  }) {
    return AppButton(
      label: '',
      onPressed: onPressed,
      variant: variant,
      size: size,
      isLoading: isLoading,
      icon: icon,
    );
  }

  double get _height {
    switch (size) {
      case AppButtonSize.small:
        return AppSpacing.buttonHeightSm;
      case AppButtonSize.medium:
        return AppSpacing.buttonHeightMd;
      case AppButtonSize.large:
        return AppSpacing.buttonHeightLg;
    }
  }

  EdgeInsets get _padding {
    switch (size) {
      case AppButtonSize.small:
        return AppSpacing.horizontalMd.copyWith(
          top: AppSpacing.xs,
          bottom: AppSpacing.xs,
        );
      case AppButtonSize.medium:
        return AppSpacing.horizontalLg.copyWith(
          top: AppSpacing.sm,
          bottom: AppSpacing.sm,
        );
      case AppButtonSize.large:
        return AppSpacing.horizontalXl.copyWith(
          top: AppSpacing.md,
          bottom: AppSpacing.md,
        );
    }
  }

  TextStyle _textStyle(BuildContext context) {
    final baseStyle = AppTypography.button();
    switch (size) {
      case AppButtonSize.small:
        return baseStyle.copyWith(fontSize: 14);
      case AppButtonSize.medium:
        return baseStyle;
      case AppButtonSize.large:
        return baseStyle.copyWith(fontSize: 18);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget buttonWidget;

    // If icon-only button
    if (icon != null) {
      buttonWidget = _buildIconButton(context, colorScheme);
    } else {
      buttonWidget = _buildTextButton(context, colorScheme);
    }

    // Wrap with shadow if needed
    if (showShadow && onPressed != null && !isLoading) {
      buttonWidget = Container(
        decoration: BoxDecoration(
          borderRadius: AppSpacing.buttonRadius,
          boxShadow: variant == AppButtonVariant.primary
              ? AppShadows.primary
              : AppShadows.button,
        ),
        child: buttonWidget,
      );
    }

    return buttonWidget;
  }

  Widget _buildTextButton(BuildContext context, ColorScheme colorScheme) {
    Widget buttonChild = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leadingIcon != null && !isLoading) ...[
          Icon(leadingIcon, size: _iconSize),
          AppSpacing.xs.horizontalSpace,
        ],
        if (isLoading)
          SizedBox(
            width: _iconSize,
            height: _iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(
                variant == AppButtonVariant.text ||
                        variant == AppButtonVariant.outline
                    ? colorScheme.primary
                    : Colors.white,
              ),
            ),
          )
        else
          Text(label, style: _textStyle(context)),
        if (trailingIcon != null && !isLoading) ...[
          AppSpacing.xs.horizontalSpace,
          Icon(trailingIcon, size: _iconSize),
        ],
      ],
    );

    switch (variant) {
      case AppButtonVariant.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(isFullWidth ? double.infinity : 88, _height),
            padding: _padding,
            backgroundColor: customColor,
          ),
          child: buttonChild,
        );

      case AppButtonVariant.secondary:
        return FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            minimumSize: Size(isFullWidth ? double.infinity : 88, _height),
            padding: _padding,
            backgroundColor: customColor,
          ),
          child: buttonChild,
        );

      case AppButtonVariant.outline:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: Size(isFullWidth ? double.infinity : 88, _height),
            padding: _padding,
          ),
          child: buttonChild,
        );

      case AppButtonVariant.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            minimumSize: Size(isFullWidth ? double.infinity : 64, _height),
            padding: _padding,
          ),
          child: buttonChild,
        );

      case AppButtonVariant.danger:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(isFullWidth ? double.infinity : 88, _height),
            padding: _padding,
            backgroundColor: customColor ?? colorScheme.error,
          ),
          child: buttonChild,
        );
    }
  }

  Widget _buildIconButton(BuildContext context, ColorScheme colorScheme) {
    switch (variant) {
      case AppButtonVariant.primary:
        return IconButton(
          onPressed: isLoading ? null : onPressed,
          icon: isLoading
              ? SizedBox(
                  width: _iconSize,
                  height: _iconSize,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : icon!,
          style: IconButton.styleFrom(
            backgroundColor: customColor ?? colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
        );

      case AppButtonVariant.secondary:
        return IconButton(
          onPressed: isLoading ? null : onPressed,
          icon: isLoading
              ? SizedBox(
                  width: _iconSize,
                  height: _iconSize,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : icon!,
          style: IconButton.styleFrom(
            backgroundColor: customColor ?? colorScheme.secondary,
            foregroundColor: colorScheme.onSecondary,
          ),
        );

      default:
        return IconButton(
          onPressed: isLoading ? null : onPressed,
          icon: isLoading
              ? SizedBox(
                  width: _iconSize,
                  height: _iconSize,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : icon!,
        );
    }
  }

  double get _iconSize {
    switch (size) {
      case AppButtonSize.small:
        return AppSpacing.iconSm;
      case AppButtonSize.medium:
        return AppSpacing.iconMd;
      case AppButtonSize.large:
        return AppSpacing.iconLg;
    }
  }
}
