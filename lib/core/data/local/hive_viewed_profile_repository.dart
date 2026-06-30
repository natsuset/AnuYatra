import 'dart:convert';

import 'package:hive_ce/hive.dart';

import 'package:testing_flutter/core/data/repositories/viewed_profile_repository.dart';
import 'package:testing_flutter/models/viewed_profile.dart';

/// Hive-backed implementation of [ViewedProfileRepository].
///
/// One row per `{userId}_{profileId}`. Re-viewing updates `viewedAt` in
/// place. On every `recordView` we prune the user's history down to
/// [maxPerUser] entries (default 50) — oldest evicted first.
class HiveViewedProfileRepository implements ViewedProfileRepository {
  final Box<String> _box;
  final int maxPerUser;

  HiveViewedProfileRepository({
    required Box<String> viewedProfilesBox,
    this.maxPerUser = 50,
  }) : _box = viewedProfilesBox;

  String _key(String userId, String profileId) => '${userId}_$profileId';

  Iterable<String> _keysForUser(String userId) {
    final prefix = '${userId}_';
    return _box.keys
        .whereType<String>()
        .where((k) => k.startsWith(prefix));
  }

  @override
  Future<void> recordView({
    required String userId,
    required String profileId,
  }) async {
    final key = _key(userId, profileId);
    final record = ViewedProfile.create(userId: userId, profileId: profileId);
    await _box.put(key, jsonEncode(record.toJson()));

    // Evict oldest if the user is over the cap.
    final userKeys = _keysForUser(userId).toList();
    if (userKeys.length > maxPerUser) {
      final records = userKeys
          .map((k) => MapEntry(
                k,
                ViewedProfile.fromJson(
                  jsonDecode(_box.get(k)!) as Map<String, dynamic>,
                ),
              ))
          .toList()
        ..sort((a, b) => a.value.viewedAt.compareTo(b.value.viewedAt));
      final toEvict = userKeys.length - maxPerUser;
      for (var i = 0; i < toEvict; i++) {
        await _box.delete(records[i].key);
      }
    }
  }

  @override
  Future<List<ViewedProfile>> getRecentViews(
    String userId, {
    int limit = 50,
  }) async {
    final records = _keysForUser(userId)
        .map((k) =>
            ViewedProfile.fromJson(jsonDecode(_box.get(k)!) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.viewedAt.compareTo(a.viewedAt));
    if (limit > 0 && records.length > limit) {
      return records.take(limit).toList();
    }
    return records;
  }

  @override
  Future<int> getViewCount(String userId) async {
    return _keysForUser(userId).length;
  }

  @override
  Future<void> clearHistory(String userId) async {
    final keys = _keysForUser(userId).toList();
    for (final k in keys) {
      await _box.delete(k);
    }
  }
}
