T? _tryParseEnum<T extends Enum>(List<T> values, String? s) {
  if (s == null) return null;
  final match = values.where((e) => e.name == s);
  return match.isEmpty ? null : match.first;
}

enum LookingFor { bride, groom }

enum FamilyType { joint, nuclear }

enum FamilyValues { orthodox, moderate, liberal }

enum Diet { vegetarian, nonVegetarian, eggetarian, vegan, jain }

enum Lifestyle { simple, moderate, luxurious }

class ParentProfile {
  final String userId;
  final String name;
  final LookingFor lookingFor;
  final String city;
  final String state;
  final List<String> preferredCommunities;
  final int? preferredMinAge;
  final int? preferredMaxAge;
  final DateTime createdAt;

  // Contact info
  final String? email;
  final String? whatsAppNumber;
  final String? alternatePhone;

  // Child's personal details (parent fills these about their child)
  final String? childName;
  final DateTime? childDateOfBirth;
  final String? childHeight;
  final String? childWeight;
  final String? childComplexion;
  final String? childBloodGroup;
  final Diet? childDiet;
  final bool? childSmokes;
  final bool? childDrinks;
  final String? childPhysicalStatus;
  final String? childManglikStatus;
  final String? childEducation;
  final String? childProfession;
  final String? childIncome;

  // Horoscope details
  final String? childRashi;
  final String? childNakshatra;
  final String? childGotra;
  final String? childBirthTime;
  final String? childBirthPlace;

  // Family details
  final FamilyType? familyType;
  final FamilyValues? familyValues;
  final String? familyAffluence;
  final int? numberOfBrothers;
  final int? numberOfSisters;
  final String? fatherOccupation;
  final String? motherOccupation;
  final String? familyLivingIn;
  final String? aboutFamily;

  // Lifestyle
  final bool? ownHouse;
  final bool? ownCar;
  final bool? willingToRelocate;
  final Lifestyle? lifestyle;

  // Partner preferences (detailed)
  final String? preferredHeightMin;
  final String? preferredHeightMax;
  final String? preferredComplexion;
  final String? preferredEducation;
  final String? preferredProfession;
  final String? preferredIncomeMin;
  final Diet? preferredDiet;
  final String? preferredLocation;
  final String? preferredReligion;
  final String? preferredCaste;
  final String? preferredMotherTongue;

  const ParentProfile({
    required this.userId,
    required this.name,
    required this.lookingFor,
    required this.city,
    required this.state,
    this.preferredCommunities = const [],
    this.preferredMinAge,
    this.preferredMaxAge,
    required this.createdAt,
    // Contact
    this.email,
    this.whatsAppNumber,
    this.alternatePhone,
    // Child personal
    this.childName,
    this.childDateOfBirth,
    this.childHeight,
    this.childWeight,
    this.childComplexion,
    this.childBloodGroup,
    this.childDiet,
    this.childSmokes,
    this.childDrinks,
    this.childPhysicalStatus,
    this.childManglikStatus,
    this.childEducation,
    this.childProfession,
    this.childIncome,
    // Horoscope
    this.childRashi,
    this.childNakshatra,
    this.childGotra,
    this.childBirthTime,
    this.childBirthPlace,
    // Family
    this.familyType,
    this.familyValues,
    this.familyAffluence,
    this.numberOfBrothers,
    this.numberOfSisters,
    this.fatherOccupation,
    this.motherOccupation,
    this.familyLivingIn,
    this.aboutFamily,
    // Lifestyle
    this.ownHouse,
    this.ownCar,
    this.willingToRelocate,
    this.lifestyle,
    // Partner preferences
    this.preferredHeightMin,
    this.preferredHeightMax,
    this.preferredComplexion,
    this.preferredEducation,
    this.preferredProfession,
    this.preferredIncomeMin,
    this.preferredDiet,
    this.preferredLocation,
    this.preferredReligion,
    this.preferredCaste,
    this.preferredMotherTongue,
  });

  String get lookingForDisplay => lookingFor == LookingFor.bride ? 'Bride' : 'Groom';

