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
import 'package:testing_flutter/models/agency.dart';
import 'package:testing_flutter/models/broker_profile.dart';

class BrokerOwnProfileScreen extends ConsumerStatefulWidget {
  const BrokerOwnProfileScreen({super.key});

  @override
  ConsumerState<BrokerOwnProfileScreen> createState() =>
      _BrokerOwnProfileScreenState();
}

class _BrokerOwnProfileScreenState extends ConsumerState<BrokerOwnProfileScreen> {
  BrokerProfile? _brokerProfile;
  Agency? _agency;
  int _clientCount = 0;
  int _profileCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final user = authState.user;
    final brokerRepo = ref.read(brokerRepositoryProvider);
    final agencyRepo = ref.read(agencyRepositoryProvider);
    final linkRepo = ref.read(linkRepositoryProvider);
    final profileRepo = ref.read(profileRepositoryProvider);

    final brokerProfile = await brokerRepo.getBrokerProfile(user.uid);
    final agency = user.agencyId != null
        ? await agencyRepo.getAgency(user.agencyId!)
        : null;
    final parentIds = await linkRepo.getConnectedParentIds(user.uid);
    final candidates = await profileRepo.getCandidatesByBroker(user.uid);

    if (!mounted) return;
    setState(() {
      _brokerProfile = brokerProfile;
      _agency = agency;
      _clientCount = parentIds.length;
      _profileCount = candidates.length;
      _isLoading = false;
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

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final brokerProfile = _brokerProfile;
    final agency = _agency;
    final clientCount = _clientCount;
    final profileCount = _profileCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
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
                        AppColors.deepMaroon.withValues(alpha: 0.15),
                    child: Text(
                      user.displayName.isNotEmpty
                          ? user.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepMaroon,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: AppSpacing.xxs),
                        decoration: BoxDecoration(
                          color:
                              AppColors.deepMaroon.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          user.role.displayName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.deepMaroon,
                          ),
                        ),
                      ),
                      if (brokerProfile != null &&
                          brokerProfile.rating > 0) ...[
                        AppSpacing.gapW8,
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                          decoration: BoxDecoration(
                            color:
                                AppColors.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: AppColors.warning,
                              ),
                              AppSpacing.gapW4,
                              Text(
                                brokerProfile.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          AppSpacing.gapH16,

          // ---- Stats row ----
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.family_restroom,
                  label: AppStrings.activeClients,
                  value: '$clientCount',
                  color: AppColors.info,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  icon: Icons.person_outline,
                  label: AppStrings.profilesManaged,
                  value: '$profileCount',
                  color: AppColors.success,
                  isDark: isDark,
                ),
              ),
            ],
          ),

          AppSpacing.gapH16,

          // ---- Details card ----
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
                if (agency != null) ...[
                  ListTile(
                    leading: const Icon(Icons.business_outlined),
                    title: const Text('Agency'),
                    trailing: Text(
                      agency.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                ],
                if (brokerProfile != null) ...[
                  ListTile(
                    leading: const Icon(Icons.work_outline),
                    title: const Text('Experience'),
                    trailing: Text(
                      '${brokerProfile.experienceYears} years',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const Divider(height: 1),
                ],
              ],
            ),
          ),

          // ---- Areas served ----
          if (brokerProfile != null &&
              brokerProfile.areasServed.isNotEmpty) ...[
            AppSpacing.gapH16,
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.roundedLg,
                side: BorderSide(
                  color:
                      isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 0.5,
                ),
              ),
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              child: Padding(
                padding: AppSpacing.allMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Areas Served',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: brokerProfile.areasServed
                          .map((area) => Chip(
                                label: Text(area),
                                backgroundColor: AppColors.info
                                    .withValues(alpha: 0.08),
                                labelStyle: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.info,
                                ),
                                side: BorderSide.none,
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ---- Specializations ----
          if (brokerProfile != null &&
              brokerProfile.specializations.isNotEmpty) ...[
            AppSpacing.gapH16,
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.roundedLg,
                side: BorderSide(
                  color:
                      isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 0.5,
                ),
              ),
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              child: Padding(
                padding: AppSpacing.allMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Specializations',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: brokerProfile.specializations
                          .map((spec) => Chip(
                                label: Text(spec),
                                backgroundColor: AppColors.sacredSaffron
                                    .withValues(alpha: 0.08),
                                labelStyle: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.sacredSaffron,
                                ),
                                side: BorderSide.none,
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],

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

// ---------------------------------------------------------------------------
// Stat tile
// ---------------------------------------------------------------------------
class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.5,
        ),
      ),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Padding(
        padding: AppSpacing.allMd,
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            AppSpacing.gapH8,
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkPrimaryText
                    : AppColors.lightPrimaryText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTertiaryText
                    : AppColors.lightTertiaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
