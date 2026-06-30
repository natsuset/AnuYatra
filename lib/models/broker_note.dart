/// A broker's note on a candidate profile, surfaced to the linked parent
/// on the profile detail page (§1.12 item 8).
///
/// One note per `(brokerId, profileId, parentId)` so different parents can
/// see different broker remarks tailored for them. Editable by the broker
/// from their `broker_clients_screen` view of the same profile.
class BrokerNote {
  /// Composite id `{brokerId}_{profileId}_{parentId}`.
  final String id;
  final String brokerUserId;
  final String candidateProfileId;
  final String forParentUserId;
  final String body;
  final DateTime updatedAt;

  const BrokerNote({
    required this.id,
    required this.brokerUserId,
    required this.candidateProfileId,
    required this.forParentUserId,
    required this.body,
    required this.updatedAt,
  });

  factory BrokerNote.create({
    required String brokerUserId,
    required String candidateProfileId,
    required String forParentUserId,
    required String body,
    DateTime? updatedAt,
  }) {
    return BrokerNote(
      id: '${brokerUserId}_${candidateProfileId}_$forParentUserId',
      brokerUserId: brokerUserId,
      candidateProfileId: candidateProfileId,
      forParentUserId: forParentUserId,
      body: body,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  BrokerNote copyWith({String? body, DateTime? updatedAt}) {
    return BrokerNote(
      id: id,
      brokerUserId: brokerUserId,
      candidateProfileId: candidateProfileId,
      forParentUserId: forParentUserId,
      body: body ?? this.body,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'brokerUserId': brokerUserId,
        'candidateProfileId': candidateProfileId,
        'forParentUserId': forParentUserId,
        'body': body,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory BrokerNote.fromJson(Map<String, dynamic> json) {
    return BrokerNote(
      id: json['id'] as String? ?? '',
      brokerUserId: json['brokerUserId'] as String? ?? '',
      candidateProfileId: json['candidateProfileId'] as String? ?? '',
      forParentUserId: json['forParentUserId'] as String? ?? '',
      body: json['body'] as String? ?? '',
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
