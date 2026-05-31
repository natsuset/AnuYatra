import 'dart:convert';

import 'package:hive_ce/hive.dart';

import 'package:testing_flutter/core/data/repositories/broker_repository.dart';
import 'package:testing_flutter/core/data/repositories/link_repository.dart';
import 'package:testing_flutter/core/data/repositories/profile_repository.dart';
import 'package:testing_flutter/core/data/repositories/shared_profile_repository.dart';
import 'package:testing_flutter/models/broker_profile.dart';

/// Hive-backed implementation of [BrokerRepository].
///
/// Stats methods depend on other repositories (link, profile, shared profile).
/// These are injected lazily to avoid circular initialization.
class HiveBrokerRepository implements BrokerRepository {
  final Box<String> _brokerProfiles;

  /// Lazily-resolved references for cross-domain stat queries.
  late final LinkRepository _linkRepo;
  late final ProfileRepository _profileRepo;
  late final SharedProfileRepository _sharedProfileRepo;

  HiveBrokerRepository({
    required Box<String> brokerProfilesBox,
  }) : _brokerProfiles = brokerProfilesBox;

  /// Must be called after all repositories are constructed.
  void init({
    required LinkRepository linkRepo,
    required ProfileRepository profileRepo,
    required SharedProfileRepository sharedProfileRepo,
  }) {
    _linkRepo = linkRepo;
    _profileRepo = profileRepo;
    _sharedProfileRepo = sharedProfileRepo;
  }

  @override
  Future<void> saveBrokerProfile(BrokerProfile profile) async {
    await _brokerProfiles.put(
        profile.userId, jsonEncode(profile.toJson()));
  }

  @override
  Future<BrokerProfile?> getBrokerProfile(String userId) async {
    final raw = _brokerProfiles.get(userId);
    if (raw == null) return null;
    return BrokerProfile.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<List<BrokerProfile>> getAllBrokerProfiles({
    int? limit,
    int? offset,
  }) async {
    var results = _brokerProfiles.values
        .map((raw) =>
            BrokerProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList()
      // Highest rating first; ties broken by newest createdAt.
      ..sort((a, b) {
        final r = b.rating.compareTo(a.rating);
        return r != 0 ? r : b.createdAt.compareTo(a.createdAt);
      });

    if (offset != null && offset > 0) {
      results = results.skip(offset).toList();
    }
    if (limit != null && limit > 0) {
      results = results.take(limit).toList();
    }

    return results;
  }

  @override
  Future<List<BrokerProfile>> getBrokersByAgency(
    String agencyId, {
    int? limit,
    int? offset,
  }) async {
    var results = (await getAllBrokerProfiles())
        .where((b) => b.agencyId == agencyId)
        .toList();

    if (offset != null && offset > 0) {
      results = results.skip(offset).toList();
    }
    if (limit != null && limit > 0) {
      results = results.take(limit).toList();
    }

    return results;
  }

  @override
  Future<List<BrokerProfile>> searchBrokers({
    String? query,
    String? city,
    double? minRating,
    int? limit,
    int? offset,
  }) async {
    var results = await getAllBrokerProfiles();

    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      results = results
          .where((b) =>
              b.name.toLowerCase().contains(q) ||
              b.bio.toLowerCase().contains(q) ||
              b.specializations.any((s) => s.toLowerCase().contains(q)) ||
              b.areasServed.any((a) => a.toLowerCase().contains(q)))
          .toList();
    }

    if (city != null) {
      results = results
          .where((b) =>
              b.areasServed.any((a) => a.toLowerCase() == city.toLowerCase()))
          .toList();
    }

    if (minRating != null) {
      results = results.where((b) => b.rating >= minRating).toList();
    }

    if (offset != null && offset > 0) {
      results = results.skip(offset).toList();
    }
    if (limit != null && limit > 0) {
      results = results.take(limit).toList();
    }

    return results;
  }

  @override
  Future<BrokerStats> getBrokerStats(String brokerUserId) async {
    final clients =
        (await _linkRepo.getConnectedParentIds(brokerUserId)).length;
    final profiles =
        (await _profileRepo.getCandidatesByBroker(brokerUserId)).length;
    final shared =
        (await _sharedProfileRepo.getSharedProfilesByBroker(brokerUserId))
            .length;
    final pending =
        (await _linkRepo.getPendingRequestsFor(brokerUserId)).length;

    return BrokerStats(
      activeClients: clients,
      profilesManaged: profiles,
      profilesShared: shared,
      pendingRequests: pending,
    );
  }

  @override
  Future<AgencyStats> getAgencyStats(String agencyId) async {
    final brokers = await getBrokersByAgency(agencyId);

    int totalClients = 0;
    int totalProfiles = 0;
    for (final broker in brokers) {
      totalClients +=
          (await _linkRepo.getConnectedParentIds(broker.userId)).length;
      totalProfiles +=
          (await _profileRepo.getCandidatesByBroker(broker.userId)).length;
    }

    return AgencyStats(
      totalBrokers: brokers.length,
      totalClients: totalClients,
      totalProfiles: totalProfiles,
    );
  }
}
