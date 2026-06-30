/// A broker's follow-up / reminder task.
///
/// Optionally tied to a client (parent) and/or a specific candidate profile,
/// so a broker can track "call Ramesh about Rahul's profile on Friday".
/// Demo/seed-driven; no push notifications — surfaced in-app on the dashboard.
enum FollowUpPriority {
  low,
  normal,
  high;

  String get displayName => switch (this) {
        FollowUpPriority.low => 'Low',
        FollowUpPriority.normal => 'Normal',
        FollowUpPriority.high => 'High',
      };
}

class BrokerFollowUp {
  final String id;
  final String brokerUserId;

  /// The parent client this follow-up is about (optional — general tasks
  /// leave this null).
  final String? clientUserId;

  /// A specific candidate profile this follow-up references (optional).
  final String? candidateProfileId;

  final String title;
  final String notes;
  final DateTime dueAt;
  final FollowUpPriority priority;
  final bool isDone;
  final DateTime createdAt;
  final DateTime? completedAt;

  const BrokerFollowUp({
    required this.id,
    required this.brokerUserId,
    this.clientUserId,
    this.candidateProfileId,
    required this.title,
    this.notes = '',
    required this.dueAt,
    this.priority = FollowUpPriority.normal,
    this.isDone = false,
    required this.createdAt,
    this.completedAt,
  });

  bool get isOverdue => !isDone && dueAt.isBefore(DateTime.now());

  bool get isDueToday {
    final now = DateTime.now();
    return !isDone &&
        dueAt.year == now.year &&
        dueAt.month == now.month &&
        dueAt.day == now.day;
  }

  BrokerFollowUp copyWith({
    String? clientUserId,
    String? candidateProfileId,
    String? title,
    String? notes,
    DateTime? dueAt,
    FollowUpPriority? priority,
    bool? isDone,
    DateTime? completedAt,
  }) {
    return BrokerFollowUp(
      id: id,
      brokerUserId: brokerUserId,
      clientUserId: clientUserId ?? this.clientUserId,
      candidateProfileId: candidateProfileId ?? this.candidateProfileId,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      dueAt: dueAt ?? this.dueAt,
      priority: priority ?? this.priority,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'brokerUserId': brokerUserId,
        'clientUserId': clientUserId,
        'candidateProfileId': candidateProfileId,
        'title': title,
        'notes': notes,
        'dueAt': dueAt.toIso8601String(),
        'priority': priority.name,
        'isDone': isDone,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory BrokerFollowUp.fromJson(Map<String, dynamic> json) {
    return BrokerFollowUp(
      id: json['id'] as String? ?? '',
      brokerUserId: json['brokerUserId'] as String? ?? '',
      clientUserId: json['clientUserId'] as String?,
      candidateProfileId: json['candidateProfileId'] as String?,
      title: json['title'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      dueAt: DateTime.tryParse(json['dueAt'] as String? ?? '') ??
          DateTime.now(),
      priority: FollowUpPriority.values.firstWhere(
        (e) => e.name == (json['priority'] as String?),
        orElse: () => FollowUpPriority.normal,
      ),
      isDone: json['isDone'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.tryParse(json['completedAt'] as String),
    );
  }
}
