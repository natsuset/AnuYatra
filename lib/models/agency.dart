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
  });

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
  };

  factory Agency.fromJson(Map<String, dynamic> json) => Agency(
    id: json['id'] as String,
    adminUserId: json['adminUserId'] as String,
    name: json['name'] as String,
    logoUrl: json['logoUrl'] as String?,
    city: json['city'] as String,
    state: json['state'] as String,
    description: json['description'] as String? ?? '',
    specializations: (json['specializations'] as List<dynamic>?)?.cast<String>() ?? [],
    areasServed: (json['areasServed'] as List<dynamic>?)?.cast<String>() ?? [],
    rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    isActive: json['isActive'] as bool? ?? true,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  Agency copyWith({
    String? name,
    String? logoUrl,
    String? description,
    List<String>? specializations,
    List<String>? areasServed,
    double? rating,
    bool? isActive,
  }) => Agency(
    id: id,
    adminUserId: adminUserId,
    name: name ?? this.name,
    logoUrl: logoUrl ?? this.logoUrl,
    city: city,
    state: state,
    description: description ?? this.description,
    specializations: specializations ?? this.specializations,
    areasServed: areasServed ?? this.areasServed,
    rating: rating ?? this.rating,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt,
  );
}
