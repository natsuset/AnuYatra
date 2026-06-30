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
import 'package:testing_flutter/models/saved_profile.dart';

/// Lists the candidate profiles the current parent has saved.
///
/// Cards are tappable (→ profile detail) with an inline "unsave" affordance
/// on each. Sorted newest-first. Reachable from the parent home dashboard
/// "Saved" tile and from the bookmark icon on any profile card.
class SavedProfilesScreen extends ConsumerStatefulWidget {
  const SavedProfilesScreen({super.key});

  @override
  ConsumerState<SavedProfilesScreen> createState() =>
      _SavedProfilesScreenState();
}

class _SavedProfilesScreenState extends ConsumerState<SavedProfilesScreen> {
  List<_SavedItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final savedRepo = ref.read(savedProfileRepositoryProvider);
    final profileRepo = ref.read(profileRepositoryProvider);

    final saves = await savedRepo.getSavedProfilesForUser(authState.user.uid);
    final items = <_SavedItem>[];
    for (final s in saves) {
      final profile = await profileRepo.getCandidateProfile(s.profileId);
      if (profile != null) items.add(_SavedItem(saved: s, profile: profile));
    }
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _unsave(_SavedItem item) async {
    final savedRepo = ref.read(savedProfileRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final colors = Theme.of(context).colorScheme;
    final originalItems = List<_SavedItem>.from(_items);

    // Optimistic remove + 6s undo before persisting.
    setState(() {
      _items = _items.where((i) => i.saved.id != item.saved.id).toList();
    });

    var undone = false;
    final controller = messenger.showSnackBar(
      SnackBar(
        content: Text('Removed ${item.profile.name}'),
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          textColor: colors.primary,
          onPressed: () {
            undone = true;
            if (mounted) setState(() => _items = originalItems);
          },
        ),
      ),
    );
    await controller.closed;
    if (!undone) {
      await savedRepo.unsave(
        userId: item.saved.userId,
        profileId: item.saved.profileId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Profiles'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? _EmptyState(colors: colors)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: AppSpacing.allMd,
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => AppSpacing.gapH12,
                    itemBuilder: (context, i) {
                      final item = _items[i];
                      return _SavedCard(
                        item: item,
                        onOpen: () => context.pushNamed(
                          RouteNames.profileView,
                          pathParameters: {'id': item.profile.id},
                        ),
                        onUnsave: () => _unsave(item),
                      );
                    },
                  ),
                ),
    );
  }
}

class _SavedItem {
  final SavedProfile saved;
  final CandidateProfile profile;
  const _SavedItem({required this.saved, required this.profile});
}

class _SavedCard extends StatelessWidget {
  final _SavedItem item;
  final VoidCallback onOpen;
  final VoidCallback onUnsave;

  const _SavedCard({
    required this.item,
    required this.onOpen,
    required this.onUnsave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final profile = item.profile;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.outlineVariant, width: 0.5),
          ),
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfilePhotoCarousel(
                photos: profile.photos,
                fallbackInitial: profile.name,
                height: 180,
              ),
              AppSpacing.gapH12,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.displayName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile.fullDetails,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove from saved',
                    icon: Icon(
                      Icons.bookmark_rounded,
                      color: context.palette.info,
                    ),
                    onPressed: onUnsave,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ColorScheme colors;
  const _EmptyState({required this.colors});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                color: context.palette.info.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_outline,
                size: 40,
                color: context.palette.info,
              ),
            ),
            AppSpacing.gapH24,
            Text(
              'No saved profiles yet',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            AppSpacing.gapH8,
            Text(
              'Tap the bookmark on any profile card to keep it here for later review.',
              textAlign: TextAlign.center,
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
