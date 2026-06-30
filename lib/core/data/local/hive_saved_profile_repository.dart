import 'dart:convert';

import 'package:hive_ce/hive.dart';

import 'package:testing_flutter/core/data/repositories/saved_profile_repository.dart';
import 'package:testing_flutter/models/saved_profile.dart';

/// Hive-backed implementation of [SavedProfileRepository].
///
/// One Hive entry per save, keyed by the composite `{userId}_{profileId}`
/// id. This makes idempotent save/unsave O(1) and lets us scan by user
/// via a key-prefix filter.
class HiveSavedProfileRepository implements SavedProfileRepository {
  final Box<String> _box;

  HiveSavedProfileRepository({required Box<String> savedProfilesBox})
      : _box = savedProfilesBox;

  String _key(String userId, String profileId) => '${userId}_$profileId';

  @override
  Future<bool> isSaved({
    required String userId,
    required String profileId,
  }) async {
    return _box.containsKey(_key(userId, profileId));
  }

  @override
  Future<SavedProfile> save({
    required String userId,
    required String profileId,
  }) async {
    final key = _key(userId, profileId);
    final existing = _box.get(key);
    if (existing != null) {
      return SavedProfile.fromJson(
        jsonDecode(existing) as Map<String, dynamic>,
      );
    }
    final record = SavedProfile.create(userId: userId, profileId: profileId);
    await _box.put(key, jsonEncode(record.toJson()));
    return record;
  }

  @override
  Future<void> unsave({
    required String userId,
    required String profileId,
  }) async {
    await _box.delete(_key(userId, profileId));
  }

  @override
  Future<bool> toggle({
    required String userId,
    required String profileId,
  }) async {
    if (await isSaved(userId: userId, profileId: profileId)) {
      await unsave(userId: userId, profileId: profileId);
      return false;
    }
    await save(userId: userId, profileId: profileId);
    return true;
  }

  @override
  Future<List<SavedProfile>> getSavedProfilesForUser(
    String userId, {
    int? limit,
    int? offset,
  }) async {
    final prefix = '${userId}_';
    final records = _box.keys
        .whereType<String>()
        .where((k) => k.startsWith(prefix))
        .map((k) =>
            SavedProfile.fromJson(jsonDecode(_box.get(k)!) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));

    Iterable<SavedProfile> view = records;
    if (offset != null && offset > 0) view = view.skip(offset);
    if (limit != null && limit > 0) view = view.take(limit);
    return identical(view, records) ? records : view.toList();
  }

  @override
  Future<int> getSavedCount(String userId) async {
    final prefix = '${userId}_';
    return _box.keys.whereType<String>().where((k) => k.startsWith(prefix)).length;
  }
}
