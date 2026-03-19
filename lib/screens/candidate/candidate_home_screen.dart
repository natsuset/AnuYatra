import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:testing_flutter/common/widgets/molecules/branded_app_bar.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/core/routing/route_names.dart';
import 'package:testing_flutter/models/app_user.dart';
import 'package:testing_flutter/models/shared_profile.dart';

class CandidateHomeScreen extends ConsumerStatefulWidget {
  const CandidateHomeScreen({super.key});

  @override
  ConsumerState<CandidateHomeScreen> createState() =>
      _CandidateHomeScreenState();
}

class _CandidateHomeScreenState extends ConsumerState<CandidateHomeScreen> {
  AppUser? _linkedParent;
  List<SharedProfile> _sharedProfiles = [];
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
    final sharedProfileRepo = ref.read(sharedProfileRepositoryProvider);

    final linkedParentId = await linkRepo.getLinkedParentId(uid);
    final linkedParent =
        linkedParentId != null ? await userRepo.getUser(linkedParentId) : null;
    final sharedProfiles = await sharedProfileRepo.getSharedProfilesForUser(uid);

    if (!mounted) return;
    setState(() {
      _linkedParent = linkedParent;
      _sharedProfiles = sharedProfiles;
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
      appBar: const BrandedAppBar(),
      body: CustomScrollView(
        slivers: [
          // ---- Welcome header ----
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.displayName.isNotEmpty
                        ? user.displayName
                        : 'Candidate',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ---- Body ----
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Link status card
                _buildLinkStatusCard(
                  context: context,
                  isDark: isDark,
                  theme: theme,
                  linkedParent: _linkedParent,
                ),

                const SizedBox(height: 16),

                // Stats card
                _buildStatsCard(
                  context: context,
                  isDark: isDark,
                  theme: theme,
                  sharedCount: _sharedProfiles.length,
                ),

                const SizedBox(height: 16),

                // Quick actions
                _buildQuickActions(context, isDark, theme),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkStatusCard({
    required BuildContext context,
    required bool isDark,
    required ThemeData theme,
    AppUser? linkedParent,
  }) {
    final isLinked = linkedParent != null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isLinked
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.warning.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (isLinked ? AppColors.success : AppColors.warning)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isLinked ? Icons.link : Icons.link_off,
                color: isLinked ? AppColors.success : AppColors.warning,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLinked ? 'Linked to Parent' : 'Not Linked',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isLinked
                        ? linkedParent.displayName
                        : 'You are not linked to any parent yet',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.lightSecondaryText,
                    ),
                  ),
                ],
              ),
            ),
            if (!isLinked)
              FilledButton(
                onPressed: () {
                  context.pushNamed(RouteNames.linkToParent);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.sacredSaffron,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Link'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard({
    required BuildContext context,
    required bool isDark,
    required ThemeData theme,
    required int sharedCount,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.5,
        ),
      ),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.people_outline, color: AppColors.info),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profiles Shared With You',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$sharedCount profile${sharedCount == 1 ? '' : 's'} available',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.lightSecondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$sharedCount',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: AppColors.info,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    bool isDark,
    ThemeData theme,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.5,
        ),
      ),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Quick Actions',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.sacredSaffron.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.visibility_outlined,
                color: AppColors.sacredSaffron,
                size: 20,
              ),
            ),
            title: const Text('View Shared Profiles'),
            subtitle: const Text('See profiles forwarded by your parent'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.goNamed(RouteNames.candidateShared);
            },
          ),
          const Divider(height: 1, indent: 72),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.link_outlined,
                color: AppColors.info,
                size: 20,
              ),
            ),
            title: const Text('Link Requests'),
            subtitle: const Text('View your connection requests'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.pushNamed(RouteNames.linkRequests);
            },
          ),
        ],
      ),
    );
  }
}
