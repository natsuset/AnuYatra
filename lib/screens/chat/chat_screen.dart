import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:testing_flutter/core/theme/app_palette.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/l10n/l10n_extension.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/core/routing/route_names.dart';
import 'package:testing_flutter/models/chat_message.dart';
import 'package:testing_flutter/models/candidate_profile.dart';
import 'package:testing_flutter/models/user_role.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  final Map<String, CandidateProfile> _sharedProfiles = {};
  String? _currentUserId;
  String _contactName = '';

  String _conversationId = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final convId = GoRouterState.of(context).pathParameters['conversationId'] ?? 'conv-001';
      _conversationId = convId;
      _loadMessages();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final messagingRepo = ref.read(messagingRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);
    final authState = ref.read(authProvider);

    if (authState is AuthAuthenticated) {
      _currentUserId = authState.user.uid;
    }

    final conversation = await messagingRepo.getConversation(_conversationId);
    if (conversation != null && _currentUserId != null) {
      final otherUserId = conversation.participantIds
          .where((id) => id != _currentUserId)
          .firstOrNull;
      if (otherUserId != null) {
        final otherUser = await userRepo.getUser(otherUserId);
        if (otherUser != null) {
          _contactName = otherUser.displayName;
        }
      }
      await messagingRepo.markMessagesAsRead(_conversationId, _currentUserId!);
    }

    final messages = await messagingRepo.getMessages(_conversationId);
    await _loadSharedProfiles(messages);
    if (!mounted) return;
    setState(() {
      _messages = messages;
    });

    _scrollToBottom();
  }

  /// Fetch the candidate profiles referenced by any profile-share messages so
  /// they can render as rich cards.
  Future<void> _loadSharedProfiles(List<ChatMessage> messages) async {
    final profileRepo = ref.read(profileRepositoryProvider);
    final ids = messages
        .where((m) =>
            m.type == ChatMessageType.profileShare && m.profileId != null)
        .map((m) => m.profileId!)
        .toSet();
    for (final id in ids) {
      if (_sharedProfiles.containsKey(id)) continue;
      final p = await profileRepo.getCandidateProfile(id);
      if (p != null) _sharedProfiles[id] = p;
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _currentUserId == null) return;

    final messagingRepo = ref.read(messagingRepositoryProvider);
    final conversation = await messagingRepo.getConversation(_conversationId);
    if (conversation == null) return;

    final recipientId = conversation.participantIds
        .where((id) => id != _currentUserId)
        .firstOrNull;
    if (recipientId == null) return;

    _messageController.clear();

    await messagingRepo.sendMessage(
      conversationId: _conversationId,
      senderId: _currentUserId!,
      recipientId: recipientId,
      content: text,
    );

    final messages = await messagingRepo.getMessages(_conversationId);
    if (!mounted) return;
    setState(() {
      _messages = messages;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? Theme.of(context).scaffoldBackgroundColor : Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            isDark ? Theme.of(context).colorScheme.surface : context.palette.success,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: context.palette.success.withValues(alpha: 0.3),
              child: Text(
                _contactName.isNotEmpty
                    ? _contactName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _contactName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    context.l10n.online,
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Message list
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: isDark
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                              : Theme.of(context).colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                        ),
                        AppSpacing.gapH16,
                        Text(
                          context.l10n.noMessagesYet,
                          style: TextStyle(
                            color: isDark
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 16,
                          ),
                        ),
                        AppSpacing.gapH4,
                        Text(
                          context.l10n.noMessagesHint,
                          style: TextStyle(
                            color: isDark
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.7)
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isSent = message.senderId == _currentUserId;
                      final showDateHeader = index == 0 ||
                          !_isSameDay(
                            _messages[index - 1].timestamp,
                            message.timestamp,
                          );

                      return Column(
                        children: [
                          if (showDateHeader)
                            _buildDateHeader(message.timestamp, isDark),
                          _buildMessageBubble(message, isSent, isDark),
                        ],
                      );
                    },
                  ),
          ),

          // Input area
          _buildInputArea(isDark),
        ],
      ),
    );
  }

  Widget _buildDateHeader(DateTime date, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: AppSpacing.roundedSm,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
          ),
        ],
      ),
      child: Text(
        _formatDateHeader(date),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color:
              isDark ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    ChatMessage message,
    bool isSent,
    bool isDark,
  ) {
    final bubbleColor = isSent
        ? (isDark ? context.palette.success : context.palette.success.withValues(alpha: 0.4))
        : (isDark ? Theme.of(context).colorScheme.surface : Colors.white);

    final textColor =
        isDark ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface;

    final timeColor =
        isDark ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.onSurfaceVariant;

    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: AppSpacing.borderRadiusMd,
            topRight: AppSpacing.borderRadiusMd,
            bottomLeft: Radius.circular(isSent ? AppSpacing.radiusMd : 2),
            bottomRight: Radius.circular(isSent ? 2 : AppSpacing.radiusMd),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (message.type == ChatMessageType.profileShare &&
                message.profileId != null)
              _buildProfileShareCard(message, isSent, textColor),
            if (message.content.isNotEmpty)
              Text(
                message.content,
                style: TextStyle(
                  fontSize: 15,
                  color: textColor,
                  height: 1.3,
                ),
              ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat.jm().format(message.timestamp),
                  style: TextStyle(fontSize: 11, color: timeColor),
                ),
                if (isSent) ...[
                  const SizedBox(width: 3),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 16,
                    color: message.isRead ? context.palette.success : timeColor,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Opens a picker so the user can share a candidate profile into the chat.
  /// Brokers share from their managed roster; others share profiles that were
  /// shared with them (forwarding). Sending also records a [SharedProfile] for
  /// brokers so the share is tracked in the Client Hub.
  Future<void> _shareProfileFromChat() async {
    final auth = ref.read(authProvider);
    if (auth is! AuthAuthenticated || _currentUserId == null) return;

    final messaging = ref.read(messagingRepositoryProvider);
    final conversation = await messaging.getConversation(_conversationId);
    if (conversation == null) return;
    final recipientId = conversation.participantIds
        .where((id) => id != _currentUserId)
        .firstOrNull;
    if (recipientId == null) return;

    final profileRepo = ref.read(profileRepositoryProvider);
    final isBroker = auth.user.role == UserRole.broker;
    List<CandidateProfile> options;
    if (isBroker) {
      options = await profileRepo.getCandidatesByBroker(_currentUserId!);
    } else {
      final shared = await ref
          .read(sharedProfileRepositoryProvider)
          .getSharedProfilesForUser(_currentUserId!);
      final list = <CandidateProfile>[];
      for (final s in shared) {
        final p = await profileRepo.getCandidateProfile(s.profileId);
        if (p != null) list.add(p);
      }
      options = list;
    }

    if (!mounted) return;
    final picked = await showModalBottomSheet<CandidateProfile>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _ChatProfilePickSheet(profiles: options),
    );
    if (picked == null) return;

    await messaging.sendMessage(
      conversationId: _conversationId,
      senderId: _currentUserId!,
      recipientId: recipientId,
      content: 'Sharing ${picked.name}\'s profile.',
      type: ChatMessageType.profileShare,
      profileId: picked.id,
    );
    if (isBroker) {
      await ref.read(sharedProfileRepositoryProvider).shareProfile(
            profileId: picked.id,
            sharedByUserId: _currentUserId!,
            sharedWithUserId: recipientId,
          );
    }

    await _loadMessages();
  }

  Widget _buildProfileShareCard(
    ChatMessage message,
    bool isSent,
    Color textColor,
  ) {
    final profile = _sharedProfiles[message.profileId];
    final colors = Theme.of(context).colorScheme;
    final hasPhoto =
        profile != null && profile.photos.isNotEmpty &&
            profile.photos.first.startsWith('http');

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: colors.surface,
        borderRadius: AppSpacing.roundedMd,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: profile == null
              ? null
              : () => context.pushNamed(
                    RouteNames.profileView,
                    pathParameters: {'id': profile.id},
                  ),
          child: Container(
            width: 230,
            decoration: BoxDecoration(
              borderRadius: AppSpacing.roundedMd,
              border: Border.all(color: colors.outlineVariant, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo / banner
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: hasPhoto
                      ? Image.network(
                          profile.photos.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _shareFallback(profile, colors),
                        )
                      : _shareFallback(profile, colors),
                ),
                Padding(
                  padding: AppSpacing.allSm,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.badge_outlined,
                              size: 13, color: colors.primary),
                          const SizedBox(width: 4),
                          Text('Shared profile',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colors.primary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile == null
                            ? 'Profile unavailable'
                            : '${profile.name}, ${profile.age}',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (profile != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          [profile.profession, profile.city]
                              .where((s) => s.isNotEmpty)
                              .join(' · '),
                          style: TextStyle(
                              fontSize: 12, color: colors.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text('View profile',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colors.primary)),
                            Icon(Icons.chevron_right,
                                size: 16, color: colors.primary),
                          ],
                        ),
                      ],
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

  Widget _shareFallback(CandidateProfile? profile, ColorScheme colors) {
    return Container(
      color: colors.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Text(
        profile != null && profile.name.isNotEmpty
            ? profile.name[0].toUpperCase()
            : '?',
        style: TextStyle(
            fontSize: 40, fontWeight: FontWeight.w700, color: colors.primary),
      ),
    );
  }

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      color: isDark ? Theme.of(context).colorScheme.surfaceContainerHighest : Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Share a profile',
              icon: Icon(
                Icons.add,
                color: isDark
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              onPressed: _shareProfileFromChat,
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: AppSpacing.roundedXxl,
                ),
                child: Row(
                  children: [
                    AppSpacing.gapW12,
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 4,
                        minLines: 1,
                        style: TextStyle(
                          color: isDark
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: context.l10n.typeAMessage,
                          hintStyle: TextStyle(
                            color: isDark
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.camera_alt_outlined,
                        color: isDark
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.gapW4,
            Container(
              decoration: BoxDecoration(
                color: context.palette.success,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon:
                    const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'Today';

    final yesterday = now.subtract(const Duration(days: 1));
    if (_isSameDay(date, yesterday)) return 'Yesterday';

    return DateFormat('MMMM d, y').format(date);
  }
}

/// Bottom sheet to pick a candidate profile to share into a chat.
class _ChatProfilePickSheet extends StatelessWidget {
  const _ChatProfilePickSheet({required this.profiles});
  final List<CandidateProfile> profiles;

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
            if (profiles.isEmpty)
              Padding(
                padding: AppSpacing.allMd,
                child: Text('No profiles available to share.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: colors.onSurfaceVariant)),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: profiles.length,
                  itemBuilder: (ctx, i) {
                    final p = profiles[i];
                    final hasPhoto = p.photos.isNotEmpty &&
                        p.photos.first.startsWith('http');
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colors.surfaceContainerHighest,
                        backgroundImage:
                            hasPhoto ? NetworkImage(p.photos.first) : null,
                        child: hasPhoto
                            ? null
                            : Text(p.name.isNotEmpty ? p.name[0] : '?'),
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
