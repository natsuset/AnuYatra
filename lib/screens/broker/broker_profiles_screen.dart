import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:testing_flutter/core/theme/app_palette.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/l10n/l10n_extension.dart';
import 'package:testing_flutter/core/routing/route_names.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/models/candidate_profile.dart';
import 'package:testing_flutter/models/app_user.dart';

enum _ProfileSort {
  newest('Newest'),
  ageAsc('Age ↑'),
  ageDesc('Age ↓'),
  nameAZ('A–Z');

  const _ProfileSort(this.label);
  final String label;
}

class BrokerProfilesScreen extends ConsumerStatefulWidget {
  const BrokerProfilesScreen({super.key});

  @override
  ConsumerState<BrokerProfilesScreen> createState() =>
      _BrokerProfilesScreenState();
}

class _BrokerProfilesScreenState extends ConsumerState<BrokerProfilesScreen> {
  List<CandidateProfile> _profiles = [];
  final _searchCtrl = TextEditingController();
  String _query = '';
  Gender? _genderFilter;
  _ProfileSort _sort = _ProfileSort.newest;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final profileRepo = ref.read(profileRepositoryProvider);
    final profiles = await profileRepo.getCandidatesByBroker(authState.user.uid);
    if (!mounted) return;
    setState(() => _profiles = profiles);
  }

  List<CandidateProfile> get _filtered {
    final q = _query.trim().toLowerCase();
    final list = _profiles.where((p) {
      if (_genderFilter != null && p.gender != _genderFilter) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.profession.toLowerCase().contains(q) ||
          p.city.toLowerCase().contains(q) ||
          p.education.toLowerCase().contains(q) ||
          p.community.toLowerCase().contains(q);
    }).toList();

    switch (_sort) {
      case _ProfileSort.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _ProfileSort.ageAsc:
        list.sort((a, b) => a.age.compareTo(b.age));
      case _ProfileSort.ageDesc:
        list.sort((a, b) => b.age.compareTo(a.age));
      case _ProfileSort.nameAZ:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.pushNamed(RouteNames.brokerCreateProfile);
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(
          'Create Profile',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: _profiles.isEmpty
          ? _EmptyState(isDark: isDark)
          : _buildList(context, theme, isDark),
    );
  }

  Widget _buildList(BuildContext context, ThemeData theme, bool isDark) {
    final colors = theme.colorScheme;
    final filtered = _filtered;
    final brides = _profiles.where((p) => p.gender == Gender.bride).length;
    final grooms = _profiles.where((p) => p.gender == Gender.groom).length;

    return CustomScrollView(
      slivers: [
        // ── Search ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search name, profession, city…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.4),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: AppSpacing.roundedMd,
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),

        // ── Filter + sort chips ─────────────────────────────────────
        SliverToBoxAdapter(
          child: SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: [
                _FilterChip(
                  label: 'All (${_profiles.length})',
                  selected: _genderFilter == null,
                  onTap: () => setState(() => _genderFilter = null),
                ),
                AppSpacing.gapW8,
                _FilterChip(
                  label: 'Brides ($brides)',
                  selected: _genderFilter == Gender.bride,
                  onTap: () => setState(() => _genderFilter = Gender.bride),
                ),
                AppSpacing.gapW8,
                _FilterChip(
                  label: 'Grooms ($grooms)',
                  selected: _genderFilter == Gender.groom,
                  onTap: () => setState(() => _genderFilter = Gender.groom),
                ),
                AppSpacing.gapW12,
                Container(width: 1, color: colors.outlineVariant),
                AppSpacing.gapW12,
                ..._ProfileSort.values.map((s) => Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: _FilterChip(
                        label: s.label,
                        selected: _sort == s,
                        onTap: () => setState(() => _sort = s),
                        outlined: true,
                      ),
                    )),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
            child: Text(
              '${filtered.length} ${filtered.length == 1 ? 'profile' : 'profiles'}',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        ),

        if (filtered.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.search_off_rounded,
                        size: 48, color: colors.outlineVariant),
                    AppSpacing.gapH12,
                    Text('No profiles match your search',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: colors.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, 88),
            sliver: SliverList.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final profile = filtered[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _ProfileCard(
                    profile: profile,
                    isDark: isDark,
                    onTap: () => context.pushNamed(
                      RouteNames.profileView,
                      pathParameters: {'id': profile.id},
                    ),
                    onShare: () => _showShareDialog(context, profile),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _showShareDialog(
      BuildContext context, CandidateProfile profile) async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final linkRepo = ref.read(linkRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);
    final sharedProfileRepo = ref.read(sharedProfileRepositoryProvider);

    final parentIds = await linkRepo.getConnectedParentIds(authState.user.uid);

    if (parentIds.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.noConnectedParents),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final parentUsers = <String, AppUser?>{};
    for (final parentId in parentIds) {
      parentUsers[parentId] = await userRepo.getUser(parentId);
    }

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: AppSpacing.allMd,
                child: const Text(
                  'Share Profile With',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              ...parentIds.map((parentId) {
                final name = parentUsers[parentId]?.displayName ?? parentId;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  title: Text(name),
                  onTap: () async {
                    await sharedProfileRepo.shareProfile(
                      profileId: profile.id,
                      sharedByUserId: authState.user.uid,
                      sharedWithUserId: parentId,
                    );
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content:
                            Text('${profile.name}\'s profile shared with $name'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                );
              }),
              AppSpacing.gapH8,
            ],
          ),
        );
      },
    );
  }
}

// ─── Filter / sort chip ───────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool outlined;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bg = selected
        ? colors.primary
        : (outlined ? Colors.transparent : colors.surfaceContainerHighest);
    final fg = selected
        ? colors.onPrimary
        : colors.onSurfaceVariant;
    return Center(
      child: Material(
        color: bg,
        borderRadius: AppSpacing.roundedFull,
        child: InkWell(
          borderRadius: AppSpacing.roundedFull,
          onTap: onTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: AppSpacing.roundedFull,
              border: outlined && !selected
                  ? Border.all(color: colors.outlineVariant)
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ),
      ),
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
                color: Theme.of(context).colorScheme.primary
                    .withValues(alpha: isDark ? 0.1 : 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_open_rounded,
                size: 56,
                color: Theme.of(context).colorScheme.primary
                    .withValues(alpha: isDark ? 0.6 : 0.5),
              ),
            ),
            AppSpacing.gapH24,
            Text(
              'No Profiles Yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            AppSpacing.gapH8,
            Text(
              'No profiles yet. Create your first\ncandidate profile.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () {
                context.pushNamed(RouteNames.brokerCreateProfile);
              },
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
              label: Text(context.l10n.createProfileAction),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.roundedMd,
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
        ? context.palette.error
        : context.palette.info;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.roundedLg,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.surface,
            borderRadius: AppSpacing.roundedLg,
            border: Border.all(
              color: isDark ? Theme.of(context).colorScheme.outline : Theme.of(context).colorScheme.outline,
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
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        AppSpacing.gapW8,
                        // Gender badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: genderColor
                                .withValues(alpha: isDark ? 0.15 : 0.1),
                            borderRadius: AppSpacing.roundedSm,
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
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          AppSpacing.gapW4,
                          Flexible(
                            child: Text(
                              profile.education,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Theme.of(context).colorScheme.onSurfaceVariant
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
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
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          AppSpacing.gapW4,
                          Flexible(
                            child: Text(
                              profile.city,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Theme.of(context).colorScheme.onSurfaceVariant
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
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
                            horizontal: AppSpacing.xs,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: context.palette.info
                                .withValues(alpha: isDark ? 0.12 : 0.08),
                            borderRadius: AppSpacing.roundedSm,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.groups_outlined,
                                size: 14,
                                color: context.palette.info,
                              ),
                              AppSpacing.gapW4,
                              Text(
                                'Listed with ${profile.listedWithBrokersCount} broker${profile.listedWithBrokersCount != 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: context.palette.info,
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
                            borderRadius: AppSpacing.roundedSm,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary
                                    .withValues(alpha: isDark ? 0.15 : 0.1),
                                borderRadius: AppSpacing.roundedSm,
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary
                                      .withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.share_rounded,
                                    size: 14,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Share',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.primary,
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
