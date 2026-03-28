import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/constants/app_strings.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
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
      return const Scaffold(
        body: Center(child: Text('Please log in')),
      );
    }

    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agency Brokers'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInviteDialog(context, ref, user.uid, user.displayName),
        backgroundColor: AppColors.sacredSaffron,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text(AppStrings.inviteBroker),
      ),
      body: _brokers.isEmpty
          ? _buildEmptyState(context, isDark, theme, ref, user.uid, user.displayName)
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                80,
              ),
              itemCount: _brokers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final broker = _brokers[index];
                final s = _brokerStats[broker.userId] ?? (clientCount: 0, profileCount: 0);
                return _BrokerCard(
                  broker: broker,
                  clientCount: s.clientCount,
                  profileCount: s.profileCount,
                  isDark: isDark,
                  theme: theme,
                );
              },
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
                ? AppColors.darkTertiaryText
                : AppColors.lightTertiaryText,
          ),
          AppSpacing.gapH16,
          Text(
            AppStrings.noBrokersInAgency,
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
                    ? AppColors.darkSecondaryText
                    : AppColors.lightSecondaryText,
              ),
            ),
          ),
          AppSpacing.gapH24,
          FilledButton.icon(
            onPressed: () => _showInviteDialog(context, ref, userId, userName),
            icon: const Icon(Icons.person_add),
            label: const Text(AppStrings.inviteBroker),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.sacredSaffron,
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
        title: const Text(AppStrings.inviteBroker),
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
              decoration: const InputDecoration(
                labelText: 'Phone Number',
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
            child: const Text(AppStrings.cancel),
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
                    const SnackBar(
                      content: Text(AppStrings.userNotFoundByPhone),
                      backgroundColor: AppColors.error,
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
                      backgroundColor: AppColors.warning,
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
                    content: Text('Invite sent to ${brokerUser.displayName}'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.sacredSaffron,
            ),
            child: const Text(AppStrings.sendInvite),
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

  const _BrokerCard({
    required this.broker,
    required this.clientCount,
    required this.profileCount,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.5,
        ),
      ),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
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
                      AppColors.deepMaroon.withValues(alpha: 0.12),
                  child: Text(
                    broker.name.isNotEmpty
                        ? broker.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.deepMaroon,
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
                              ? AppColors.darkTertiaryText
                              : AppColors.lightTertiaryText,
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
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: AppColors.warning,
                        ),
                        AppSpacing.gapW4,
                        Text(
                          broker.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warning,
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
                  label: 'Experience',
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
                          color: AppColors.info.withValues(alpha: 0.08),
                          borderRadius: AppSpacing.roundedXs,
                        ),
                        child: Text(
                          s,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.info,
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
              isDark ? AppColors.darkTertiaryText : AppColors.lightTertiaryText,
        ),
        AppSpacing.gapW4,
        Text(
          '$value $label',
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? AppColors.darkSecondaryText
                : AppColors.lightSecondaryText,
          ),
        ),
      ],
    );
  }
}
