import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:testing_flutter/core/theme/app_palette.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/l10n/l10n_extension.dart';
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
      return Scaffold(
        body: Center(child: Text(context.l10n.pleaseLogIn)),
      );
    }

    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.myProfile),
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
                color: isDark ? Theme.of(context).colorScheme.outline : Theme.of(context).colorScheme.outline,
                width: 0.5,
              ),
            ),
            color: isDark ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                    child: Text(
                      user.displayName.isNotEmpty
                          ? user.displayName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user.displayName.isNotEmpty
                        ? user.displayName
                        : context.l10n.noNameSet,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.gapH4,
                  Text(
                    user.phoneNumber,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.gapH8,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      user.role.displayName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
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
                color: isDark ? Theme.of(context).colorScheme.outline : Theme.of(context).colorScheme.outline,
                width: 0.5,
              ),
            ),
            color: isDark ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                if (_parentProfile != null) ...[
                  ListTile(
                    leading: const Icon(Icons.search),
                    title: Text(context.l10n.lookingForSection),
                    trailing: Text(
                      _parentProfile!.lookingForDisplay,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.location_city_outlined),
                    title: Text(context.l10n.cityLabel),
                    trailing: Text(
                      _parentProfile!.city.isNotEmpty
                          ? _parentProfile!.city
                          : context.l10n.notSet,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.map_outlined),
                    title: Text(context.l10n.stateLabel),
                    trailing: Text(
                      _parentProfile!.state.isNotEmpty
                          ? _parentProfile!.state
                          : context.l10n.notSet,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const Divider(height: 1),
                ],
                ListTile(
                  leading: const Icon(Icons.handshake_outlined),
                  title: Text(context.l10n.connectedBrokers),
                  trailing: Text(
                    '${_connectedBrokerIds.length}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.palette.info,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.family_restroom,
                    color: _linkedChild != null
                        ? context.palette.success
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  title: Text(context.l10n.linkedChild),
                  trailing: Text(
                    _linkedChild != null
                        ? _linkedChild!.displayName
                        : context.l10n.notLinked,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _linkedChild != null
                          ? context.palette.success
                          : (isDark
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                              : Theme.of(context).colorScheme.onSurfaceVariant),
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
                color: isDark ? Theme.of(context).colorScheme.outline : Theme.of(context).colorScheme.outline,
                width: 0.5,
              ),
            ),
            color: isDark ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color:
                          context.palette.success.withValues(alpha: 0.12),
                      borderRadius: AppSpacing.roundedSm,
                    ),
                    child: Icon(
                      Icons.family_restroom_rounded,
                      color: context.palette.success,
                      size: 18,
                    ),
                  ),
                  title: const Text("My children's profiles"),
                  subtitle: const Text(
                    "Manage profiles you've created for your son or daughter",
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.pushNamed(RouteNames.myProfiles),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: context.palette.info.withValues(alpha: 0.12),
                      borderRadius: AppSpacing.roundedSm,
                    ),
                    child: Icon(
                      Icons.link,
                      color: context.palette.info,
                      size: 18,
                    ),
                  ),
                  title: Text(context.l10n.viewLinkRequests),
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
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: AppSpacing.roundedSm,
                    ),
                    child: Icon(
                      Icons.settings_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 18,
                    ),
                  ),
                  title: Text(context.l10n.settings),
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
                      color: context.palette.error.withValues(alpha: 0.12),
                      borderRadius: AppSpacing.roundedSm,
                    ),
                    child: Icon(
                      Icons.logout,
                      color: context.palette.error,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    context.l10n.logout,
                    style: TextStyle(color: context.palette.error),
                  ),
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
                              backgroundColor: context.palette.error,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
