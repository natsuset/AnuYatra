import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/core/routing/route_names.dart';
import 'package:testing_flutter/core/theme/app_palette.dart';
import 'package:testing_flutter/models/app_user.dart';
import 'package:testing_flutter/models/broker_follow_up.dart';
import 'package:testing_flutter/models/candidate_profile.dart';
import 'package:testing_flutter/models/chat_message.dart';
import 'package:testing_flutter/models/client_engagement.dart';
import 'package:testing_flutter/models/parent_profile.dart';
import 'package:testing_flutter/models/shared_profile.dart';

/// The broker's complete view of one client (parent): engagement & payment,
/// stated requirements, every profile shared with them and its response status,
/// follow-ups, and a jump into the full chat history.
class BrokerClientHubScreen extends ConsumerStatefulWidget {
  const BrokerClientHubScreen({super.key, required this.clientUserId});

  final String clientUserId;

  @override
  ConsumerState<BrokerClientHubScreen> createState() =>
      _BrokerClientHubScreenState();
}

class _BrokerClientHubScreenState extends ConsumerState<BrokerClientHubScreen> {
  AppUser? _client;
  ParentProfile? _clientProfile;
  ClientEngagement? _engagement;
  List<BrokerFollowUp> _followUps = [];
  List<_SharedItem> _shared = [];
  bool _loading = true;

  String get _brokerUid {
    final auth = ref.read(authProvider);
    return auth is AuthAuthenticated ? auth.user.uid : '';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final uid = _brokerUid;
    if (uid.isEmpty) return;

    final userRepo = ref.read(userRepositoryProvider);
    final profileRepo = ref.read(profileRepositoryProvider);
    final engagementRepo = ref.read(clientEngagementRepositoryProvider);
    final followUpRepo = ref.read(brokerFollowUpRepositoryProvider);
    final sharedRepo = ref.read(sharedProfileRepositoryProvider);

    final client = await userRepo.getUser(widget.clientUserId);
    final clientProfile = await profileRepo.getParentProfile(widget.clientUserId);
    final engagement = await engagementRepo.get(
      brokerUserId: uid,
      parentUserId: widget.clientUserId,
    );
    final followUps = await followUpRepo.getForClient(
      brokerUserId: uid,
      clientUserId: widget.clientUserId,
    );

    final allShared = await sharedRepo.getSharedProfilesByBroker(uid);
    final forClient =
        allShared.where((s) => s.sharedWithUserId == widget.clientUserId).toList()
          ..sort((a, b) => b.sharedAt.compareTo(a.sharedAt));
    final items = <_SharedItem>[];
    for (final s in forClient) {
      final p = await profileRepo.getCandidateProfile(s.profileId);
      if (p != null) items.add(_SharedItem(shared: s, profile: p));
    }

    if (!mounted) return;
    setState(() {
      _client = client;
      _clientProfile = clientProfile;
      _engagement = engagement;
      _followUps = followUps;
      _shared = items;
      _loading = false;
    });
  }

  Future<void> _openChat() async {
    final convId = await ref
        .read(messagingRepositoryProvider)
        .getOrCreateConversation(_brokerUid, widget.clientUserId);
    if (!mounted) return;
    context.pushNamed(RouteNames.chat,
        pathParameters: {'conversationId': convId});
  }

  Future<void> _shareProfile() async {
    final managed = await ref
        .read(profileRepositoryProvider)
        .getCandidatesByBroker(_brokerUid);
    if (!mounted) return;
    final alreadyShared = _shared.map((s) => s.profile.id).toSet();
    final candidates =
        managed.where((p) => !alreadyShared.contains(p.id)).toList();

    final picked = await showModalBottomSheet<CandidateProfile>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _ShareSheet(candidates: candidates),
    );
    if (picked == null) return;

    await ref.read(sharedProfileRepositoryProvider).shareProfile(
          profileId: picked.id,
          sharedByUserId: _brokerUid,
          sharedWithUserId: widget.clientUserId,
        );

