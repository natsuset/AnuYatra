import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/l10n/l10n_extension.dart';
import 'package:testing_flutter/core/providers/theme_provider.dart';
import 'package:testing_flutter/common/widgets/atoms/language_picker_tile.dart';

class AppSettingsScreen extends ConsumerWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    if (authState is! AuthAuthenticated) {
      return Scaffold(
        body: Center(child: Text(context.l10n.pleaseLogIn)),
      );
    }

    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settings),
      ),
      body: ListView(
        children: [
          // ---- Account section ----
          _SectionHeader(title: context.l10n.account, isDark: isDark),
          Card(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xxs,
            ),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.roundedMd,
              side: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 0.5,
              ),
            ),
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        AppColors.sacredSaffron.withValues(alpha: 0.15),
                    child: Text(
                      user.displayName.isNotEmpty
                          ? user.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.sacredSaffron,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    user.displayName.isNotEmpty
                        ? user.displayName
                        : context.l10n.noNameSet,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(user.phoneNumber),
                  trailing: _RoleBadge(role: user.role.displayName),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: Text(context.l10n.phoneNumber),
                  subtitle: Text(user.phoneNumber),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: Text(context.l10n.roleLabel),
                  subtitle: Text(user.role.displayName),
                ),
              ],
            ),
          ),

          AppSpacing.gapH16,

          // ---- Appearance section ----
          _SectionHeader(title: context.l10n.appearance, isDark: isDark),
          Card(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xxs,
            ),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.roundedMd,
              side: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 0.5,
              ),
            ),
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    color: AppColors.sacredSaffron,
                  ),
                  title: Text(context.l10n.darkMode),
                  subtitle: Text(
                    themeMode == ThemeMode.dark
                        ? context.l10n.darkThemeActive
                        : context.l10n.lightThemeActive,
                  ),
                  value: themeMode == ThemeMode.dark,
                  activeTrackColor: AppColors.sacredSaffron,
                  onChanged: (_) {
                    ref.read(themeModeProvider.notifier).toggleTheme();
                  },
                ),
                const Divider(height: 1),
                const LanguagePickerTile(),
              ],
            ),
          ),

          AppSpacing.gapH16,

          // ---- Danger zone ----
          _SectionHeader(title: context.l10n.session, isDark: isDark),
          Card(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xxs,
            ),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.roundedMd,
              side: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 0.5,
              ),
            ),
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: Text(
                context.l10n.logout,
                style: TextStyle(color: AppColors.error),
              ),
              subtitle: Text(context.l10n.signOutSubtitle),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(context.l10n.logoutConfirmTitle),
                    content: Text(
                      context.l10n.logoutConfirmMessage,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(context.l10n.cancel),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        child: Text(context.l10n.logout),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  ref.read(authProvider.notifier).logout();
                }
              },
            ),
          ),

          AppSpacing.gapH32,

          // ---- App version ----
          Center(
            child: Column(
              children: [
                Text(
                  context.l10n.vivahaSamskara,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.darkTertiaryText
                        : AppColors.lightTertiaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                AppSpacing.gapH4,
                Text(
                  'Version 1.0.0 (beta)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTertiaryText
                        : AppColors.lightTertiaryText,
                  ),
                ),
              ],
            ),
          ),

          AppSpacing.gapH32,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, AppSpacing.xs, 20, AppSpacing.xxs),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color:
              isDark ? AppColors.darkTertiaryText : AppColors.lightTertiaryText,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Role badge
// ---------------------------------------------------------------------------
class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.sacredSaffron.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        role,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.sacredSaffron,
        ),
      ),
    );
  }
}
