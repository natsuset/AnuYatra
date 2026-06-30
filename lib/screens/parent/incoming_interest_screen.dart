import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:testing_flutter/common/widgets/molecules/profile_photo_carousel.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/core/routing/route_names.dart';
import 'package:testing_flutter/core/theme/app_palette.dart';
import 'package:testing_flutter/models/app_user.dart';
import 'package:testing_flutter/models/candidate_profile.dart';
import 'package:testing_flutter/models/shared_profile.dart';

class IncomingInterestScreen extends ConsumerStatefulWidget {
  const IncomingInterestScreen({super.key});

  @override
  ConsumerState<IncomingInterestScreen> createState() =>
      _IncomingInterestScreenState();
}

class _IncomingInterestScreenState
    extends ConsumerState<IncomingInterestScreen> {
  List<_IncomingInterestItem> _items = const [];
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
    final sharedRepo = ref.read(sharedProfileRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);

    final allCandidates = await profileRepo.getAllCandidateProfiles();
    final myOwned = {
      for (final c in allCandidates.where((c) => c.parentUserId == uid)) c.id: c,
    };
    if (myOwned.isEmpty) {
      if (mounted) {
        setState(() {
          _items = const [];
          _loading = false;
        });
      }
      return;
    }
    final shares = await sharedRepo.getAllSharedProfiles();
    final items = <_IncomingInterestItem>[];
    for (final s in shares) {
      if (!myOwned.containsKey(s.profileId)) continue;
      if (s.parentResponse != SharedProfileResponse.interested) continue;
      final receivingParent = await userRepo.getUser(s.sharedWithUserId);
      items.add(_IncomingInterestItem(
        share: s,
        candidate: myOwned[s.profileId]!,
        interestedParent: receivingParent,
      ));
    }
    items.sort((a, b) => b.share.sharedAt.compareTo(a.share.sharedAt));
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Incoming Interest')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? _Empty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: AppSpacing.allMd,
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => AppSpacing.gapH12,
                    itemBuilder: (context, i) => _IncomingTile(item: _items[i]),
                  ),
                ),
    );
  }
}

class _IncomingInterestItem {
  final SharedProfile share;
  final CandidateProfile candidate;
  final AppUser? interestedParent;

  _IncomingInterestItem({
    required this.share,
    required this.candidate,
    required this.interestedParent,
  });
}

class _IncomingTile extends StatelessWidget {
  const _IncomingTile({required this.item});
  final _IncomingInterestItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final parentName = item.interestedParent?.displayName ?? 'A parent';
    final candidateName = item.candidate.name;
    return Material(
      color: colors.surface,
      borderRadius: AppSpacing.roundedLg,
      child: InkWell(
        borderRadius: AppSpacing.roundedLg,
        onTap: () => context.pushNamed(
          RouteNames.profileView,
          pathParameters: {'id': item.candidate.id},
        ),
        child: Container(
          padding: AppSpacing.allMd,
          decoration: BoxDecoration(
            borderRadius: AppSpacing.roundedLg,
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ProfilePhotoCarousel(
                    photos: item.candidate.photos,
                    fallbackInitial: candidateName.isNotEmpty
                        ? candidateName[0]
                        : '?',
                    height: 60,
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
                        Icon(
                          Icons.favorite_rounded,
                          size: 14,
                          color: context.palette.success,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '$parentName is interested',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: context.palette.success,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'For $candidateName',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('d MMM, h:mm a').format(item.share.sharedAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
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
            Icon(Icons.favorite_border_rounded,
                size: 56, color: scheme.onSurfaceVariant),
            AppSpacing.gapH12,
            Text(
              'No incoming interest yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'When other parents express interest in your child\'s profile, '
              'they\'ll show up here.',
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
