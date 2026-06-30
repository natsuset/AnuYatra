import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:testing_flutter/common/widgets/molecules/branded_app_bar.dart';
import 'package:testing_flutter/common/widgets/molecules/profile_photo_carousel.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/l10n/l10n_extension.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/core/routing/route_names.dart';
import 'package:testing_flutter/core/theme/app_palette.dart';
import 'package:intl/intl.dart';
import 'package:testing_flutter/models/app_user.dart';
import 'package:testing_flutter/models/candidate_profile.dart';
import 'package:testing_flutter/models/meeting.dart';
import 'package:testing_flutter/models/shared_profile.dart';

class CandidateHomeScreen extends ConsumerStatefulWidget {
  const CandidateHomeScreen({super.key});

  @override
  ConsumerState<CandidateHomeScreen> createState() =>
      _CandidateHomeScreenState();
}

class _CandidateHomeScreenState extends ConsumerState<CandidateHomeScreen> {
  AppUser? _linkedParent;
  CandidateProfile? _ownProfile;
  List<SharedProfile> _sharedProfiles = [];
  List<_CandMeeting> _meetings = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final auth = ref.read(authProvider);
    if (auth is! AuthAuthenticated) return;

    final uid = auth.user.uid;
    final linkRepo = ref.read(linkRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);
    final profileRepo = ref.read(profileRepositoryProvider);
    final sharedRepo = ref.read(sharedProfileRepositoryProvider);

    final linkedParentId = await linkRepo.getLinkedParentId(uid);
    final results = await Future.wait([
      linkedParentId != null
          ? userRepo.getUser(linkedParentId)
          : Future.value(null),
      sharedRepo.getSharedProfilesForUser(uid),
      profileRepo.getAllCandidateProfiles(),
    ]);

    final linkedParent = results[0] as AppUser?;
    final shared = results[1] as List<SharedProfile>;
    final allProfiles = results[2] as List<CandidateProfile>;
    final ownProfile =
        allProfiles.where((p) => p.candidateUserId == uid).firstOrNull;

    // Upcoming meetings scheduled by the broker (visible to the candidate's
    // party), discussed around profiles shared with the candidate.
    final meetings = <_CandMeeting>[];
    if (linkedParentId != null) {
      final meetingRepo = ref.read(meetingRepositoryProvider);
      final nowTs = DateTime.now();
      final byId = {for (final p in allProfiles) p.id: p};
      for (final s in shared) {
        final list = await meetingRepo.getMeetingsFor(
          parentUserId: linkedParentId,
          candidateProfileId: s.profileId,
          viewerUserId: uid,
        );
        for (final m in list) {
          if (m.status == MeetingStatus.scheduled && m.when.isAfter(nowTs)) {
            final p = byId[s.profileId];
            if (p != null) meetings.add(_CandMeeting(meeting: m, profile: p));
          }
        }
      }
      meetings.sort((a, b) => a.meeting.when.compareTo(b.meeting.when));
    }

    if (!mounted) return;
    setState(() {
      _linkedParent = linkedParent;
      _sharedProfiles = shared;
      _ownProfile = ownProfile;
      _meetings = meetings;
      _loading = false;
    });
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    if (auth is! AuthAuthenticated) {
      return Scaffold(body: Center(child: Text(context.l10n.pleaseLogIn)));
    }

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = auth.user;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final palette = context.palette;
    final isLinked = _linkedParent != null;
    final interestedCount = _sharedProfiles
        .where((s) => s.childResponse == SharedProfileResponse.interested)
        .length;
    final firstName = user.displayName.split(' ').first;
    final completeness =
        _ownProfile != null ? _ownProfile!.profileCompleteness / 20.0 : 0.0;

