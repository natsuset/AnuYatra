import 'package:testing_flutter/models/profile.dart';

enum Gender {
  bride,
  groom;

  String get displayName {
    switch (this) {
      case Gender.bride:
        return 'Bride';
      case Gender.groom:
        return 'Groom';
    }
  }
}

enum ProfileVisibility {
  public,
  connectedOnly,
  hidden;

  String get displayName {
    switch (this) {
      case ProfileVisibility.public:
        return 'Public';
      case ProfileVisibility.connectedOnly:
        return 'Connected Only';
      case ProfileVisibility.hidden:
        return 'Hidden';
    }
  }
}

class CandidateProfile {
  final String id;
  final String createdByUserId;
  final String name;
  final int age;
  final Gender gender;
  final String profession;
  final String education;
  final String city;
  final String community;
  final String height;
  final String religion;
  final String caste;
  final String motherTongue;
  final String maritalStatus;
  final String aboutMe;
  final String familyBackground;
  final List<String> interests;
  final String fatherOccupation;
  final String motherOccupation;
  final String siblings;
  final List<String> photos;
  final List<String> brokerIds;
  final String? parentUserId;
  final String? candidateUserId;
  final ProfileVisibility visibility;
  final String? deduplicationKey;
  final int listedWithBrokersCount;
  final List<String> searchTags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CandidateProfile({
    required this.id,
    required this.createdByUserId,
    required this.name,
    required this.age,
    required this.gender,
    required this.profession,
    required this.education,
    required this.city,
    this.community = '',
    required this.height,
    this.religion = '',
    this.caste = '',
    this.motherTongue = '',
    this.maritalStatus = 'Never Married',
    this.aboutMe = '',
    this.familyBackground = '',
    this.interests = const [],
    this.fatherOccupation = '',
    this.motherOccupation = '',
    this.siblings = '',
    required this.photos,
    this.brokerIds = const [],
    this.parentUserId,
    this.candidateUserId,
    this.visibility = ProfileVisibility.public,
    this.deduplicationKey,
    this.listedWithBrokersCount = 1,
    this.searchTags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayName => '$name, $age';
  String get snippet => '$education, $city';
  String get fullDetails =>
      '$profession \u2022 $education \u2022 $city${community.isNotEmpty ? ' \u2022 $community' : ''}';

  /// Convert from legacy Profile model for backward compatibility
  factory CandidateProfile.fromLegacyProfile(Profile profile, {
    required String createdByUserId,
    Gender gender = Gender.bride,
  }) => CandidateProfile(
    id: profile.id,
    createdByUserId: createdByUserId,
    name: profile.name,
    age: profile.age,
    gender: gender,
    profession: profile.profession,
    education: profile.education,
    city: profile.city,
    community: profile.community,
    height: profile.height,
    religion: profile.religion,
    caste: profile.caste,
    motherTongue: profile.motherTongue,
    maritalStatus: profile.maritalStatus,
    aboutMe: profile.aboutMe,
    familyBackground: profile.familyBackground,
    interests: profile.interests,
    fatherOccupation: profile.fatherOccupation,
    motherOccupation: profile.motherOccupation,
    siblings: profile.siblings,
    photos: profile.photos,
    createdAt: profile.createdAt,
    updatedAt: profile.createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdByUserId': createdByUserId,
    'name': name,
    'age': age,
    'gender': gender.name,
    'profession': profession,
    'education': education,
    'city': city,
    'community': community,
    'height': height,
    'religion': religion,
    'caste': caste,
    'motherTongue': motherTongue,
    'maritalStatus': maritalStatus,
    'aboutMe': aboutMe,
    'familyBackground': familyBackground,
    'interests': interests,
    'fatherOccupation': fatherOccupation,
    'motherOccupation': motherOccupation,
    'siblings': siblings,
    'photos': photos,
    'brokerIds': brokerIds,
    'parentUserId': parentUserId,
    'candidateUserId': candidateUserId,
    'visibility': visibility.name,
    'deduplicationKey': deduplicationKey,
    'listedWithBrokersCount': listedWithBrokersCount,
    'searchTags': searchTags,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory CandidateProfile.fromJson(Map<String, dynamic> json) => CandidateProfile(
    id: json['id'] as String,
    createdByUserId: json['createdByUserId'] as String,
    name: json['name'] as String,
    age: json['age'] as int,
    gender: Gender.values.byName(json['gender'] as String),
    profession: json['profession'] as String? ?? '',
    education: json['education'] as String? ?? '',
    city: json['city'] as String? ?? '',
    community: json['community'] as String? ?? '',
    height: json['height'] as String? ?? '',
    religion: json['religion'] as String? ?? '',
    caste: json['caste'] as String? ?? '',
    motherTongue: json['motherTongue'] as String? ?? '',
    maritalStatus: json['maritalStatus'] as String? ?? 'Never Married',
    aboutMe: json['aboutMe'] as String? ?? '',
    familyBackground: json['familyBackground'] as String? ?? '',
    interests: (json['interests'] as List<dynamic>?)?.cast<String>() ?? [],
    fatherOccupation: json['fatherOccupation'] as String? ?? '',
    motherOccupation: json['motherOccupation'] as String? ?? '',
    siblings: json['siblings'] as String? ?? '',
    photos: (json['photos'] as List<dynamic>?)?.cast<String>() ?? [],
    brokerIds: (json['brokerIds'] as List<dynamic>?)?.cast<String>() ?? [],
    parentUserId: json['parentUserId'] as String?,
    candidateUserId: json['candidateUserId'] as String?,
    visibility: json['visibility'] != null
        ? ProfileVisibility.values.byName(json['visibility'] as String)
        : ProfileVisibility.public,
    deduplicationKey: json['deduplicationKey'] as String?,
    listedWithBrokersCount: json['listedWithBrokersCount'] as int? ?? 1,
    searchTags: (json['searchTags'] as List<dynamic>?)?.cast<String>() ?? [],
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  CandidateProfile copyWith({
    String? name,
    int? age,
    Gender? gender,
    String? profession,
    String? education,
    String? city,
    String? community,
    String? height,
    String? religion,
    String? caste,
    String? motherTongue,
    String? maritalStatus,
    String? aboutMe,
    String? familyBackground,
    List<String>? interests,
    String? fatherOccupation,
    String? motherOccupation,
    String? siblings,
    List<String>? photos,
    List<String>? brokerIds,
    String? parentUserId,
    String? candidateUserId,
    ProfileVisibility? visibility,
    String? deduplicationKey,
    int? listedWithBrokersCount,
    List<String>? searchTags,
    DateTime? updatedAt,
  }) => CandidateProfile(
    id: id,
    createdByUserId: createdByUserId,
    name: name ?? this.name,
    age: age ?? this.age,
    gender: gender ?? this.gender,
    profession: profession ?? this.profession,
    education: education ?? this.education,
    city: city ?? this.city,
    community: community ?? this.community,
    height: height ?? this.height,
    religion: religion ?? this.religion,
    caste: caste ?? this.caste,
    motherTongue: motherTongue ?? this.motherTongue,
    maritalStatus: maritalStatus ?? this.maritalStatus,
    aboutMe: aboutMe ?? this.aboutMe,
    familyBackground: familyBackground ?? this.familyBackground,
    interests: interests ?? this.interests,
    fatherOccupation: fatherOccupation ?? this.fatherOccupation,
    motherOccupation: motherOccupation ?? this.motherOccupation,
    siblings: siblings ?? this.siblings,
    photos: photos ?? this.photos,
    brokerIds: brokerIds ?? this.brokerIds,
    parentUserId: parentUserId ?? this.parentUserId,
    candidateUserId: candidateUserId ?? this.candidateUserId,
    visibility: visibility ?? this.visibility,
    deduplicationKey: deduplicationKey ?? this.deduplicationKey,
    listedWithBrokersCount: listedWithBrokersCount ?? this.listedWithBrokersCount,
    searchTags: searchTags ?? this.searchTags,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
