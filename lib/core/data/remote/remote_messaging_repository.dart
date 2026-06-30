import 'package:testing_flutter/core/data/remote/api_client.dart';
import 'package:testing_flutter/core/data/repositories/messaging_repository.dart';
import 'package:testing_flutter/core/errors/app_exceptions.dart';
import 'package:testing_flutter/models/chat_message.dart';

class RemoteMessagingRepository implements MessagingRepository {
  final ApiClient _api;

  RemoteMessagingRepository(this._api);

  @override
  Future<String> getOrCreateConversation(
    String userId1,
    String userId2,
  ) async {
    final data = await _api.post('/api/v1/conversations', body: {
      'otherUserId': userId2,
    });
    return data['id'] as String;
  }

  @override
  Future<Conversation?> getConversation(String id) async {
    try {
      final data = await _api.get('/api/v1/conversations/$id');
      return Conversation.fromJson(data);
    } on NotFoundException {
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Conversation>> getConversationsForUser(
    String userId, {
    int? limit,
    int? offset,
  }) async {
    final params = <String, String>{};
    if (limit != null) params['limit'] = '$limit';
    if (offset != null) params['offset'] = '$offset';
    final data = await _api.get('/api/v1/conversations', queryParams: params);
    final items = data['data'] as List<dynamic>? ?? [];
    return items
        .cast<Map<String, dynamic>>()
        .map(Conversation.fromJson)
        .toList(growable: false);
  }

  @override
  Future<List<Conversation>> getAllConversations({
    int? limit,
    int? offset,
  }) async {
    return getConversationsForUser('', limit: limit, offset: offset);
  }

  @override
  Future<void> saveConversation(Conversation conversation) async {}

  @override
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String senderId,
    required String recipientId,
    required String content,
    ChatMessageType type = ChatMessageType.text,
    String? profileId,
  }) async {
    final data = await _api.post(
      '/api/v1/conversations/$conversationId/messages',
      body: {
        'content': content,
        'type': type.name,
        'recipientId': recipientId,
        'profileId': profileId,
      },
    );
    return ChatMessage.fromJson(data);
  }

  @override
  Future<void> saveMessage(ChatMessage message) async {}

  @override
  Future<List<ChatMessage>> getMessages(
    String conversationId, {
    int? limit,
    int? offset,
  }) async {
    final params = <String, String>{};
    if (limit != null) params['limit'] = '$limit';
    if (offset != null) params['offset'] = '$offset';
    final data = await _api.get(
      '/api/v1/conversations/$conversationId/messages',
      queryParams: params,
    );
    final items = data['data'] as List<dynamic>? ?? [];
    return items
        .cast<Map<String, dynamic>>()
        .map(ChatMessage.fromJson)
        .toList(growable: false);
  }

  @override
  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    await _api.post('/api/v1/conversations/$conversationId/read');
  }
}
