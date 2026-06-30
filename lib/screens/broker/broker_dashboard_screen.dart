import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:testing_flutter/common/widgets/molecules/branded_app_bar.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/theme/app_palette.dart';
import 'package:testing_flutter/core/data/repositories/broker_repository.dart';
import 'package:testing_flutter/core/l10n/l10n_extension.dart';
import 'package:testing_flutter/core/routing/route_names.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/core/services/broker_inbox.dart';
import 'package:testing_flutter/models/broker_profile.dart';
import 'package:testing_flutter/models/candidate_profile.dart';

class BrokerDashboardScreen extends ConsumerStatefulWidget {
  const BrokerDashboardScreen({super.key});

  @override
  ConsumerState<BrokerDashboardScreen> createState() =>
      _BrokerDashboardScreenState();
}

class _BrokerDashboardScreenState extends ConsumerState<BrokerDashboardScreen> {
  BrokerStats _stats = BrokerStats.empty;
  BrokerProfile? _brokerProfile;
  List<BrokerAttentionItem> _inbox = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;
    final uid = authState.user.uid;

    final brokerRepo = ref.read(brokerRepositoryProvider);
    final sharedRepo = ref.read(sharedProfileRepositoryProvider);
    final linkRepo = ref.read(linkRepositoryProvider);
    final profileRepo = ref.read(profileRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);
    final engagementRepo = ref.read(clientEngagementRepositoryProvider);
    final followUpRepo = ref.read(brokerFollowUpRepositoryProvider);

    final stats = await brokerRepo.getBrokerStats(uid);
    final brokerProfile = await brokerRepo.getBrokerProfile(uid);
    final pending = await linkRepo.getPendingRequestsFor(uid);
    final shared = await sharedRepo.getSharedProfilesByBroker(uid);
    final allShares = await sharedRepo.getAllSharedProfiles();
    final engagements = await engagementRepo.getForBroker(uid);
    final followUps = await followUpRepo.getForBroker(uid);

    // Resolve display names and profiles referenced by the inbox.
    final userIds = <String>{
      ...pending.map((r) => r.fromUserId),
      ...shared.map((s) => s.sharedWithUserId),
      ...engagements.map((e) => e.parentUserId),
    };
    final userNames = <String, String>{};
    for (final id in userIds) {
      final u = await userRepo.getUser(id);
      if (u != null) userNames[id] = u.displayName;
    }

    final profileIds = <String>{
      ...shared.map((s) => s.profileId),
      ...followUps
          .where((f) => f.candidateProfileId != null)
          .map((f) => f.candidateProfileId!),
    };
    final profiles = <String, CandidateProfile>{};
    for (final id in profileIds) {
      final p = await profileRepo.getCandidateProfile(id);
      if (p != null) profiles[id] = p;
    }

    final inbox = buildBrokerInbox(
      pendingRequests: pending,
      sharedByBroker: shared,
      engagements: engagements,
      followUps: followUps,
      userNames: userNames,
      profiles: profiles,
      allShares: allShares,
    );

