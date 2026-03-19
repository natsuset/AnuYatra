import 'dart:convert';

import 'package:hive_ce/hive.dart';

import 'package:testing_flutter/core/data/repositories/profile_repository.dart';
import 'package:testing_flutter/core/data/repositories/shared_profile_repository.dart';
import 'package:testing_flutter/models/candidate_profile.dart';
import 'package:testing_flutter/models/parent_profile.dart';

/// Hive-backed implementation of [ProfileRepository].
class HiveProfileRepository implements ProfileRepository {
  final Box<String> _parentProfiles;
  final Box<String> _candidateProfiles;

  late final SharedProfileRepository _sharedProfileRepo;

  HiveProfileRepository({
    required Box<String> parentProfilesBox,
    required Box<String> candidateProfilesBox,
  })  : _parentProfiles = parentProfilesBox,
        _candidateProfiles = candidateProfilesBox;

  /// Must be called after all repositories are constructed.
  void init({required SharedProfileRepository sharedProfileRepo}) {
    _sharedProfileRepo = sharedProfileRepo;
  }

  // ── Parent Profiles ──

  @override
  Future<void> saveParentProfile(ParentProfile profile) async {
    await _parentProfiles.put(
        profile.userId, jsonEncode(profile.toJson()));
  }

  @override
  Future<ParentProfile?> getParentProfile(String userId) async {
    final raw = _parentProfiles.get(userId);
    if (raw == null) return null;
    return ParentProfile.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<List<ParentProfile>> getAllParentProfiles({
    int? limit,
    int? offset,
  }) async {
    var results = _parentProfiles.values
        .map((raw) =>
            ParentProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList();

    if (offset != null && offset > 0) {
      results = results.skip(offset).toList();
    }
    if (limit != null && limit > 0) {
      results = results.take(limit).toList();
    }

    return results;
  }

  // ── Candidate Profiles ──

  @override
  Future<void> saveCandidateProfile(CandidateProfile profile) async {
    await _candidateProfiles.put(profile.id, jsonEncode(profile.toJson()));
  }

  @override
  Future<CandidateProfile?> getCandidateProfile(String id) async {
    final raw = _candidateProfiles.get(id);
    if (raw == null) return null;
    return CandidateProfile.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<List<CandidateProfile>> getAllCandidateProfiles({
    int? limit,
    int? offset,
  }) async {
    var results = _candidateProfiles.values
        .map((raw) => CandidateProfile.fromJson(
            jsonDecode(raw) as Map<String, dynamic>))
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
  Future<List<CandidateProfile>> getCandidatesByBroker(
    String brokerUserId, {
    int? limit,
    int? offset,
  }) async {
    var results = (await getAllCandidateProfiles())
        .where((p) =>
            p.brokerIds.contains(brokerUserId) ||
            p.createdByUserId == brokerUserId)
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
  Future<List<CandidateProfile>> getSharedCandidatesForParent(
    String parentUserId,
  ) async {
    final shared =
        await _sharedProfileRepo.getSharedProfilesForUser(parentUserId);
    final profileIds = shared.map((s) => s.profileId).toSet();
    return (await getAllCandidateProfiles())
        .where((p) => profileIds.contains(p.id))
        .toList();
  }
}
