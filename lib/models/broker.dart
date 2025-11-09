class Broker {
  final String id;
  final String name;
  final String phoneNumber;
  final String profilePhoto;
  final String agencyName;
  final String agencyLogo;
  final bool isOnline;
  final DateTime lastSeen;

  Broker({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.profilePhoto,
    required this.agencyName,
    required this.agencyLogo,
    this.isOnline = true,
    required this.lastSeen,
  });

  String get displayName => name;
  String get statusText =>
      isOnline ? 'Online' : 'Last seen ${_formatLastSeen()}';

  String _formatLastSeen() {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String content;
  final ChatMessageType type;
  final DateTime timestamp;
  final bool isRead;
  final dynamic profile; // For profile-related messages

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.profile,
  });

  bool get isSentByBroker => senderId != 'parent';
}

enum ChatMessageType {
  text,
  profile,
  voice,
  image,
  action, // For user actions like interested, not match, etc.
}

class Notification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final NotificationType type;

  Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    required this.type,
  });
}

enum NotificationType {
  newProfiles,
  mutualInterest,
  brokerMessage,
  statusUpdate,
}
