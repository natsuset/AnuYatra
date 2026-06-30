/// Kinds of events tracked against a candidate profile.
///
/// Activity timeline events power the "what's been happening" surface on
/// the profile detail page (§1.12 item 7) and also feed the parent's
/// "recently viewed" / "events feed" surfaces.
enum ProfileActivityKind {
  brokerSharedProfile,
  brokerSentMessage,
  parentMarkedInterested,
  parentMarkedPass,
  parentMarkedPending,
  parentSavedProfile,
  parentUnsavedProfile,
  parentForwardedToChild,
  childMarkedInterested,
  childMarkedPass,
  meetingScheduled,
  meetingCompleted,
  meetingCancelled,
  brokerNoteAdded,
  parentNoteAdded,
  profileViewed;
}

/// A single event recorded against a candidate profile.
///
/// Append-only — once written, never edited. The `ActivityRepository`
/// prunes to the last 50 per profile on every write (decision in §1.12).
class ProfileActivity {
  /// Unique id (uuid).
  final String id;

  /// The candidate profile this event is about.
  final String profileId;

  /// User who triggered the event (broker, parent, candidate, or system).
  /// `null` for system-emitted events without a clear actor.
  final String? actorUserId;

  /// Optional display name of the actor (cached so the timeline can render
  /// without a per-row user lookup).
  final String? actorName;

  final ProfileActivityKind kind;
  final DateTime at;

  /// Free-form additional context per event kind. E.g.
  /// `brokerSentMessage` → `{ "snippet": "I have some matches..." }`,
  /// `meetingScheduled` → `{ "when": "2026-04-12T18:00:00Z", "where": "Zoom" }`,
  /// `brokerNoteAdded` → `{ "snippet": "Family met last week..." }`.
  final Map<String, dynamic> meta;

  const ProfileActivity({
    required this.id,
    required this.profileId,
    required this.kind,
    required this.at,
    this.actorUserId,
    this.actorName,
    this.meta = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'profileId': profileId,
        'actorUserId': actorUserId,
        'actorName': actorName,
        'kind': kind.name,
        'at': at.toIso8601String(),
        'meta': meta,
      };

  factory ProfileActivity.fromJson(Map<String, dynamic> json) {
    final kindName = json['kind'] as String? ?? '';
    final kind = ProfileActivityKind.values.firstWhere(
      (k) => k.name == kindName,
      orElse: () => ProfileActivityKind.profileViewed,
    );
    return ProfileActivity(
      id: json['id'] as String? ?? '',
      profileId: json['profileId'] as String? ?? '',
      actorUserId: json['actorUserId'] as String?,
      actorName: json['actorName'] as String?,
      kind: kind,
      at: DateTime.tryParse(json['at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      meta: (json['meta'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
}
