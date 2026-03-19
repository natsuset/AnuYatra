import 'dart:convert';

import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

import 'package:testing_flutter/core/data/repositories/shared_profile_repository.dart';
import 'package:testing_flutter/models/shared_profile.dart';

const _uuid = Uuid();

/// Hive-backed implementation of [SharedProfileRepository].
class HiveSharedProfileRepository implements SharedProfileRepository {
  final Box<String> _sharedProfiles;

  HiveSharedProfileRepository({required Box<String> sharedProfilesBox})
      : _sharedProfiles = sharedProfilesBox;

  @override
  Future<SharedProfile> shareProfile({
    required String profileId,
    required String sharedByUserId,
    required String sharedWithUserId,
  }) async {
    final id = _uuid.v4();
    final shared = SharedProfile(
      id: id,
      profileId: profileId,
      sharedByUserId: sharedByUserId,
      sharedWithUserId: sharedWithUserId,
      sharedAt: DateTime.now(),
    );
    await _sharedProfiles.put(id, jsonEncode(shared.toJson()));
    return shared;
  }

  @override
  Future<void> saveSharedProfile(SharedProfile shared) async {
    await _sharedProfiles.put(shared.id, jsonEncode(shared.toJson()));
  }

  @override
  Future<void> updateSharedProfile(SharedProfile shared) async {
    await _sharedProfiles.put(shared.id, jsonEncode(shared.toJson()));
  }

  @override
  Future<List<SharedProfile>> getSharedProfilesForUser(
    String userId, {
    int? limit,
    int? offset,
  }) async {
    var results = (await getAllSharedProfiles())
        .where((s) => s.sharedWithUserId == userId)
        .toList()
      ..sort((a, b) => b.sharedAt.compareTo(a.sharedAt));

    if (offset != null && offset > 0) {
      results = results.skip(offset).toList();
    }
    if (limit != null && limit > 0) {
      results = results.take(limit).toList();
    }

    return results;
  }

  @override
  Future<List<SharedProfile>> getSharedProfilesByBroker(
    String brokerUserId, {
    int? limit,
    int? offset,
  }) async {
    var results = (await getAllSharedProfiles())
        .where((s) => s.sharedByUserId == brokerUserId)
        .toList()
      ..sort((a, b) => b.sharedAt.compareTo(a.sharedAt));

    if (offset != null && offset > 0) {
      results = results.skip(offset).toList();
    }
    if (limit != null && limit > 0) {
      results = results.take(limit).toList();
    }

    return results;
  }

  @override
  Future<void> forwardProfileToChild(String sharedProfileId) async {
    final all = await getAllSharedProfiles();
    final shared = all.where((s) => s.id == sharedProfileId).firstOrNull;
    if (shared == null) return;
    final updated = shared.copyWith(forwardedToChild: true);
    await _sharedProfiles.put(updated.id, jsonEncode(updated.toJson()));
  }

  @override
  Future<List<SharedProfile>> getForwardedProfiles(
    String parentUserId, {
    int? limit,
    int? offset,
  }) async {
    var results = (await getAllSharedProfiles())
        .where(
            (s) => s.sharedWithUserId == parentUserId && s.forwardedToChild)
        .toList()
      ..sort((a, b) => b.sharedAt.compareTo(a.sharedAt));

    if (offset != null && offset > 0) {
      results = results.skip(offset).toList();
    }
    if (limit != null && limit > 0) {
      results = results.take(limit).toList();
    }

    return results;
  }

  @override
  Future<List<SharedProfile>> getAllSharedProfiles({
    int? limit,
    int? offset,
  }) async {
    var results = _sharedProfiles.values
        .map((raw) =>
            SharedProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList();

    if (offset != null && offset > 0) {
      results = results.skip(offset).toList();
    }
    if (limit != null && limit > 0) {
      results = results.take(limit).toList();
    }

    return results;
  }
}
