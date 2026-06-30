import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:testing_flutter/common/widgets/molecules/profile_photo_carousel.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/l10n/l10n_extension.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/core/routing/route_names.dart';
import 'package:testing_flutter/core/theme/app_palette.dart';
import 'package:testing_flutter/models/candidate_profile.dart';
import 'package:testing_flutter/models/shared_profile.dart';

class CandidateSharedProfilesScreen extends ConsumerStatefulWidget {
  const CandidateSharedProfilesScreen({super.key});

  @override
  ConsumerState<CandidateSharedProfilesScreen> createState() =>
      _CandidateSharedProfilesScreenState();
}

class _CandidateSharedProfilesScreenState
    extends ConsumerState<CandidateSharedProfilesScreen> {
  List<_Item> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final auth = ref.read(authProvider);
    if (auth is! AuthAuthenticated) return;

    final sharedRepo = ref.read(sharedProfileRepositoryProvider);
    final profileRepo = ref.read(profileRepositoryProvider);
    final uid = auth.user.uid;

    final shared = await sharedRepo.getSharedProfilesForUser(uid);
    final items = <_Item>[];
    for (final s in shared) {
      final profile = await profileRepo.getCandidateProfile(s.profileId);
      if (profile != null) items.add(_Item(shared: s, profile: profile));
    }

    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _respond(SharedProfile shared, SharedProfileResponse response) async {
    final repo = ref.read(sharedProfileRepositoryProvider);
    await repo.updateSharedProfile(shared.copyWith(childResponse: response));

    // Notify whoever shared this profile (parent or broker) in chat, so the
    // response is visible in the conversation thread.
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

    await _loadProfiles();

    if (!mounted) return;
    final label = response == SharedProfileResponse.interested
        ? context.l10n.markedAsInterested
        : context.l10n.markedAsPass;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(label),
        behavior: SnackBarBehavior.floating,
        backgroundColor: response == SharedProfileResponse.interested
            ? context.palette.success
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final palette = context.palette;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pending = _items.where((i) => i.shared.childResponse == null).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.sharedProfiles),
        actions: [
          if (_items.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs, vertical: 3),
              decoration: BoxDecoration(
                color: pending > 0
                    ? palette.warning.withValues(alpha: 0.15)
                    : colors.surfaceContainerHighest,
                borderRadius: AppSpacing.roundedFull,
              ),
              child: Text(
                '$pending pending',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: pending > 0 ? palette.warning : colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _items.isEmpty
          ? _EmptyState(colors: colors, theme: theme)
          : RefreshIndicator(
              onRefresh: () async {
                setState(() => _loading = true);
                await _loadProfiles();
              },
              child: ListView.separated(
                padding: AppSpacing.allMd,
                itemCount: _items.length,
                separatorBuilder: (_, __) => AppSpacing.gapH12,
                itemBuilder: (context, i) {
                  final item = _items[i];
                  return _SharedProfileCard(
                    item: item,
                    colors: colors,
                    theme: theme,
                    palette: palette,
                    onInterested: item.shared.childResponse == null
                        ? () => _respond(
                            item.shared, SharedProfileResponse.interested)
                        : null,
                    onPass: item.shared.childResponse == null
                        ? () => _respond(
                            item.shared, SharedProfileResponse.pass)
                        : null,
                  );
                },
              ),
            ),
    );
  }
}

// ── Data holder ───────────────────────────────────────────────────────────────

class _Item {
  const _Item({required this.shared, required this.profile});
  final SharedProfile shared;
  final CandidateProfile profile;
}

// ── Profile card ──────────────────────────────────────────────────────────────

class _SharedProfileCard extends StatelessWidget {
  const _SharedProfileCard({
    required this.item,
    required this.colors,
    required this.theme,
    required this.palette,
    this.onInterested,
    this.onPass,
  });

  final _Item item;
  final ColorScheme colors;
  final ThemeData theme;
  final AppPalette palette;
  final VoidCallback? onInterested;
  final VoidCallback? onPass;

  @override
  Widget build(BuildContext context) {
    final profile = item.profile;
    final response = item.shared.childResponse;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.roundedLg,
        side: BorderSide(color: colors.outlineVariant, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Photo area ──────────────────────────────────────────────────
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
                  height: 200,
                  borderRadius: BorderRadius.zero,
                ),
                if (response != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _ResponseBadge(
                        response: response, palette: palette, colors: colors),
                  ),
              ],
            ),
          ),

          // ── Text body ────────────────────────────────────────────────────
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
                  // Name + age
                  Text(
                    profile.displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  AppSpacing.gapH4,
                  Text(
                    profile.fullDetails,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Attribute chips
                  if (profile.height.isNotEmpty ||
                      profile.religion.isNotEmpty) ...[
                    AppSpacing.gapH8,
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        if (profile.height.isNotEmpty)
                          _Chip(Icons.straighten_rounded, profile.height, colors),
                        if (profile.religion.isNotEmpty)
                          _Chip(Icons.temple_hindu_rounded, profile.religion, colors),
                        if (profile.maritalStatus.isNotEmpty)
                          _Chip(Icons.favorite_border_rounded,
                              profile.maritalStatus, colors),
                      ],
                    ),
                  ],

                  // About me
                  if (profile.aboutMe.isNotEmpty) ...[
                    AppSpacing.gapH8,
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

                  // Action row or responded status
                  if (response == null) ...[
                    AppSpacing.gapH16,
                    Row(
                      children: [
                        _CircleActionButton(
                          icon: Icons.close_rounded,
                          color: colors.onSurfaceVariant,
                          bg: colors.surfaceContainerHighest,
                          onTap: onPass,
                        ),
                        AppSpacing.gapW12,
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: onInterested,
                            icon: const Icon(Icons.favorite_rounded, size: 18),
                            label: Text(
                              context.l10n.interested,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: palette.success,
                              minimumSize: const Size.fromHeight(46),
                              shape: const StadiumBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    AppSpacing.gapH12,
                    Row(
                      children: [
                        Icon(
                          response == SharedProfileResponse.interested
                              ? Icons.favorite_rounded
                              : Icons.do_not_disturb_on_rounded,
                          size: 16,
                          color: response == SharedProfileResponse.interested
                              ? palette.success
                              : colors.onSurfaceVariant,
                        ),
                        AppSpacing.gapW8,
                        Text(
                          'You responded: ${response.displayName}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: response == SharedProfileResponse.interested
                                ? palette.success
                                : colors.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

// ── Small attribute chip ──────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip(this.icon, this.label, this.colors);
  final IconData icon;
  final String label;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
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

// ── Circle action button (Pass) ───────────────────────────────────────────────

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}

// ── Response badge ────────────────────────────────────────────────────────────

class _ResponseBadge extends StatelessWidget {
  const _ResponseBadge({
    required this.response,
    required this.palette,
    required this.colors,
  });

  final SharedProfileResponse response;
  final AppPalette palette;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final isInterested = response == SharedProfileResponse.interested;
    final color = isInterested ? palette.success : colors.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isInterested ? Icons.favorite_rounded : Icons.do_not_disturb_on_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            response.displayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.colors, required this.theme});

  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_outlined,
              size: 72, color: colors.outlineVariant),
          AppSpacing.gapH16,
          Text(
            'No shared profiles yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          AppSpacing.gapH8,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              context.l10n.noSharedProfilesForCandidate,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