    return Scaffold(
      appBar: const BrandedAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _loading = true);
          await _loadData();
        },
        child: CustomScrollView(
          slivers: [
            // ── Welcome header ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _WelcomeHeader(
                greeting: _greeting(),
                firstName: firstName,
                ownProfile: _ownProfile,
                colors: colors,
                palette: palette,
                theme: theme,
              ),
            ),

            // ── Stats row ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        icon: Icons.favorite_rounded,
                        label: 'Shared',
                        value: '${_sharedProfiles.length}',
                        color: palette.info,
                        onTap: () =>
                            context.pushNamed(RouteNames.candidateSharedList),
                      ),
                    ),
                    AppSpacing.gapW12,
                    Expanded(
                      child: _StatTile(
                        icon: Icons.thumb_up_rounded,
                        label: 'Interested',
                        value: '$interestedCount',
                        color: palette.success,
                        onTap: () =>
                            context.pushNamed(RouteNames.candidateSharedList),
                      ),
                    ),
                    AppSpacing.gapW12,
                    Expanded(
                      child: _StatTile(
                        icon: Icons.person_rounded,
                        label: 'Profile',
                        value: '${(completeness * 100).round()}%',
                        color: completeness >= 0.8
                            ? palette.success
                            : palette.warning,
                        onTap: () =>
                            context.goNamed(RouteNames.candidateProfile),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Link prompt (only when not linked) ──────────────────────────
            if (!isLinked)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    0,
                  ),
                  child: _LinkPromptBanner(palette: palette, colors: colors),
                ),
              ),

            // ── Upcoming meetings ───────────────────────────────────────────
            if (_meetings.isNotEmpty)
              SliverToBoxAdapter(
                child: _UpcomingMeetings(
                  meetings: _meetings,
                  colors: colors,
                  theme: theme,
                  palette: palette,
                ),
              ),

            // ── "New for you" horizontal strip ──────────────────────────────
            if (_sharedProfiles.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.xs,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Shared With You',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            context.pushNamed(RouteNames.candidateSharedList),
                        child: const Text('See all'),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _RecentProfilesStrip(
                  sharedProfiles: _sharedProfiles.take(6).toList(),
                  colors: colors,
                  theme: theme,
                ),
              ),
            ],

            // ── Quick actions ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: _QuickActionsCard(
                  colors: colors,
                  palette: palette,
                  theme: theme,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ),
      ),
    );
  }
}

