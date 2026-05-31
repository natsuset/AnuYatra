import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:testing_flutter/common/widgets/molecules/branded_app_bar.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/data/repositories/broker_repository.dart';
import 'package:testing_flutter/core/l10n/l10n_extension.dart';
import 'package:testing_flutter/core/routing/route_names.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/models/broker_profile.dart';

class BrokerDashboardScreen extends ConsumerStatefulWidget {
  const BrokerDashboardScreen({super.key});

  @override
  ConsumerState<BrokerDashboardScreen> createState() =>
      _BrokerDashboardScreenState();
}

class _BrokerDashboardScreenState
    extends ConsumerState<BrokerDashboardScreen> {
  BrokerStats _stats = BrokerStats.empty;
  BrokerProfile? _brokerProfile;
  List<_ActivityData> _activities = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final brokerRepo = ref.read(brokerRepositoryProvider);
    final sharedProfileRepo = ref.read(sharedProfileRepositoryProvider);
    final linkRepo = ref.read(linkRepositoryProvider);
    final profileRepo = ref.read(profileRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);
    final uid = authState.user.uid;

    final stats = await brokerRepo.getBrokerStats(uid);
    final brokerProfile = await brokerRepo.getBrokerProfile(uid);

    final recentShared = await sharedProfileRepo.getSharedProfilesByBroker(uid);
    final pendingRequests = await linkRepo.getPendingRequestsFor(uid);

    final activities = <_ActivityData>[];
    for (final sp in recentShared.take(3)) {
      final profile = await profileRepo.getCandidateProfile(sp.profileId);
      final parent = await userRepo.getUser(sp.sharedWithUserId);
      if (profile != null) {
        activities.add(_ActivityData(
          icon: Icons.share_rounded,
          iconColor: AppColors.success,
          title: 'Profile shared',
          subtitle:
              '${profile.name} shared with ${parent?.displayName ?? 'client'}',
          time: _formatTime(sp.sharedAt),
          timestamp: sp.sharedAt,
        ));
      }
    }
    for (final req in pendingRequests.take(3)) {
      activities.add(_ActivityData(
        icon: Icons.person_add_rounded,
        iconColor: AppColors.sacredSaffron,
        title: 'Connection request',
        subtitle: '${req.fromUserName} wants to connect',
        time: _formatTime(req.createdAt),
        timestamp: req.createdAt,
      ));
    }
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (!mounted) return;
    setState(() {
      _stats = stats;
      _brokerProfile = brokerProfile;
      _activities = activities;
    });
  }

  static String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = authState.user;

    return Scaffold(
      appBar: const BrandedAppBar(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _WelcomeHeader(
              displayName: user.displayName.isNotEmpty
                  ? user.displayName
                  : 'Broker',
              rating: _brokerProfile?.rating ?? 0.0,
              experienceYears: _brokerProfile?.experienceYears ?? 0,
              isDark: isDark,
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: [
                _StatCard(
                  label: l10n.connectedClients,
                  value: _stats.activeClients,
                  icon: Icons.people_alt_rounded,
                  color: AppColors.info,
                  isDark: isDark,
                ),
                _StatCard(
                  label: l10n.managedProfiles,
                  value: _stats.profilesManaged,
                  icon: Icons.badge_rounded,
                  color: AppColors.success,
                  isDark: isDark,
                ),
                _StatCard(
                  label: l10n.profilesSharedStat,
                  value: _stats.profilesShared,
                  icon: Icons.share_rounded,
                  color: AppColors.sacredSaffron,
                  isDark: isDark,
                ),
                _StatCard(
                  label: l10n.pendingRequestsStat,
                  value: _stats.pendingRequests,
                  icon: Icons.pending_actions_rounded,
                  color: AppColors.warning,
                  isDark: isDark,
                ),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.quickActions,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.lightPrimaryText,
                    ),
                  ),
                  AppSpacing.gapH12,
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _QuickActionChip(
                        label: l10n.createProfileAction,
                        icon: Icons.person_add_alt_1_rounded,
                        color: AppColors.success,
                        isDark: isDark,
                        onTap: () {
                          context.pushNamed(RouteNames.brokerCreateProfile);
                        },
                      ),
                      _QuickActionChip(
                        label: l10n.shareProfileAction,
                        icon: Icons.send_rounded,
                        color: AppColors.sacredSaffron,
                        isDark: isDark,
                        onTap: () {
                          context.goNamed(RouteNames.brokerProfiles);
                        },
                      ),
                      _QuickActionChip(
                        label: l10n.viewRequestsAction,
                        icon: Icons.inbox_rounded,
                        color: AppColors.info,
                        isDark: isDark,
                        onTap: () {
                          context.pushNamed(RouteNames.linkRequests);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                l10n.recentActivity,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.lightPrimaryText,
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: _buildRecentActivityList(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityList(bool isDark) {
    if (_activities.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          padding: AppSpacing.allLg,
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 40,
                  color: isDark
                      ? AppColors.darkTertiaryText
                      : AppColors.lightTertiaryText,
                ),
                AppSpacing.gapH12,
                Text(
                  context.l10n.noRecentActivity,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.lightSecondaryText,
                  ),
                ),
                AppSpacing.gapH4,
                Text(
                  context.l10n.recentActivityHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTertiaryText
                        : AppColors.lightTertiaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList.separated(
      itemCount: _activities.length.clamp(0, 5),
      separatorBuilder: (_, __) => AppSpacing.gapH8,
      itemBuilder: (context, index) {
        final a = _activities[index];
        return _ActivityTile(
          icon: a.icon,
          iconColor: a.iconColor,
          title: a.title,
          subtitle: a.subtitle,
          time: a.time,
          isDark: isDark,
        );
      },
    );
  }
}

class _ActivityData {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;
  final DateTime timestamp;

  const _ActivityData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.timestamp,
  });
}

// ─── Welcome Header ──────────────────────────────────────────────

class _WelcomeHeader extends StatelessWidget {
  final String displayName;
  final double rating;
  final int experienceYears;
  final bool isDark;

  const _WelcomeHeader({
    required this.displayName,
    required this.rating,
    required this.experienceYears,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.deepMaroonDark, AppColors.darkSurface]
              : [AppColors.sacredSaffron, AppColors.deepMaroon],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : 'B',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapH16,
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _HeaderBadge(
                    icon: Icons.star_rounded,
                    label: rating > 0
                        ? '${rating.toStringAsFixed(1)} Rating'
                        : 'New Broker',
                  ),
                  _HeaderBadge(
                    icon: Icons.work_history_rounded,
                    label: experienceYears > 0
                        ? '$experienceYears yrs experience'
                        : 'Getting started',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: AppSpacing.roundedXl,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card ──────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.5,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Adapt icon size and padding based on available space
          final compact = constraints.maxHeight < 120;
          final iconPad = compact ? 6.0 : 8.0;
          final iconSize = compact ? 18.0 : 22.0;
          final pad = compact ? 10.0 : 14.0;

          return Padding(
            padding: EdgeInsets.all(pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(iconPad),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: iconSize),
                ),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$value',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.lightPrimaryText,
                    ),
                    maxLines: 1,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.lightSecondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Quick Action Chip ──────────────────────────────────────────

class _QuickActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.roundedMd,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.15 : 0.08),
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              AppSpacing.gapW8,
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Activity Tile ──────────────────────────────────────────────

class _ActivityTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;
  final bool isDark;

  const _ActivityTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: isDark ? 0.15 : 0.1),
              borderRadius: AppSpacing.roundedMd,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkPrimaryText
                        : AppColors.lightPrimaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.lightSecondaryText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            time,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDark
                  ? AppColors.darkTertiaryText
                  : AppColors.lightTertiaryText,
            ),
          ),
        ],
      ),
    );
  }
}
