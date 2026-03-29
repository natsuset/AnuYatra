import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/l10n/l10n_extension.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/core/routing/route_names.dart';

/// Shows all clients (parents) connected to any broker in the agency.
class AdminClientsScreen extends ConsumerStatefulWidget {
  const AdminClientsScreen({super.key});

  @override
  ConsumerState<AdminClientsScreen> createState() => _AdminClientsScreenState();
}

class _AdminClientsScreenState extends ConsumerState<AdminClientsScreen> {
  List<_ClientInfo> _clients = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated || authState.user.agencyId == null) {
      if (mounted) setState(() => _clients = []);
      return;
    }

    final agencyId = authState.user.agencyId!;
    final brokerRepo = ref.read(brokerRepositoryProvider);
    final linkRepo = ref.read(linkRepositoryProvider);
    final profileRepo = ref.read(profileRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);

    final brokers = await brokerRepo.getBrokersByAgency(agencyId);
    final clientMap = <String, _ClientInfo>{};

    for (final broker in brokers) {
      final parentIds = await linkRepo.getConnectedParentIds(broker.userId);
      for (final parentId in parentIds) {
        if (!clientMap.containsKey(parentId)) {
          final parent = await profileRepo.getParentProfile(parentId);
          final parentUser = await userRepo.getUser(parentId);
          if (parent != null && parentUser != null) {
            clientMap[parentId] = _ClientInfo(
              userId: parentId,
              name: parent.name,
              phone: parentUser.phoneNumber,
              city: parent.city,
              lookingFor: parent.lookingForDisplay,
              brokerNames: [broker.name],
            );
          }
        } else {
          clientMap[parentId]!.brokerNames.add(broker.name);
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _clients = clientMap.values.toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authProvider);

    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = authState.user;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.agencyClientsTitle),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.sacredSaffron.withValues(alpha: 0.15),
                  borderRadius: AppSpacing.roundedMd,
                ),
                child: Text(
                  '${_clients.length}',
                  style: TextStyle(
                    color: AppColors.sacredSaffron,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _clients.isEmpty
          ? Center(
              child: Padding(
                padding: AppSpacing.allXl,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.family_restroom_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.4),
                    ),
                    AppSpacing.gapH16,
                    Text(
                      context.l10n.noClientsYet,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    AppSpacing.gapH8,
                    Text(
                      'When parents connect with your brokers, they\'ll appear here.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: AppSpacing.allMd,
              itemCount: _clients.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final client = _clients[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    final messagingRepo = ref.read(messagingRepositoryProvider);
                    final convId = await messagingRepo.getOrCreateConversation(
                      user.uid, client.userId);
                    if (!context.mounted) return;
                    context.pushNamed(
                      RouteNames.chat,
                      pathParameters: {'conversationId': convId},
                    );
                  },
                  child: Container(
                  padding: AppSpacing.allMd,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkDivider
                          : AppColors.lightDivider,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor:
                            AppColors.sacredSaffron.withValues(alpha: 0.12),
                        child: Text(
                          client.name.isNotEmpty
                              ? client.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: AppColors.sacredSaffron,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              client.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            AppSpacing.gapH4,
                            Text(
                              '${client.city} \u2022 Looking for ${client.lookingFor}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              children: client.brokerNames.map((name) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.info.withValues(alpha: 0.1),
                                    borderRadius: AppSpacing.roundedSm,
                                  ),
                                  child: Text(
                                    name,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppColors.info,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ),
                );
              },
            ),
    );
  }
}

class _ClientInfo {
  final String userId;
  final String name;
  final String phone;
  final String city;
  final String lookingFor;
  final List<String> brokerNames;

  _ClientInfo({
    required this.userId,
    required this.name,
    required this.phone,
    required this.city,
    required this.lookingFor,
    required this.brokerNames,
  });
}