// ── Welcome header ────────────────────────────────────────────────────────────

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({
    required this.greeting,
    required this.firstName,
    required this.ownProfile,
    required this.colors,
    required this.palette,
    required this.theme,
  });

  final String greeting;
  final String firstName;
  final CandidateProfile? ownProfile;
  final ColorScheme colors;
  final AppPalette palette;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final photos = ownProfile?.photos ?? [];
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: AppSpacing.roundedLg,
        gradient: LinearGradient(
          colors: [
            colors.primary.withValues(alpha: 0.12),
            colors.secondary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Avatar / photo — fixed 72×72 so it doesn't expand in the Row
            SizedBox(
              width: 72,
              height: 72,
              child: ClipRRect(
                borderRadius: AppSpacing.roundedMd,
                child: photos.isNotEmpty
                    ? ProfilePhotoCarousel(
                        photos: photos,
                        fallbackInitial: firstName,
                        height: 72,
                        borderRadius: AppSpacing.roundedMd,
                      )
                    : Container(
                        color: colors.primary.withValues(alpha: 0.18),
                        alignment: Alignment.center,
                        child: Text(
                          firstName.isNotEmpty
                              ? firstName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: colors.primary,
                          ),
                        ),
                      ),
              ),
            ),
            AppSpacing.gapW16,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting,',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    firstName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                  if (ownProfile != null &&
                      ownProfile!.profession.isNotEmpty) ...[
                    AppSpacing.gapH4,
                    Text(
                      '${ownProfile!.profession} · ${ownProfile!.city}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat tile ─────────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: AppSpacing.roundedLg,
      child: InkWell(
        borderRadius: AppSpacing.roundedLg,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              AppSpacing.gapH12,
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colors.onSurface,
                      height: 1.0,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Link prompt banner ────────────────────────────────────────────────────────

class _LinkPromptBanner extends StatelessWidget {
  const _LinkPromptBanner({required this.palette, required this.colors});

  final AppPalette palette;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: palette.warning.withValues(alpha: 0.08),
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: palette.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.link_off_rounded, color: palette.warning, size: 22),
          AppSpacing.gapW12,
          Expanded(
            child: Text(
              'Link to your parent to start receiving profiles',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.warning,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          AppSpacing.gapW8,
          FilledButton(
            onPressed: () => context.pushNamed(RouteNames.linkToParent),
            style: FilledButton.styleFrom(
              backgroundColor: palette.warning,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.roundedSm,
              ),
            ),
            child: const Text('Link Now', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ── Recent profiles horizontal strip ─────────────────────────────────────────

class _RecentProfilesStrip extends StatelessWidget {
  const _RecentProfilesStrip({
    required this.sharedProfiles,
    required this.colors,
    required this.theme,
  });

  final List<SharedProfile> sharedProfiles;
  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: sharedProfiles.length,
        separatorBuilder: (_, __) => AppSpacing.gapW12,
        itemBuilder: (ctx, i) => _MiniProfileCard(
          shared: sharedProfiles[i],
          colors: colors,
          theme: theme,
        ),
      ),
    );
  }
}

class _MiniProfileCard extends ConsumerWidget {
  const _MiniProfileCard({
    required this.shared,
    required this.colors,
    required this.theme,
  });

  final SharedProfile shared;
  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<CandidateProfile?>(
      future: ref
          .read(profileRepositoryProvider)
          .getCandidateProfile(shared.profileId),
      builder: (ctx, snap) {
        final profile = snap.data;
        return GestureDetector(
          onTap: profile == null
              ? null
              : () => context.pushNamed(
                    RouteNames.profileView,
                    pathParameters: {'id': profile.id},
                  ),
          child: Container(
            width: 110,
            decoration: BoxDecoration(
              borderRadius: AppSpacing.roundedMd,
              border: Border.all(
                  color: colors.outlineVariant, width: 0.5),
              color: colors.surface,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: profile == null
                      ? Container(color: colors.surfaceContainerHighest)
                      : ProfilePhotoCarousel(
                          photos: profile.photos,
                          fallbackInitial: profile.name,
                          height: 110,
                          borderRadius: BorderRadius.zero,
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 5,
                  ),
                  child: Text(
                    profile?.name ?? '…',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Quick actions (compact chip grid) ─────────────────────────────────────────

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({
    required this.colors,
    required this.palette,
    required this.theme,
  });

  final ColorScheme colors;
  final AppPalette palette;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final actions = <_QuickAction>[
      _QuickAction(
        icon: Icons.favorite_rounded,
        color: palette.info,
        label: context.l10n.viewSharedProfiles,
        onTap: () => context.pushNamed(RouteNames.candidateSharedList),
      ),
      _QuickAction(
        icon: Icons.auto_awesome_rounded,
        color: colors.secondary,
        label: 'Kundali Match',
        onTap: () => context.goNamed(RouteNames.candidateAnuyatra),
      ),
      _QuickAction(
        icon: Icons.link_rounded,
        color: palette.success,
        label: context.l10n.linkRequests,
        onTap: () => context.pushNamed(RouteNames.linkRequests),
      ),
      _QuickAction(
        icon: Icons.person_rounded,
        color: colors.primary,
        label: 'My Profile',
        onTap: () => context.goNamed(RouteNames.candidateProfile),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: 2),
          child: Text(
            context.l10n.quickActions,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 0.82,
          children: actions
              .map((a) => _QuickActionChip(action: a, colors: colors, theme: theme))
              .toList(),
        ),
      ],
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.action,
    required this.colors,
    required this.theme,
  });

  final _QuickAction action;
  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppSpacing.roundedMd,
        onTap: action.onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.12),
                borderRadius: AppSpacing.roundedMd,
              ),
              child: Icon(action.icon, color: action.color, size: 24),
            ),
            AppSpacing.gapH8,
            Text(
              action.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.1,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Upcoming meetings ───────────────────────────────────────────────────────

class _CandMeeting {
  final Meeting meeting;
  final CandidateProfile profile;
  const _CandMeeting({required this.meeting, required this.profile});
}

class _UpcomingMeetings extends StatelessWidget {
  const _UpcomingMeetings({
    required this.meetings,
    required this.colors,
    required this.theme,
    required this.palette,
  });

  final List<_CandMeeting> meetings;
  final ColorScheme colors;
  final ThemeData theme;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.lg, AppSpacing.md, 0),
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
          ...meetings.map((u) {
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
                  border: Border.all(color: colors.outlineVariant, width: 0.5),
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
                      child: Icon(icon, color: palette.meetingPurple, size: 20),
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
                            '$typeLabel · ${u.profile.name}${detail.isNotEmpty ? ' · $detail' : ''}',
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
}
