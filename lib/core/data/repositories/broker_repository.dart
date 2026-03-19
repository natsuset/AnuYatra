import 'package:testing_flutter/models/broker_profile.dart';

/// Contract for broker profile CRUD, search, and stats.
abstract class BrokerRepository {
  /// Persist a broker profile (create or update).
  Future<void> saveBrokerProfile(BrokerProfile profile);

  /// Get a broker profile by the broker's user ID.
  Future<BrokerProfile?> getBrokerProfile(String userId);

  /// Get all broker profiles, with optional pagination.
  Future<List<BrokerProfile>> getAllBrokerProfiles({int? limit, int? offset});

  /// Get brokers belonging to a specific agency.
  Future<List<BrokerProfile>> getBrokersByAgency(
    String agencyId, {
    int? limit,
    int? offset,
  });

  /// Search brokers by query, city, and/or minimum rating.
  Future<List<BrokerProfile>> searchBrokers({
    String? query,
    String? city,
    double? minRating,
    int? limit,
    int? offset,
  });

  /// Get dashboard statistics for a broker.
  ///
  /// Returns a map with keys: activeClients, profilesManaged,
  /// profilesShared, pendingRequests.
  Future<Map<String, int>> getBrokerStats(String brokerUserId);

  /// Get dashboard statistics for an agency.
  ///
  /// Returns a map with keys: totalBrokers, totalClients, totalProfiles.
  Future<Map<String, int>> getAgencyStats(String agencyId);
}