    if (!mounted) return;
    setState(() {
      _stats = stats;
      _brokerProfile = brokerProfile;
      _inbox = inbox;
      _loading = false;
    });
  }

  Future<void> _acceptConnection(String requestId) async {
    await ref.read(linkRepositoryProvider).acceptLinkRequest(requestId);
    await _loadData();
  }

  Future<void> _declineConnection(String requestId) async {
    await ref.read(linkRepositoryProvider).declineLinkRequest(requestId);
    await _loadData();
  }

  Future<void> _openChat(String clientUserId) async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;
    final convId = await ref
        .read(messagingRepositoryProvider)
        .getOrCreateConversation(authState.user.uid, clientUserId);
    if (!mounted) return;
    context.pushNamed(RouteNames.chat,
        pathParameters: {'conversationId': convId});
  }

  void _openClientHub(String clientUserId) {
    context.pushNamed(RouteNames.brokerClientHub,
        pathParameters: {'id': clientUserId});
  }

  Future<void> _completeFollowUp(String followUpId) async {
    // The inbox item only carries the id; fetch, flip done, save.
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;
    final repo = ref.read(brokerFollowUpRepositoryProvider);
    final all = await repo.getForBroker(authState.user.uid);
    final match = all.where((f) => f.id == followUpId).firstOrNull;
    if (match != null) {
      await repo.save(match.copyWith(isDone: true, completedAt: DateTime.now()));
    }
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = authState.user;

    return Scaffold(
      appBar: const BrandedAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _WelcomeHeader(
                displayName:
                    user.displayName.isNotEmpty ? user.displayName : 'Broker',
                rating: _brokerProfile?.rating ?? 0.0,
                experienceYears: _brokerProfile?.experienceYears ?? 0,
                isDark: isDark,
              ),
            ),

            // ── KPI strip ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: _KpiTile(
                        label: l10n.connectedClients,
                        value: _stats.activeClients,
                        icon: Icons.people_alt_rounded,
                        color: context.palette.info,
                      ),
                    ),
                    AppSpacing.gapW12,
                    Expanded(
                      child: _KpiTile(
                        label: l10n.managedProfiles,
                        value: _stats.profilesManaged,
                        icon: Icons.badge_rounded,
                        color: context.palette.success,
                      ),
                    ),
                    AppSpacing.gapW12,
                    Expanded(
                      child: _KpiTile(
                        label: 'Shared',
                        value: _stats.profilesShared,
                        icon: Icons.send_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Quick actions ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    _QuickAction(
                      label: 'Add Profile',
                      icon: Icons.person_add_alt_1_rounded,
                      color: context.palette.success,
                      onTap: () =>
                          context.pushNamed(RouteNames.brokerCreateProfile),
                    ),
                    AppSpacing.gapW12,
                    _QuickAction(
                      label: 'Profiles',
                      icon: Icons.badge_rounded,
                      color: theme.colorScheme.primary,
                      onTap: () => context.goNamed(RouteNames.brokerProfiles),
                    ),
                    AppSpacing.gapW12,
                    _QuickAction(
                      label: 'Kundali',
                      icon: Icons.stars_rounded,
                      color: const Color(0xFF7B2FBE),
                      onTap: () =>
                          context.pushNamed(RouteNames.brokerAstrologyMatch),
                    ),
                    AppSpacing.gapW12,
                    _QuickAction(
                      label: 'Clients',
                      icon: Icons.groups_rounded,
                      color: context.palette.info,
                      onTap: () => context.goNamed(RouteNames.brokerClients),
                    ),
                  ],
                ),
              ),
            ),

            // ── Needs Attention header ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  children: [
                    Text(
                      'Needs Attention',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    AppSpacing.gapW8,
                    if (_inbox.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.palette.warning.withValues(alpha: 0.15),
                          borderRadius: AppSpacing.roundedFull,
                        ),
                        child: Text(
                          '${_inbox.length}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: context.palette.warning,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            if (_loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (_inbox.isEmpty)
              SliverToBoxAdapter(child: _AllCaughtUp(theme: theme))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                sliver: SliverList.separated(
                  itemCount: _inbox.length,
                  separatorBuilder: (_, __) => AppSpacing.gapH8,
                  itemBuilder: (context, i) => _AttentionTile(
                    item: _inbox[i],
                    onTapClient: _openClientHub,
                    onMessage: _openChat,
                    onAccept: _acceptConnection,
                    onDecline: _declineConnection,
                    onCompleteFollowUp: _completeFollowUp,
                    onSuggestProfiles: () =>
                        context.goNamed(RouteNames.brokerProfiles),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Attention feed tile ────────────────────────────────────────────

class _AttentionVisual {
  final IconData icon;
  final Color color;
  const _AttentionVisual(this.icon, this.color);
}

class _AttentionTile extends StatelessWidget {
  const _AttentionTile({
    required this.item,
    required this.onTapClient,
    required this.onMessage,
    required this.onAccept,
    required this.onDecline,
    required this.onCompleteFollowUp,
    required this.onSuggestProfiles,
  });

  final BrokerAttentionItem item;
  final void Function(String clientUserId) onTapClient;
  final Future<void> Function(String clientUserId) onMessage;
  final Future<void> Function(String requestId) onAccept;
  final Future<void> Function(String requestId) onDecline;
  final Future<void> Function(String followUpId) onCompleteFollowUp;
  final VoidCallback onSuggestProfiles;

  _AttentionVisual _visual(AppPalette palette, ColorScheme colors) {
    return switch (item.kind) {
      BrokerAttentionKind.mutualMatch =>
        _AttentionVisual(Icons.favorite_rounded, const Color(0xFFE91E63)),
      BrokerAttentionKind.pendingConnection =>
        _AttentionVisual(Icons.person_add_rounded, colors.primary),
      BrokerAttentionKind.clientInterested =>
        _AttentionVisual(Icons.favorite_rounded, palette.success),
      BrokerAttentionKind.clientPassed =>
        _AttentionVisual(Icons.do_not_disturb_on_rounded, colors.onSurfaceVariant),
      BrokerAttentionKind.awaitingClient =>
        _AttentionVisual(Icons.hourglass_top_rounded, palette.warning),
      BrokerAttentionKind.paymentPending =>
        _AttentionVisual(Icons.payments_rounded, palette.error),
      BrokerAttentionKind.sharingStartsSoon =>
        _AttentionVisual(Icons.schedule_send_rounded, palette.info),
      BrokerAttentionKind.followUpDue =>
        _AttentionVisual(Icons.notifications_active_rounded, palette.warning),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final palette = context.palette;
    final v = _visual(palette, colors);

    final clientId = item.clientUserId;

    return Material(
      color: colors.surface,
      borderRadius: AppSpacing.roundedLg,
      child: InkWell(
        borderRadius: AppSpacing.roundedLg,
        onTap: clientId != null ? () => onTapClient(clientId) : null,
        child: Container(
          padding: AppSpacing.allMd,
          decoration: BoxDecoration(
            borderRadius: AppSpacing.roundedLg,
            border: Border.all(color: colors.outlineVariant, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: v.color.withValues(alpha: 0.12),
                      borderRadius: AppSpacing.roundedMd,
                    ),
                    child: Icon(v.icon, color: v.color, size: 20),
                  ),
                  AppSpacing.gapW12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (clientId != null)
                    Icon(Icons.chevron_right, color: colors.outline, size: 20),
                ],
              ),
              AppSpacing.gapH12,
              _actions(context, palette, colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actions(BuildContext context, AppPalette palette, ColorScheme colors) {
    final clientId = item.clientUserId;

    switch (item.kind) {
      case BrokerAttentionKind.pendingConnection:
        final reqId = item.linkRequestId;
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: reqId == null ? null : () => onDecline(reqId),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.onSurfaceVariant,
                  side: BorderSide(color: colors.outline),
                  shape: const StadiumBorder(),
                ),
                child: const Text('Decline'),
              ),
            ),
            AppSpacing.gapW12,
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: reqId == null ? null : () => onAccept(reqId),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Accept'),
                style: FilledButton.styleFrom(
                  backgroundColor: palette.success,
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ],
        );

      case BrokerAttentionKind.followUpDue:
        final fuId = item.followUpId;
        return Row(
          children: [
            if (clientId != null)
              _MiniBtn(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Message',
                onTap: () => onMessage(clientId),
              ),
            if (clientId != null) AppSpacing.gapW8,
            Expanded(
              child: FilledButton.icon(
                onPressed: fuId == null ? null : () => onCompleteFollowUp(fuId),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text('Mark done'),
                style: FilledButton.styleFrom(
                  backgroundColor: palette.success,
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ],
        );

      case BrokerAttentionKind.clientPassed:
        return Row(
          children: [
            if (clientId != null)
              _MiniBtn(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Message',
                onTap: () => onMessage(clientId),
              ),
            if (clientId != null) AppSpacing.gapW8,
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onSuggestProfiles,
                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: const Text('Suggest another'),
                style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
              ),
            ),
          ],
        );

      default:
        // clientInterested, awaitingClient, paymentPending, sharingStartsSoon
        return Row(
          children: [
            if (clientId != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onTapClient(clientId),
                  icon: const Icon(Icons.account_circle_outlined, size: 16),
                  label: const Text('Open client'),
                  style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
                ),
              ),
            if (clientId != null) AppSpacing.gapW12,
            if (clientId != null)
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => onMessage(clientId),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: const Text('Message'),
                  style: FilledButton.styleFrom(shape: const StadiumBorder()),
                ),
              ),
          ],
        );
    }
  }
}

class _MiniBtn extends StatelessWidget {
  const _MiniBtn(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.onSurfaceVariant,
        side: BorderSide(color: colors.outline),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
    );
  }
}

// ─── All caught up ──────────────────────────────────────────────────

class _AllCaughtUp extends StatelessWidget {
  const _AllCaughtUp({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 56, color: colors.outlineVariant),
          AppSpacing.gapH12,
          Text('You\'re all caught up',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          AppSpacing.gapH4,
          Text(
            'New requests and client responses will show up here.',
            textAlign: TextAlign.center,
            style:
                theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ─── Welcome Header ──────────────────────────────────────────────

class _WelcomeHeader extends StatelessWidget {
  final String displayName;
  final double rating;
  final int experienceYears;
  final bool isDark;

  const _WelcomeHeader({
    required this.displayName,
    required this.rating,
    required this.experienceYears,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [theme.colorScheme.secondary, theme.colorScheme.surface]
              : [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'B',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.gapH8,
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _HeaderBadge(
                          icon: Icons.star_rounded,
                          label: rating > 0
                              ? '${rating.toStringAsFixed(1)} Rating'
                              : 'New Broker',
                        ),
                        _HeaderBadge(
                          icon: Icons.work_history_rounded,
                          label: experienceYears > 0
                              ? '$experienceYears yrs exp'
                              : 'Getting started',
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

class _HeaderBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: AppSpacing.roundedFull,
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── KPI tile ───────────────────────────────────────────────────────

class _KpiTile extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _KpiTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppSpacing.roundedLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          AppSpacing.gapH12,
          Text(
            '$value',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.onSurface,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: colors.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Quick action ───────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppSpacing.roundedMd,
          onTap: onTap,
          child: Column(
            children: [
              Container(
                height: 52,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: AppSpacing.roundedMd,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              AppSpacing.gapH8,
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
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