  int get profileCompleteness {
    int filled = 0;
    int total = 15; // count of important fields
    if (childName != null && childName!.isNotEmpty) filled++;
    if (childDateOfBirth != null) filled++;
    if (childHeight != null && childHeight!.isNotEmpty) filled++;
    if (childEducation != null && childEducation!.isNotEmpty) filled++;
    if (childProfession != null && childProfession!.isNotEmpty) filled++;
    if (childDiet != null) filled++;
    if (familyType != null) filled++;
    if (fatherOccupation != null && fatherOccupation!.isNotEmpty) filled++;
    if (motherOccupation != null && motherOccupation!.isNotEmpty) filled++;
    if (aboutFamily != null && aboutFamily!.isNotEmpty) filled++;
    if (childRashi != null && childRashi!.isNotEmpty) filled++;
    if (preferredMinAge != null) filled++;
    if (preferredCommunities.isNotEmpty) filled++;
    if (email != null && email!.isNotEmpty) filled++;
    if (childIncome != null && childIncome!.isNotEmpty) filled++;
    return ((filled / total) * 100).round();
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'name': name,
    'lookingFor': lookingFor.name,
    'city': city,
    'state': state,
    'preferredCommunities': preferredCommunities,
    'preferredMinAge': preferredMinAge,
    'preferredMaxAge': preferredMaxAge,
    'createdAt': createdAt.toIso8601String(),
    // Contact
    'email': email,
    'whatsAppNumber': whatsAppNumber,
    'alternatePhone': alternatePhone,
    // Child personal
    'childName': childName,
    'childDateOfBirth': childDateOfBirth?.toIso8601String(),
    'childHeight': childHeight,
    'childWeight': childWeight,
    'childComplexion': childComplexion,
    'childBloodGroup': childBloodGroup,
    'childDiet': childDiet?.name,
    'childSmokes': childSmokes,
    'childDrinks': childDrinks,
    'childPhysicalStatus': childPhysicalStatus,
    'childManglikStatus': childManglikStatus,
    'childEducation': childEducation,
    'childProfession': childProfession,
    'childIncome': childIncome,
    // Horoscope
    'childRashi': childRashi,
    'childNakshatra': childNakshatra,
    'childGotra': childGotra,
    'childBirthTime': childBirthTime,
    'childBirthPlace': childBirthPlace,
    // Family
    'familyType': familyType?.name,
    'familyValues': familyValues?.name,
    'familyAffluence': familyAffluence,
    'numberOfBrothers': numberOfBrothers,
    'numberOfSisters': numberOfSisters,
    'fatherOccupation': fatherOccupation,
    'motherOccupation': motherOccupation,
    'familyLivingIn': familyLivingIn,
    'aboutFamily': aboutFamily,
    // Lifestyle
    'ownHouse': ownHouse,
    'ownCar': ownCar,
    'willingToRelocate': willingToRelocate,
    'lifestyle': lifestyle?.name,
    // Partner preferences
    'preferredHeightMin': preferredHeightMin,
    'preferredHeightMax': preferredHeightMax,
    'preferredComplexion': preferredComplexion,
    'preferredEducation': preferredEducation,
    'preferredProfession': preferredProfession,
    'preferredIncomeMin': preferredIncomeMin,
    'preferredDiet': preferredDiet?.name,
    'preferredLocation': preferredLocation,
    'preferredReligion': preferredReligion,
    'preferredCaste': preferredCaste,
    'preferredMotherTongue': preferredMotherTongue,
  };

