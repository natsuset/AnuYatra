import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:testing_flutter/common/widgets/molecules/app_voice_search_bar.dart';
import 'package:testing_flutter/common/widgets/molecules/profile_photo_carousel.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/core/routing/route_names.dart';
import 'package:testing_flutter/core/theme/app_palette.dart';
import 'package:testing_flutter/models/candidate_profile.dart';

// ── Filter enum ───────────────────────────────────────────────────────────────

enum VaultFilter {
  all,
  pending,
  interested,
  saved,
  manual;

  String get label => switch (this) {
        VaultFilter.all => 'All',
        VaultFilter.pending => 'Pending',
        VaultFilter.interested => 'Interested',
        VaultFilter.saved => 'Saved',
        VaultFilter.manual => 'Manual',
      };

  IconData get icon => switch (this) {
        VaultFilter.all => Icons.grid_view_rounded,
        VaultFilter.pending => Icons.hourglass_top_rounded,
        VaultFilter.interested => Icons.favorite_rounded,
        VaultFilter.saved => Icons.bookmark_rounded,
        VaultFilter.manual => Icons.person_add_rounded,
      };
}

// ── Providers ─────────────────────────────────────────────────────────────────

/// Combined broker-shared + manually added profiles for this parent.
final _vaultProfilesProvider =
    FutureProvider.autoDispose<List<CandidateProfile>>((ref) async {
  final auth = ref.watch(authProvider);
  if (auth is! AuthAuthenticated) return [];

  final profileRepo = ref.read(profileRepositoryProvider);
  final uid = auth.user.uid;

  final sharedFuture = profileRepo.getSharedCandidatesForParent(uid);
  final allFuture = profileRepo.getAllCandidateProfiles();

  final results = await Future.wait([sharedFuture, allFuture]);
  final shared = results[0];
  final all = results[1];

  // Manual = source == manual AND created by this parent (createdByUserId == uid)
  final manual = all.where(
    (p) => p.source == ProfileSource.manual && p.createdByUserId == uid,
  );

  // Merge, deduplicate by id, shared first
  final seen = <String>{};
  final merged = <CandidateProfile>[];
  for (final p in [...shared, ...manual]) {
    if (seen.add(p.id)) merged.add(p);
  }
  return merged;
});

/// Note counts per profile id for the current parent.
final _noteCountsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final auth = ref.watch(authProvider);
  if (auth is! AuthAuthenticated) return {};
  final profiles = await ref.watch(_vaultProfilesProvider.future);
  if (profiles.isEmpty) return {};

  final noteRepo = ref.read(parentNoteRepositoryProvider);
  final uid = auth.user.uid;
  final Map<String, int> counts = {};
  await Future.wait(profiles.map((p) async {
    counts[p.id] = await noteRepo.getNoteCount(
      parentUserId: uid,
      candidateProfileId: p.id,
    );
  }));
  return counts;
});

