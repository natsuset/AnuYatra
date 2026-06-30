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
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/core/routing/route_names.dart';
import 'package:testing_flutter/models/agency.dart';
import 'package:testing_flutter/models/app_user.dart';
import 'package:testing_flutter/models/broker_profile.dart';
import 'package:testing_flutter/models/link_request.dart';
import 'package:testing_flutter/models/user_role.dart';

class AgencyDashboardScreen extends ConsumerStatefulWidget {
  const AgencyDashboardScreen({super.key});

  @override
  ConsumerState<AgencyDashboardScreen> createState() =>
      _AgencyDashboardScreenState();
}

class _AgencyDashboardScreenState extends ConsumerState<AgencyDashboardScreen> {
  Agency? _agency;
  AgencyStats _stats = AgencyStats.empty;
  List<BrokerProfile> _brokers = [];
  Map<String, AppUser?> _brokerUsers = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated || authState.user.agencyId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final agencyId = authState.user.agencyId!;
    final agencyRepo = ref.read(agencyRepositoryProvider);
    final brokerRepo = ref.read(brokerRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);

    final agency = await agencyRepo.getAgency(agencyId);
    final stats = await brokerRepo.getAgencyStats(agencyId);
    final brokers = await brokerRepo.getBrokersByAgency(agencyId);
    final brokerUsers = <String, AppUser?>{};
    for (final broker in brokers) {
      brokerUsers[broker.userId] = await userRepo.getUser(broker.userId);
    }

    if (!mounted) return;
    setState(() {
      _agency = agency;
      _stats = stats;
      _brokers = brokers;
      _brokerUsers = brokerUsers;
      _loading = false;
    });
  }

  /// Brokers ranked by an activity score (clients + profiles), then rating.
  List<BrokerProfile> get _leaderboard {
    final list = [..._brokers];
    list.sort((a, b) {
      final sa = a.clientCount + a.profilesManaged;
      final sb = b.clientCount + b.profilesManaged;
      if (sb != sa) return sb.compareTo(sa);
      return b.rating.compareTo(a.rating);
    });
    return list;
  }

  void _openBroker(String brokerUserId) {
    context.pushNamed(RouteNames.adminBrokerDetail,
        pathParameters: {'id': brokerUserId});
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) {
      return Scaffold(body: Center(child: Text(context.l10n.pleaseLogIn)));
    }

    final user = authState.user;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final palette = context.palette;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final leaderboard = _leaderboard;

    return Scaffold(
      appBar: const BrandedAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // ── Agency header ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: _AgencyHeader(agency: _agency, theme: theme, colors: colors),
            ),

            // ── KPI strip ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: _Kpi(
                        label: context.l10n.activeBrokers,
                        value: _stats.totalBrokers,
                        icon: Icons.groups_rounded,
                        color: palette.info,
                      ),
                    ),
                    AppSpacing.gapW12,
                    Expanded(
                      child: _Kpi(
                        label: context.l10n.activeClients,
                        value: _stats.totalClients,
                        icon: Icons.family_restroom_rounded,
                        color: colors.primary,
                      ),
                    ),
                    AppSpacing.gapW12,
                    Expanded(
                      child: _Kpi(
                        label: context.l10n.profilesManaged,
                        value: _stats.totalProfiles,
                        icon: Icons.badge_rounded,
                        color: palette.success,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Leaderboard header ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.leaderboard_rounded,
                            size: 20, color: palette.warning),
                        AppSpacing.gapW8,
                        Text('Broker Performance',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    if (_brokers.length > 3)
                      TextButton(
                        onPressed: () =>
                            context.goNamed(RouteNames.adminBrokers),
                        child: Text(context.l10n.viewAll),
                      ),
                  ],
                ),
              ),
            ),

            if (leaderboard.isEmpty)
              SliverToBoxAdapter(
                child: _EmptyBrokers(theme: theme, colors: colors),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.separated(
                  itemCount: leaderboard.take(5).length,
                  separatorBuilder: (_, __) => AppSpacing.gapH8,
                  itemBuilder: (context, i) {
                    final b = leaderboard[i];
                    return _LeaderboardTile(
                      rank: i + 1,
                      broker: b,
                      isActive: _brokerUsers[b.userId]?.isActive ?? true,
                      onTap: () => _openBroker(b.userId),
                      theme: theme,
                      colors: colors,
                      palette: palette,
                    );
                  },
                ),
              ),

            // ── Invite broker ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                child: _InviteCard(
                  theme: theme,
                  colors: colors,
                  onTap: () => _showInviteDialog(
                      context, ref, user.uid, user.displayName),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteDialog(BuildContext context, WidgetRef ref,
      String currentUserId, String currentUserName) {
    final phoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.inviteBroker),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone number',
            hintText: 'Enter broker phone number',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final phone = phoneController.text.trim();
              if (phone.isEmpty) return;
              Navigator.pop(ctx);

              final userRepo = ref.read(userRepositoryProvider);
              final linkRepo = ref.read(linkRepositoryProvider);
              final brokerUser = await userRepo.getUserByPhone(phone);

              if (brokerUser == null) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.userNotFoundByPhone),
                      backgroundColor: context.palette.error,
                    ),
                  );
                }
                return;
              }

              if (brokerUser.role != UserRole.broker) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '${brokerUser.displayName} is not registered as a broker'),
                      backgroundColor: context.palette.warning,
                    ),
                  );
                }
                return;
              }

              await linkRepo.sendLinkRequest(
                fromUserId: currentUserId,
                toUserId: brokerUser.uid,
                fromUserName: currentUserName,
                toUserName: brokerUser.displayName,
                type: LinkRequestType.agencyToBroker,
                note: 'Join our agency',
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(context.l10n.inviteSentTo(brokerUser.displayName)),
                    backgroundColor: context.palette.success,
                  ),
                );
              }
            },
            child: Text(context.l10n.sendInvite),
          ),
        ],
      ),
    );
  }
}