  factory ParentProfile.fromJson(Map<String, dynamic> json) => ParentProfile(
    userId: json['userId'] as String? ?? '',
    name: json['name'] as String? ?? '',
    lookingFor: LookingFor.values.firstWhere(
      (e) => e.name == (json['lookingFor'] as String?),
      orElse: () => LookingFor.bride,
    ),
    city: json['city'] as String? ?? '',
    state: json['state'] as String? ?? '',
    preferredCommunities: (json['preferredCommunities'] as List<dynamic>?)?.cast<String>() ?? [],
    preferredMinAge: json['preferredMinAge'] as int?,
    preferredMaxAge: json['preferredMaxAge'] as int?,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    // Contact
    email: json['email'] as String?,
    whatsAppNumber: json['whatsAppNumber'] as String?,
    alternatePhone: json['alternatePhone'] as String?,
    // Child personal
    childName: json['childName'] as String?,
    childDateOfBirth: DateTime.tryParse(json['childDateOfBirth'] as String? ?? ''),
    childHeight: json['childHeight'] as String?,
    childWeight: json['childWeight'] as String?,
    childComplexion: json['childComplexion'] as String?,
    childBloodGroup: json['childBloodGroup'] as String?,
    childDiet: _tryParseEnum(Diet.values, json['childDiet'] as String?),
    childSmokes: json['childSmokes'] as bool?,
    childDrinks: json['childDrinks'] as bool?,
    childPhysicalStatus: json['childPhysicalStatus'] as String?,
    childManglikStatus: json['childManglikStatus'] as String?,
    childEducation: json['childEducation'] as String?,
    childProfession: json['childProfession'] as String?,
    childIncome: json['childIncome'] as String?,
    // Horoscope
    childRashi: json['childRashi'] as String?,
    childNakshatra: json['childNakshatra'] as String?,
    childGotra: json['childGotra'] as String?,
    childBirthTime: json['childBirthTime'] as String?,
    childBirthPlace: json['childBirthPlace'] as String?,
    // Family
    familyType: _tryParseEnum(FamilyType.values, json['familyType'] as String?),
    familyValues: _tryParseEnum(FamilyValues.values, json['familyValues'] as String?),
    familyAffluence: json['familyAffluence'] as String?,
    numberOfBrothers: json['numberOfBrothers'] as int?,
    numberOfSisters: json['numberOfSisters'] as int?,
    fatherOccupation: json['fatherOccupation'] as String?,
    motherOccupation: json['motherOccupation'] as String?,
    familyLivingIn: json['familyLivingIn'] as String?,
    aboutFamily: json['aboutFamily'] as String?,
    // Lifestyle
    ownHouse: json['ownHouse'] as bool?,
    ownCar: json['ownCar'] as bool?,
    willingToRelocate: json['willingToRelocate'] as bool?,
    lifestyle: _tryParseEnum(Lifestyle.values, json['lifestyle'] as String?),
    // Partner preferences
    preferredHeightMin: json['preferredHeightMin'] as String?,
    preferredHeightMax: json['preferredHeightMax'] as String?,
    preferredComplexion: json['preferredComplexion'] as String?,
    preferredEducation: json['preferredEducation'] as String?,
    preferredProfession: json['preferredProfession'] as String?,
    preferredIncomeMin: json['preferredIncomeMin'] as String?,
    preferredDiet: _tryParseEnum(Diet.values, json['preferredDiet'] as String?),
    preferredLocation: json['preferredLocation'] as String?,
    preferredReligion: json['preferredReligion'] as String?,
    preferredCaste: json['preferredCaste'] as String?,
    preferredMotherTongue: json['preferredMotherTongue'] as String?,
  );

