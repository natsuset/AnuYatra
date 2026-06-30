import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/l10n/l10n_extension.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/core/routing/route_names.dart';
import 'package:testing_flutter/core/theme/app_palette.dart';
import 'package:testing_flutter/common/widgets/molecules/profile_photo_carousel.dart';
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
  CandidateProfile? _profile;
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

    final linkedParentId = await linkRepo.getLinkedParentId(uid);
    final results = await Future.wait([
      linkedParentId != null
          ? userRepo.getUser(linkedParentId)
          : Future.value(null),
      profileRepo.getAllCandidateProfiles(),
    ]);

    final linkedParent = results[0] as AppUser?;
    final all = results[1] as List<CandidateProfile>;
    final profile = all.where((p) => p.candidateUserId == uid).firstOrNull;

    if (!mounted) return;
    setState(() {
      _linkedParent = linkedParent;
      _profile = profile;
      _loading = false;
    });
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
    final profile = _profile;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.xs),
            decoration: const BoxDecoration(
              color: Colors.black45,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              tooltip: context.l10n.settings,
              icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 20),
              onPressed: () => context.pushNamed(RouteNames.appSettings),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ── Photo header ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _PhotoHeader(
              user: user,
              profile: profile,
              colors: colors,
            ),
          ),

          SliverPadding(
            padding: AppSpacing.allMd,
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                // ── Identity ───────────────────────────────────────────────
                _IdentityCard(user: user, profile: profile, colors: colors, theme: theme, palette: palette),

                AppSpacing.gapH16,

                // ── Profile completeness ────────────────────────────────────
                if (profile != null)
                  _CompletenessCard(profile: profile, colors: colors, theme: theme, palette: palette),

                if (profile != null) AppSpacing.gapH16,

                // ── Details ─────────────────────────────────────────────────
                if (profile != null)
                  _DetailsCard(profile: profile, colors: colors, theme: theme),

                if (profile != null) AppSpacing.gapH16,

                // ── About me ────────────────────────────────────────────────
                if (profile != null && profile.aboutMe.isNotEmpty)
                  _AboutCard(profile: profile, colors: colors, theme: theme),

                if (profile != null && profile.aboutMe.isNotEmpty)
                  AppSpacing.gapH16,

                // ── Interests ───────────────────────────────────────────────
                if (profile != null && profile.interests.isNotEmpty)
                  _InterestsCard(profile: profile, colors: colors, theme: theme),

                if (profile != null && profile.interests.isNotEmpty)
                  AppSpacing.gapH16,

                // ── No profile CTA ──────────────────────────────────────────
                if (profile == null)
                  _NoProfileCard(colors: colors, theme: theme),

                if (profile == null) AppSpacing.gapH16,

                // ── Link status ─────────────────────────────────────────────
                _LinkStatusTile(
                  linkedParent: _linkedParent,
                  colors: colors,
                  theme: theme,
                  palette: palette,
                ),

                AppSpacing.gapH16,

                // ── Account actions ─────────────────────────────────────────
                _AccountActionsCard(colors: colors, palette: palette, theme: theme),

                AppSpacing.gapH48,
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Photo header ──────────────────────────────────────────────────────────────

class _PhotoHeader extends StatelessWidget {
  const _PhotoHeader({
    required this.user,
    required this.profile,
    required this.colors,
  });

  final AppUser user;
  final CandidateProfile? profile;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final photos = profile?.photos ?? [];
    if (photos.isNotEmpty) {
      return Stack(
        children: [
          ProfilePhotoCarousel(
            photos: photos,
            fallbackInitial: user.displayName,
            height: 300,
            borderRadius: BorderRadius.zero,
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 100,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      height: 240,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary.withValues(alpha: 0.85),
            colors.secondary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 48),
            CircleAvatar(
              radius: 52,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Text(
                user.displayName.isNotEmpty
                    ? user.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Identity card ─────────────────────────────────────────────────────────────

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.user,
    required this.profile,
    required this.colors,
    required this.theme,
    required this.palette,
  });

  final AppUser user;
  final CandidateProfile? profile;
  final ColorScheme colors;
  final ThemeData theme;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.roundedLg,
        side: BorderSide(color: colors.outlineVariant, width: 0.5),
      ),
      child: Padding(
        padding: AppSpacing.allMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.displayName.isNotEmpty ? user.displayName : 'Your Name',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (profile != null) ...[
              AppSpacing.gapH4,
              Text(
                '${profile!.age} yrs · ${profile!.gender.displayName}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              if (profile!.profession.isNotEmpty ||
                  profile!.city.isNotEmpty) ...[
                AppSpacing.gapH4,
                Text(
                  [profile!.profession, profile!.city]
                      .where((s) => s.isNotEmpty)
                      .join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
            AppSpacing.gapH12,
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
              decoration: BoxDecoration(
                color: colors.secondary.withValues(alpha: 0.12),
                borderRadius: AppSpacing.roundedFull,
              ),
              child: Text(
                user.role.displayName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Completeness card ─────────────────────────────────────────────────────────

class _CompletenessCard extends StatelessWidget {
  const _CompletenessCard({
    required this.profile,
    required this.colors,
    required this.theme,
    required this.palette,
  });

  final CandidateProfile profile;
  final ColorScheme colors;
  final ThemeData theme;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final pct = profile.profileCompleteness;
    final total = 20;
    final fraction = pct / total;
    final color = fraction >= 0.8
        ? palette.success
        : fraction >= 0.5
            ? palette.warning
            : palette.error;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.roundedLg,
        side: BorderSide(color: colors.outlineVariant, width: 0.5),
      ),
      child: Padding(
        padding: AppSpacing.allMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Profile Completeness',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$pct / $total',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            AppSpacing.gapH8,
            ClipRRect(
              borderRadius: AppSpacing.roundedFull,
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 8,
                backgroundColor: colors.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            AppSpacing.gapH8,
            Text(
              fraction >= 1.0
                  ? 'Your profile is complete!'
                  : 'Add more details to attract better matches',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Details card ──────────────────────────────────────────────────────────────

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({
    required this.profile,
    required this.colors,
    required this.theme,
  });

  final CandidateProfile profile;
  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final rows = <_DetailRow>[
      if (profile.education.isNotEmpty)
        _DetailRow(Icons.school_outlined, 'Education', profile.education),
      if (profile.height.isNotEmpty)
        _DetailRow(Icons.straighten_rounded, 'Height', profile.height),
      if (profile.religion.isNotEmpty)
        _DetailRow(Icons.temple_hindu_rounded, 'Religion', profile.religion),
      if (profile.community.isNotEmpty)
        _DetailRow(Icons.groups_outlined, 'Community', profile.community),
      if (profile.motherTongue.isNotEmpty)
        _DetailRow(Icons.translate_rounded, 'Mother tongue', profile.motherTongue),
      if (profile.maritalStatus.isNotEmpty)
        _DetailRow(Icons.favorite_border_rounded, 'Marital status', profile.maritalStatus),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.roundedLg,
        side: BorderSide(color: colors.outlineVariant, width: 0.5),
      ),
      child: Padding(
        padding: AppSpacing.allMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            AppSpacing.gapH12,
            ...rows.asMap().entries.map((e) => _DetailRowWidget(
                  row: e.value,
                  colors: colors,
                  theme: theme,
                  isLast: e.key == rows.length - 1,
                )),
          ],
        ),
      ),
    );
  }
}

class _DetailRow {
  const _DetailRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;
}

class _DetailRowWidget extends StatelessWidget {
  const _DetailRowWidget({
    required this.row,
    required this.colors,
    required this.theme,
    this.isLast = false,
  });

  final _DetailRow row;
  final ColorScheme colors;
  final ThemeData theme;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
      child: Row(
        children: [
          Icon(row.icon, size: 17, color: colors.onSurfaceVariant),
          AppSpacing.gapW12,
          Text(
            row.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              row.value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── About card ────────────────────────────────────────────────────────────────

class _AboutCard extends StatelessWidget {
  const _AboutCard({
    required this.profile,
    required this.colors,
    required this.theme,
  });

  final CandidateProfile profile;
  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.roundedLg,
        side: BorderSide(color: colors.outlineVariant, width: 0.5),
      ),
      child: Padding(
        padding: AppSpacing.allMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About Me',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            AppSpacing.gapH8,
            Text(
              profile.aboutMe,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Interests card ────────────────────────────────────────────────────────────

class _InterestsCard extends StatelessWidget {
  const _InterestsCard({
    required this.profile,
    required this.colors,
    required this.theme,
  });

  final CandidateProfile profile;
  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.roundedLg,
        side: BorderSide(color: colors.outlineVariant, width: 0.5),
      ),
      child: Padding(
        padding: AppSpacing.allMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Interests',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            AppSpacing.gapH12,
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: profile.interests.map((interest) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: AppSpacing.roundedFull,
                  ),
                  child: Text(
                    interest,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── No profile CTA ────────────────────────────────────────────────────────────

class _NoProfileCard extends StatelessWidget {
  const _NoProfileCard({required this.colors, required this.theme});

  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.roundedLg,
        side: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Padding(
        padding: AppSpacing.allLg,
        child: Column(
          children: [
            Icon(Icons.person_add_outlined,
                size: 56, color: colors.outlineVariant),
            AppSpacing.gapH16,
            Text(
              'No Profile Set Up',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            AppSpacing.gapH8,
            Text(
              'Your profile hasn\'t been created yet. Ask your parent or broker to set one up for you.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Link status tile ──────────────────────────────────────────────────────────

class _LinkStatusTile extends StatelessWidget {
  const _LinkStatusTile({
    required this.linkedParent,
    required this.colors,
    required this.theme,
    required this.palette,
  });

  final AppUser? linkedParent;
  final ColorScheme colors;
  final ThemeData theme;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final isLinked = linkedParent != null;
    final accent = isLinked ? palette.success : palette.warning;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.roundedLg,
        side: BorderSide(color: accent.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: AppSpacing.roundedMd,
          ),
          child: Icon(
            isLinked ? Icons.link_rounded : Icons.link_off_rounded,
            color: accent,
          ),
        ),
        title: Text(
          isLinked ? 'Linked to Parent' : 'Not Linked',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          isLinked
              ? linkedParent!.displayName
              : 'Tap to link your account to a parent',
        ),
        trailing: isLinked
            ? null
            : Icon(Icons.chevron_right, color: accent),
        onTap: isLinked
            ? null
            : () => context.pushNamed(RouteNames.linkToParent),
      ),
    );
  }
}

// ── Account actions card ──────────────────────────────────────────────────────

class _AccountActionsCard extends StatelessWidget {
  const _AccountActionsCard({
    required this.colors,
    required this.palette,
    required this.theme,
  });

  final ColorScheme colors;
  final AppPalette palette;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.roundedLg,
        side: BorderSide(color: colors.outlineVariant, width: 0.5),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: palette.error.withValues(alpha: 0.12),
                borderRadius: AppSpacing.roundedSm,
              ),
              child: Icon(Icons.logout, color: palette.error, size: 18),
            ),
            title: Text(
              context.l10n.logout,
              style: TextStyle(color: palette.error),
            ),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(context.l10n.logoutConfirmTitle),
                  content: Text(context.l10n.logoutConfirmMessage),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(context.l10n.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                          backgroundColor: palette.error),
                      child: Text(context.l10n.logout),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                // ignore: use_build_context_synchronously
                ProviderScope.containerOf(context)
                    .read(authProvider.notifier)
                    .logout();
              }
            },
          ),
        ],
      ),
    );
  }
}