    // Also drop a profile-share message into the chat so it shows up there.
    final messaging = ref.read(messagingRepositoryProvider);
    final convId = await messaging.getOrCreateConversation(
        _brokerUid, widget.clientUserId);
    await messaging.sendMessage(
      conversationId: convId,
      senderId: _brokerUid,
      recipientId: widget.clientUserId,
      content: 'Sharing ${picked.name}\'s profile for your consideration.',
      type: ChatMessageType.profileShare,
      profileId: picked.id,
    );

    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Shared ${picked.name} with ${_client?.displayName ?? 'client'}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _addFollowUp() async {
    final result = await showDialog<_FollowUpDraft>(
      context: context,
      builder: (ctx) => const _AddFollowUpDialog(),
    );
    if (result == null) return;
    final fu = BrokerFollowUp(
      id: 'fu-${DateTime.now().millisecondsSinceEpoch}',
      brokerUserId: _brokerUid,
      clientUserId: widget.clientUserId,
      title: result.title,
      notes: result.notes,
      dueAt: result.dueAt,
      priority: result.priority,
      createdAt: DateTime.now(),
    );
    await ref.read(brokerFollowUpRepositoryProvider).save(fu);
    await _load();
  }

  Future<void> _toggleFollowUp(BrokerFollowUp f) async {
    await ref.read(brokerFollowUpRepositoryProvider).save(
          f.copyWith(
            isDone: !f.isDone,
            completedAt: f.isDone ? null : DateTime.now(),
          ),
        );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final palette = context.palette;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final client = _client;
    if (client == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Client')),
        body: const Center(child: Text('Client not found')),
      );
    }

    final interested =
        _shared.where((s) => s.shared.parentResponse == SharedProfileResponse.interested).length;
    final passed =
        _shared.where((s) => s.shared.parentResponse == SharedProfileResponse.pass).length;
    final pending = _shared.length - interested - passed;

    return Scaffold(
      appBar: AppBar(
        title: Text(client.displayName),
        actions: [
          IconButton(
            tooltip: 'Chat',
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            onPressed: _openChat,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _shareProfile,
        icon: const Icon(Icons.send_rounded),
        label: const Text('Share profile'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            _ClientHeader(
              client: client,
              profile: _clientProfile,
              engagement: _engagement,
              colors: colors,
              theme: theme,
              palette: palette,
            ),
            AppSpacing.gapH16,

            // Response summary
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'Shared',
                    value: '${_shared.length}',
                    color: colors.primary,
                  ),
                ),
                AppSpacing.gapW12,
                Expanded(
                  child: _MiniStat(
                    label: 'Interested',
                    value: '$interested',
                    color: palette.success,
                  ),
                ),
                AppSpacing.gapW12,
                Expanded(
                  child: _MiniStat(
                    label: 'Passed',
                    value: '$passed',
                    color: colors.onSurfaceVariant,
                  ),
                ),
                AppSpacing.gapW12,
                Expanded(
                  child: _MiniStat(
                    label: 'Waiting',
                    value: '$pending',
                    color: palette.warning,
                  ),
                ),
              ],
            ),
            AppSpacing.gapH16,

            _PaymentCard(engagement: _engagement, theme: theme, colors: colors, palette: palette),
            AppSpacing.gapH16,

            _RequirementsCard(
              engagement: _engagement,
              profile: _clientProfile,
              theme: theme,
              colors: colors,
            ),
            AppSpacing.gapH16,

            // Follow-ups
            _SectionHeader(
              title: 'Follow-ups',
              theme: theme,
              action: TextButton.icon(
                onPressed: _addFollowUp,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add'),
              ),
            ),
            if (_followUps.isEmpty)
              _EmptyHint(text: 'No follow-ups for this client', colors: colors, theme: theme)
            else
              ..._followUps.map((f) => _FollowUpTile(
                    followUp: f,
                    onToggle: () => _toggleFollowUp(f),
                    colors: colors,
                    theme: theme,
                    palette: palette,
                  )),
            AppSpacing.gapH16,

            // Shared profiles + statuses
            _SectionHeader(title: 'Profiles Shared', theme: theme),
            if (_shared.isEmpty)
              _EmptyHint(
                  text: 'Nothing shared yet. Use “Share profile”.',
                  colors: colors,
                  theme: theme)
            else
              ..._shared.map((s) => _SharedProfileTile(
                    item: s,
                    colors: colors,
                    theme: theme,
                    palette: palette,
                    onTap: () => context.pushNamed(
                      RouteNames.profileView,
                      pathParameters: {'id': s.profile.id},
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

// ── Data holder ──────────────────────────────────────────────────────────────

class _SharedItem {
  const _SharedItem({required this.shared, required this.profile});
  final SharedProfile shared;
  final CandidateProfile profile;
}

// ── Client header ──────────────────────────────────────────────────────────────

class _ClientHeader extends StatelessWidget {
  const _ClientHeader({
    required this.client,
    required this.profile,
    required this.engagement,
    required this.colors,
    required this.theme,
    required this.palette,
  });

  final AppUser client;
  final ParentProfile? profile;
  final ClientEngagement? engagement;
  final ColorScheme colors;
  final ThemeData theme;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final lookingFor = profile?.lookingForDisplay;
    final loc = profile == null
        ? null
        : [profile!.city, profile!.state].where((s) => s.isNotEmpty).join(', ');

    return Container(
      padding: AppSpacing.allMd,
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
        border: Border.all(color: colors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: colors.primary.withValues(alpha: 0.18),
            child: Text(
              client.displayName.isNotEmpty
                  ? client.displayName[0].toUpperCase()
                  : '?',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          AppSpacing.gapW16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.displayName,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (lookingFor != null) 'Seeking $lookingFor',
                    if (loc != null && loc.isNotEmpty) loc,
                  ].join(' · '),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
                AppSpacing.gapH8,
                if (engagement != null)
                  _StageChip(stage: engagement!.stage, palette: palette, colors: colors),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StageChip extends StatelessWidget {
  const _StageChip(
      {required this.stage, required this.palette, required this.colors});
  final EngagementStage stage;
  final AppPalette palette;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final (Color c, IconData ic) = switch (stage) {
      EngagementStage.active => (palette.success, Icons.verified_rounded),
      EngagementStage.paid => (palette.info, Icons.check_circle_rounded),
      EngagementStage.connected => (palette.warning, Icons.link_rounded),
      EngagementStage.requested => (colors.primary, Icons.outgoing_mail),
      EngagementStage.lead => (colors.onSurfaceVariant, Icons.person_outline),
      EngagementStage.lapsed => (palette.error, Icons.history_toggle_off),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: AppSpacing.roundedFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ic, size: 13, color: c),
          const SizedBox(width: 5),
          Text(
            stage.displayName,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c),
          ),
        ],
      ),
    );
  }
}

// ── Mini stat ──────────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppSpacing.roundedMd,
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ── Payment card ─────────────────────────────────────────────────────────────

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.engagement,
    required this.theme,
    required this.colors,
    required this.palette,
  });

