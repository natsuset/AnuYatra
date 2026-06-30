import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:testing_flutter/core/theme/app_palette.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/l10n/l10n_extension.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/core/routing/route_names.dart';
import 'package:testing_flutter/models/broker_profile.dart';
import 'package:testing_flutter/models/link_request.dart';
import 'package:testing_flutter/models/user_role.dart';

class AdminBrokersScreen extends ConsumerStatefulWidget {
  const AdminBrokersScreen({super.key});

  @override
  ConsumerState<AdminBrokersScreen> createState() => _AdminBrokersScreenState();
}

class _AdminBrokersScreenState extends ConsumerState<AdminBrokersScreen> {
  List<BrokerProfile> _brokers = [];
  Map<String, ({int clientCount, int profileCount})> _brokerStats = {};
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  String _query = '';

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

  List<BrokerProfile> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _brokers;
    return _brokers.where((b) {
      return b.name.toLowerCase().contains(q) ||
          b.phoneNumber.toLowerCase().contains(q) ||
          b.specializations.any((s) => s.toLowerCase().contains(q)) ||
          b.areasServed.any((a) => a.toLowerCase().contains(q));
    }).toList();
  }

  Future<void> _loadData() async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated || authState.user.agencyId == null) {
      if (mounted) setState(() => _brokers = []);
      return;
    }

    final agencyId = authState.user.agencyId!;
    final brokerRepo = ref.read(brokerRepositoryProvider);
    final linkRepo = ref.read(linkRepositoryProvider);
    final profileRepo = ref.read(profileRepositoryProvider);

    final brokers = await brokerRepo.getBrokersByAgency(agencyId);
    final stats = <String, ({int clientCount, int profileCount})>{};

    for (final broker in brokers) {
      final parentIds = await linkRepo.getConnectedParentIds(broker.userId);
      final candidates = await profileRepo.getCandidatesByBroker(broker.userId);
      stats[broker.userId] = (
        clientCount: parentIds.length,
        profileCount: candidates.length,
      );
    }

    if (!mounted) return;
    setState(() {
      _brokers = brokers;
      _brokerStats = stats;
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
      appBar: AppBar(
        title: Text(context.l10n.agencyBrokersTitle),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInviteDialog(context, ref, user.uid, user.displayName),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: Text(context.l10n.inviteBroker),
      ),
      body: _brokers.isEmpty
          ? _buildEmptyState(context, isDark, theme, ref, user.uid, user.displayName)
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search brokers, specialization, area…',
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
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: AppSpacing.roundedMd,
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final filtered = _filtered;
                      if (filtered.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off_rounded,
                                  size: 48,
                                  color: theme.colorScheme.outlineVariant),
                              AppSpacing.gapH12,
                              Text('No brokers match your search',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md, AppSpacing.xs, AppSpacing.md, 80),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final broker = filtered[index];
                          final s = _brokerStats[broker.userId] ??
                              (clientCount: 0, profileCount: 0);
                          return _BrokerCard(
                            broker: broker,
                            clientCount: s.clientCount,
                            profileCount: s.profileCount,
                            isDark: isDark,
                            theme: theme,
                            onTap: () => context.pushNamed(
                              RouteNames.adminBrokerDetail,
                              pathParameters: {'id': broker.userId},
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    bool isDark,
    ThemeData theme,
    WidgetRef ref,
    String userId,
    String userName,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.groups_outlined,
            size: 72,
            color: isDark
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          AppSpacing.gapH16,
          Text(
            context.l10n.noBrokersInAgency,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          AppSpacing.gapH8,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Invite brokers to join your agency and start managing clients together',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          AppSpacing.gapH24,
          FilledButton.icon(
            onPressed: () => _showInviteDialog(context, ref, userId, userName),
            icon: const Icon(Icons.person_add),
            label: Text(context.l10n.inviteBroker),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog(BuildContext context, WidgetRef ref, String currentUserId, String currentUserName) {
    final phoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.inviteBroker),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the phone number of the broker you want to invite to your agency.',
            ),
            AppSpacing.gapH16,
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: context.l10n.phoneNumber,
                hintText: '+91 XXXXX XXXXX',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),
          ],
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
// Broker card
// ---------------------------------------------------------------------------
class _BrokerCard extends StatelessWidget {
  final BrokerProfile broker;
  final int clientCount;
  final int profileCount;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onTap;

  const _BrokerCard({
    required this.broker,
    required this.clientCount,
    required this.profileCount,
    required this.isDark,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? Theme.of(context).colorScheme.outline : Theme.of(context).colorScheme.outline,
          width: 0.5,
        ),
      ),
      color: isDark ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
        padding: AppSpacing.allMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: avatar + name + rating
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      Theme.of(context).colorScheme.secondary.withValues(alpha: 0.12),
                  child: Text(
                    broker.name.isNotEmpty
                        ? broker.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        broker.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        broker.phoneNumber,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Rating badge
                if (broker.rating > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: context.palette.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 14,
                          color: context.palette.warning,
                        ),
                        AppSpacing.gapW4,
                        Text(
                          broker.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.palette.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            // Stats row
            Row(
              children: [
                _MiniStat(
                  icon: Icons.family_restroom,
                  label: 'Clients',
                  value: '$clientCount',
                  isDark: isDark,
                ),
                const SizedBox(width: 20),
                _MiniStat(
                  icon: Icons.person_outline,
                  label: 'Profiles',
                  value: '$profileCount',
                  isDark: isDark,
                ),
                const SizedBox(width: 20),
                _MiniStat(
                  icon: Icons.work_outline,
                  label: context.l10n.experienceLabel,
                  value: '${broker.experienceYears}y',
                  isDark: isDark,
                ),
              ],
            ),

            // Specializations
            if (broker.specializations.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: broker.specializations
                    .take(3)
                    .map(
                      (s) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs, vertical: 3),
                        decoration: BoxDecoration(
                          color: context.palette.info.withValues(alpha: 0.08),
                          borderRadius: AppSpacing.roundedXs,
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.palette.info,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mini stat widget
// ---------------------------------------------------------------------------
class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color:
              isDark ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        AppSpacing.gapW4,
        Text(
          '$value $label',
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
