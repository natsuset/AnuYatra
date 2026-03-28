enum LinkRequestType {
  parentToBroker,
  parentToAgency,
  agencyToBroker,
  childToParent;

  String get displayName {
    switch (this) {
      case LinkRequestType.parentToBroker:
        return 'Connection Request';
      case LinkRequestType.parentToAgency:
        return 'Agency Connection';
      case LinkRequestType.agencyToBroker:
        return 'Agency Invite';
      case LinkRequestType.childToParent:
        return 'Family Link';
    }
  }
}

enum LinkRequestStatus {
  pending,
  accepted,
  declined;

  String get displayName {
    switch (this) {
      case LinkRequestStatus.pending:
        return 'Pending';
      case LinkRequestStatus.accepted:
        return 'Accepted';
      case LinkRequestStatus.declined:
        return 'Declined';
    }
  }
}

class LinkRequest {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String fromUserName;
  final String toUserName;
  final LinkRequestType type;
  final LinkRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? note;

  const LinkRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.fromUserName,
    required this.toUserName,
    required this.type,
    this.status = LinkRequestStatus.pending,
    required this.createdAt,
    this.respondedAt,
    this.note,
  });

  bool get isPending => status == LinkRequestStatus.pending;

  Map<String, dynamic> toJson() => {
    'id': id,
    'fromUserId': fromUserId,
    'toUserId': toUserId,
    'fromUserName': fromUserName,
    'toUserName': toUserName,
    'type': type.name,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'respondedAt': respondedAt?.toIso8601String(),
    'note': note,
  };

  factory LinkRequest.fromJson(Map<String, dynamic> json) => LinkRequest(
    id: json['id'] as String? ?? '',
    fromUserId: json['fromUserId'] as String? ?? '',
    toUserId: json['toUserId'] as String? ?? '',
    fromUserName: json['fromUserName'] as String? ?? '',
    toUserName: json['toUserName'] as String? ?? '',
    type: LinkRequestType.values.firstWhere(
      (e) => e.name == (json['type'] as String?),
      orElse: () => LinkRequestType.parentToBroker,
    ),
    status: LinkRequestStatus.values.firstWhere(
      (e) => e.name == (json['status'] as String?),
      orElse: () => LinkRequestStatus.pending,
    ),
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    respondedAt: json['respondedAt'] != null ? DateTime.parse(json['respondedAt'] as String) : null,
    note: json['note'] as String?,
  );

  LinkRequest copyWith({
    LinkRequestStatus? status,
    DateTime? respondedAt,
    String? note,
  }) => LinkRequest(
    id: id,
    fromUserId: fromUserId,
    toUserId: toUserId,
    fromUserName: fromUserName,
    toUserName: toUserName,
    type: type,
    status: status ?? this.status,
    createdAt: createdAt,
    respondedAt: respondedAt ?? this.respondedAt,
    note: note ?? this.note,
  );
}
