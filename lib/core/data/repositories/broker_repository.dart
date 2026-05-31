import 'package:testing_flutter/models/broker_profile.dart';

/// Dashboard statistics for a single broker.
class BrokerStats {
  final int activeClients;
  final int profilesManaged;
  final int profilesShared;
  final int pendingRequests;

  const BrokerStats({
    required this.activeClients,
    required this.profilesManaged,
    required this.profilesShared,
    required this.pendingRequests,
  });

  /// Zero-valued stats, useful for initial/loading states.
  static const empty = BrokerStats(
    activeClients: 0,
    profilesManaged: 0,
    profilesShared: 0,
    pendingRequests: 0,
  );
}

/// Dashboard statistics for an agency aggregated across its brokers.
class AgencyStats {
  final int totalBrokers;
  final int totalClients;
  final int totalProfiles;

  const AgencyStats({
    required this.totalBrokers,
    required this.totalClients,
    required this.totalProfiles,
  });

  /// Zero-valued stats, useful for initial/loading states.
  static const empty = AgencyStats(
    totalBrokers: 0,
    totalClients: 0,
    totalProfiles: 0,
  );
}

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
  Future<BrokerStats> getBrokerStats(String brokerUserId);

  /// Get dashboard statistics for an agency aggregated across its brokers.
  Future<AgencyStats> getAgencyStats(String agencyId);
}
