/// A profile a user has bookmarked for later review.
///
/// Independent of [SharedProfileResponse] — saving is a private bookmark
/// that does NOT notify the broker. A profile can be saved AND have a
/// response of pending / interested / pass. The set of saves forms the
/// "Saved Profiles" surface on the parent shell (and eventually candidate).
class SavedProfile {
  /// Stable id (`{userId}_{profileId}`) so saving is idempotent and a
  /// double-tap doesn't create two records.
  final String id;
  final String userId;
  final String profileId;
  final DateTime savedAt;

  const SavedProfile({
    required this.id,
    required this.userId,
    required this.profileId,
    required this.savedAt,
  });

  /// Convenience constructor that derives the id from `{userId}_{profileId}`.
  factory SavedProfile.create({
    required String userId,
    required String profileId,
    DateTime? savedAt,
  }) {
    return SavedProfile(
      id: '${userId}_$profileId',
      userId: userId,
      profileId: profileId,
      savedAt: savedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'profileId': profileId,
        'savedAt': savedAt.toIso8601String(),
      };

  factory SavedProfile.fromJson(Map<String, dynamic> json) {
    return SavedProfile(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      profileId: json['profileId'] as String? ?? '',
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
