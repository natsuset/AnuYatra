import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/l10n/l10n_extension.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/core/routing/route_names.dart';
import 'package:testing_flutter/models/app_user.dart';
import 'package:testing_flutter/models/candidate_profile.dart';

class CandidateOwnProfileScreen extends ConsumerStatefulWidget {
  const CandidateOwnProfileScreen({super.key});

  @override
  ConsumerState<CandidateOwnProfileScreen> createState() =>
      _CandidateOwnProfileScreenState();
}

class _CandidateOwnProfileScreenState
    extends ConsumerState<CandidateOwnProfileScreen> {
  AppUser? _linkedParent;
  CandidateProfile? _candidateProfile;
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
    final linkRepo = ref.read(linkRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);
    final profileRepo = ref.read(profileRepositoryProvider);

    final linkedParentId = await linkRepo.getLinkedParentId(uid);
    final linkedParent =
        linkedParentId != null ? await userRepo.getUser(linkedParentId) : null;
    final allCandidates = await profileRepo.getAllCandidateProfiles();
    final candidateProfile = allCandidates
        .where((c) => c.candidateUserId == uid)
        .firstOrNull;

    if (!mounted) return;
    setState(() {
      _linkedParent = linkedParent;
      _candidateProfile = candidateProfile;
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
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 0.5,
              ),
            ),
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            child: Padding(
              padding: AppSpacing.allLg,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor:
                        AppColors.deepMaroon.withValues(alpha: 0.15),
                    child: Text(
                      user.displayName.isNotEmpty
                          ? user.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepMaroon,
                      ),
                    ),
                  ),
                  AppSpacing.gapH16,
                  Text(
                    user.displayName.isNotEmpty
                        ? user.displayName
                        : context.l10n.noNameSet,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_candidateProfile != null) ...[
                    AppSpacing.gapH4,
                    Text(
                      '${_candidateProfile!.age} years \u2022 ${_candidateProfile!.gender.displayName}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.lightSecondaryText,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.deepMaroon.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      user.role.displayName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.deepMaroon,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          AppSpacing.gapH16,

          // ---- Link status ----
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.roundedLg,
              side: BorderSide(
                color: _linkedParent != null
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.warning.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: AppSpacing.xs),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (_linkedParent != null
                          ? AppColors.success
                          : AppColors.warning)
                      .withValues(alpha: 0.12),
                  borderRadius: AppSpacing.roundedMd,
                ),
                child: Icon(
                  _linkedParent != null ? Icons.link : Icons.link_off,
                  color: _linkedParent != null
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ),
              title: Text(
                _linkedParent != null ? 'Linked to Parent' : 'Not Linked',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                _linkedParent != null
                    ? _linkedParent!.displayName
                    : 'No parent linked to your account',
              ),
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
                      color: AppColors.sacredSaffron.withValues(alpha: 0.12),
                      borderRadius: AppSpacing.roundedSm,
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
                      color: AppColors.sacredSaffron,
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
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: AppSpacing.roundedSm,
                    ),
                    child: const Icon(
                      Icons.logout,
                      color: AppColors.error,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    context.l10n.logout,
                    style: TextStyle(color: AppColors.error),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
