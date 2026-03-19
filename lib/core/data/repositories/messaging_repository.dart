import 'package:testing_flutter/models/chat_message.dart';

/// Contract for conversations and messages.
abstract class MessagingRepository {
  /// Get or create a conversation between two users. Returns the conversation ID.
  Future<String> getOrCreateConversation(String userId1, String userId2);

  /// Get a conversation by its unique ID.
  Future<Conversation?> getConversation(String id);

  /// Get conversations for a user, sorted by most recent message.
  Future<List<Conversation>> getConversationsForUser(
    String userId, {
    int? limit,
    int? offset,
  });

  /// Get all conversations, with optional pagination.
  Future<List<Conversation>> getAllConversations({int? limit, int? offset});

  /// Persist a conversation (create or update, used for seeding).
  Future<void> saveConversation(Conversation conversation);

  /// Send a new message, updating the conversation's last message metadata.
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String senderId,
    required String recipientId,
    required String content,
    ChatMessageType type = ChatMessageType.text,
    String? profileId,
  });

  /// Persist a message directly (used for seeding).
  Future<void> saveMessage(ChatMessage message);

  /// Get messages for a conversation, sorted chronologically.
  Future<List<ChatMessage>> getMessages(
    String conversationId, {
    int? limit,
    int? offset,
  });

  /// Mark all messages in a conversation as read for a specific recipient.
  Future<void> markMessagesAsRead(String conversationId, String userId);
}
