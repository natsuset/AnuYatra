import 'package:testing_flutter/core/data/remote/api_client.dart';
import 'package:testing_flutter/core/data/repositories/shared_profile_repository.dart';
import 'package:testing_flutter/models/shared_profile.dart';

class RemoteSharedProfileRepository implements SharedProfileRepository {
  final ApiClient _api;

  RemoteSharedProfileRepository(this._api);

  @override
  Future<SharedProfile> shareProfile({
    required String profileId,
    required String sharedByUserId,
    required String sharedWithUserId,
  }) async {
    final data = await _api.post('/api/v1/shared-profiles', body: {
      'profileId': profileId,
      'sharedWithUserId': sharedWithUserId,
    });
    return SharedProfile.fromJson(data);
  }

  @override
  Future<void> saveSharedProfile(SharedProfile shared) async {}

  @override
  Future<void> updateSharedProfile(SharedProfile shared) async {
    await _api.put(
      '/api/v1/shared-profiles/${shared.id}/respond',
      body: {
        'response': shared.parentResponse.name,
        'parentNote': shared.parentNote,
      },
    );
  }

  @override
  Future<List<SharedProfile>> getSharedProfilesForUser(
    String userId, {
    int? limit,
    int? offset,
  }) async {
    final data = await _api.get(
      '/api/v1/shared-profiles/for-me',
      queryParams: _p(limit, offset),
    );
    return _parse(data);
  }

  @override
  Future<List<SharedProfile>> getSharedProfilesByBroker(
    String brokerUserId, {
    int? limit,
    int? offset,
  }) async {
    final data = await _api.get(
      '/api/v1/shared-profiles/by-me',
      queryParams: _p(limit, offset),
    );
    return _parse(data);
  }

  @override
  Future<void> forwardProfileToChild(String sharedProfileId) async {
    await _api.post('/api/v1/shared-profiles/$sharedProfileId/forward');
  }

  @override
  Future<List<SharedProfile>> getForwardedProfiles(
    String parentUserId, {
    int? limit,
    int? offset,
  }) async {
    final data = await _api.get(
      '/api/v1/shared-profiles/forwarded',
      queryParams: _p(limit, offset),
    );
    return _parse(data);
  }

  @override
  Future<List<SharedProfile>> getAllSharedProfiles({
    int? limit,
    int? offset,
  }) async {
    return getSharedProfilesForUser('', limit: limit, offset: offset);
  }

  List<SharedProfile> _parse(Map<String, dynamic> response) {
    final items = response['data'] as List<dynamic>? ?? [];
    return items
        .cast<Map<String, dynamic>>()
        .map(SharedProfile.fromJson)
        .toList(growable: false);
  }

  Map<String, String> _p(int? limit, int? offset) {
    final params = <String, String>{};
    if (limit != null) params['limit'] = '$limit';
    if (offset != null) params['offset'] = '$offset';
    return params;
  }
}
