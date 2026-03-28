import 'package:testing_flutter/models/broker_profile.dart';

class Agency {
  final String id;
  final String adminUserId;
  final String name;
  final String? logoUrl;
  final String city;
  final String state;
  final String description;
  final List<String> specializations;
  final List<String> areasServed;
  final double rating;
  final bool isActive;
  final DateTime createdAt;

  // New business fields
  final String? email;
  final String? phone;
  final String? website;
  final int? foundedYear;
  final String? licenseNumber;
  final int totalStaff;
  final int totalSuccessfulMatches;
  final List<String> languagesServed;
  final String? feeStructure;
  final List<String> awardsAndRecognition;
  final VerificationStatus verificationStatus;
  final List<String> officeAddresses;

  const Agency({
    required this.id,
    required this.adminUserId,
    required this.name,
    this.logoUrl,
    required this.city,
    required this.state,
    this.description = '',
    this.specializations = const [],
    this.areasServed = const [],
    this.rating = 0.0,
    this.isActive = true,
    required this.createdAt,
    // New fields
    this.email,
    this.phone,
    this.website,
    this.foundedYear,
    this.licenseNumber,
    this.totalStaff = 0,
    this.totalSuccessfulMatches = 0,
    this.languagesServed = const [],
    this.feeStructure,
    this.awardsAndRecognition = const [],
    this.verificationStatus = VerificationStatus.unverified,
    this.officeAddresses = const [],
  });

  bool get isVerified => verificationStatus == VerificationStatus.verified;

  Map<String, dynamic> toJson() => {
    'id': id,
    'adminUserId': adminUserId,
    'name': name,
    'logoUrl': logoUrl,
    'city': city,
    'state': state,
    'description': description,
    'specializations': specializations,
    'areasServed': areasServed,
    'rating': rating,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    // New fields
    'email': email,
    'phone': phone,
    'website': website,
    'foundedYear': foundedYear,
    'licenseNumber': licenseNumber,
    'totalStaff': totalStaff,
    'totalSuccessfulMatches': totalSuccessfulMatches,
    'languagesServed': languagesServed,
    'feeStructure': feeStructure,
    'awardsAndRecognition': awardsAndRecognition,
    'verificationStatus': verificationStatus.name,
    'officeAddresses': officeAddresses,
  };

  factory Agency.fromJson(Map<String, dynamic> json) => Agency(
    id: json['id'] as String? ?? '',
    adminUserId: json['adminUserId'] as String? ?? '',
    name: json['name'] as String? ?? '',
    logoUrl: json['logoUrl'] as String?,
    city: json['city'] as String? ?? '',
    state: json['state'] as String? ?? '',
    description: json['description'] as String? ?? '',
    specializations: (json['specializations'] as List<dynamic>?)?.cast<String>() ?? [],
    areasServed: (json['areasServed'] as List<dynamic>?)?.cast<String>() ?? [],
    rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    isActive: json['isActive'] as bool? ?? true,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    // New fields
    email: json['email'] as String?,
    phone: json['phone'] as String?,
    website: json['website'] as String?,
    foundedYear: json['foundedYear'] as int?,
    licenseNumber: json['licenseNumber'] as String?,
    totalStaff: (json['totalStaff'] as num?)?.toInt() ?? 0,
    totalSuccessfulMatches: (json['totalSuccessfulMatches'] as num?)?.toInt() ?? 0,
    languagesServed: (json['languagesServed'] as List<dynamic>?)?.cast<String>() ?? [],
    feeStructure: json['feeStructure'] as String?,
    awardsAndRecognition: (json['awardsAndRecognition'] as List<dynamic>?)?.cast<String>() ?? [],
    verificationStatus: VerificationStatus.values.firstWhere(
      (e) => e.name == (json['verificationStatus'] as String?),
      orElse: () => VerificationStatus.unverified,
    ),
    officeAddresses: (json['officeAddresses'] as List<dynamic>?)?.cast<String>() ?? [],
  );

  Agency copyWith({
    String? name,
    String? logoUrl,
    String? city,
    String? state,
    String? description,
    List<String>? specializations,
    List<String>? areasServed,
    double? rating,
    bool? isActive,
    // New fields
    String? email,
    String? phone,
    String? website,
    int? foundedYear,
    String? licenseNumber,
    int? totalStaff,
    int? totalSuccessfulMatches,
    List<String>? languagesServed,
    String? feeStructure,
    List<String>? awardsAndRecognition,
    VerificationStatus? verificationStatus,
    List<String>? officeAddresses,
  }) => Agency(
    id: id,
    adminUserId: adminUserId,
    name: name ?? this.name,
    logoUrl: logoUrl ?? this.logoUrl,
    city: city ?? this.city,
    state: state ?? this.state,
    description: description ?? this.description,
    specializations: specializations ?? this.specializations,
    areasServed: areasServed ?? this.areasServed,
    rating: rating ?? this.rating,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    website: website ?? this.website,
    foundedYear: foundedYear ?? this.foundedYear,
    licenseNumber: licenseNumber ?? this.licenseNumber,
    totalStaff: totalStaff ?? this.totalStaff,
    totalSuccessfulMatches: totalSuccessfulMatches ?? this.totalSuccessfulMatches,
    languagesServed: languagesServed ?? this.languagesServed,
    feeStructure: feeStructure ?? this.feeStructure,
    awardsAndRecognition: awardsAndRecognition ?? this.awardsAndRecognition,
    verificationStatus: verificationStatus ?? this.verificationStatus,
    officeAddresses: officeAddresses ?? this.officeAddresses,
  );
}
