import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:testing_flutter/common/widgets/atoms/theme_toggle_button.dart';
import 'package:testing_flutter/common/widgets/molecules/profile_photo_carousel.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/l10n/l10n_extension.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/core/routing/route_names.dart';
import 'package:testing_flutter/core/theme/app_palette.dart';
import 'package:testing_flutter/core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:testing_flutter/models/candidate_profile.dart';
import 'package:testing_flutter/models/meeting.dart';
import 'package:testing_flutter/models/shared_profile.dart';
import 'package:testing_flutter/screens/debug/theme_tinkerer_screen.dart';
import 'package:testing_flutter/screens/parent/forward_to_child_sheet.dart';
import 'package:testing_flutter/screens/parent/profile_vault_screen.dart' show VaultFilter;

/// Parent home: shows shared profiles from brokers as photo-driven cards
/// with Save · Interested · Pass actions. Saved counter on the dashboard
/// tile navigates to [SavedProfilesScreen].
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<_SharedProfileItem> _items = [];
  List<_ChildResponseItem> _childResponses = const [];
  List<_UpcomingMeeting> _upcomingMeetings = const [];
  List<CandidateProfile> _recentlyViewed = const [];
  int _connectedBrokerCount = 0;
  int _pendingRequestCount = 0;
  int _savedCount = 0;
  int _incomingInterestCount = 0;
  final Set<String> _savedProfileIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final sharedProfileRepo = ref.read(sharedProfileRepositoryProvider);
    final profileRepo = ref.read(profileRepositoryProvider);
    final brokerRepo = ref.read(brokerRepositoryProvider);
    final linkRepo = ref.read(linkRepositoryProvider);
    final savedRepo = ref.read(savedProfileRepositoryProvider);
    final uid = authState.user.uid;

    // Shared profiles for this parent.
    final sharedProfiles = await sharedProfileRepo.getSharedProfilesForUser(
      uid,
    );
    final items = <_SharedProfileItem>[];
    for (final sp in sharedProfiles) {
      final profile = await profileRepo.getCandidateProfile(sp.profileId);
      if (profile != null) {
        final sharedBy = await brokerRepo.getBrokerProfile(sp.sharedByUserId);
        items.add(
          _SharedProfileItem(
            shared: sp,
            profile: profile,
            brokerName: sharedBy?.name,
          ),
        );
      }
    }

    // Stats.
    final brokerIds = await linkRepo.getConnectedBrokerIds(uid);
    final pendingRequests = await linkRepo.getPendingRequestsFor(uid);
    final saves = await savedRepo.getSavedProfilesForUser(uid);

    final viewedRepo = ref.read(viewedProfileRepositoryProvider);
    final recentViews = await viewedRepo.getRecentViews(uid, limit: 10);
    final recentProfiles = <CandidateProfile>[];
    for (final v in recentViews) {
      final p = await profileRepo.getCandidateProfile(v.profileId);
      if (p != null) recentProfiles.add(p);
    }

    final allShares = await sharedProfileRepo.getAllSharedProfiles();

    final allCandidates = await profileRepo.getAllCandidateProfiles();
    final myOwnedIds = allCandidates
        .where((c) => c.parentUserId == uid)
        .map((c) => c.id)
        .toSet();
    var incomingCount = 0;
    if (myOwnedIds.isNotEmpty) {
      incomingCount = allShares
          .where((s) =>
              myOwnedIds.contains(s.profileId) &&
              s.parentResponse == SharedProfileResponse.interested)
          .length;
    }

    // Child responses: profiles this parent forwarded to their child that the
    // child has responded to. Surfaced so the parent can act on them.
    final userRepo = ref.read(userRepositoryProvider);
    final childId = await linkRepo.getLinkedChildId(uid);
    final childResponses = <_ChildResponseItem>[];
    if (childId != null) {
      final childUser = await userRepo.getUser(childId);
      final childName = childUser?.displayName ?? 'Your child';
      final responded = allShares.where((s) =>
          s.sharedByUserId == uid &&
          s.sharedWithUserId == childId &&
          s.childResponse != null &&
          s.childResponse != SharedProfileResponse.pending);
      for (final s in responded) {
        final p = await profileRepo.getCandidateProfile(s.profileId);
        if (p != null) {
          childResponses.add(_ChildResponseItem(
            profile: p,
            response: s.childResponse!,
            childName: childName,
          ));
        }
      }
    }

    // Upcoming meetings (broker-scheduled introductions are visible to the
    // parent party). Look across the profiles shared with this parent.
    final meetingRepo = ref.read(meetingRepositoryProvider);
    final nowTs = DateTime.now();
    final upcoming = <_UpcomingMeeting>[];
    for (final item in items) {
      final meetings = await meetingRepo.getMeetingsFor(
        parentUserId: uid,
        candidateProfileId: item.profile.id,
        viewerUserId: uid,
      );
      for (final m in meetings) {
        if (m.status == MeetingStatus.scheduled && m.when.isAfter(nowTs)) {
          upcoming.add(_UpcomingMeeting(meeting: m, profile: item.profile));
        }
      }
    }
    upcoming.sort((a, b) => a.meeting.when.compareTo(b.meeting.when));

    if (!mounted) return;
    setState(() {
      _items = items;
      _childResponses = childResponses;
      _upcomingMeetings = upcoming;
      _connectedBrokerCount = brokerIds.length;
      _pendingRequestCount = pendingRequests.length;
      _savedCount = saves.length;
      _recentlyViewed = recentProfiles;
      _incomingInterestCount = incomingCount;
      _savedProfileIds
        ..clear()
        ..addAll(saves.map((s) => s.profileId));
    });
  }

  Future<void> _toggleSave(CandidateProfile profile) async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;
    final savedRepo = ref.read(savedProfileRepositoryProvider);
    final nowSaved = await savedRepo.toggle(
      userId: authState.user.uid,
      profileId: profile.id,
    );
    if (!mounted) return;
    setState(() {
      if (nowSaved) {
        _savedProfileIds.add(profile.id);
        _savedCount += 1;
      } else {
        _savedProfileIds.remove(profile.id);
        _savedCount = (_savedCount - 1).clamp(0, _savedCount);
      }
    });
  }

  /// Record an Interested response (notifies broker via persisted state).
  Future<void> _markInterested(SharedProfile shared) async {
    await _setResponse(shared, SharedProfileResponse.interested);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.markedAsInterested),
        backgroundColor: context.palette.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Record a Pass response — with a 6-second snackbar undo before the
  /// optimistic UI removal is committed. Tapping Undo restores the
  /// pending state.
  Future<void> _markPass(SharedProfile shared) async {
    final original = shared;
    final repo = ref.read(sharedProfileRepositoryProvider);

    // Persist Pass eagerly so the card disappears immediately; if undone,
    // revert in the snackbar callback.
    await repo.updateSharedProfile(
      shared.copyWith(parentResponse: SharedProfileResponse.pass),
    );
    await _loadData();

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final colors = Theme.of(context).colorScheme;
    var undone = false;
    final controller = messenger.showSnackBar(
      SnackBar(
        content: Text(context.l10n.markedAsPass),
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          textColor: colors.primary,
          onPressed: () async {
            undone = true;
            await repo.updateSharedProfile(
              original.copyWith(parentResponse: SharedProfileResponse.pending),
            );
            await _loadData();
          },
        ),
      ),
    );
    await controller.closed;
    // No-op tail; if undone, _loadData already ran inside the action.
    if (undone) return;
  }

  Future<void> _setResponse(
    SharedProfile shared,
    SharedProfileResponse response,
  ) async {
    final repo = ref.read(sharedProfileRepositoryProvider);
    await repo.updateSharedProfile(shared.copyWith(parentResponse: response));

    // Notify the broker who shared this profile in chat.
    final auth = ref.read(authProvider);
    if (auth is AuthAuthenticated && shared.sharedByUserId.isNotEmpty) {
      final profileName = _items
              .where((i) => i.shared.id == shared.id)
              .map((i) => i.profile.name)
              .firstOrNull ??
          'the profile';
      final verb = response == SharedProfileResponse.interested
          ? 'is interested in'
          : 'passed on';
      final messaging = ref.read(messagingRepositoryProvider);
      final convId = await messaging.getOrCreateConversation(
          auth.user.uid, shared.sharedByUserId);
      await messaging.sendMessage(
        conversationId: convId,
        senderId: auth.user.uid,
        recipientId: shared.sharedByUserId,
        content: '${auth.user.displayName} $verb $profileName.',
      );
    }

    await _loadData();
  }

  void _showForwardSheet(String sharedProfileId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppSpacing.borderRadiusLg),
      ),
      builder: (_) => ForwardToChildSheet(sharedProfileId: sharedProfileId),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            // Long-press on the logo opens the debug-only ThemeTinkererScreen
            // in debug builds. Release builds: tap-only, no-op.
            GestureDetector(
              onLongPress: kDebugMode
                  ? () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ThemeTinkererScreen(),
                      ),
                    )
                  : null,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: Icon(Icons.favorite, color: colors.primary, size: 20),
              ),
            ),
            AppSpacing.gapW12,
            Text(
              context.l10n.appNameStyled,
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
            SliverToBoxAdapter(child: _buildDashboardSummary(theme)),
            if (_upcomingMeetings.isNotEmpty)
              SliverToBoxAdapter(child: _buildUpcomingMeetings(theme)),
            if (_childResponses.isNotEmpty)
              SliverToBoxAdapter(child: _buildChildResponses(theme)),
            if (_recentlyViewed.isNotEmpty)
              SliverToBoxAdapter(child: _buildRecentlyViewed(theme)),
            SliverToBoxAdapter(child: _buildSectionHeader(theme)),
            if (_items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(isDark, theme),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = _items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _ParentProfileCard(
                        item: item,
                        isSaved: _savedProfileIds.contains(item.profile.id),
                        onToggleSave: () => _toggleSave(item.profile),
                        onInterested:
                            item.shared.parentResponse ==
                                SharedProfileResponse.pending
                            ? () => _markInterested(item.shared)
                            : null,
                        onPass:
                            item.shared.parentResponse ==
                                SharedProfileResponse.pending
                            ? () => _markPass(item.shared)
                            : null,
                        onForward: !item.shared.forwardedToChild
                            ? () => _showForwardSheet(item.shared.id)
                            : null,
                      ),
                    );
                  }, childCount: _items.length),
                ),
              ),
            const SliverToBoxAdapter(child: AppSpacing.gapH24),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingMeetings(ThemeData theme) {
    final colors = theme.colorScheme;
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_available_rounded,
                  size: 20, color: palette.meetingPurple),
              AppSpacing.gapW8,
              Text('Upcoming meetings',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          AppSpacing.gapH8,
          ..._upcomingMeetings.map((u) {
            final m = u.meeting;
            final (IconData icon, String typeLabel) = switch (m.type) {
              MeetingType.inPerson => (Icons.place_rounded, 'In person'),
              MeetingType.virtual => (Icons.videocam_rounded, 'Virtual'),
              MeetingType.phone => (Icons.call_rounded, 'Phone'),
            };
            final detail = m.type == MeetingType.inPerson
                ? m.location
                : (m.virtualLink ?? '');
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Container(
                padding: AppSpacing.allSm,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: AppSpacing.roundedMd,
                  border:
                      Border.all(color: colors.outlineVariant, width: 0.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: palette.meetingPurple.withValues(alpha: 0.12),
                        borderRadius: AppSpacing.roundedMd,
                      ),
                      child:
                          Icon(icon, color: palette.meetingPurple, size: 20),
                    ),
                    AppSpacing.gapW12,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEE, d MMM · h:mm a').format(m.when),
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$typeLabel · with ${u.profile.name}${detail.isNotEmpty ? ' · $detail' : ''}',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: colors.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChildResponses(ThemeData theme) {
    final colors = theme.colorScheme;
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.how_to_reg_rounded, size: 20, color: palette.meetingPurple),
              AppSpacing.gapW8,
              Text(
                'Your child\'s responses',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          AppSpacing.gapH8,
          ..._childResponses.map((item) {
            final interested =
                item.response == SharedProfileResponse.interested;
            final accent = interested ? palette.success : colors.onSurfaceVariant;
            final hasPhoto = item.profile.photos.isNotEmpty &&
                item.profile.photos.first.startsWith('http');
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Material(
                color: colors.surface,
                borderRadius: AppSpacing.roundedMd,
                child: InkWell(
                  borderRadius: AppSpacing.roundedMd,
                  onTap: () => context.pushNamed(
                    RouteNames.profileView,
                    pathParameters: {'id': item.profile.id},
                  ),
                  child: Container(
                    padding: AppSpacing.allSm,
                    decoration: BoxDecoration(
                      borderRadius: AppSpacing.roundedMd,
                      border:
                          Border.all(color: colors.outlineVariant, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: colors.surfaceContainerHighest,
                          backgroundImage:
                              hasPhoto ? NetworkImage(item.profile.photos.first) : null,
                          child: hasPhoto
                              ? null
                              : Text(item.profile.name.isNotEmpty
                                  ? item.profile.name[0]
                                  : '?'),
                        ),
                        AppSpacing.gapW12,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item.childName} ${interested ? 'is interested in' : 'passed on'} ${item.profile.name}',
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                [item.profile.profession, item.profile.city]
                                    .where((s) => s.isNotEmpty)
                                    .join(' · '),
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: colors.onSurfaceVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.gapW8,
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.14),
                            borderRadius: AppSpacing.roundedFull,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                  interested
                                      ? Icons.favorite_rounded
                                      : Icons.do_not_disturb_on_rounded,
                                  size: 12,
                                  color: accent),
                              const SizedBox(width: 4),
                              Text(interested ? 'Interested' : 'Passed',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: accent)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecentlyViewed(ThemeData theme) {
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, size: 18, color: colors.primary),
              AppSpacing.gapW8,
              Text(
                'Recently viewed',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          AppSpacing.gapH8,
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: _recentlyViewed.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final p = _recentlyViewed[index];
                return _RecentlyViewedTile(
                  profile: p,
                  onTap: () => context.pushNamed(
                    RouteNames.profileView,
                    pathParameters: {'id': p.id},
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme) {
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(Icons.people_alt_outlined, size: 20, color: colors.primary),
          AppSpacing.gapW8,
          Text(
            context.l10n.sharedProfiles,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          AppSpacing.gapW8,
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${_items.length}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardSummary(ThemeData theme) {
    final colors = theme.colorScheme;
    final interestedCount = _items
        .where(
          (i) => i.shared.parentResponse == SharedProfileResponse.interested,
        )
        .length;

    return Container(
      margin: AppSpacing.allMd,
      padding: AppSpacing.allMd,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: colors.outlineVariant, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.dashboard,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _DashboardStat(
                icon: Icons.inbox_rounded,
                label: 'Received',
                value: '${_items.length}',
                accent: colors.primary,
                onTap: () => context.pushNamed(
                  RouteNames.profileVault,
                  extra: VaultFilter.all,
                ),
              ),
              AppSpacing.gapW16,
              _DashboardStat(
                icon: Icons.favorite_rounded,
                label: 'Interested',
                value: '$interestedCount',
                accent: context.palette.success,
                onTap: () => context.pushNamed(
                  RouteNames.profileVault,
                  extra: VaultFilter.interested,
                ),
              ),
              AppSpacing.gapW16,
              _DashboardStat(
                icon: Icons.bookmark_rounded,
                label: 'Saved',
                value: '$_savedCount',
                accent: context.palette.info,
                onTap: () => context.pushNamed(
                  RouteNames.profileVault,
                  extra: VaultFilter.saved,
                ),
              ),
              AppSpacing.gapW16,
              _DashboardStat(
                icon: Icons.mark_email_unread_rounded,
                label: 'Incoming',
                value: '$_incomingInterestCount',
                accent: context.palette.warning,
                onTap: () => context.pushNamed(RouteNames.incomingInterest),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, ThemeData theme) {
    final colors = theme.colorScheme;
    return Center(
      child: Padding(
        padding: AppSpacing.allXxl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 40,
                color: colors.primary,
              ),
            ),
            AppSpacing.gapH24,
            Text(
              context.l10n.noProfilesShared,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            AppSpacing.gapH8,
            Text(
              _connectedBrokerCount == 0
                  ? 'Connect with brokers from the Search tab to start receiving profiles'
                  : context.l10n.brokerSharesHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.secondaryText(context),
                height: 1.5,
              ),
            ),
            if (_connectedBrokerCount == 0) ...[
              AppSpacing.gapH24,
              FilledButton.icon(
                onPressed: () {
                  final shell = StatefulNavigationShell.of(context);
                  shell.goBranch(1);
                },
                icon: const Icon(Icons.search, size: 18),
                label: Text(context.l10n.findBrokers),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
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

/// A response the parent's child gave on a profile the parent forwarded.
class _ChildResponseItem {
  final CandidateProfile profile;
  final SharedProfileResponse response;
  final String childName;
  const _ChildResponseItem({
    required this.profile,
    required this.response,
    required this.childName,
  });
}

/// An upcoming meeting visible to the parent, paired with its profile.
class _UpcomingMeeting {
  final Meeting meeting;
  final CandidateProfile profile;
  const _UpcomingMeeting({required this.meeting, required this.profile});
}

// ---------------------------------------------------------------------------
// Dashboard stat tile (tappable when [onTap] is provided)
// ---------------------------------------------------------------------------
class _DashboardStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final VoidCallback? onTap;

  const _DashboardStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tile = Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: accent),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
        ),
      ],
    );

    return Expanded(
      child: onTap == null
          ? tile
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: tile,
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Parent profile card — photo carousel + Save/Interested/Pass action row
// ---------------------------------------------------------------------------
class _ParentProfileCard extends StatelessWidget {
  final _SharedProfileItem item;
  final bool isSaved;
  final VoidCallback onToggleSave;
  final VoidCallback? onInterested;
  final VoidCallback? onPass;
  final VoidCallback? onForward;

  const _ParentProfileCard({
    required this.item,
    required this.isSaved,
    required this.onToggleSave,
    this.onInterested,
    this.onPass,
    this.onForward,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final palette = context.palette;
    final profile = item.profile;
    final response = item.shared.parentResponse;
    final isPending = response == SharedProfileResponse.pending;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.outlineVariant, width: 0.5),
      ),
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      // The carousel (PageView) must NOT be inside the InkWell — InkWell's
      // gesture recognizer competes with PageView's horizontal drag and wins,
      // making the carousel un-swipeable. Split: carousel is a sibling above
      // InkWell; tapping the carousel area also navigates via its own GestureDetector.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Photo carousel with overlaid controls ─────────────────────
          GestureDetector(
            onTap: () => context.pushNamed(
              RouteNames.profileView,
              pathParameters: {'id': profile.id},
            ),
            child: Stack(
              children: [
                ProfilePhotoCarousel(
                  photos: profile.photos,
                  fallbackInitial: profile.name,
                  height: 220,
                  borderRadius: BorderRadius.zero,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _SaveToggleButton(
                    isSaved: isSaved,
                    onPressed: onToggleSave,
                  ),
                ),
                if (!isPending)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _ResponseBadge(response: response),
                  ),
              ],
            ),
          ),

          // ── Text body — InkWell only covers this area ──────────────────
          InkWell(
            onTap: () => context.pushNamed(
              RouteNames.profileView,
              pathParameters: {'id': profile.id},
            ),
            child: Padding(
              padding: AppSpacing.allMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Identity ─────────────────────────────────────────
                  Text(
                    profile.displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    profile.fullDetails,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // ── Key attribute chips ───────────────────────────────
                  if (profile.height.isNotEmpty || profile.religion.isNotEmpty) ...[
                    AppSpacing.gapH8,
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        if (profile.height.isNotEmpty)
                          _AttrChip(Icons.straighten_rounded, profile.height),
                        if (profile.religion.isNotEmpty)
                          _AttrChip(Icons.temple_hindu_rounded, profile.religion),
                        if (profile.maritalStatus.isNotEmpty)
                          _AttrChip(Icons.favorite_border_rounded,
                              profile.maritalStatus),
                      ],
                    ),
                  ],

                  // ── Broker attribution ───────────────────────────────
                  if (item.brokerName != null) ...[
                    AppSpacing.gapH8,
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                        AppSpacing.gapW4,
                        Flexible(
                          child: Text(
                            'Shared by ${item.brokerName}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: colors.onSurfaceVariant.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.shared.forwardedToChild) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: palette.info.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.forward_to_inbox,
                                  size: 12,
                                  color: palette.info,
                                ),
                                AppSpacing.gapW4,
                                Text(
                                  'Forwarded',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: palette.info,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],

                  // ── About preview ────────────────────────────────────
                  if (profile.aboutMe.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      profile.aboutMe,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // ── Child response (only when forwarded) ─────────────
                  if (item.shared.forwardedToChild &&
                      item.shared.childResponse != null) ...[
                    const SizedBox(height: 10),
                    _ChildResponsePill(response: item.shared.childResponse!),
                  ],

                  // ── Action row: Pass · Interested (only when pending) ─
                  if (isPending) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onPass,
                            icon: const Icon(Icons.close, size: 16),
                            label: Text(
                              context.l10n.pass,
                              style: const TextStyle(fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.onSurfaceVariant,
                              side: BorderSide(color: colors.outline),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppSpacing.roundedSm,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xs,
                              ),
                            ),
                          ),
                        ),
                        AppSpacing.gapW8,
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: onInterested,
                            icon: const Icon(Icons.favorite, size: 16),
                            label: Text(
                              context.l10n.interested,
                              style: const TextStyle(fontSize: 13),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: palette.success,
                              shape: RoundedRectangleBorder(
                                borderRadius: AppSpacing.roundedSm,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xs,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // ── Forward-to-child (after parent has responded) ────
                  if (!isPending && onForward != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onForward,
                        icon: const Icon(Icons.forward_to_inbox, size: 16),
                        label: Text(context.l10n.forwardToChild),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.primary,
                          side: BorderSide(
                            color: colors.primary.withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppSpacing.roundedSm,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xs,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bookmark toggle overlaid on the photo. Filled when saved, outlined when not.
class _SaveToggleButton extends StatelessWidget {
  final bool isSaved;
  final VoidCallback onPressed;

  const _SaveToggleButton({required this.isSaved, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        tooltip: isSaved ? 'Remove from saved' : 'Save',
        iconSize: 20,
        onPressed: onPressed,
        icon: Icon(
          isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          color: isSaved ? palette.info : Colors.white,
        ),
      ),
    );
  }
}

/// Coloured pill summarising the parent's current response — shown overlaid
/// on the photo for already-responded profiles.
class _ResponseBadge extends StatelessWidget {
  final SharedProfileResponse response;
  const _ResponseBadge({required this.response});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final (color, label) = switch (response) {
      SharedProfileResponse.interested => (palette.success, 'Interested'),
      SharedProfileResponse.pass => (Colors.white, 'Passed'),
      // Legacy: any `maybe` records still in storage are treated as pending
      // (the badge is suppressed for pending by the caller), but the switch
      // must remain exhaustive.
      // ignore: deprecated_member_use_from_same_package
      SharedProfileResponse.maybe ||
      SharedProfileResponse.pending => (Colors.white, ''),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small inline pill showing the linked child's response on a forwarded profile.
class _ChildResponsePill extends StatelessWidget {
  final SharedProfileResponse response;
  const _ChildResponsePill({required this.response});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final colors = Theme.of(context).colorScheme;
    final interested = response == SharedProfileResponse.interested;
    final color = interested ? palette.success : colors.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppSpacing.roundedSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            interested ? Icons.favorite : Icons.close,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            'Child: ${response.displayName}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small pill chip showing an icon + text attribute (height, religion, etc.)
class _AttrChip extends StatelessWidget {
  const _AttrChip(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: colors.onSurfaceVariant),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentlyViewedTile extends StatelessWidget {
  final CandidateProfile profile;
  final VoidCallback onTap;

  const _RecentlyViewedTile({required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 96,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppSpacing.roundedMd,
        child: InkWell(
          borderRadius: AppSpacing.roundedMd,
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: AppSpacing.roundedMd,
                child: ProfilePhotoCarousel(
                  photos: profile.photos,
                  fallbackInitial: profile.name.isNotEmpty
                      ? profile.name[0]
                      : '?',
                  height: 96,
                  borderRadius: AppSpacing.roundedMd,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                profile.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
