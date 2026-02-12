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
  });

  bool get isIndependent => agencyId == null;

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
  };

  factory BrokerProfile.fromJson(Map<String, dynamic> json) => BrokerProfile(
    userId: json['userId'] as String,
    agencyId: json['agencyId'] as String?,
    name: json['name'] as String,
    phoneNumber: json['phoneNumber'] as String,
    photoUrl: json['photoUrl'] as String?,
    specializations: (json['specializations'] as List<dynamic>?)?.cast<String>() ?? [],
    areasServed: (json['areasServed'] as List<dynamic>?)?.cast<String>() ?? [],
    experienceYears: json['experienceYears'] as int? ?? 0,
    clientCount: json['clientCount'] as int? ?? 0,
    profilesManaged: json['profilesManaged'] as int? ?? 0,
    rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    bio: json['bio'] as String? ?? '',
    isOnline: json['isOnline'] as bool? ?? false,
    lastSeen: DateTime.parse(json['lastSeen'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
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
  );
}
