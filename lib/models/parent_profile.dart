enum LookingFor { bride, groom }

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
  });

  String get lookingForDisplay => lookingFor == LookingFor.bride ? 'Bride' : 'Groom';

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
  };

  factory ParentProfile.fromJson(Map<String, dynamic> json) => ParentProfile(
    userId: json['userId'] as String,
    name: json['name'] as String,
    lookingFor: LookingFor.values.byName(json['lookingFor'] as String),
    city: json['city'] as String,
    state: json['state'] as String,
    preferredCommunities: (json['preferredCommunities'] as List<dynamic>?)?.cast<String>() ?? [],
    preferredMinAge: json['preferredMinAge'] as int?,
    preferredMaxAge: json['preferredMaxAge'] as int?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
