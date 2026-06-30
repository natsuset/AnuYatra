import 'package:testing_flutter/core/data/remote/api_client.dart';
import 'package:testing_flutter/core/data/repositories/broker_repository.dart';
import 'package:testing_flutter/core/errors/app_exceptions.dart';
import 'package:testing_flutter/models/broker_profile.dart';

class RemoteBrokerRepository implements BrokerRepository {
  final ApiClient _api;

  RemoteBrokerRepository(this._api);

  @override
  Future<void> saveBrokerProfile(BrokerProfile profile) async {
    await _api.put('/api/v1/broker-profiles/me', body: profile.toJson());
  }

  @override
  Future<BrokerProfile?> getBrokerProfile(String userId) async {
    try {
      final data = await _api.get('/api/v1/broker-profiles/$userId');
      return BrokerProfile.fromJson(data);
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<List<BrokerProfile>> getAllBrokerProfiles({
    int? limit,
    int? offset,
  }) async {
    final params = <String, String>{};
    if (limit != null) params['limit'] = '$limit';
    if (offset != null) params['offset'] = '$offset';
    final data = await _api.get('/api/v1/broker-profiles', queryParams: params);
    return _listFromJson(data, BrokerProfile.fromJson);
  }

  @override
  Future<List<BrokerProfile>> getBrokersByAgency(
    String agencyId, {
    int? limit,
    int? offset,
  }) async {
    final params = <String, String>{};
    if (limit != null) params['limit'] = '$limit';
    if (offset != null) params['offset'] = '$offset';
    final data = await _api.get(
      '/api/v1/agencies/$agencyId/brokers',
      queryParams: params,
    );
    return _listFromJson(data, BrokerProfile.fromJson);
  }

  @override
  Future<List<BrokerProfile>> searchBrokers({
    String? query,
    String? city,
    double? minRating,
    int? limit,
    int? offset,
  }) async {
    final params = <String, String>{};
    if (query != null) params['q'] = query;
    if (city != null) params['city'] = city;
    if (minRating != null) params['minRating'] = '$minRating';
    if (limit != null) params['limit'] = '$limit';
    if (offset != null) params['offset'] = '$offset';
    final data = await _api.get('/api/v1/broker-profiles', queryParams: params);
    return _listFromJson(data, BrokerProfile.fromJson);
  }

  @override
  Future<BrokerStats> getBrokerStats(String brokerUserId) async {
    try {
      final data = await _api.get('/api/v1/broker-profiles/$brokerUserId/stats');
      return BrokerStats(
        activeClients: data['activeClients'] as int? ?? 0,
        profilesManaged: data['profilesManaged'] as int? ?? 0,
        profilesShared: data['profilesShared'] as int? ?? 0,
        pendingRequests: data['pendingRequests'] as int? ?? 0,
      );
    } catch (_) {
      return BrokerStats.empty;
    }
  }

  @override
  Future<AgencyStats> getAgencyStats(String agencyId) async {
    try {
      final data = await _api.get('/api/v1/agencies/$agencyId/stats');
      return AgencyStats(
        totalBrokers: data['totalBrokers'] as int? ?? 0,
        totalClients: data['totalClients'] as int? ?? 0,
        totalProfiles: data['totalProfiles'] as int? ?? 0,
      );
    } catch (_) {
      return AgencyStats.empty;
    }
  }
}

List<T> _listFromJson<T>(
  Map<String, dynamic> response,
  T Function(Map<String, dynamic>) fromJson,
) {
  final items = response['data'] as List<dynamic>? ?? [];
  return items
      .cast<Map<String, dynamic>>()
      .map(fromJson)
      .toList(growable: false);
}
