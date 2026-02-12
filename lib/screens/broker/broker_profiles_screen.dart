import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/routing/route_names.dart';
import 'package:testing_flutter/core/services/local_storage_service.dart';
import 'package:testing_flutter/models/candidate_profile.dart';

class BrokerProfilesScreen extends ConsumerWidget {
  const BrokerProfilesScreen({super.key});

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
    final profiles = storage.getCandidatesByBroker(user.uid);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.pushNamed(RouteNames.brokerCreateProfile);
        },
        backgroundColor: AppColors.sacredSaffron,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(
          'Create Profile',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: profiles.isEmpty
          ? _EmptyState(isDark: isDark)
          : CustomScrollView(
              slivers: [
                // -- Header with count --
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.sacredSaffron
                                .withValues(alpha: isDark ? 0.15 : 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.badge_rounded,
                            color: AppColors.sacredSaffron,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Managed Profiles',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.lightPrimaryText,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.sacredSaffron
                                .withValues(alpha: isDark ? 0.2 : 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${profiles.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.sacredSaffron,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // -- Profile Cards List --
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                  sliver: SliverList.builder(
                    itemCount: profiles.length,
                    itemBuilder: (context, index) {
                      final profile = profiles[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ProfileCard(
                          profile: profile,
                          isDark: isDark,
                          onTap: () {
                            context.pushNamed(
                              RouteNames.profileView,
                              pathParameters: {'id': profile.id},
                            );
                          },
                          onShare: () {
                            _showShareDialog(context, ref, profile);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  /// Shows dialog to pick a connected parent to share profile with
  void _showShareDialog(
      BuildContext context, WidgetRef ref, CandidateProfile profile) {
    final storage = ref.read(localStorageServiceProvider);
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final parentIds = storage.getConnectedParentIds(authState.user.uid);

    if (parentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No connected parents to share with'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Share Profile With',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              ...parentIds.map((parentId) {
                final parentUser = storage.getUser(parentId);
                final name = parentUser?.displayName ?? parentId;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        AppColors.sacredSaffron.withValues(alpha: 0.12),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppColors.sacredSaffron),
                    ),
                  ),
                  title: Text(name),
                  onTap: () {
                    storage.shareProfile(
                      profileId: profile.id,
                      sharedByUserId: authState.user.uid,
                      sharedWithUserId: parentId,
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('${profile.name}\'s profile shared with $name'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isDark;

  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.sacredSaffron
                    .withValues(alpha: isDark ? 0.1 : 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_open_rounded,
                size: 56,
                color: AppColors.sacredSaffron
                    .withValues(alpha: isDark ? 0.6 : 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Profiles Yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkPrimaryText
                    : AppColors.lightPrimaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No profiles yet. Create your first\ncandidate profile.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.lightSecondaryText,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () {
                context.pushNamed(RouteNames.brokerCreateProfile);
              },
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
              label: const Text('Create Profile'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.sacredSaffron,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Profile Card ──────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final CandidateProfile profile;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onShare;

  const _ProfileCard({
    required this.profile,
    required this.isDark,
    required this.onTap,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final genderColor = profile.gender == Gender.bride
        ? AppColors.pink
        : AppColors.info;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
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
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -- Photo placeholder --
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: genderColor.withValues(alpha: isDark ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: genderColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: profile.photos.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.network(
                          profile.photos.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _PhotoPlaceholder(
                            name: profile.name,
                            color: genderColor,
                          ),
                        ),
                      )
                    : _PhotoPlaceholder(
                        name: profile.name,
                        color: genderColor,
                      ),
              ),
              const SizedBox(width: 14),

              // -- Profile Info --
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            profile.displayName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkPrimaryText
                                  : AppColors.lightPrimaryText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Gender badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: genderColor
                                .withValues(alpha: isDark ? 0.15 : 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            profile.gender.displayName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: genderColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Education & City
                    Row(
                      children: [
                        if (profile.education.isNotEmpty) ...[
                          Icon(
                            Icons.school_outlined,
                            size: 13,
                            color: isDark
                                ? AppColors.darkTertiaryText
                                : AppColors.lightTertiaryText,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              profile.education,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkSecondaryText
                                    : AppColors.lightSecondaryText,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (profile.city.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: isDark
                                ? AppColors.darkTertiaryText
                                : AppColors.lightTertiaryText,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              profile.city,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkSecondaryText
                                    : AppColors.lightSecondaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),

                    // Bottom row: broker badge + share action
                    Row(
                      children: [
                        // Listed with brokers badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.info
                                .withValues(alpha: isDark ? 0.12 : 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.groups_outlined,
                                size: 14,
                                color: AppColors.info,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Listed with ${profile.listedWithBrokersCount} broker${profile.listedWithBrokersCount != 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.info,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),

                        // Share button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onShare,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.sacredSaffron
                                    .withValues(alpha: isDark ? 0.15 : 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.sacredSaffron
                                      .withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.share_rounded,
                                    size: 14,
                                    color: AppColors.sacredSaffron,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Share',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.sacredSaffron,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Photo Placeholder ──────────────────────────────────────────

class _PhotoPlaceholder extends StatelessWidget {
  final String name;
  final Color color;

  const _PhotoPlaceholder({
    required this.name,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: color.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
