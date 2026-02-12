import 'package:testing_flutter/models/user_role.dart';

class AppUser {
  final String uid;
  final String phoneNumber;
  final String displayName;
  final String? photoUrl;
  final UserRole role;
  final String? agencyId;
  final DateTime createdAt;
  final bool isActive;

  const AppUser({
    required this.uid,
    required this.phoneNumber,
    required this.displayName,
    this.photoUrl,
    required this.role,
    this.agencyId,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'phoneNumber': phoneNumber,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'role': role.name,
    'agencyId': agencyId,
    'createdAt': createdAt.toIso8601String(),
    'isActive': isActive,
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    uid: json['uid'] as String,
    phoneNumber: json['phoneNumber'] as String,
    displayName: json['displayName'] as String,
    photoUrl: json['photoUrl'] as String?,
    role: UserRole.values.byName(json['role'] as String),
    agencyId: json['agencyId'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    isActive: json['isActive'] as bool? ?? true,
  );

  AppUser copyWith({
    String? displayName,
    String? photoUrl,
    String? agencyId,
    bool? isActive,
  }) => AppUser(
    uid: uid,
    phoneNumber: phoneNumber,
    displayName: displayName ?? this.displayName,
    photoUrl: photoUrl ?? this.photoUrl,
    role: role,
    agencyId: agencyId ?? this.agencyId,
    createdAt: createdAt,
    isActive: isActive ?? this.isActive,
  );
}