  ParentProfile copyWith({
    String? name,
    LookingFor? lookingFor,
    String? city,
    String? state,
    List<String>? preferredCommunities,
    int? preferredMinAge,
    int? preferredMaxAge,
    String? email,
    String? whatsAppNumber,
    String? alternatePhone,
    String? childName,
    DateTime? childDateOfBirth,
    String? childHeight,
    String? childWeight,
    String? childComplexion,
    String? childBloodGroup,
    Diet? childDiet,
    bool? childSmokes,
    bool? childDrinks,
    String? childPhysicalStatus,
    String? childManglikStatus,
    String? childEducation,
    String? childProfession,
    String? childIncome,
    String? childRashi,
    String? childNakshatra,
    String? childGotra,
    String? childBirthTime,
    String? childBirthPlace,
    FamilyType? familyType,
    FamilyValues? familyValues,
    String? familyAffluence,
    int? numberOfBrothers,
    int? numberOfSisters,
    String? fatherOccupation,
    String? motherOccupation,
    String? familyLivingIn,
    String? aboutFamily,
    bool? ownHouse,
    bool? ownCar,
    bool? willingToRelocate,
    Lifestyle? lifestyle,
    String? preferredHeightMin,
    String? preferredHeightMax,
    String? preferredComplexion,
    String? preferredEducation,
    String? preferredProfession,
    String? preferredIncomeMin,
    Diet? preferredDiet,
    String? preferredLocation,
    String? preferredReligion,
    String? preferredCaste,
    String? preferredMotherTongue,
  }) => ParentProfile(
    userId: userId,
    name: name ?? this.name,
    lookingFor: lookingFor ?? this.lookingFor,
    city: city ?? this.city,
    state: state ?? this.state,
    preferredCommunities: preferredCommunities ?? this.preferredCommunities,
    preferredMinAge: preferredMinAge ?? this.preferredMinAge,
    preferredMaxAge: preferredMaxAge ?? this.preferredMaxAge,
    createdAt: createdAt,
    email: email ?? this.email,
    whatsAppNumber: whatsAppNumber ?? this.whatsAppNumber,
    alternatePhone: alternatePhone ?? this.alternatePhone,
    childName: childName ?? this.childName,
    childDateOfBirth: childDateOfBirth ?? this.childDateOfBirth,
    childHeight: childHeight ?? this.childHeight,
    childWeight: childWeight ?? this.childWeight,
    childComplexion: childComplexion ?? this.childComplexion,
    childBloodGroup: childBloodGroup ?? this.childBloodGroup,
    childDiet: childDiet ?? this.childDiet,
    childSmokes: childSmokes ?? this.childSmokes,
    childDrinks: childDrinks ?? this.childDrinks,
    childPhysicalStatus: childPhysicalStatus ?? this.childPhysicalStatus,
    childManglikStatus: childManglikStatus ?? this.childManglikStatus,
    childEducation: childEducation ?? this.childEducation,
    childProfession: childProfession ?? this.childProfession,
    childIncome: childIncome ?? this.childIncome,
    childRashi: childRashi ?? this.childRashi,
    childNakshatra: childNakshatra ?? this.childNakshatra,
    childGotra: childGotra ?? this.childGotra,
    childBirthTime: childBirthTime ?? this.childBirthTime,
    childBirthPlace: childBirthPlace ?? this.childBirthPlace,
    familyType: familyType ?? this.familyType,
    familyValues: familyValues ?? this.familyValues,
    familyAffluence: familyAffluence ?? this.familyAffluence,
    numberOfBrothers: numberOfBrothers ?? this.numberOfBrothers,
    numberOfSisters: numberOfSisters ?? this.numberOfSisters,
    fatherOccupation: fatherOccupation ?? this.fatherOccupation,
    motherOccupation: motherOccupation ?? this.motherOccupation,
    familyLivingIn: familyLivingIn ?? this.familyLivingIn,
    aboutFamily: aboutFamily ?? this.aboutFamily,
    ownHouse: ownHouse ?? this.ownHouse,
    ownCar: ownCar ?? this.ownCar,
    willingToRelocate: willingToRelocate ?? this.willingToRelocate,
    lifestyle: lifestyle ?? this.lifestyle,
    preferredHeightMin: preferredHeightMin ?? this.preferredHeightMin,
    preferredHeightMax: preferredHeightMax ?? this.preferredHeightMax,
    preferredComplexion: preferredComplexion ?? this.preferredComplexion,
    preferredEducation: preferredEducation ?? this.preferredEducation,
    preferredProfession: preferredProfession ?? this.preferredProfession,
    preferredIncomeMin: preferredIncomeMin ?? this.preferredIncomeMin,
    preferredDiet: preferredDiet ?? this.preferredDiet,
    preferredLocation: preferredLocation ?? this.preferredLocation,
    preferredReligion: preferredReligion ?? this.preferredReligion,
    preferredCaste: preferredCaste ?? this.preferredCaste,
    preferredMotherTongue: preferredMotherTongue ?? this.preferredMotherTongue,
  );
}
