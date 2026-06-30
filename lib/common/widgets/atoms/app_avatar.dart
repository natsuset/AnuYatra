import 'package:flutter/material.dart';
import 'package:testing_flutter/core/theme/app_palette.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';

/// Reusable avatar component with fallback support
enum AvatarSize {
  xs(AppSpacing.avatarSm),
  sm(AppSpacing.avatarMd),
  md(AppSpacing.avatarLg),
  lg(AppSpacing.avatarXl),
  xl(AppSpacing.avatarXxl);

  const AvatarSize(this.size);
  final double size;
}

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final AvatarSize size;
  final bool showBadge;
  final Color? badgeColor;
  final VoidCallback? onTap;
  final bool showBorder;
  final Color? borderColor;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = AvatarSize.md,
    this.showBadge = false,
    this.badgeColor,
    this.onTap,
    this.showBorder = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget avatar = Container(
      width: size.size,
      height: size.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color:
                    borderColor ??
                    (isDark ? Theme.of(context).colorScheme.outline : Theme.of(context).colorScheme.outline),
                width: 2,
              )
            : null,
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                width: size.size,
                height: size.size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder(context);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildPlaceholder(context, showLoading: true);
                },
              )
            : _buildPlaceholder(context),
      ),
    );

    if (showBadge) {
      avatar = Stack(
        children: [
          avatar,
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: size.size * 0.25,
              height: size.size * 0.25,
              decoration: BoxDecoration(
                color: badgeColor ?? context.palette.success,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }

  Widget _buildPlaceholder(BuildContext context, {bool showLoading = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (showLoading) {
      return Container(
        color: isDark
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Center(
          child: SizedBox(
            width: size.size * 0.3,
            height: size.size * 0.3,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

    return Container(
      color: isDark
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.person,
          size: size.size * 0.5,
          color: isDark
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
