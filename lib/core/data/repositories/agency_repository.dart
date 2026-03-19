import 'package:testing_flutter/models/agency.dart';

/// Contract for agency CRUD and search.
abstract class AgencyRepository {
  /// Create a new agency, generating a unique ID.
  /// Also updates the admin user's agencyId.
  Future<Agency> createAgency({
    required String adminUserId,
    required String name,
    required String city,
    required String state,
    String? logoUrl,
    String description = '',
    List<String> specializations = const [],
    List<String> areasServed = const [],
  });

  /// Persist an agency (create or update).
  Future<void> saveAgency(Agency agency);

  /// Get an agency by its unique ID.
  Future<Agency?> getAgency(String id);

  /// Get all agencies, with optional pagination.
  Future<List<Agency>> getAllAgencies({int? limit, int? offset});

  /// Search agencies by query, city, and/or minimum rating.
  Future<List<Agency>> searchAgencies({
    String? query,
    String? city,
    double? minRating,
    int? limit,
    int? offset,
  });
}
