/// Tracks when a user opened a candidate profile detail screen.
///
/// One record per `(userId, profileId)` pair. Viewing the same profile
/// again updates `viewedAt` to "now" rather than creating a duplicate row.
/// Powers the "Recently Viewed" surface on the parent home + a Viewed tab
/// inside the Saved Profiles screen.
class ViewedProfile {
  /// Composite id `{userId}_{profileId}` so re-views are idempotent.
  final String id;
  final String userId;
  final String profileId;
  final DateTime viewedAt;

  const ViewedProfile({
    required this.id,
    required this.userId,
    required this.profileId,
    required this.viewedAt,
  });

  factory ViewedProfile.create({
    required String userId,
    required String profileId,
    DateTime? viewedAt,
  }) {
    return ViewedProfile(
      id: '${userId}_$profileId',
      userId: userId,
      profileId: profileId,
      viewedAt: viewedAt ?? DateTime.now(),
    );
  }

  ViewedProfile copyWith({DateTime? viewedAt}) {
    return ViewedProfile(
      id: id,
      userId: userId,
      profileId: profileId,
      viewedAt: viewedAt ?? this.viewedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'profileId': profileId,
        'viewedAt': viewedAt.toIso8601String(),
      };

  factory ViewedProfile.fromJson(Map<String, dynamic> json) {
    return ViewedProfile(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      profileId: json['profileId'] as String? ?? '',
      viewedAt: DateTime.tryParse(json['viewedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
