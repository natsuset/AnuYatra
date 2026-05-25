class Profile {
  final String id;
  final String name;
  final int age;
  final String profession;
  final String education;
  final String city;
  final String community;
  final String height;
  // Extended personal fields
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
  final bool isNew;
  final DateTime createdAt;
  final ProfileStatus status;

  Profile({
    required this.id,
    required this.name,
    required this.age,
    required this.profession,
    required this.education,
    required this.city,
    this.community = '',
    required this.height,
    this.religion = '',
    this.caste = '',
    this.motherTongue = '',
    this.maritalStatus = '',
    this.aboutMe = '',
    this.familyBackground = '',
    this.interests = const [],
    this.fatherOccupation = '',
    this.motherOccupation = '',
    this.siblings = '',
    required this.photos,
    this.isNew = false,
    required this.createdAt,
    this.status = ProfileStatus.pending,
  });

  String get displayName => '$name, $age';
  String get snippet => '$education, $city';
  String get fullDetails =>
      '$profession • $education • $city${community.isNotEmpty ? ' • $community' : ''}';

  Profile copyWith({
    ProfileStatus? status,
    bool? isNew,
    String? religion,
    String? caste,
    String? motherTongue,
    String? maritalStatus,
    String? aboutMe,
    String? familyBackground,
    List<String>? interests,
  }) {
    return Profile(
      id: id,
      name: name,
      age: age,
      profession: profession,
      education: education,
      city: city,
      community: community,
      height: height,
      religion: religion ?? this.religion,
      caste: caste ?? this.caste,
      motherTongue: motherTongue ?? this.motherTongue,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      aboutMe: aboutMe ?? this.aboutMe,
      familyBackground: familyBackground ?? this.familyBackground,
      interests: interests ?? this.interests,
      fatherOccupation: fatherOccupation,
      motherOccupation: motherOccupation,
      siblings: siblings,
      photos: photos,
      isNew: isNew ?? this.isNew,
      createdAt: createdAt,
      status: status ?? this.status,
    );
  }
}

enum ProfileStatus {
  pending,
  interested,
  notMatch,
  saved,
  mutualInterest,
  awaitingResponse,
}

extension ProfileStatusExtension on ProfileStatus {
  String get displayName {
    switch (this) {
      case ProfileStatus.pending:
        return 'New';
      case ProfileStatus.interested:
        return 'Interested';
      case ProfileStatus.notMatch:
        return 'Not a Match';
      case ProfileStatus.saved:
        return 'Saved';
      case ProfileStatus.mutualInterest:
        return 'Mutual Interest';
      case ProfileStatus.awaitingResponse:
        return 'Awaiting Response';
    }
  }

  String get actionLabel {
    switch (this) {
      case ProfileStatus.interested:
        return 'You showed interest';
      case ProfileStatus.notMatch:
        return 'You marked as not a match';
      case ProfileStatus.saved:
        return 'You saved for later';
      case ProfileStatus.mutualInterest:
        return 'Mutual interest!';
      case ProfileStatus.awaitingResponse:
        return 'Awaiting their response';
      default:
        return '';
    }
  }
}