  final ClientEngagement? engagement;
  final ThemeData theme;
  final ColorScheme colors;
  final AppPalette palette;

  String _money(double? v) {
    if (v == null) return '—';
    final s = v.toStringAsFixed(0);
    // Indian grouping (e.g. 25000 -> 25,000)
    final buf = StringBuffer();
    final digits = s.split('');
    for (var i = 0; i < digits.length; i++) {
      final fromEnd = digits.length - i;
      buf.write(digits[i]);
      if (fromEnd > 1 && ((fromEnd - 1) == 3 || ((fromEnd - 1) > 3 && (fromEnd - 1) % 2 == 1))) {
        buf.write(',');
      }
    }
    return '₹$buf';
  }

  String _date(DateTime? d) {
    if (d == null) return '—';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final e = engagement;
    return _Card(
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payments_rounded, size: 18, color: palette.financialGreen),
              AppSpacing.gapW8,
              Text('Payment & Plan',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          AppSpacing.gapH12,
          if (e == null)
            Text('No engagement record yet.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colors.onSurfaceVariant))
          else ...[
            _kv('Status', e.stage.displayName, theme, colors,
                emphasize: true),
            _kv('Plan', e.planName ?? '—', theme, colors),
            _kv('Amount paid', _money(e.amountPaid), theme, colors),
            _kv('Paid on', _date(e.paidAt), theme, colors),
            _kv(
              'Sharing starts',
              e.sharingStartsAt == null
                  ? '—'
                  : (e.sharingStarted
                      ? 'Live since ${_date(e.sharingStartsAt)}'
                      : '${_date(e.sharingStartsAt)} (in ${e.daysUntilSharing} days)'),
              theme,
              colors,
            ),
            _kv('Valid until', _date(e.validUntil), theme, colors, isLast: true),
            if (!e.hasPaid && e.stage == EngagementStage.connected) ...[
              AppSpacing.gapH8,
              Container(
                padding: AppSpacing.allSm,
                decoration: BoxDecoration(
                  color: palette.warning.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 16, color: palette.warning),
                    AppSpacing.gapW8,
                    Expanded(
                      child: Text(
                        'Profile sharing is gated until this client pays.',
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: palette.warning),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _kv(String k, String v, ThemeData theme, ColorScheme colors,
      {bool emphasize = false, bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: colors.onSurfaceVariant)),
          const Spacer(),
          Flexible(
            child: Text(
              v,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
                color: emphasize ? colors.primary : colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Requirements card ────────────────────────────────────────────────────────

class _RequirementsCard extends StatelessWidget {
  const _RequirementsCard({
    required this.engagement,
    required this.profile,
    required this.theme,
    required this.colors,
  });

  final ClientEngagement? engagement;
  final ParentProfile? profile;
  final ThemeData theme;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final e = engagement;
    final p = profile;
    final ageRange = (p?.preferredMinAge != null && p?.preferredMaxAge != null)
        ? '${p!.preferredMinAge}–${p.preferredMaxAge} yrs'
        : null;
    final communities =
        (p?.preferredCommunities.isNotEmpty ?? false) ? p!.preferredCommunities.join(', ') : null;

    return _Card(
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 18, color: colors.primary),
              AppSpacing.gapW8,
              Text('Requirements',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          AppSpacing.gapH12,
          if (e?.budgetExpectation != null)
            _reqRow(Icons.account_balance_wallet_outlined,
                e!.budgetExpectation!, theme, colors),
          if (e?.expectedIncomeMin != null)
            _reqRow(Icons.trending_up_rounded, 'Expects ${e!.expectedIncomeMin}',
                theme, colors),
          if (ageRange != null)
            _reqRow(Icons.cake_outlined, 'Age $ageRange', theme, colors),
          if (communities != null)
            _reqRow(Icons.groups_outlined, communities, theme, colors),
          if (e?.requirementNotes != null) ...[
            AppSpacing.gapH8,
            Text(
              e!.requirementNotes!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant, height: 1.4),
            ),
          ],
          if (e?.budgetExpectation == null &&
              e?.expectedIncomeMin == null &&
              ageRange == null &&
              communities == null &&
              e?.requirementNotes == null)
            Text('No requirements captured yet.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _reqRow(IconData icon, String text, ThemeData theme, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colors.onSurfaceVariant),
          AppSpacing.gapW8,
          Expanded(
            child: Text(text,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

// ── Follow-up tile ────────────────────────────────────────────────────────────

class _FollowUpTile extends StatelessWidget {
  const _FollowUpTile({
    required this.followUp,
    required this.onToggle,
    required this.colors,
    required this.theme,
    required this.palette,
  });

  final BrokerFollowUp followUp;
  final VoidCallback onToggle;
  final ColorScheme colors;
  final ThemeData theme;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final f = followUp;
    final accent = f.isDone
        ? colors.onSurfaceVariant
        : f.isOverdue
            ? palette.error
            : f.isDueToday
                ? palette.warning
                : colors.onSurfaceVariant;
    final due = f.isDone
        ? 'Done'
        : f.isOverdue
            ? 'Overdue'
            : f.isDueToday
                ? 'Due today'
                : 'Due ${f.dueAt.day}/${f.dueAt.month}';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: colors.surface,
        borderRadius: AppSpacing.roundedMd,
        child: InkWell(
          borderRadius: AppSpacing.roundedMd,
          onTap: onToggle,
          child: Container(
            padding: AppSpacing.allSm,
            decoration: BoxDecoration(
              borderRadius: AppSpacing.roundedMd,
              border: Border.all(color: colors.outlineVariant, width: 0.5),
            ),
            child: Row(
              children: [
                Icon(
                  f.isDone
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: f.isDone ? palette.success : accent,
                  size: 22,
                ),
                AppSpacing.gapW12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          decoration:
                              f.isDone ? TextDecoration.lineThrough : null,
                          color: f.isDone ? colors.onSurfaceVariant : null,
                        ),
                      ),
                      Text(due,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: accent)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared profile tile ─────────────────────────────────────────────────────

class _SharedProfileTile extends StatelessWidget {
  const _SharedProfileTile({
    required this.item,
    required this.colors,
    required this.theme,
    required this.palette,
    required this.onTap,
  });

  final _SharedItem item;
  final ColorScheme colors;
  final ThemeData theme;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = item.profile;
    final parentResp = item.shared.parentResponse;
    final childResp = item.shared.childResponse;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: colors.surface,
        borderRadius: AppSpacing.roundedMd,
        child: InkWell(
          borderRadius: AppSpacing.roundedMd,
          onTap: onTap,
          child: Container(
            padding: AppSpacing.allSm,
            decoration: BoxDecoration(
              borderRadius: AppSpacing.roundedMd,
              border: Border.all(color: colors.outlineVariant, width: 0.5),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: colors.surfaceContainerHighest,
                  backgroundImage: p.photos.isNotEmpty &&
                          p.photos.first.startsWith('http')
                      ? NetworkImage(p.photos.first)
                      : null,
                  child: p.photos.isEmpty
                      ? Text(p.name.isNotEmpty ? p.name[0] : '?')
                      : null,
                ),
                AppSpacing.gapW12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${p.name}, ${p.age}',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      Text(
                        [p.profession, p.city]
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
                _ResponsePill(
                    parent: parentResp, child: childResp, palette: palette, colors: colors, theme: theme),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResponsePill extends StatelessWidget {
  const _ResponsePill({
    required this.parent,
    required this.child,
    required this.palette,
    required this.colors,
    required this.theme,
  });

  final SharedProfileResponse parent;
  final SharedProfileResponse? child;
  final AppPalette palette;
  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final (String label, Color c) = switch (parent) {
      SharedProfileResponse.interested => ('Interested', palette.success),
      SharedProfileResponse.pass => ('Passed', colors.onSurfaceVariant),
      _ => ('Waiting', palette.warning),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.14),
            borderRadius: AppSpacing.roundedFull,
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: c)),
        ),
        if (child != null) ...[
          const SizedBox(height: 3),
          Text(
            'Candidate: ${child == SharedProfileResponse.interested ? 'Yes' : child == SharedProfileResponse.pass ? 'No' : '…'}',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

// ── Reusable bits ─────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child, required this.colors});
  final Widget child;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.allMd,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: colors.outlineVariant, width: 0.5),
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.theme, this.action});
  final String title;
  final ThemeData theme;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs, left: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(
      {required this.text, required this.colors, required this.theme});
  final String text;
  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(text,
          style:
              theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
    );
  }
}

// ── Share sheet ───────────────────────────────────────────────────────────────

class _ShareSheet extends StatelessWidget {
  const _ShareSheet({required this.candidates});
  final List<CandidateProfile> candidates;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SafeArea(
      child: Padding(
        padding: AppSpacing.allMd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share a profile',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            AppSpacing.gapH12,
            if (candidates.isEmpty)
              Padding(
                padding: AppSpacing.allMd,
                child: Text('No more profiles to share.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: colors.onSurfaceVariant)),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: candidates.length,
                  itemBuilder: (ctx, i) {
                    final p = candidates[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colors.surfaceContainerHighest,
                        backgroundImage: p.photos.isNotEmpty &&
                                p.photos.first.startsWith('http')
                            ? NetworkImage(p.photos.first)
                            : null,
                        child: p.photos.isEmpty
                            ? Text(p.name.isNotEmpty ? p.name[0] : '?')
                            : null,
                      ),
                      title: Text('${p.name}, ${p.age}'),
                      subtitle: Text(
                        [p.profession, p.city]
                            .where((s) => s.isNotEmpty)
                            .join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.send_rounded, size: 18),
                      onTap: () => Navigator.pop(context, p),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Add follow-up dialog ────────────────────────────────────────────────────

class _FollowUpDraft {
  const _FollowUpDraft({
    required this.title,
    required this.notes,
    required this.dueAt,
    required this.priority,
  });
  final String title;
  final String notes;
  final DateTime dueAt;
  final FollowUpPriority priority;
}

class _AddFollowUpDialog extends StatefulWidget {
  const _AddFollowUpDialog();

  @override
  State<_AddFollowUpDialog> createState() => _AddFollowUpDialogState();
}

class _AddFollowUpDialogState extends State<_AddFollowUpDialog> {
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _due = DateTime.now().add(const Duration(days: 1));
  FollowUpPriority _priority = FollowUpPriority.normal;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _due = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('New follow-up'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Call about Rahul\'s profile',
              ),
            ),
            AppSpacing.gapH12,
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            AppSpacing.gapH16,
            Row(
              children: [
                Icon(Icons.event_rounded,
                    size: 18, color: theme.colorScheme.primary),
                AppSpacing.gapW8,
                Text('Due ${_due.day}/${_due.month}/${_due.year}'),
                const Spacer(),
                TextButton(onPressed: _pickDate, child: const Text('Change')),
              ],
            ),
            AppSpacing.gapH8,
            SegmentedButton<FollowUpPriority>(
              segments: const [
                ButtonSegment(
                    value: FollowUpPriority.low, label: Text('Low')),
                ButtonSegment(
                    value: FollowUpPriority.normal, label: Text('Normal')),
                ButtonSegment(
                    value: FollowUpPriority.high, label: Text('High')),
              ],
              selected: {_priority},
              onSelectionChanged: (s) => setState(() => _priority = s.first),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_titleCtrl.text.trim().isEmpty) return;
            Navigator.pop(
              context,
              _FollowUpDraft(
                title: _titleCtrl.text.trim(),
                notes: _notesCtrl.text.trim(),
                dueAt: _due,
                priority: _priority,
              ),
            );
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
