import 'dart:convert';

import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

import 'package:testing_flutter/core/data/repositories/messaging_repository.dart';
import 'package:testing_flutter/models/chat_message.dart';

const _uuid = Uuid();

/// Hive-backed implementation of [MessagingRepository].
///
/// Messages are stored per-conversation as a JSON array. The format
/// will be migrated to individual keys in a later phase (see PLAN_DELTA §1.2).
class HiveMessagingRepository implements MessagingRepository {
  final Box<String> _conversations;
  final Box<String> _messages;

  HiveMessagingRepository({
    required Box<String> conversationsBox,
    required Box<String> messagesBox,
  })  : _conversations = conversationsBox,
        _messages = messagesBox;

  @override
  Future<String> getOrCreateConversation(
      String userId1, String userId2) async {
    final existing = (await getAllConversations()).where((c) =>
        c.participantIds.contains(userId1) &&
        c.participantIds.contains(userId2)).firstOrNull;

    if (existing != null) return existing.id;

    final id = _uuid.v4();
    final conversation = Conversation(
      id: id,
      participantIds: [userId1, userId2],
    );
    await _conversations.put(id, jsonEncode(conversation.toJson()));
    return id;
  }

  @override
  Future<Conversation?> getConversation(String id) async {
    final raw = _conversations.get(id);
    if (raw == null) return null;
    return Conversation.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<List<Conversation>> getConversationsForUser(
    String userId, {
    int? limit,
    int? offset,
  }) async {
    var results = (await getAllConversations())
        .where((c) => c.participantIds.contains(userId))
        .toList()
      ..sort((a, b) {
        final aTime = a.lastMessageAt ?? DateTime(2000);
        final bTime = b.lastMessageAt ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });

    if (offset != null && offset > 0) {
      results = results.skip(offset).toList();
    }
    if (limit != null && limit > 0) {
      results = results.take(limit).toList();
    }

    return results;
  }

  @override
  Future<List<Conversation>> getAllConversations({
    int? limit,
    int? offset,
  }) async {
    var results = _conversations.values
        .map((raw) =>
            Conversation.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList();

    if (offset != null && offset > 0) {
      results = results.skip(offset).toList();
    }
    if (limit != null && limit > 0) {
      results = results.take(limit).toList();
    }

    return results;
  }

  @override
  Future<void> saveConversation(Conversation conversation) async {
    await _conversations.put(
        conversation.id, jsonEncode(conversation.toJson()));
  }

  @override
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String senderId,
    required String recipientId,
    required String content,
    ChatMessageType type = ChatMessageType.text,
    String? profileId,
  }) async {
    final id = _uuid.v4();
    final message = ChatMessage(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      recipientId: recipientId,
      content: content,
      type: type,
      timestamp: DateTime.now(),
      profileId: profileId,
    );
    await _saveMessage(message);

    final conv = await getConversation(conversationId);
    if (conv != null) {
      final updated = conv.copyWith(
        lastMessagePreview: content,
        lastMessageAt: message.timestamp,
        unreadCount: conv.unreadCount + 1,
      );
      await _conversations.put(
          conversationId, jsonEncode(updated.toJson()));
    }

    return message;
  }

  @override
  Future<void> saveMessage(ChatMessage message) async {
    await _saveMessage(message);
  }

  static String _msgKey(String convId, String msgId) => '${convId}_$msgId';
  static String _idxKey(String convId) => '_idx_$convId';

  Future<void> _saveMessage(ChatMessage message) async {
    await _messages.put(
      _msgKey(message.conversationId, message.id),
      jsonEncode(message.toJson()),
    );
    await _appendToIndex(message.conversationId, message.id);
  }

  Future<void> _appendToIndex(String conversationId, String messageId) async {
    final key = _idxKey(conversationId);
    final raw = _messages.get(key);
    final List<String> ids = raw != null
        ? (jsonDecode(raw) as List<dynamic>).cast<String>()
        : [];
    ids.add(messageId);
    await _messages.put(key, jsonEncode(ids));
  }

  List<String> _readIndex(String conversationId) {
    final raw = _messages.get(_idxKey(conversationId));
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>).cast<String>();
  }

  @override
  Future<List<ChatMessage>> getMessages(
    String conversationId, {
    int? limit,
    int? offset,
  }) async {
    final ids = _readIndex(conversationId);
    if (ids.isEmpty) return [];

    final messages = <ChatMessage>[];
    for (final id in ids) {
      final raw = _messages.get(_msgKey(conversationId, id));
      if (raw != null) {
        messages
            .add(ChatMessage.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      }
    }
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    var results = messages;
    if (offset != null && offset > 0) {
      results = results.skip(offset).toList();
    }
    if (limit != null && limit > 0) {
      results = results.take(limit).toList();
    }

    return results;
  }

  @override
  Future<void> markMessagesAsRead(
      String conversationId, String userId) async {
    final ids = _readIndex(conversationId);
    for (final id in ids) {
      final key = _msgKey(conversationId, id);
      final raw = _messages.get(key);
      if (raw == null) continue;
      final msg =
          ChatMessage.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      if (msg.recipientId == userId && !msg.isRead) {
        final updated = msg.copyWith(isRead: true);
        await _messages.put(key, jsonEncode(updated.toJson()));
      }
    }

    final conv = await getConversation(conversationId);
    if (conv != null) {
      await _conversations.put(
        conversationId,
        jsonEncode(conv.copyWith(unreadCount: 0).toJson()),
      );
    }
  }
}
