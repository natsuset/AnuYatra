import 'dart:convert';

import 'package:hive_ce/hive.dart';

import 'package:testing_flutter/core/data/repositories/meeting_repository.dart';
import 'package:testing_flutter/models/meeting.dart';

/// Hive-backed [MeetingRepository].
///
/// Keys are `{candidateProfileId}_{parentUserId}_{meetingId}` so meetings
/// for a `(parent, candidate)` pair can be retrieved via key prefix.
/// Visibility filtering happens at read time based on the viewer's id.
class HiveMeetingRepository implements MeetingRepository {
  final Box<String> _box;

  HiveMeetingRepository({required Box<String> meetingsBox}) : _box = meetingsBox;

  String _key(String candidateProfileId, String parentUserId, String meetingId) =>
      '${candidateProfileId}_${parentUserId}_$meetingId';

  String _prefix(String candidateProfileId, String parentUserId) =>
      '${candidateProfileId}_${parentUserId}_';

  bool _isVisible(Meeting m, String viewerUserId) {
    if (viewerUserId == m.brokerUserId) return m.brokerVisible;
    // Parent + candidate share the "parent party" visibility.
    if (viewerUserId == m.parentUserId) return m.parentPartyVisible;
    return m.parentPartyVisible;
  }

  @override
  Future<void> save(Meeting meeting) async {
    await _box.put(
      _key(meeting.candidateProfileId, meeting.parentUserId, meeting.id),
      jsonEncode(meeting.toJson()),
    );
  }

  @override
  Future<Meeting?> get(String id) async {
    for (final key in _box.keys.whereType<String>()) {
      if (key.endsWith('_$id')) {
        return Meeting.fromJson(jsonDecode(_box.get(key)!) as Map<String, dynamic>);
      }
    }
    return null;
  }

  @override
  Future<List<Meeting>> getMeetingsFor({
    required String parentUserId,
    required String candidateProfileId,
    required String viewerUserId,
    int? limit,
  }) async {
    final prefix = _prefix(candidateProfileId, parentUserId);
    final rows = _box.keys
        .whereType<String>()
        .where((k) => k.startsWith(prefix))
        .map((k) => Meeting.fromJson(
              jsonDecode(_box.get(k)!) as Map<String, dynamic>,
            ))
        .where((m) => _isVisible(m, viewerUserId))
        .toList()
      ..sort((a, b) => a.when.compareTo(b.when));
    if (limit != null && limit > 0 && rows.length > limit) {
      return rows.take(limit).toList();
    }
    return rows;
  }

  @override
  Future<Meeting?> getNextMeeting({
    required String parentUserId,
    required String candidateProfileId,
    required String viewerUserId,
  }) async {
    final now = DateTime.now();
    final all = await getMeetingsFor(
      parentUserId: parentUserId,
      candidateProfileId: candidateProfileId,
      viewerUserId: viewerUserId,
    );
    for (final m in all) {
      if (m.status == MeetingStatus.scheduled && m.when.isAfter(now)) return m;
    }
    return null;
  }

  @override
  Future<void> cancel(String meetingId) async {
    final existing = await get(meetingId);
    if (existing == null) return;
    await save(existing.copyWith(status: MeetingStatus.cancelled));
  }
}
