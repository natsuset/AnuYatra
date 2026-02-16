import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/routing/route_names.dart';
import 'package:testing_flutter/core/services/local_storage_service.dart';
import 'package:testing_flutter/models/candidate_profile.dart';
import 'package:testing_flutter/models/shared_profile.dart';
import 'package:testing_flutter/screens/parent/forward_to_child_sheet.dart';
import 'package:testing_flutter/theme/app_theme.dart';
import 'package:testing_flutter/common/widgets/atoms/theme_toggle_button.dart';

/// Parent home screen: shows shared profiles from brokers with response actions.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<_SharedProfileItem> _items = [];
  int _connectedBrokerCount = 0;
  int _pendingRequestCount = 0;
  String? _linkedChildName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final storage = ref.read(localStorageServiceProvider);
    final uid = authState.user.uid;

    // Get shared profiles for this parent
    final sharedProfiles = storage.getSharedProfilesForUser(uid);
    final items = <_SharedProfileItem>[];
    for (final sp in sharedProfiles) {
      final profile = storage.getCandidateProfile(sp.profileId);
      if (profile != null) {
        final sharedBy = storage.getBrokerProfile(sp.sharedByUserId);
        items.add(_SharedProfileItem(
          shared: sp,
          profile: profile,
          brokerName: sharedBy?.name,
        ));
      }
    }

    // Get stats
    final brokerIds = storage.getConnectedBrokerIds(uid);
    final pendingRequests = storage.getPendingRequestsFor(uid);
    final childId = storage.getLinkedChildId(uid);
    final childUser = childId != null ? storage.getUser(childId) : null;

    setState(() {
      _items = items;
      _connectedBrokerCount = brokerIds.length;
      _pendingRequestCount = pendingRequests.length;
      _linkedChildName = childUser?.displayName;
    });
  }

  Future<void> _respondToProfile(
      SharedProfile shared, SharedProfileResponse response) async {
    final storage = ref.read(localStorageServiceProvider);
    final updated = shared.copyWith(parentResponse: response);
    await storage.updateSharedProfile(updated);
    _loadData();

    if (mounted) {
      final label = switch (response) {
        SharedProfileResponse.interested => 'Marked as Interested',
        SharedProfileResponse.maybe => 'Marked as Maybe',
        SharedProfileResponse.pass => 'Marked as Pass',
        SharedProfileResponse.pending => '',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(label),
          behavior: SnackBarBehavior.floating,
          backgroundColor: response == SharedProfileResponse.interested
              ? AppColors.success
              : response == SharedProfileResponse.maybe
                  ? AppColors.warning
                  : AppColors.lightSecondaryText,
        ),
      );
    }
  }

  void _showForwardSheet(String sharedProfileId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ForwardToChildSheet(sharedProfileId: sharedProfileId),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.favorite, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Anuyātrā',
              style: theme.appBarTheme.titleTextStyle,
            ),
          ],
        ),
        actions: [
          const ThemeToggleButton(),
          if (_pendingRequestCount > 0)
            Badge(
              label: Text('$_pendingRequestCount'),
              child: IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.pushNamed(RouteNames.linkRequests),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => context.pushNamed(RouteNames.linkRequests),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: CustomScrollView(
          slivers: [
            // Dashboard summary
            SliverToBoxAdapter(child: _buildDashboardSummary(isDark, theme)),

            // Section header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.people_alt_outlined,
                        size: 20, color: AppColors.sacredSaffron),
                    const SizedBox(width: 8),
                    Text(
                      'Shared Profiles',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.sacredSaffron.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_items.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.sacredSaffron,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Profiles list or empty state
            if (_items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(isDark, theme),
              )
            else
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = _items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ParentProfileCard(
                          item: item,
                          isDark: isDark,
                          theme: theme,
                          onInterested:
                              item.shared.parentResponse ==
                                      SharedProfileResponse.pending
                                  ? () => _respondToProfile(
                                      item.shared,
                                      SharedProfileResponse.interested)
                                  : null,
                          onMaybe: item.shared.parentResponse ==
                                  SharedProfileResponse.pending
                              ? () => _respondToProfile(
                                  item.shared, SharedProfileResponse.maybe)
                              : null,
                          onPass: item.shared.parentResponse ==
                                  SharedProfileResponse.pending
                              ? () => _respondToProfile(
                                  item.shared, SharedProfileResponse.pass)
                              : null,
                          onForward: !item.shared.forwardedToChild
                              ? () => _showForwardSheet(item.shared.id)
                              : null,
                        ),
                      );
                    },
                    childCount: _items.length,
                  ),
                ),
              ),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardSummary(bool isDark, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                colors: [
                  AppColors.darkSurface,
                  AppColors.darkSurfaceVariant,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _DashboardStat(
                icon: Icons.people,
                label: 'Brokers',
                value: '$_connectedBrokerCount',
                color: Colors.white,
              ),
              const SizedBox(width: 16),
              _DashboardStat(
                icon: Icons.person_search,
                label: 'Profiles',
                value: '${_items.length}',
                color: Colors.white,
              ),
              const SizedBox(width: 16),
              _DashboardStat(
                icon: Icons.child_care,
                label: 'Child',
                value: _linkedChildName != null ? 'Linked' : 'None',
                color: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.sacredSaffron.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline,
                size: 40,
                color: AppColors.sacredSaffron,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No profiles shared yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _connectedBrokerCount == 0
                  ? 'Connect with brokers from the Search tab to start receiving profiles'
                  : 'Your connected brokers will share profiles here for your review',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.secondaryText(context),
                height: 1.5,
              ),
            ),
            if (_connectedBrokerCount == 0) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  // Navigate to Search tab (index 1)
                  final shell = StatefulNavigationShell.of(context);
                  shell.goBranch(1);
                },
                icon: const Icon(Icons.search, size: 18),
                label: const Text('Find Brokers'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.sacredSaffron,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data holder
// ---------------------------------------------------------------------------
class _SharedProfileItem {
  final SharedProfile shared;
  final CandidateProfile profile;
  final String? brokerName;
  const _SharedProfileItem({
    required this.shared,
    required this.profile,
    this.brokerName,
  });
}

// ---------------------------------------------------------------------------
// Dashboard stat widget
// ---------------------------------------------------------------------------
class _DashboardStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DashboardStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 24, color: color.withValues(alpha: 0.8)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Parent profile card with response actions
// ---------------------------------------------------------------------------
class _ParentProfileCard extends StatelessWidget {
  final _SharedProfileItem item;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback? onInterested;
  final VoidCallback? onMaybe;
  final VoidCallback? onPass;
  final VoidCallback? onForward;

  const _ParentProfileCard({
    required this.item,
    required this.isDark,
    required this.theme,
    this.onInterested,
    this.onMaybe,
    this.onPass,
    this.onForward,
  });

  @override
  Widget build(BuildContext context) {
    final profile = item.profile;
    final response = item.shared.parentResponse;
    final isPending = response == SharedProfileResponse.pending;

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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.pushNamed(
            RouteNames.profileView,
            pathParameters: {'id': profile.id},
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile info
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor:
                        AppColors.deepMaroon.withValues(alpha: 0.12),
                    child: Text(
                      profile.name.isNotEmpty
                          ? profile.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.deepMaroon,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.displayName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile.fullDetails,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.lightSecondaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!isPending) _buildResponseBadge(response),
                ],
              ),

              // Broker info
              if (item.brokerName != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 14,
                        color: isDark
                            ? AppColors.darkTertiaryText
                            : AppColors.lightTertiaryText),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Shared by ${item.brokerName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTertiaryText
                              : AppColors.lightTertiaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.shared.forwardedToChild) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.forward_to_inbox,
                                size: 12, color: AppColors.info),
                            SizedBox(width: 4),
                            Text(
                              'Forwarded',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.info,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],

              // About section
              if (profile.aboutMe.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  profile.aboutMe,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.lightSecondaryText,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Child response if forwarded and child responded
              if (item.shared.forwardedToChild &&
                  item.shared.childResponse != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: item.shared.childResponse ==
                            SharedProfileResponse.interested
                        ? AppColors.success.withValues(alpha: 0.08)
                        : AppColors.lightSecondaryText
                            .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.shared.childResponse ==
                                SharedProfileResponse.interested
                            ? Icons.favorite
                            : Icons.close,
                        size: 14,
                        color: item.shared.childResponse ==
                                SharedProfileResponse.interested
                            ? AppColors.success
                            : AppColors.lightSecondaryText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Child: ${item.shared.childResponse!.displayName}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: item.shared.childResponse ==
                                  SharedProfileResponse.interested
                              ? AppColors.success
                              : AppColors.lightSecondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Action buttons
              if (isPending) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    // Pass
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onPass,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.lightSecondaryText,
                          side: BorderSide(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('Pass', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Maybe
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onMaybe,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.warning,
                          side: BorderSide(
                            color: AppColors.warning.withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('Maybe', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Interested
                    Expanded(
                      child: FilledButton(
                        onPressed: onInterested,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('Interested',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ],

              // Forward to child button (show when parent has responded but not yet forwarded)
              if (!isPending && onForward != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onForward,
                    icon: const Icon(Icons.forward_to_inbox, size: 16),
                    label: const Text('Forward to Child'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.sacredSaffron,
                      side: BorderSide(
                        color: AppColors.sacredSaffron.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponseBadge(SharedProfileResponse response) {
    final color = switch (response) {
      SharedProfileResponse.interested => AppColors.success,
      SharedProfileResponse.maybe => AppColors.warning,
      SharedProfileResponse.pass => AppColors.lightSecondaryText,
      SharedProfileResponse.pending => AppColors.lightSecondaryText,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        response.displayName,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
