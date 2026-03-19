import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/core/routing/route_names.dart';
import 'package:testing_flutter/models/app_user.dart';
import 'package:testing_flutter/models/chat_message.dart';

/// WhatsApp-style conversation list for brokers.
/// Shows all conversations with last message preview.
class BrokerMessagesScreen extends ConsumerStatefulWidget {
  const BrokerMessagesScreen({super.key});

  @override
  ConsumerState<BrokerMessagesScreen> createState() =>
      _BrokerMessagesScreenState();
}

class _BrokerMessagesScreenState extends ConsumerState<BrokerMessagesScreen> {
  List<Conversation> _conversations = [];
  Map<String, AppUser?> _otherUsersByUserId = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final user = authState.user;
    final messagingRepo = ref.read(messagingRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);

    final conversations =
        await messagingRepo.getConversationsForUser(user.uid);
    final otherUsersByUserId = <String, AppUser?>{};
    for (final conv in conversations) {
      final otherUserId = conv.participantIds.firstWhere(
        (id) => id != user.uid,
        orElse: () => '',
      );
      if (otherUserId.isNotEmpty) {
        otherUsersByUserId[otherUserId] =
            await userRepo.getUser(otherUserId);
      }
    }

    if (!mounted) return;
    setState(() {
      _conversations = conversations;
      _otherUsersByUserId = otherUsersByUserId;
      _isLoading = false;
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
    final conversations = _conversations;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: conversations.isEmpty
          ? _buildEmptyState(theme)
          : ListView.separated(
              itemCount: conversations.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 76,
                color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
              ),
              itemBuilder: (context, index) {
                final conv = conversations[index];
                // Find the other participant
                final otherUserId = conv.participantIds.firstWhere(
                  (id) => id != user.uid,
                  orElse: () => '',
                );
                final otherUser = _otherUsersByUserId[otherUserId];
                final otherName = otherUser?.displayName ?? 'Unknown';
                final initial =
                    otherName.isNotEmpty ? otherName[0].toUpperCase() : '?';

                // Format time
                String timeStr = '';
                if (conv.lastMessageAt != null) {
                  final diff =
                      DateTime.now().difference(conv.lastMessageAt!);
                  if (diff.inMinutes < 60) {
                    timeStr = '${diff.inMinutes}m ago';
                  } else if (diff.inHours < 24) {
                    timeStr = '${diff.inHours}h ago';
                  } else {
                    timeStr = '${diff.inDays}d ago';
                  }
                }

                return ListTile(
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundColor:
                        AppColors.sacredSaffron.withValues(alpha: 0.15),
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: AppColors.sacredSaffron,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          otherName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: conv.unreadCount > 0
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        timeStr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: conv.unreadCount > 0
                              ? AppColors.sacredSaffron
                              : theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.lastMessagePreview ?? 'No messages yet',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: conv.unreadCount > 0
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: conv.unreadCount > 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conv.unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.chatDarkGreen,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${conv.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  onTap: () {
                    context.pushNamed(
                      RouteNames.chat,
                      pathParameters: {'conversationId': conv.id},
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When parents connect with you, conversations will appear here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
