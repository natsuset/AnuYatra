import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/providers/theme_provider.dart';
import 'package:testing_flutter/core/theme/theme_extensions.dart';

/// Reusable theme toggle button
/// Can be placed in AppBar, Settings, or anywhere in the app
class ThemeToggleButton extends ConsumerWidget {
  final bool showLabel;
  final IconData? customIcon;

  const ThemeToggleButton({super.key, this.showLabel = false, this.customIcon});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = context.isDarkMode;

    if (showLabel) {
      return _buildLabeledButton(context, ref, themeMode, isDark);
    } else {
      return _buildIconButton(context, ref, isDark);
    }
  }

  Widget _buildIconButton(BuildContext context, WidgetRef ref, bool isDark) {
    return IconButton(
      icon: Icon(
        customIcon ?? (isDark ? Icons.light_mode : Icons.dark_mode),
        color: isDark ? Colors.white : null,
      ),
      tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
      onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
    );
  }

  Widget _buildLabeledButton(
    BuildContext context,
    WidgetRef ref,
    ThemeMode themeMode,
    bool isDark,
  ) {
    return InkWell(
      onTap: () => _showThemeDialog(context, ref, themeMode),
      borderRadius: AppSpacing.roundedMd,
      child: Padding(
        padding: AppSpacing.allMd,
        child: Row(
          children: [
            Icon(
              _getThemeModeIcon(themeMode),
              color: isDark ? Colors.white : AppColors.lightPrimaryText,
            ),
            AppSpacing.md.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Theme', style: context.bodyLarge),
                  AppSpacing.xxs.verticalSpace,
                  Text(_getThemeModeLabel(themeMode), style: context.bodySmall),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark
                  ? AppColors.darkSecondaryText
                  : AppColors.lightSecondaryText,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getThemeModeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System Default';
    }
  }

  void _showThemeDialog(
    BuildContext context,
    WidgetRef ref,
    ThemeMode currentMode,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(
              context,
              ref,
              'Light',
              Icons.light_mode,
              ThemeMode.light,
              currentMode == ThemeMode.light,
            ),
            _buildThemeOption(
              context,
              ref,
              'Dark',
              Icons.dark_mode,
              ThemeMode.dark,
              currentMode == ThemeMode.dark,
            ),
            _buildThemeOption(
              context,
              ref,
              'System Default',
              Icons.brightness_auto,
              ThemeMode.system,
              currentMode == ThemeMode.system,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref,
    String label,
    IconData icon,
    ThemeMode mode,
    bool isSelected,
  ) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.sacredSaffron : null),
      title: Text(label),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.sacredSaffron)
          : null,
      selected: isSelected,
      onTap: () {
        ref.read(themeModeProvider.notifier).setThemeMode(mode);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Theme changed to $label'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }
}

/// Quick theme toggle FAB for easy access
class ThemeToggleFab extends ConsumerWidget {
  const ThemeToggleFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDarkMode;

    return FloatingActionButton.small(
      onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
      tooltip: isDark ? 'Light Mode' : 'Dark Mode',
      child: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
    );
  }
}
