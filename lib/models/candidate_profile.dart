import 'package:testing_flutter/models/profile.dart';
import 'package:testing_flutter/models/parent_profile.dart';

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

  // ─── New enriched fields ───────────────────────────────────
  final DateTime? dateOfBirth;
  final String? annualIncome;
  final String? complexion;
  final String? weight;
  final String? bloodGroup;
  final Diet? diet;
  final bool? smokes;
  final bool? drinks;
  final String? manglikStatus;
  final String? gotra;
  final String? rashi;
  final String? nakshatra;
  final String? birthTime;
  final String? birthPlace;
  final FamilyType? familyType;
  final FamilyValues? familyValues;
  final String? familyAffluence;
  final int? numberOfBrothers;
  final int? numberOfSisters;
  final bool? ownHouse;
  final bool? ownCar;
  final bool? willingToRelocate;
  final String? physicalStatus;

  // Partner preferences
  final int? preferredAgeMin;
  final int? preferredAgeMax;
  final String? preferredHeightMin;
  final String? preferredHeightMax;
  final String? preferredEducation;
  final String? preferredProfession;
  final String? preferredLocation;
  final String? preferredReligion;
  final String? preferredCaste;
  final String? preferredIncomeMin;

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
    // New fields
    this.dateOfBirth,
    this.annualIncome,
    this.complexion,
    this.weight,
    this.bloodGroup,
    this.diet,
    this.smokes,
    this.drinks,
    this.manglikStatus,
    this.gotra,
    this.rashi,
    this.nakshatra,
    this.birthTime,
    this.birthPlace,
    this.familyType,
    this.familyValues,
    this.familyAffluence,
    this.numberOfBrothers,
    this.numberOfSisters,
    this.ownHouse,
    this.ownCar,
    this.willingToRelocate,
    this.physicalStatus,
    this.preferredAgeMin,
    this.preferredAgeMax,
    this.preferredHeightMin,
    this.preferredHeightMax,
    this.preferredEducation,
    this.preferredProfession,
    this.preferredLocation,
    this.preferredReligion,
    this.preferredCaste,
    this.preferredIncomeMin,
  });

  String get displayName => '$name, $age';
  String get snippet => '$education, $city';
  String get fullDetails =>
      '$profession \u2022 $education \u2022 $city${community.isNotEmpty ? ' \u2022 $community' : ''}';

  int get profileCompleteness {
    int filled = 0;
    int total = 20;
    if (name.isNotEmpty) filled++;
    if (profession.isNotEmpty) filled++;
    if (education.isNotEmpty) filled++;
    if (city.isNotEmpty) filled++;
    if (height.isNotEmpty) filled++;
    if (religion.isNotEmpty) filled++;
    if (community.isNotEmpty) filled++;
    if (aboutMe.isNotEmpty) filled++;
    if (familyBackground.isNotEmpty) filled++;
    if (fatherOccupation.isNotEmpty) filled++;
    if (motherOccupation.isNotEmpty) filled++;
    if (interests.isNotEmpty) filled++;
    if (photos.isNotEmpty) filled++;
    if (annualIncome != null && annualIncome!.isNotEmpty) filled++;
    if (diet != null) filled++;
    if (manglikStatus != null && manglikStatus!.isNotEmpty) filled++;
    if (familyType != null) filled++;
    if (dateOfBirth != null) filled++;
    if (complexion != null && complexion!.isNotEmpty) filled++;
    if (gotra != null && gotra!.isNotEmpty) filled++;
    return ((filled / total) * 100).round();
  }

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
    // New fields
    'dateOfBirth': dateOfBirth?.toIso8601String(),
    'annualIncome': annualIncome,
    'complexion': complexion,
    'weight': weight,
    'bloodGroup': bloodGroup,
    'diet': diet?.name,
    'smokes': smokes,
    'drinks': drinks,
    'manglikStatus': manglikStatus,
    'gotra': gotra,
    'rashi': rashi,
    'nakshatra': nakshatra,
    'birthTime': birthTime,
    'birthPlace': birthPlace,
    'familyType': familyType?.name,
    'familyValues': familyValues?.name,
    'familyAffluence': familyAffluence,
    'numberOfBrothers': numberOfBrothers,
    'numberOfSisters': numberOfSisters,
    'ownHouse': ownHouse,
    'ownCar': ownCar,
    'willingToRelocate': willingToRelocate,
    'physicalStatus': physicalStatus,
    'preferredAgeMin': preferredAgeMin,
    'preferredAgeMax': preferredAgeMax,
    'preferredHeightMin': preferredHeightMin,
    'preferredHeightMax': preferredHeightMax,
    'preferredEducation': preferredEducation,
    'preferredProfession': preferredProfession,
    'preferredLocation': preferredLocation,
    'preferredReligion': preferredReligion,
    'preferredCaste': preferredCaste,
    'preferredIncomeMin': preferredIncomeMin,
  };

  factory CandidateProfile.fromJson(Map<String, dynamic> json) => CandidateProfile(
    id: json['id'] as String? ?? '',
    createdByUserId: json['createdByUserId'] as String? ?? '',
    name: json['name'] as String? ?? '',
    age: (json['age'] as num?)?.toInt() ?? 0,
    gender: Gender.values.firstWhere(
      (e) => e.name == (json['gender'] as String?),
      orElse: () => Gender.bride,
    ),
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
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    // New fields
    dateOfBirth: json['dateOfBirth'] != null ? DateTime.parse(json['dateOfBirth'] as String) : null,
    annualIncome: json['annualIncome'] as String?,
    complexion: json['complexion'] as String?,
    weight: json['weight'] as String?,
    bloodGroup: json['bloodGroup'] as String?,
    diet: json['diet'] != null ? Diet.values.byName(json['diet'] as String) : null,
    smokes: json['smokes'] as bool?,
    drinks: json['drinks'] as bool?,
    manglikStatus: json['manglikStatus'] as String?,
    gotra: json['gotra'] as String?,
    rashi: json['rashi'] as String?,
    nakshatra: json['nakshatra'] as String?,
    birthTime: json['birthTime'] as String?,
    birthPlace: json['birthPlace'] as String?,
    familyType: json['familyType'] != null ? FamilyType.values.byName(json['familyType'] as String) : null,
    familyValues: json['familyValues'] != null ? FamilyValues.values.byName(json['familyValues'] as String) : null,
    familyAffluence: json['familyAffluence'] as String?,
    numberOfBrothers: json['numberOfBrothers'] as int?,
    numberOfSisters: json['numberOfSisters'] as int?,
    ownHouse: json['ownHouse'] as bool?,
    ownCar: json['ownCar'] as bool?,
    willingToRelocate: json['willingToRelocate'] as bool?,
    physicalStatus: json['physicalStatus'] as String?,
    preferredAgeMin: json['preferredAgeMin'] as int?,
    preferredAgeMax: json['preferredAgeMax'] as int?,
    preferredHeightMin: json['preferredHeightMin'] as String?,
    preferredHeightMax: json['preferredHeightMax'] as String?,
    preferredEducation: json['preferredEducation'] as String?,
    preferredProfession: json['preferredProfession'] as String?,
    preferredLocation: json['preferredLocation'] as String?,
    preferredReligion: json['preferredReligion'] as String?,
    preferredCaste: json['preferredCaste'] as String?,
    preferredIncomeMin: json['preferredIncomeMin'] as String?,
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
    // New fields
    DateTime? dateOfBirth,
    String? annualIncome,
    String? complexion,
    String? weight,
    String? bloodGroup,
    Diet? diet,
    bool? smokes,
    bool? drinks,
    String? manglikStatus,
    String? gotra,
    String? rashi,
    String? nakshatra,
    String? birthTime,
    String? birthPlace,
    FamilyType? familyType,
    FamilyValues? familyValues,
    String? familyAffluence,
    int? numberOfBrothers,
    int? numberOfSisters,
    bool? ownHouse,
    bool? ownCar,
    bool? willingToRelocate,
    String? physicalStatus,
    int? preferredAgeMin,
    int? preferredAgeMax,
    String? preferredHeightMin,
    String? preferredHeightMax,
    String? preferredEducation,
    String? preferredProfession,
    String? preferredLocation,
    String? preferredReligion,
    String? preferredCaste,
    String? preferredIncomeMin,
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
    dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    annualIncome: annualIncome ?? this.annualIncome,
    complexion: complexion ?? this.complexion,
    weight: weight ?? this.weight,
    bloodGroup: bloodGroup ?? this.bloodGroup,
    diet: diet ?? this.diet,
    smokes: smokes ?? this.smokes,
    drinks: drinks ?? this.drinks,
    manglikStatus: manglikStatus ?? this.manglikStatus,
    gotra: gotra ?? this.gotra,
    rashi: rashi ?? this.rashi,
    nakshatra: nakshatra ?? this.nakshatra,
    birthTime: birthTime ?? this.birthTime,
    birthPlace: birthPlace ?? this.birthPlace,
    familyType: familyType ?? this.familyType,
    familyValues: familyValues ?? this.familyValues,
    familyAffluence: familyAffluence ?? this.familyAffluence,
    numberOfBrothers: numberOfBrothers ?? this.numberOfBrothers,
    numberOfSisters: numberOfSisters ?? this.numberOfSisters,
    ownHouse: ownHouse ?? this.ownHouse,
    ownCar: ownCar ?? this.ownCar,
    willingToRelocate: willingToRelocate ?? this.willingToRelocate,
    physicalStatus: physicalStatus ?? this.physicalStatus,
    preferredAgeMin: preferredAgeMin ?? this.preferredAgeMin,
    preferredAgeMax: preferredAgeMax ?? this.preferredAgeMax,
    preferredHeightMin: preferredHeightMin ?? this.preferredHeightMin,
    preferredHeightMax: preferredHeightMax ?? this.preferredHeightMax,
    preferredEducation: preferredEducation ?? this.preferredEducation,
    preferredProfession: preferredProfession ?? this.preferredProfession,
    preferredLocation: preferredLocation ?? this.preferredLocation,
    preferredReligion: preferredReligion ?? this.preferredReligion,
    preferredCaste: preferredCaste ?? this.preferredCaste,
    preferredIncomeMin: preferredIncomeMin ?? this.preferredIncomeMin,
  );
}
