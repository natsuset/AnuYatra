import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/constants/app_strings.dart';
import 'package:testing_flutter/core/routing/route_names.dart';
import 'package:testing_flutter/models/user_role.dart';

/// First screen: "I am a..." role selection.
/// Beautiful cards for each role with icons and descriptions.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSpacing.gapH48,

              // Brand header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: AppSpacing.roundedXl,
                ),
                child: const Text(
                  AppStrings.appName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              AppSpacing.gapH16,

              Text(
                AppStrings.welcome,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.gapH8,
              Text(
                'How would you like to use Anuyatra?',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.gapH32,

              // Role cards
              Expanded(
                child: ListView(
                  children: UserRole.values.map((role) {
                    return _RoleCard(
                      role: role,
                      isDark: isDark,
                      onTap: () {
                        context.pushNamed(
                          RouteNames.login,
                          extra: role,
                        );
                      },
                    );
                  }).toList(),
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.only(bottom: 24, top: 8),
                child: Center(
                  child: Text(
                    AppStrings.appTagline,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final UserRole role;
  final bool isDark;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.isDark,
    required this.onTap,
  });

  IconData get _icon {
    switch (role) {
      case UserRole.agencyAdmin:
        return Icons.business;
      case UserRole.broker:
        return Icons.handshake;
      case UserRole.parent:
        return Icons.family_restroom;
      case UserRole.candidate:
        return Icons.favorite;
    }
  }

  Color get _color {
    switch (role) {
      case UserRole.agencyAdmin:
        return AppColors.info;
      case UserRole.broker:
        return AppColors.success;
      case UserRole.parent:
        return AppColors.sacredSaffron;
      case UserRole.candidate:
        return AppColors.deepMaroon;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: AppSpacing.roundedLg,
        elevation: isDark ? 0 : 1,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.roundedLg,
          child: Padding(
            padding: AppSpacing.allMd,
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_icon, color: _color, size: 28),
                ),
                AppSpacing.gapW16,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AppSpacing.gapH4,
                      Text(
                        role.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
