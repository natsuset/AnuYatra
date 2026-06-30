import 'package:testing_flutter/core/data/remote/api_client.dart';
import 'package:testing_flutter/core/data/repositories/profile_repository.dart';
import 'package:testing_flutter/core/errors/app_exceptions.dart';
import 'package:testing_flutter/models/candidate_profile.dart';
import 'package:testing_flutter/models/parent_profile.dart';

class RemoteProfileRepository implements ProfileRepository {
  final ApiClient _api;

  RemoteProfileRepository(this._api);

  // ── Parent Profiles ──

  @override
  Future<void> saveParentProfile(ParentProfile profile) async {
    await _api.put('/api/v1/parent-profiles/me', body: profile.toJson());
  }

  @override
  Future<ParentProfile?> getParentProfile(String userId) async {
    try {
      final data = await _api.get('/api/v1/parent-profiles/$userId');
      return ParentProfile.fromJson(data);
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<List<ParentProfile>> getAllParentProfiles({
    int? limit,
    int? offset,
  }) async {
    final params = <String, String>{};
    if (limit != null) params['limit'] = '$limit';
    if (offset != null) params['offset'] = '$offset';
    final data = await _api.get('/api/v1/parent-profiles', queryParams: params);
    return _listFromJson(data, ParentProfile.fromJson);
  }

  // ── Candidate Profiles ──

  @override
  Future<void> saveCandidateProfile(CandidateProfile profile) async {
    if (profile.id.isEmpty) {
      await _api.post('/api/v1/candidate-profiles', body: profile.toJson());
    } else {
      await _api.put(
        '/api/v1/candidate-profiles/${profile.id}',
        body: profile.toJson(),
      );
    }
  }

  @override
  Future<CandidateProfile?> getCandidateProfile(String id) async {
    try {
      final data = await _api.get('/api/v1/candidate-profiles/$id');
      return CandidateProfile.fromJson(data);
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<List<CandidateProfile>> getAllCandidateProfiles({
    int? limit,
    int? offset,
  }) async {
    final data = await _api.get(
      '/api/v1/candidate-profiles',
      queryParams: _paginationParams(limit, offset),
    );
    return _listFromJson(data, CandidateProfile.fromJson);
  }

  @override
  Future<List<CandidateProfile>> getCandidatesByBroker(
    String brokerUserId, {
    int? limit,
    int? offset,
  }) async {
    final params = _paginationParams(limit, offset);
    params['brokerId'] = brokerUserId;
    final data = await _api.get('/api/v1/candidate-profiles', queryParams: params);
    return _listFromJson(data, CandidateProfile.fromJson);
  }

  @override
  Future<List<CandidateProfile>> getSharedCandidatesForParent(
    String parentUserId,
  ) async {
    final spData = await _api.get('/api/v1/shared-profiles/for-me');
    final items = spData['data'] as List<dynamic>? ?? [];
    final profiles = <CandidateProfile>[];
    for (final sp in items) {
      final profileId = (sp as Map<String, dynamic>)['profileId'] as String?;
      if (profileId != null) {
        final cp = await getCandidateProfile(profileId);
        if (cp != null) profiles.add(cp);
      }
    }
    return profiles;
  }
}

Map<String, String> _paginationParams(int? limit, int? offset) {
  final params = <String, String>{};
  if (limit != null) params['limit'] = '$limit';
  if (offset != null) params['offset'] = '$offset';
  return params;
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