// ─── Agency header ──────────────────────────────────────────────────

class _AgencyHeader extends StatelessWidget {
  const _AgencyHeader(
      {required this.agency, required this.theme, required this.colors});
  final Agency? agency;
  final ThemeData theme;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: AppSpacing.roundedMd,
                ),
                child: const Icon(Icons.business_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agency?.name ?? 'My Agency',
                      style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (agency != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${agency!.city}, ${agency!.state}',
                        style:
                            const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
              if ((agency?.rating ?? 0) > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: AppSpacing.roundedFull,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 15, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(agency!.rating.toStringAsFixed(1),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
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

// ─── KPI tile ────────────────────────────────────────────────────────

class _Kpi extends StatelessWidget {
  const _Kpi(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          Text('$value',
              style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  height: 1.0)),
          const SizedBox(height: 2),
          Text(label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─── Leaderboard tile ─────────────────────────────────────────────────

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({
    required this.rank,
    required this.broker,
    required this.isActive,
    required this.onTap,
    required this.theme,
    required this.colors,
    required this.palette,
  });

  final int rank;
  final BrokerProfile broker;
  final bool isActive;
  final VoidCallback onTap;
  final ThemeData theme;
  final ColorScheme colors;
  final AppPalette palette;

  Color get _rankColor => switch (rank) {
        1 => const Color(0xFFFFB300),
        2 => const Color(0xFF90A4AE),
        3 => const Color(0xFFA1887F),
        _ => colors.onSurfaceVariant,
      };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surface,
      borderRadius: AppSpacing.roundedLg,
      child: InkWell(
        borderRadius: AppSpacing.roundedLg,
        onTap: onTap,
        child: Container(
          padding: AppSpacing.allSm,
          decoration: BoxDecoration(
            borderRadius: AppSpacing.roundedLg,
            border: Border.all(color: colors.outlineVariant, width: 0.5),
          ),
          child: Row(
            children: [
              // Rank
              SizedBox(
                width: 28,
                child: Center(
                  child: rank <= 3
                      ? Icon(Icons.emoji_events_rounded,
                          color: _rankColor, size: 22)
                      : Text('$rank',
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.onSurfaceVariant)),
                ),
              ),
              AppSpacing.gapW8,
              CircleAvatar(
                radius: 20,
                backgroundColor: colors.secondary.withValues(alpha: 0.14),
                child: Text(
                  broker.name.isNotEmpty ? broker.name[0].toUpperCase() : '?',
                  style: TextStyle(
                      color: colors.secondary, fontWeight: FontWeight.w700),
                ),
              ),
              AppSpacing.gapW12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(broker.name,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (!isActive) ...[
                          AppSpacing.gapW8,
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: colors.onSurfaceVariant
                                  .withValues(alpha: 0.12),
                              borderRadius: AppSpacing.roundedFull,
                            ),
                            child: Text('Inactive',
                                style: theme.textTheme.labelSmall?.copyWith(
                                    color: colors.onSurfaceVariant)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${broker.clientCount} clients · ${broker.profilesManaged} profiles',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (broker.rating > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, size: 15, color: palette.warning),
                    const SizedBox(width: 2),
                    Text(broker.rating.toStringAsFixed(1),
                        style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: palette.warning)),
                  ],
                ),
              AppSpacing.gapW4,
              Icon(Icons.chevron_right, color: colors.outline, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Invite card ──────────────────────────────────────────────────────

class _InviteCard extends StatelessWidget {
  const _InviteCard(
      {required this.theme, required this.colors, required this.onTap});
  final ThemeData theme;
  final ColorScheme colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppSpacing.roundedLg,
        onTap: onTap,
        child: Container(
          padding: AppSpacing.allMd,
          decoration: BoxDecoration(
            borderRadius: AppSpacing.roundedLg,
            border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
            color: colors.primary.withValues(alpha: 0.04),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: AppSpacing.roundedMd,
                ),
                child: Icon(Icons.person_add_rounded, color: colors.primary),
              ),
              AppSpacing.gapW16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.inviteBroker,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text('Add a broker to your agency by phone',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: colors.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty brokers ────────────────────────────────────────────────────

class _EmptyBrokers extends StatelessWidget {
  const _EmptyBrokers({required this.theme, required this.colors});
  final ThemeData theme;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.group_off_outlined, size: 48, color: colors.outlineVariant),
          AppSpacing.gapH12,
          Text('No brokers yet',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          AppSpacing.gapH4,
          Text('Invite brokers to start building your agency roster.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
