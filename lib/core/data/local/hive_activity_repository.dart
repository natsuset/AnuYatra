import 'dart:convert';

import 'package:hive_ce/hive.dart';

import 'package:testing_flutter/core/data/repositories/activity_repository.dart';
import 'package:testing_flutter/models/profile_activity.dart';

/// Hive-backed [ActivityRepository].
///
/// Keys are `{profileId}_{eventId}` so we can scan a profile's events by
/// key prefix without decoding the whole box. Cap per profile = 50.
class HiveActivityRepository implements ActivityRepository {
  final Box<String> _box;
  final int maxPerProfile;

  HiveActivityRepository({
    required Box<String> activityBox,
    this.maxPerProfile = 50,
  }) : _box = activityBox;

  String _key(String profileId, String eventId) => '${profileId}_$eventId';

  Iterable<String> _keysForProfile(String profileId) {
    final prefix = '${profileId}_';
    return _box.keys.whereType<String>().where((k) => k.startsWith(prefix));
  }

  @override
  Future<void> record(ProfileActivity event) async {
    await _box.put(_key(event.profileId, event.id), jsonEncode(event.toJson()));

    // Prune to the cap.
    final keys = _keysForProfile(event.profileId).toList();
    if (keys.length > maxPerProfile) {
      final rows = keys
          .map((k) => MapEntry(
                k,
                ProfileActivity.fromJson(
                  jsonDecode(_box.get(k)!) as Map<String, dynamic>,
                ),
              ))
          .toList()
        ..sort((a, b) => a.value.at.compareTo(b.value.at));
      final toEvict = keys.length - maxPerProfile;
      for (var i = 0; i < toEvict; i++) {
        await _box.delete(rows[i].key);
      }
    }
  }

  @override
  Future<List<ProfileActivity>> getActivityForProfile(
    String profileId, {
    int limit = 50,
  }) async {
    final rows = _keysForProfile(profileId)
        .map((k) =>
            ProfileActivity.fromJson(jsonDecode(_box.get(k)!) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.at.compareTo(a.at));
    if (limit > 0 && rows.length > limit) return rows.take(limit).toList();
    return rows;
  }
}
