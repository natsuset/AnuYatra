import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:testing_flutter/models/broker.dart';
import 'package:testing_flutter/theme/app_theme.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/theme/theme_extensions.dart';
import 'package:testing_flutter/widgets/chat_bubble.dart';
import 'package:testing_flutter/widgets/profile_message_card.dart';
import 'package:testing_flutter/data/mock_data.dart';

class BrokerScreen extends ConsumerStatefulWidget {
  final Broker broker;

  const BrokerScreen({super.key, required this.broker});

  @override
  ConsumerState<BrokerScreen> createState() => _BrokerScreenState();
}

class _BrokerScreenState extends ConsumerState<BrokerScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> messages = MockData.getChatMessages();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get WhatsApp-like chat background color based on theme
    final isDark = context.isDarkMode;
    final chatBackgroundColor = isDark
        ? AppColors.chatDarkBackground // WhatsApp dark mode background
        : AppColors.chatLightBackground; // WhatsApp light mode background

    return Scaffold(
      backgroundColor: chatBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarBackground(context),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.whatsAppGray,
              backgroundImage: widget.broker.profilePhoto.isNotEmpty
                  ? CachedNetworkImageProvider(widget.broker.profilePhoto)
                  : null,
              child: widget.broker.profilePhoto.isEmpty
                  ? const Icon(Icons.person, size: 24, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.broker.displayName,
                    style: Theme.of(
                      context,
                    ).appBarTheme.titleTextStyle?.copyWith(fontSize: 16),
                  ),
                  Row(
                    children: [
                      Icon(
                        widget.broker.isOnline ? Icons.circle : Icons.schedule,
                        size: 12,
                        color: widget.broker.isOnline
                            ? AppTheme.statusGreen
                            : Colors.white.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.broker.statusText,
                          style: Theme.of(context).appBarTheme.titleTextStyle
                              ?.copyWith(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              // TODO: Implement video call
            },
          ),
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () => _makePhoneCall(),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Text('View Broker Profile'),
              ),
              const PopupMenuItem(
                value: 'mute',
                child: Text('Mute Notifications'),
              ),
              const PopupMenuItem(value: 'clear', child: Text('Clear Chat')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return _buildMessageItem(message);
              },
            ),
          ),

          // Message input area
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage message) {
    if (message.type == ChatMessageType.profile && message.profile != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            if (!message.isSentByBroker) const Spacer(),
            ProfileMessageCard(
              profile: message.profile!,
              timestamp: message.timestamp,
              isSentByBroker: message.isSentByBroker,
              broker: widget.broker,
            ),
            if (message.isSentByBroker) const Spacer(),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          if (!message.isSentByBroker) ...[
            const Spacer(),
            Flexible(
              child: ChatBubble(
                message: message.content,
                isSentByUser: !message.isSentByBroker,
                timestamp: message.timestamp,
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.sacredSaffron,
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ] else ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.whatsAppGray,
              backgroundImage: widget.broker.profilePhoto.isNotEmpty
                  ? CachedNetworkImageProvider(widget.broker.profilePhoto)
                  : null,
              child: widget.broker.profilePhoto.isEmpty
                  ? const Icon(Icons.person, size: 18, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: ChatBubble(
                message: message.content,
                isSentByUser: !message.isSentByBroker,
                timestamp: message.timestamp,
              ),
            ),
            const Spacer(),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final isDark = context.isDarkMode;
    final inputBackgroundColor = isDark
        ? AppColors.chatDarkInput // WhatsApp dark input background
        : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: inputBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Voice note button
              Container(
                decoration: const BoxDecoration(
                  color: AppTheme.sacredSaffron,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.mic, color: Colors.white),
                  onPressed: () {
                    // TODO: Implement voice note recording
                    _showVoiceNoteDialog();
                  },
                ),
              ),

              const SizedBox(width: 12),

              // Text input
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.lightPrimaryText,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.black.withValues(alpha: 0.5),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.chatDarkInputField // Dark mode input field
                        : AppColors.chatLightInputField, // Light mode input field
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (text) => _sendMessage(text),
                ),
              ),

              const SizedBox(width: 12),

              // Send button
              Container(
                decoration: const BoxDecoration(
                  color: AppTheme.sacredSaffron,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: () => _sendMessage(_messageController.text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'parent',
      content: text.trim(),
      type: ChatMessageType.text,
      timestamp: DateTime.now(),
      isRead: false,
    );

    setState(() {
      messages.add(newMessage);
      _messageController.clear();
    });

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    // Simulate broker response after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        final response = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: 'broker',
          content: 'Thank you for your message. I\'ll get back to you shortly.',
          type: ChatMessageType.text,
          timestamp: DateTime.now(),
          isRead: false,
        );

        setState(() {
          messages.add(response);
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    });
  }

  void _makePhoneCall() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call Broker'),
        content: Text(
          'Call ${widget.broker.displayName} at ${widget.broker.phoneNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement actual phone call
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Calling ${widget.broker.displayName}...'),
                  backgroundColor: AppTheme.statusGreen,
                ),
              );
            },
            child: const Text('Call'),
          ),
        ],
      ),
    );
  }

  void _showVoiceNoteDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.mic, size: 64, color: AppTheme.sacredSaffron),
              const SizedBox(height: 16),
              const Text(
                'Voice Note Recording',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Hold to record, release to send',
                style: TextStyle(color: AppTheme.secondaryText(context)),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Implement voice recording
                    },
                    child: const Text('Start Recording'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
