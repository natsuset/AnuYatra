import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:testing_flutter/common/widgets/molecules/branded_app_bar.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/routing/route_names.dart';
import 'package:testing_flutter/core/services/local_storage_service.dart';

class BrokerDashboardScreen extends ConsumerWidget {
  const BrokerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final storage = ref.watch(localStorageServiceProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = authState.user;
    final stats = storage.getBrokerStats(user.uid);
    final brokerProfile = storage.getBrokerProfile(user.uid);

    return Scaffold(
      appBar: const BrandedAppBar(),
      body: CustomScrollView(
        slivers: [
          // -- Welcome Header --
          SliverToBoxAdapter(
            child: _WelcomeHeader(
              displayName: user.displayName.isNotEmpty
                  ? user.displayName
                  : 'Broker',
              rating: brokerProfile?.rating ?? 0.0,
              experienceYears: brokerProfile?.experienceYears ?? 0,
              isDark: isDark,
            ),
          ),

          // -- Stat Cards Grid --
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: [
                _StatCard(
                  label: 'Active Clients',
                  value: stats['activeClients'] ?? 0,
                  icon: Icons.people_alt_rounded,
                  color: AppColors.info,
                  isDark: isDark,
                ),
                _StatCard(
                  label: 'Profiles Managed',
                  value: stats['profilesManaged'] ?? 0,
                  icon: Icons.badge_rounded,
                  color: AppColors.success,
                  isDark: isDark,
                ),
                _StatCard(
                  label: 'Profiles Shared',
                  value: stats['profilesShared'] ?? 0,
                  icon: Icons.share_rounded,
                  color: AppColors.sacredSaffron,
                  isDark: isDark,
                ),
                _StatCard(
                  label: 'Pending Requests',
                  value: stats['pendingRequests'] ?? 0,
                  icon: Icons.pending_actions_rounded,
                  color: AppColors.warning,
                  isDark: isDark,
                ),
              ],
            ),
          ),

          // -- Quick Actions Section --
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.lightPrimaryText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _QuickActionChip(
                        label: 'Create Profile',
                        icon: Icons.person_add_alt_1_rounded,
                        color: AppColors.success,
                        isDark: isDark,
                        onTap: () {
                          context.pushNamed(RouteNames.brokerCreateProfile);
                        },
                      ),
                      _QuickActionChip(
                        label: 'Share Profile',
                        icon: Icons.send_rounded,
                        color: AppColors.sacredSaffron,
                        isDark: isDark,
                        onTap: () {
                          context.goNamed(RouteNames.brokerProfiles);
                        },
                      ),
                      _QuickActionChip(
                        label: 'View Requests',
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

          // -- Recent Activity Section --
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Recent Activity',
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
            sliver: _buildRecentActivityList(storage, user.uid, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityList(
      LocalStorageService storage, String brokerUserId, bool isDark) {
    // Build real activity from shared profiles, link requests, etc.
    final recentShared = storage.getSharedProfilesByBroker(brokerUserId);
    final pendingRequests = storage.getPendingRequestsFor(brokerUserId);

    final activities = <_ActivityData>[];

    // Add recent shares
    for (final sp in recentShared.take(3)) {
      final profile = storage.getCandidateProfile(sp.profileId);
      final parent = storage.getUser(sp.sharedWithUserId);
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

    // Add pending requests
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

    // Sort by time descending
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (activities.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(24),
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
                const SizedBox(height: 12),
                Text(
                  'No recent activity',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.lightSecondaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Activity from shared profiles and connections will appear here',
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
      itemCount: activities.length.clamp(0, 5),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final a = activities[index];
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

  static String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
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
              const SizedBox(height: 16),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
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
        borderRadius: BorderRadius.circular(16),
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
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
              borderRadius: BorderRadius.circular(12),
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
