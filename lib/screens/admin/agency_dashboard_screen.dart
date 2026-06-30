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
  ConsumerState<AgencyDashboardScreen> createState() => _AgencyDashboardScreenState();
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) {
      return Scaffold(
        body: Center(child: Text(context.l10n.pleaseLogIn)),
      );
    }

    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: const BrandedAppBar(),
      body: CustomScrollView(
        slivers: [
          // ---- Agency header ----
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xxl,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: AppSpacing.roundedMd,
                              ),
                              child: const Icon(
                                Icons.business,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _agency?.name ?? 'My Agency',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (_agency != null)
                                    Text(
                                      '${_agency!.city}, ${_agency!.state}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ---- Body ----
          SliverPadding(
            padding: AppSpacing.allMd,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stat cards row
                _buildStatCards(_stats, isDark, theme),

                const SizedBox(height: 20),

                // Broker roster preview
                _buildBrokerRoster(context, _brokers, _brokerUsers, isDark, theme),

                AppSpacing.gapH16,

                // Quick action: Invite Broker
                _buildInviteBrokerAction(context, isDark, theme, ref, user.uid, user.displayName),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(
    AgencyStats stats,
    bool isDark,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.people_outline,
            iconColor: context.palette.info,
            label: context.l10n.activeBrokers,
            value: '${stats.totalBrokers}',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.family_restroom,
            iconColor: Theme.of(context).colorScheme.primary,
            label: context.l10n.activeClients,
            value: '${stats.totalClients}',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.person_outline,
            iconColor: context.palette.success,
            label: context.l10n.profilesManaged,
            value: '${stats.totalProfiles}',
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildBrokerRoster(
    BuildContext context,
    List<BrokerProfile> brokers,
    Map<String, AppUser?> brokerUsers,
    bool isDark,
    ThemeData theme,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.roundedLg,
        side: BorderSide(
          color: isDark ? Theme.of(context).colorScheme.outline : Theme.of(context).colorScheme.outline,
          width: 0.5,
        ),
      ),
      color: isDark ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, AppSpacing.md, 20, AppSpacing.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.brokerRoster,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (brokers.length > 4)
                  TextButton(
                    onPressed: () {
                      context.goNamed(RouteNames.adminBrokers);
                    },
                    child: Text(context.l10n.viewAll),
                  ),
              ],
            ),
          ),
          if (brokers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.group_off_outlined,
                      size: 40,
                      color: isDark
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    AppSpacing.gapH8,
                    Text(
                      'No brokers yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...brokers.take(4).map((broker) {
              final user = brokerUsers[broker.userId];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.secondary.withValues(alpha: 0.12),
                  child: Text(
                    broker.name.isNotEmpty
                        ? broker.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  broker.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${broker.clientCount} clients \u2022 ${broker.profilesManaged} profiles',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                  decoration: BoxDecoration(
                    color: (user?.isActive ?? false)
                        ? context.palette.success.withValues(alpha: 0.12)
                        : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.12),
                    borderRadius: AppSpacing.roundedXs,
                  ),
                  child: Text(
                    (user?.isActive ?? false) ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: (user?.isActive ?? false)
                          ? context.palette.success
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }),
          AppSpacing.gapH8,
        ],
      ),
    );
  }

  Widget _buildInviteBrokerAction(
    BuildContext context,
    bool isDark,
    ThemeData theme,
    WidgetRef ref,
    String userId,
    String userName,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.roundedLg,
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      color: isDark ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.surface,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: AppSpacing.xs),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: AppSpacing.roundedMd,
          ),
          child: Icon(
            Icons.person_add_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          context.l10n.inviteBroker,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(context.l10n.addNewBroker),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.primary,
        ),
        onTap: () {
          _showInviteDialog(context, ref, userId, userName);
        },
      ),
    );
  }

  void _showInviteDialog(BuildContext context, WidgetRef ref, String currentUserId, String currentUserName) {
    final phoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.inviteBroker),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: context.l10n.phoneNumber,
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
                      content: Text('${brokerUser.displayName} is not registered as a broker'),
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
                    content: Text(
                      context.l10n.inviteSentTo(brokerUser.displayName),
                    ),
                    backgroundColor: context.palette.success,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: Text(context.l10n.sendInvite),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stat card
// ---------------------------------------------------------------------------
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? Theme.of(context).colorScheme.outline : Theme.of(context).colorScheme.outline,
          width: 0.5,
        ),
      ),
      color: isDark ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: AppSpacing.allMd,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
