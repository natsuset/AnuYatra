import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:testing_flutter/common/animations/app_animations.dart';
import 'package:testing_flutter/common/widgets/atoms/app_avatar.dart';
import 'package:testing_flutter/common/widgets/atoms/app_button.dart';
import 'package:testing_flutter/common/widgets/atoms/app_loading.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/providers/theme_provider.dart';
import 'package:testing_flutter/core/theme/theme_extensions.dart';

/// Demo screen showcasing the new design system
class DesignSystemDemoScreen extends ConsumerWidget {
  const DesignSystemDemoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Design System Demo',
          style: context.titleLarge.copyWith(color: Colors.white),
        ),
        actions: [
          // Theme toggle button
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Toggle Theme',
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
        ],
      ),
      body: ListView(
        padding: context.screenPadding,
        children: [
          // Header
          FadeInUp(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome to', style: context.bodyMedium),
                Text('Anuyātrā', style: context.displaySmall),
                AppSpacing.sm.verticalSpace,
                Text(
                  'Explore our new design system with dark mode support!',
                  style: context.bodyMedium.copyWith(
                    color: context.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),

          AppSpacing.xl.verticalSpace,

          // Colors Section
          _buildSection(
            context,
            title: 'Brand Colors',
            child: Row(
              children: [
                _buildColorChip('Primary', AppColors.sacredSaffron),
                AppSpacing.sm.horizontalSpace,
                _buildColorChip('Secondary', AppColors.deepMaroon),
                AppSpacing.sm.horizontalSpace,
                _buildColorChip('Success', AppColors.success),
              ],
            ),
          ),

          // Typography Section
          _buildSection(
            context,
            title: 'Typography',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Display Large', style: context.displayLarge),
                Text('Headline Medium', style: context.headlineMedium),
                Text('Title Large', style: context.titleLarge),
                Text('Body Medium', style: context.bodyMedium),
                Text('Label Small', style: context.labelSmall),
              ],
            ),
          ),

          // Buttons Section
          _buildSection(
            context,
            title: 'Buttons',
            child: Column(
              children: [
                AppButton.primary(
                  label: 'Primary Button',
                  onPressed: () =>
                      _showMessage(context, 'Primary button pressed'),
                  leadingIcon: Icons.favorite,
                  isFullWidth: true,
                ),
                AppSpacing.sm.verticalSpace,
                AppButton.secondary(
                  label: 'Secondary Button',
                  onPressed: () =>
                      _showMessage(context, 'Secondary button pressed'),
                  trailingIcon: Icons.arrow_forward,
                  isFullWidth: true,
                ),
                AppSpacing.sm.verticalSpace,
                AppButton.outline(
                  label: 'Outline Button',
                  onPressed: () =>
                      _showMessage(context, 'Outline button pressed'),
                  isFullWidth: true,
                ),
                AppSpacing.sm.verticalSpace,
                Row(
                  children: [
                    Expanded(
                      child: AppButton.text(
                        label: 'Text Button',
                        onPressed: () {},
                      ),
                    ),
                    AppSpacing.sm.horizontalSpace,
                    Expanded(
                      child: AppButton.danger(
                        label: 'Danger',
                        onPressed: () {},
                        leadingIcon: Icons.delete,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Avatars Section
          _buildSection(
            context,
            title: 'Avatars',
            child: Row(
              children: [
                const AppAvatar(size: AvatarSize.xs, showBorder: true),
                AppSpacing.md.horizontalSpace,
                const AppAvatar(
                  size: AvatarSize.sm,
                  showBadge: true,
                  badgeColor: AppColors.success,
                ),
                AppSpacing.md.horizontalSpace,
                const AppAvatar(
                  size: AvatarSize.md,
                  showBorder: true,
                  showBadge: true,
                ),
                AppSpacing.md.horizontalSpace,
                const AppAvatar(size: AvatarSize.lg, showBorder: true),
              ],
            ),
          ),

          // Loading Indicators Section
          _buildSection(
            context,
            title: 'Loading Indicators',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                AppLoadingIndicator.small(),
                const AppLoadingIndicator(),
                AppLoadingIndicator.large(message: 'Loading...'),
              ],
            ),
          ),

          // Animations Section
          _buildSection(
            context,
            title: 'Animations',
            child: Column(
              children: [
                FadeInUp(
                  delay: Duration.zero,
                  child: Card(
                    child: Padding(
                      padding: AppSpacing.allMd,
                      child: Text(
                        'Fade In Up Animation',
                        style: context.bodyMedium,
                      ),
                    ),
                  ),
                ),
                AppSpacing.sm.verticalSpace,
                ScaleIn(
                  delay: const Duration(milliseconds: 200),
                  child: Card(
                    child: Padding(
                      padding: AppSpacing.allMd,
                      child: Text(
                        'Scale In Animation',
                        style: context.bodyMedium,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Theme Info
          _buildSection(
            context,
            title: 'Theme Information',
            child: Card(
              child: Padding(
                padding: AppSpacing.allMd,
                child: Column(
                  children: [
                    _buildInfoRow('Mode', isDark ? 'Dark' : 'Light'),
                    const Divider(),
                    _buildInfoRow(
                      'Screen Width',
                      '${context.screenWidth.toInt()}px',
                    ),
                    const Divider(),
                    _buildInfoRow(
                      'Device Type',
                      context.isMobile
                          ? 'Mobile'
                          : context.isTablet
                          ? 'Tablet'
                          : 'Desktop',
                    ),
                  ],
                ),
              ),
            ),
          ),

          AppSpacing.xxl.verticalSpace,
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return ScaleIn(
      delay: const Duration(milliseconds: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.titleLarge),
          AppSpacing.sm.verticalSpace,
          child,
          AppSpacing.xl.verticalSpace,
        ],
      ),
    );
  }

  Widget _buildColorChip(String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppSpacing.roundedSm,
            ),
          ),
          AppSpacing.xs.verticalSpace,
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: AppSpacing.verticalSm,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
