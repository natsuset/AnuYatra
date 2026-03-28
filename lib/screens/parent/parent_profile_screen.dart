import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/constants/app_strings.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/core/routing/route_names.dart';
import 'package:testing_flutter/models/app_user.dart';
import 'package:testing_flutter/models/parent_profile.dart';

class ParentProfileScreen extends ConsumerStatefulWidget {
  const ParentProfileScreen({super.key});

  @override
  ConsumerState<ParentProfileScreen> createState() =>
      _ParentProfileScreenState();
}

class _ParentProfileScreenState extends ConsumerState<ParentProfileScreen> {
  ParentProfile? _parentProfile;
  List<String> _connectedBrokerIds = [];
  AppUser? _linkedChild;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final uid = authState.user.uid;
    final profileRepo = ref.read(profileRepositoryProvider);
    final linkRepo = ref.read(linkRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);

    final parentProfile = await profileRepo.getParentProfile(uid);
    final connectedBrokerIds = await linkRepo.getConnectedBrokerIds(uid);
    final linkedChildId = await linkRepo.getLinkedChildId(uid);
    final linkedChild =
        linkedChildId != null ? await userRepo.getUser(linkedChildId) : null;

    if (!mounted) return;
    setState(() {
      _parentProfile = parentProfile;
      _connectedBrokerIds = connectedBrokerIds;
      _linkedChild = linkedChild;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        body: Center(child: Text('Please log in')),
      );
    }

    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.myProfile),
      ),
      body: ListView(
        padding: AppSpacing.allMd,
        children: [
          // ---- Profile header ----
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.roundedLg,
              side: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 0.5,
              ),
            ),
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor:
                        AppColors.sacredSaffron.withValues(alpha: 0.15),
                    child: Text(
                      user.displayName.isNotEmpty
                          ? user.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sacredSaffron,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user.displayName.isNotEmpty
                        ? user.displayName
                        : 'No name set',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.gapH4,
                  Text(
                    user.phoneNumber,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.lightSecondaryText,
                    ),
                  ),
                  AppSpacing.gapH8,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.sacredSaffron.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      user.role.displayName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.sacredSaffron,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          AppSpacing.gapH16,

          // ---- Profile details ----
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.roundedLg,
              side: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 0.5,
              ),
            ),
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            child: Column(
              children: [
                if (_parentProfile != null) ...[
                  ListTile(
                    leading: const Icon(Icons.search),
                    title: const Text('Looking For'),
                    trailing: Text(
                      _parentProfile!.lookingForDisplay,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.deepMaroon,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.location_city_outlined),
                    title: const Text('City'),
                    trailing: Text(
                      _parentProfile!.city.isNotEmpty
                          ? _parentProfile!.city
                          : 'Not set',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.map_outlined),
                    title: const Text('State'),
                    trailing: Text(
                      _parentProfile!.state.isNotEmpty
                          ? _parentProfile!.state
                          : 'Not set',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const Divider(height: 1),
                ],
                ListTile(
                  leading: const Icon(Icons.handshake_outlined),
                  title: const Text('Connected Brokers'),
                  trailing: Text(
                    '${_connectedBrokerIds.length}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.info,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.family_restroom,
                    color: _linkedChild != null
                        ? AppColors.success
                        : AppColors.lightTertiaryText,
                  ),
                  title: const Text('Linked Child'),
                  trailing: Text(
                    _linkedChild != null
                        ? _linkedChild!.displayName
                        : 'Not linked',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _linkedChild != null
                          ? AppColors.success
                          : (isDark
                              ? AppColors.darkTertiaryText
                              : AppColors.lightTertiaryText),
                    ),
                  ),
                ),
              ],
            ),
          ),

          AppSpacing.gapH16,

          // ---- Actions ----
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.roundedLg,
              side: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 0.5,
              ),
            ),
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.12),
                      borderRadius: AppSpacing.roundedSm,
                    ),
                    child: const Icon(
                      Icons.link,
                      color: AppColors.info,
                      size: 18,
                    ),
                  ),
                  title: const Text('View Link Requests'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.pushNamed(RouteNames.linkRequests);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.sacredSaffron.withValues(alpha: 0.12),
                      borderRadius: AppSpacing.roundedSm,
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
                      color: AppColors.sacredSaffron,
                      size: 18,
                    ),
                  ),
                  title: const Text(AppStrings.settings),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.pushNamed(RouteNames.appSettings);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: AppSpacing.roundedSm,
                    ),
                    child: const Icon(
                      Icons.logout,
                      color: AppColors.error,
                      size: 18,
                    ),
                  ),
                  title: const Text(
                    AppStrings.logout,
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text(AppStrings.logoutConfirmTitle),
                        content: const Text(
                          AppStrings.logoutConfirmMessage,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text(AppStrings.cancel),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.error,
                            ),
                            child: const Text(AppStrings.logout),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      ref.read(authProvider.notifier).logout();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
