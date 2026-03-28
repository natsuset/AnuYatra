enum VerificationStatus {
  unverified,
  pending,
  verified;

  String get displayName {
    switch (this) {
      case VerificationStatus.unverified:
        return 'Unverified';
      case VerificationStatus.pending:
        return 'Pending';
      case VerificationStatus.verified:
        return 'Verified';
    }
  }
}

class BrokerProfile {
  final String userId;
  final String? agencyId;
  final String name;
  final String phoneNumber;
  final String? photoUrl;
  final List<String> specializations;
  final List<String> areasServed;
  final int experienceYears;
  final int clientCount;
  final int profilesManaged;
  final double rating;
  final String bio;
  final bool isOnline;
  final DateTime lastSeen;
  final DateTime createdAt;

  // New business fields
  final String? email;
  final String? officeAddress;
  final String? website;
  final String? licenseNumber;
  final List<String> languagesSpoken;
  final int totalSuccessfulMatches;
  final String? feeStructure;
  final String? workingHours;
  final Map<String, String> socialMediaLinks;
  final VerificationStatus verificationStatus;

  const BrokerProfile({
    required this.userId,
    this.agencyId,
    required this.name,
    required this.phoneNumber,
    this.photoUrl,
    this.specializations = const [],
    this.areasServed = const [],
    this.experienceYears = 0,
    this.clientCount = 0,
    this.profilesManaged = 0,
    this.rating = 0.0,
    this.bio = '',
    this.isOnline = false,
    required this.lastSeen,
    required this.createdAt,
    // New fields
    this.email,
    this.officeAddress,
    this.website,
    this.licenseNumber,
    this.languagesSpoken = const [],
    this.totalSuccessfulMatches = 0,
    this.feeStructure,
    this.workingHours,
    this.socialMediaLinks = const {},
    this.verificationStatus = VerificationStatus.unverified,
  });

  bool get isIndependent => agencyId == null;
  bool get isVerified => verificationStatus == VerificationStatus.verified;

  String get statusText =>
      isOnline ? 'Online' : 'Last seen ${_formatLastSeen()}';

  String _formatLastSeen() {
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'agencyId': agencyId,
    'name': name,
    'phoneNumber': phoneNumber,
    'photoUrl': photoUrl,
    'specializations': specializations,
    'areasServed': areasServed,
    'experienceYears': experienceYears,
    'clientCount': clientCount,
    'profilesManaged': profilesManaged,
    'rating': rating,
    'bio': bio,
    'isOnline': isOnline,
    'lastSeen': lastSeen.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    // New fields
    'email': email,
    'officeAddress': officeAddress,
    'website': website,
    'licenseNumber': licenseNumber,
    'languagesSpoken': languagesSpoken,
    'totalSuccessfulMatches': totalSuccessfulMatches,
    'feeStructure': feeStructure,
    'workingHours': workingHours,
    'socialMediaLinks': socialMediaLinks,
    'verificationStatus': verificationStatus.name,
  };

  factory BrokerProfile.fromJson(Map<String, dynamic> json) => BrokerProfile(
    userId: json['userId'] as String? ?? '',
    agencyId: json['agencyId'] as String?,
    name: json['name'] as String? ?? '',
    phoneNumber: json['phoneNumber'] as String? ?? '',
    photoUrl: json['photoUrl'] as String?,
    specializations: (json['specializations'] as List<dynamic>?)?.cast<String>() ?? [],
    areasServed: (json['areasServed'] as List<dynamic>?)?.cast<String>() ?? [],
    experienceYears: (json['experienceYears'] as num?)?.toInt() ?? 0,
    clientCount: (json['clientCount'] as num?)?.toInt() ?? 0,
    profilesManaged: (json['profilesManaged'] as num?)?.toInt() ?? 0,
    rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    bio: json['bio'] as String? ?? '',
    isOnline: json['isOnline'] as bool? ?? false,
    lastSeen: DateTime.tryParse(json['lastSeen'] as String? ?? '') ?? DateTime.now(),
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    // New fields
    email: json['email'] as String?,
    officeAddress: json['officeAddress'] as String?,
    website: json['website'] as String?,
    licenseNumber: json['licenseNumber'] as String?,
    languagesSpoken: (json['languagesSpoken'] as List<dynamic>?)?.cast<String>() ?? [],
    totalSuccessfulMatches: (json['totalSuccessfulMatches'] as num?)?.toInt() ?? 0,
    feeStructure: json['feeStructure'] as String?,
    workingHours: json['workingHours'] as String?,
    socialMediaLinks: (json['socialMediaLinks'] as Map<String, dynamic>?)
        ?.map((k, v) => MapEntry(k, v.toString())) ?? {},
    verificationStatus: VerificationStatus.values.firstWhere(
      (e) => e.name == (json['verificationStatus'] as String?),
      orElse: () => VerificationStatus.unverified,
    ),
  );

  BrokerProfile copyWith({
    String? agencyId,
    String? name,
    String? photoUrl,
    List<String>? specializations,
    List<String>? areasServed,
    int? experienceYears,
    int? clientCount,
    int? profilesManaged,
    double? rating,
    String? bio,
    bool? isOnline,
    DateTime? lastSeen,
    // New fields
    String? email,
    String? officeAddress,
    String? website,
    String? licenseNumber,
    List<String>? languagesSpoken,
    int? totalSuccessfulMatches,
    String? feeStructure,
    String? workingHours,
    Map<String, String>? socialMediaLinks,
    VerificationStatus? verificationStatus,
  }) => BrokerProfile(
    userId: userId,
    agencyId: agencyId ?? this.agencyId,
    name: name ?? this.name,
    phoneNumber: phoneNumber,
    photoUrl: photoUrl ?? this.photoUrl,
    specializations: specializations ?? this.specializations,
    areasServed: areasServed ?? this.areasServed,
    experienceYears: experienceYears ?? this.experienceYears,
    clientCount: clientCount ?? this.clientCount,
    profilesManaged: profilesManaged ?? this.profilesManaged,
    rating: rating ?? this.rating,
    bio: bio ?? this.bio,
    isOnline: isOnline ?? this.isOnline,
    lastSeen: lastSeen ?? this.lastSeen,
    createdAt: createdAt,
    email: email ?? this.email,
    officeAddress: officeAddress ?? this.officeAddress,
    website: website ?? this.website,
    licenseNumber: licenseNumber ?? this.licenseNumber,
    languagesSpoken: languagesSpoken ?? this.languagesSpoken,
    totalSuccessfulMatches: totalSuccessfulMatches ?? this.totalSuccessfulMatches,
    feeStructure: feeStructure ?? this.feeStructure,
    workingHours: workingHours ?? this.workingHours,
    socialMediaLinks: socialMediaLinks ?? this.socialMediaLinks,
    verificationStatus: verificationStatus ?? this.verificationStatus,
  );
}