/// IDs of profiles saved by this parent.
final _savedProfileIdsProvider =
    FutureProvider.autoDispose<Set<String>>((ref) async {
  final auth = ref.watch(authProvider);
  if (auth is! AuthAuthenticated) return {};
  final savedRepo = ref.read(savedProfileRepositoryProvider);
  final saved = await savedRepo.getSavedProfilesForUser(auth.user.uid);
  return saved.map((s) => s.profileId).toSet();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class ProfileVaultScreen extends ConsumerStatefulWidget {
  const ProfileVaultScreen({super.key, this.initialFilter});

  /// Optionally open the vault with a pre-selected filter (e.g. from dashboard).
  final VaultFilter? initialFilter;

  @override
  ConsumerState<ProfileVaultScreen> createState() => _ProfileVaultScreenState();
}

class _ProfileVaultScreenState extends ConsumerState<ProfileVaultScreen> {
  late VaultFilter _filter;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter ?? VaultFilter.all;
    _searchController.addListener(() {
      final q = _searchController.text.toLowerCase();
      if (q != _query) setState(() => _query = q);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CandidateProfile> _applyFilter(
    List<CandidateProfile> profiles,
    Set<String> savedIds,
  ) {
    var filtered = profiles;

    switch (_filter) {
      case VaultFilter.all:
        break;
      case VaultFilter.manual:
        filtered = filtered.where((p) => p.source == ProfileSource.manual).toList();
      case VaultFilter.saved:
        filtered = filtered.where((p) => savedIds.contains(p.id)).toList();
      case VaultFilter.pending:
      case VaultFilter.interested:
        // These require SharedProfile response data — not yet plumbed here.
        // For now show broker-shared (non-manual) profiles as approximation.
        filtered = filtered.where((p) => p.source == ProfileSource.broker).toList();
    }

    if (_query.isNotEmpty) {
      filtered = filtered
          .where((p) =>
              p.name.toLowerCase().contains(_query) ||
              p.city.toLowerCase().contains(_query) ||
              p.profession.toLowerCase().contains(_query) ||
              p.religion.toLowerCase().contains(_query))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final palette = context.palette;

    final profilesAsync = ref.watch(_vaultProfilesProvider);
    final savedIdsAsync = ref.watch(_savedProfileIdsProvider);
    final noteCountsAsync = ref.watch(_noteCountsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile Vault',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  AppSpacing.gapH4,
                  Text(
                    'All profiles in one place',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // ── Voice search bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: AppVoiceSearchBar(
                controller: _searchController,
                onSubmitted: (q) => setState(() => _query = q.toLowerCase()),
                onChanged: (q) => setState(() => _query = q.toLowerCase()),
              ),
            ),

            AppSpacing.gapH8,

            // ── Filter tabs ───────────────────────────────────────────────────
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                children: VaultFilter.values.map((f) {
                  final selected = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: _FilterTab(
                      filter: f,
                      selected: selected,
                      colors: colors,
                      palette: palette,
                      theme: theme,
                      onTap: () => setState(() => _filter = f),
                    ),
                  );
                }).toList(),
              ),
            ),

            AppSpacing.gapH8,

            // ── Profile list ──────────────────────────────────────────────────
            Expanded(
              child: profilesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (profiles) {
                  final savedIds = savedIdsAsync.valueOrNull ?? {};
                  final noteCounts = noteCountsAsync.valueOrNull ?? {};
                  final visible = _applyFilter(profiles, savedIds);

                  if (visible.isEmpty) {
                    return _EmptyState(
                      filter: _filter,
                      hasQuery: _query.isNotEmpty,
                      colors: colors,
                      theme: theme,
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.md,
                      right: AppSpacing.md,
                      bottom: AppSpacing.xl + 56, // FAB clearance
                    ),
                    itemCount: visible.length,
                    itemBuilder: (ctx, i) {
                      final profile = visible[i];
                      return _VaultProfileCard(
                        profile: profile,
                        isSaved: savedIds.contains(profile.id),
                        noteCount: noteCounts[profile.id] ?? 0,
                        palette: palette,
                        colors: colors,
                        theme: theme,
                        onTap: () => context.goNamed(
                          RouteNames.profileView,
                          pathParameters: {'id': profile.id},
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(RouteNames.manualProfileEntry),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Profile'),
      ),
    );
  }
}

// ── Filter tab chip ───────────────────────────────────────────────────────────

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.filter,
    required this.selected,
    required this.colors,
    required this.palette,
    required this.theme,
    required this.onTap,
  });

  final VaultFilter filter;
  final bool selected;
  final ColorScheme colors;
  final AppPalette palette;
  final ThemeData theme;
  final VoidCallback onTap;

  Color get _accent => switch (filter) {
        VaultFilter.all => colors.primary,
        VaultFilter.pending => palette.warning,
        VaultFilter.interested => colors.error,
        VaultFilter.saved => colors.secondary,
        VaultFilter.manual => colors.tertiary,
      };

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: AppSpacing.roundedFull,
          border: Border.all(
            color: selected ? accent : colors.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              filter.icon,
              size: 14,
              color: selected ? accent : colors.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              filter.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: selected ? accent : colors.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Profile card ──────────────────────────────────────────────────────────────

class _VaultProfileCard extends StatelessWidget {
  const _VaultProfileCard({
    required this.profile,
    required this.isSaved,
    required this.noteCount,
    required this.palette,
    required this.colors,
    required this.theme,
    required this.onTap,
  });

  final CandidateProfile profile;
  final bool isSaved;
  final int noteCount;
  final AppPalette palette;
  final ColorScheme colors;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isManual = profile.source == ProfileSource.manual;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.roundedMd,
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo carousel
            ProfilePhotoCarousel(
              photos: profile.photos,
              fallbackInitial: profile.name.isNotEmpty
                  ? profile.name[0].toUpperCase()
                  : '?',
              height: 180,
            ),

            Padding(
              padding: AppSpacing.allMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + badges row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          profile.displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSaved)
                        Icon(Icons.bookmark_rounded,
                            size: 16, color: colors.secondary),
                      if (isSaved) AppSpacing.gapW4,
                      // Source badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isManual
                              ? colors.tertiary.withValues(alpha: 0.12)
                              : colors.primary.withValues(alpha: 0.1),
                          borderRadius: AppSpacing.roundedSm,
                        ),
                        child: Text(
                          isManual ? 'Manual' : 'Broker',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isManual ? colors.tertiary : colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  AppSpacing.gapH4,

                  // Details chips row
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (profile.city.isNotEmpty)
                        _Chip(
                          icon: Icons.location_on_outlined,
                          label: profile.city,
                          colors: colors,
                          theme: theme,
                        ),
                      if (profile.profession.isNotEmpty)
                        _Chip(
                          icon: Icons.work_outline_rounded,
                          label: profile.profession,
                          colors: colors,
                          theme: theme,
                        ),
                      if (profile.religion.isNotEmpty)
                        _Chip(
                          icon: Icons.auto_awesome_outlined,
                          label: profile.religion,
                          colors: colors,
                          theme: theme,
                        ),
                    ],
                  ),

                  // Notes count
                  if (noteCount > 0) ...[
                    AppSpacing.gapH8,
                    Row(
                      children: [
                        Icon(Icons.notes_rounded,
                            size: 13, color: colors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '$noteCount note${noteCount == 1 ? '' : 's'}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
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

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.colors,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: AppSpacing.roundedSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: colors.onSurfaceVariant),
          const SizedBox(width: 3),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.filter,
    required this.hasQuery,
    required this.colors,
    required this.theme,
  });

  final VaultFilter filter;
  final bool hasQuery;
  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final (icon, title, body) = hasQuery
        ? (
            Icons.search_off_rounded,
            'No results',
            'Try a different name or keyword.',
          )
        : switch (filter) {
            VaultFilter.all => (
                Icons.folder_open_rounded,
                'No profiles yet',
                'Brokers will share profiles with you here.\nOr tap + to add one manually.',
              ),
            VaultFilter.pending => (
                Icons.hourglass_empty_rounded,
                'No pending profiles',
                'Profiles you haven\'t responded to will appear here.',
              ),
            VaultFilter.interested => (
                Icons.favorite_border_rounded,
                'None yet',
                'Profiles you\'ve marked as Interested will show here.',
              ),
            VaultFilter.saved => (
                Icons.bookmark_border_rounded,
                'No saved profiles',
                'Bookmark any profile to find it here quickly.',
              ),
            VaultFilter.manual => (
                Icons.person_add_alt_1_rounded,
                'No manual profiles',
                'Add profiles you\'ve found yourself using the + button.',
              ),
          };

    return Center(
      child: Padding(
        padding: AppSpacing.allLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: colors.outlineVariant),
            AppSpacing.gapH16,
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapH8,
            Text(
              body,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
