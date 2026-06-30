/// Who scheduled the meeting (drives the visibility rules below).
enum MeetingScheduledBy { parent, candidate, broker }

/// Where / how the meeting happens.
enum MeetingType { inPerson, virtual, phone }

/// Status of the meeting.
enum MeetingStatus { scheduled, completed, cancelled }

/// A meeting scheduled around a specific candidate profile + parent + broker
/// triple.
///
/// **Three-way visibility (decision in PRODUCT_PLAN §1.12 item 6).**
/// Visibility depends on who scheduled it:
///
/// - **Broker-scheduled** → visible to all three parties (broker + parent +
///   candidate). Both [brokerVisible] and [parentPartyVisible] true.
/// - **Parent- or candidate-scheduled** → visible only to the parent+candidate
///   "party" (broker doesn't see it). Only [parentPartyVisible] true.
class Meeting {
  final String id;
  final String candidateProfileId;
  final String parentUserId;
  final String brokerUserId;

  /// User id of whoever created the record.
  final String scheduledByUserId;
  final MeetingScheduledBy scheduledByRole;

  /// Visibility flags computed at write time from [scheduledByRole]:
  /// `brokerVisible = scheduledByRole == broker`,
  /// `parentPartyVisible = true` (always, since the parent party always
  /// sees their own scheduling AND broker-scheduled meetings).
  final bool brokerVisible;
  final bool parentPartyVisible;

  final DateTime when;
  final int durationMinutes;
  final MeetingType type;
  final String location;

  /// Join link for virtual meetings (Zoom / Meet / etc.). `null` otherwise.
  final String? virtualLink;

  final MeetingStatus status;
  final String? notes;
  final DateTime createdAt;

  const Meeting({
    required this.id,
    required this.candidateProfileId,
    required this.parentUserId,
    required this.brokerUserId,
    required this.scheduledByUserId,
    required this.scheduledByRole,
    required this.brokerVisible,
    required this.parentPartyVisible,
    required this.when,
    required this.durationMinutes,
    required this.type,
    required this.location,
    required this.status,
    required this.createdAt,
    this.virtualLink,
    this.notes,
  });

  /// Construct + auto-derive visibility flags from [scheduledByRole].
  factory Meeting.create({
    required String id,
    required String candidateProfileId,
    required String parentUserId,
    required String brokerUserId,
    required String scheduledByUserId,
    required MeetingScheduledBy scheduledByRole,
    required DateTime when,
    int durationMinutes = 30,
    MeetingType type = MeetingType.virtual,
    String location = '',
    String? virtualLink,
    String? notes,
    MeetingStatus status = MeetingStatus.scheduled,
    DateTime? createdAt,
  }) {
    final brokerVisible = scheduledByRole == MeetingScheduledBy.broker;
    const parentPartyVisible = true;
    return Meeting(
      id: id,
      candidateProfileId: candidateProfileId,
      parentUserId: parentUserId,
      brokerUserId: brokerUserId,
      scheduledByUserId: scheduledByUserId,
      scheduledByRole: scheduledByRole,
      brokerVisible: brokerVisible,
      parentPartyVisible: parentPartyVisible,
      when: when,
      durationMinutes: durationMinutes,
      type: type,
      location: location,
      virtualLink: virtualLink,
      notes: notes,
      status: status,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  Meeting copyWith({
    DateTime? when,
    int? durationMinutes,
    MeetingType? type,
    String? location,
    String? virtualLink,
    MeetingStatus? status,
    String? notes,
  }) {
    return Meeting(
      id: id,
      candidateProfileId: candidateProfileId,
      parentUserId: parentUserId,
      brokerUserId: brokerUserId,
      scheduledByUserId: scheduledByUserId,
      scheduledByRole: scheduledByRole,
      brokerVisible: brokerVisible,
      parentPartyVisible: parentPartyVisible,
      when: when ?? this.when,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      type: type ?? this.type,
      location: location ?? this.location,
      virtualLink: virtualLink ?? this.virtualLink,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'candidateProfileId': candidateProfileId,
        'parentUserId': parentUserId,
        'brokerUserId': brokerUserId,
        'scheduledByUserId': scheduledByUserId,
        'scheduledByRole': scheduledByRole.name,
        'brokerVisible': brokerVisible,
        'parentPartyVisible': parentPartyVisible,
        'when': when.toIso8601String(),
        'durationMinutes': durationMinutes,
        'type': type.name,
        'location': location,
        'virtualLink': virtualLink,
        'status': status.name,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Meeting.fromJson(Map<String, dynamic> json) {
    MeetingScheduledBy parseScheduledBy(String? s) =>
        MeetingScheduledBy.values.firstWhere(
          (e) => e.name == s,
          orElse: () => MeetingScheduledBy.broker,
        );
    MeetingType parseType(String? s) => MeetingType.values.firstWhere(
          (e) => e.name == s,
          orElse: () => MeetingType.virtual,
        );
    MeetingStatus parseStatus(String? s) => MeetingStatus.values.firstWhere(
          (e) => e.name == s,
          orElse: () => MeetingStatus.scheduled,
        );

    return Meeting(
      id: json['id'] as String? ?? '',
      candidateProfileId: json['candidateProfileId'] as String? ?? '',
      parentUserId: json['parentUserId'] as String? ?? '',
      brokerUserId: json['brokerUserId'] as String? ?? '',
      scheduledByUserId: json['scheduledByUserId'] as String? ?? '',
      scheduledByRole: parseScheduledBy(json['scheduledByRole'] as String?),
      brokerVisible: json['brokerVisible'] as bool? ?? false,
      parentPartyVisible: json['parentPartyVisible'] as bool? ?? true,
      when: DateTime.tryParse(json['when'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 30,
      type: parseType(json['type'] as String?),
      location: json['location'] as String? ?? '',
      virtualLink: json['virtualLink'] as String?,
      status: parseStatus(json['status'] as String?),
      notes: json['notes'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
