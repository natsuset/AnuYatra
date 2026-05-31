enum ChatMessageType {
  text,
  profileShare,
  image,
  system;

  String get displayName {
    switch (this) {
      case ChatMessageType.text:
        return 'Text';
      case ChatMessageType.profileShare:
        return 'Profile Share';
      case ChatMessageType.image:
        return 'Image';
      case ChatMessageType.system:
        return 'System';
    }
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String recipientId;
  final String content;
  final ChatMessageType type;
  final DateTime timestamp;
  final bool isRead;
  final String? profileId;
  final String? attachmentUrl;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.recipientId,
    required this.content,
    this.type = ChatMessageType.text,
    required this.timestamp,
    this.isRead = false,
    this.profileId,
    this.attachmentUrl,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversationId': conversationId,
    'senderId': senderId,
    'recipientId': recipientId,
    'content': content,
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
    'profileId': profileId,
    'attachmentUrl': attachmentUrl,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String? ?? '',
    conversationId: json['conversationId'] as String? ?? '',
    senderId: json['senderId'] as String? ?? '',
    recipientId: json['recipientId'] as String? ?? '',
    content: json['content'] as String? ?? '',
    type: ChatMessageType.values.firstWhere(
      (e) => e.name == (json['type'] as String?),
      orElse: () => ChatMessageType.text,
    ),
    timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
    isRead: json['isRead'] as bool? ?? false,
    profileId: json['profileId'] as String?,
    attachmentUrl: json['attachmentUrl'] as String?,
  );

  ChatMessage copyWith({
    bool? isRead,
  }) => ChatMessage(
    id: id,
    conversationId: conversationId,
    senderId: senderId,
    recipientId: recipientId,
    content: content,
    type: type,
    timestamp: timestamp,
    isRead: isRead ?? this.isRead,
    profileId: profileId,
    attachmentUrl: attachmentUrl,
  );
}

class Conversation {
  final String id;
  final List<String> participantIds;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const Conversation({
    required this.id,
    required this.participantIds,
    this.lastMessagePreview,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'participantIds': participantIds,
    'lastMessagePreview': lastMessagePreview,
    'lastMessageAt': lastMessageAt?.toIso8601String(),
    'unreadCount': unreadCount,
  };

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id: json['id'] as String? ?? '',
    participantIds: (json['participantIds'] as List<dynamic>?)?.cast<String>() ?? [],
    lastMessagePreview: json['lastMessagePreview'] as String?,
    lastMessageAt: json['lastMessageAt'] != null
        ? DateTime.parse(json['lastMessageAt'] as String)
        : null,
    unreadCount: json['unreadCount'] as int? ?? 0,
  );

  Conversation copyWith({
    String? lastMessagePreview,
    DateTime? lastMessageAt,
    int? unreadCount,
  }) => Conversation(
    id: id,
    participantIds: participantIds,
    lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
    lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    unreadCount: unreadCount ?? this.unreadCount,
  );
}
