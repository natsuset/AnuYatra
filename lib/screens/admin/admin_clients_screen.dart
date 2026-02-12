import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/routing/route_names.dart';
import 'package:testing_flutter/core/services/local_storage_service.dart';

/// Shows all clients (parents) connected to any broker in the agency.
class AdminClientsScreen extends ConsumerWidget {
  const AdminClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final storage = ref.watch(localStorageServiceProvider);

    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = authState.user;
    final agencyId = user.agencyId;

    // Gather all clients across all brokers in the agency
    final brokers =
        agencyId != null ? storage.getBrokersByAgency(agencyId) : [];
    final clientMap = <String, _ClientInfo>{};

    for (final broker in brokers) {
      final parentIds = storage.getConnectedParentIds(broker.userId);
      for (final parentId in parentIds) {
        if (!clientMap.containsKey(parentId)) {
          final parent = storage.getParentProfile(parentId);
          final parentUser = storage.getUser(parentId);
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

    final clients = clientMap.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agency Clients'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.sacredSaffron.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${clients.length}',
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
      body: clients.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.family_restroom_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No clients yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
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
              padding: const EdgeInsets.all(16),
              itemCount: clients.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final client = clients[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    // Navigate to chat with this parent
                    final convId = storage.getOrCreateConversation(
                      user.uid, client.userId);
                    context.pushNamed(
                      RouteNames.chat,
                      pathParameters: {'conversationId': convId},
                    );
                  },
                  child: Container(
                  padding: const EdgeInsets.all(16),
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
                            const SizedBox(height: 4),
                            Text(
                              '${client.city} \u2022 Looking for ${client.lookingFor}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              children: client.brokerNames.map((name) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.info.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
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
