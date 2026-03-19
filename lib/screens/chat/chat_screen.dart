import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/models/chat_message.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  String? _currentUserId;
  String _contactName = 'Chat';

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
    if (!mounted) return;
    setState(() {
      _messages = messages;
    });

    _scrollToBottom();
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
          isDark ? AppColors.chatDarkBackground : AppColors.chatLightBackground,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.chatDarkBubble : AppColors.chatDarkGreen,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.chatGreen.withValues(alpha: 0.3),
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
                  const Text(
                    'online',
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
                              ? AppColors.chatDarkGray
                              : AppColors.chatDarkGray
                                  .withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.chatDarkGray
                                : AppColors.lightSecondaryText,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Send a message to start the conversation',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.chatDarkGray
                                    .withValues(alpha: 0.7)
                                : AppColors.lightTertiaryText,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
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
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.chatDarkBubble.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
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
              isDark ? AppColors.chatDarkGray : AppColors.lightSecondaryText,
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
        ? (isDark ? AppColors.chatDarkSentBubble : AppColors.chatLightGreen)
        : (isDark ? AppColors.chatDarkBubble : Colors.white);

    final textColor =
        isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;

    final timeColor =
        isDark ? AppColors.chatDarkGray : AppColors.lightTertiaryText;

    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isSent ? 12 : 2),
            bottomRight: Radius.circular(isSent ? 2 : 12),
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
                    color: message.isRead ? AppColors.chatGreen : timeColor,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      color: isDark ? AppColors.chatDarkInput : AppColors.lightSurface,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.add,
                color: isDark
                    ? AppColors.chatDarkGray
                    : AppColors.lightSecondaryText,
              ),
              onPressed: () {},
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.chatDarkInputField
                      : AppColors.chatLightInputField,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 4,
                        minLines: 1,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.lightPrimaryText,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type a message',
                          hintStyle: TextStyle(
                            color: isDark
                                ? AppColors.chatDarkGray
                                : AppColors.lightTertiaryText,
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
                            ? AppColors.chatDarkGray
                            : AppColors.lightSecondaryText,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              decoration: const BoxDecoration(
                color: AppColors.chatDarkGreen,
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
