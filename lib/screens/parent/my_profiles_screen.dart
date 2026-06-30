import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:testing_flutter/common/widgets/molecules/profile_photo_carousel.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/core/routing/route_names.dart';
import 'package:testing_flutter/core/theme/app_palette.dart';
import 'package:testing_flutter/models/candidate_profile.dart';

class MyProfilesScreen extends ConsumerStatefulWidget {
  const MyProfilesScreen({super.key});

  @override
  ConsumerState<MyProfilesScreen> createState() => _MyProfilesScreenState();
}

class _MyProfilesScreenState extends ConsumerState<MyProfilesScreen> {
  List<CandidateProfile> _profiles = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = ref.read(authProvider);
    if (auth is! AuthAuthenticated) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final uid = auth.user.uid;
    final profileRepo = ref.read(profileRepositoryProvider);
    final all = await profileRepo.getAllCandidateProfiles();
    final mine = all
        .where((c) => c.parentUserId == uid || c.createdByUserId == uid)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (!mounted) return;
    setState(() {
      _profiles = mine;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Children's Profiles")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.pushNamed(RouteNames.parentCreateChildProfile);
          _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add profile'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _profiles.isEmpty
              ? _Empty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      80,
                    ),
                    itemCount: _profiles.length,
                    separatorBuilder: (_, __) => AppSpacing.gapH12,
                    itemBuilder: (context, i) =>
                        _ProfileCard(profile: _profiles[i]),
                  ),
                ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});
  final CandidateProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: AppSpacing.roundedLg,
      child: InkWell(
        borderRadius: AppSpacing.roundedLg,
        onTap: () => context.pushNamed(
          RouteNames.profileView,
          pathParameters: {'id': profile.id},
        ),
        child: Container(
          padding: AppSpacing.allMd,
          decoration: BoxDecoration(
            borderRadius: AppSpacing.roundedLg,
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ProfilePhotoCarousel(
                    photos: profile.photos,
                    fallbackInitial:
                        profile.name.isNotEmpty ? profile.name[0] : '?',
                    height: 64,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              AppSpacing.gapW12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            profile.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _CompletionPill(profile: profile),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (profile.age > 0) '${profile.age}',
                        if (profile.profession.isNotEmpty) profile.profession,
                        if (profile.city.isNotEmpty) profile.city,
                      ].where((s) => s.isNotEmpty).join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 14,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${profile.photos.length} photo${profile.photos.length == 1 ? '' : 's'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletionPill extends StatelessWidget {
  const _CompletionPill({required this.profile});
  final CandidateProfile profile;

  @override
  Widget build(BuildContext context) {
    final pct = profile.profileCompleteness;
    final color = pct >= 80
        ? context.palette.success
        : pct >= 50
            ? context.palette.info
            : context.palette.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$pct%',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: AppSpacing.allXxl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.family_restroom_rounded,
                size: 56, color: scheme.onSurfaceVariant),
            AppSpacing.gapH12,
            Text(
              'No profiles yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap "Add profile" to create one for your son or daughter.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
