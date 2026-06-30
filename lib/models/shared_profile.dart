enum SharedProfileResponse {
  pending,
  interested,

  /// The `maybe` response was removed from the UI in Slice 6 — parents now
  /// have only Interested / Pass on the action row plus a separate Save
  /// bookmark. The enum value is kept so legacy seed data and any pre-migrated
  /// records still deserialise; UI surfaces should treat `maybe` as `pending`.
  @Deprecated('Use Save (SavedProfile) instead. Display as pending.')
  maybe,

  pass;

  String get displayName {
    switch (this) {
      case SharedProfileResponse.pending:
        return 'Pending';
      case SharedProfileResponse.interested:
        return 'Interested';
      // ignore: deprecated_member_use_from_same_package
      case SharedProfileResponse.maybe:
        return 'Maybe';
      case SharedProfileResponse.pass:
        return 'Pass';
    }
  }
}

class SharedProfile {
  final String id;
  final String profileId;
  final String sharedByUserId;
  final String sharedWithUserId;
  final DateTime sharedAt;
  final SharedProfileResponse parentResponse;
  final bool forwardedToChild;
  final SharedProfileResponse? childResponse;
  final String? parentNote;

  const SharedProfile({
    required this.id,
    required this.profileId,
    required this.sharedByUserId,
    required this.sharedWithUserId,
    required this.sharedAt,
    this.parentResponse = SharedProfileResponse.pending,
    this.forwardedToChild = false,
    this.childResponse,
    this.parentNote,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'profileId': profileId,
    'sharedByUserId': sharedByUserId,
    'sharedWithUserId': sharedWithUserId,
    'sharedAt': sharedAt.toIso8601String(),
    'parentResponse': parentResponse.name,
    'forwardedToChild': forwardedToChild,
    'childResponse': childResponse?.name,
    'parentNote': parentNote,
  };

  factory SharedProfile.fromJson(Map<String, dynamic> json) => SharedProfile(
    id: json['id'] as String? ?? '',
    profileId: json['profileId'] as String? ?? '',
    sharedByUserId: json['sharedByUserId'] as String? ?? '',
    sharedWithUserId: json['sharedWithUserId'] as String? ?? '',
    sharedAt: DateTime.tryParse(json['sharedAt'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
    parentResponse: SharedProfileResponse.values.firstWhere(
      (e) => e.name == (json['parentResponse'] as String?),
      orElse: () => SharedProfileResponse.pending,
    ),
    forwardedToChild: json['forwardedToChild'] as bool? ?? false,
    childResponse: json['childResponse'] != null
        ? SharedProfileResponse.values.byName(json['childResponse'] as String)
        : null,
    parentNote: json['parentNote'] as String?,
  );

  SharedProfile copyWith({
    SharedProfileResponse? parentResponse,
    bool? forwardedToChild,
    SharedProfileResponse? childResponse,
    String? parentNote,
  }) => SharedProfile(
    id: id,
    profileId: profileId,
    sharedByUserId: sharedByUserId,
    sharedWithUserId: sharedWithUserId,
    sharedAt: sharedAt,
    parentResponse: parentResponse ?? this.parentResponse,
    forwardedToChild: forwardedToChild ?? this.forwardedToChild,
    childResponse: childResponse ?? this.childResponse,
    parentNote: parentNote ?? this.parentNote,
  );
}
