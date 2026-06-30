import 'dart:convert';

import 'package:hive_ce/hive.dart';

import 'package:testing_flutter/core/data/repositories/broker_note_repository.dart';
import 'package:testing_flutter/models/broker_note.dart';

class HiveBrokerNoteRepository implements BrokerNoteRepository {
  final Box<String> _box;

  HiveBrokerNoteRepository({required Box<String> brokerNotesBox})
      : _box = brokerNotesBox;

  String _key(String brokerId, String profileId, String parentId) =>
      '${brokerId}_${profileId}_$parentId';

  @override
  Future<BrokerNote?> get({
    required String brokerUserId,
    required String candidateProfileId,
    required String forParentUserId,
  }) async {
    final raw =
        _box.get(_key(brokerUserId, candidateProfileId, forParentUserId));
    if (raw == null) return null;
    return BrokerNote.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> upsert({
    required String brokerUserId,
    required String candidateProfileId,
    required String forParentUserId,
    required String body,
  }) async {
    final key = _key(brokerUserId, candidateProfileId, forParentUserId);
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      await _box.delete(key);
      return;
    }
    final note = BrokerNote.create(
      brokerUserId: brokerUserId,
      candidateProfileId: candidateProfileId,
      forParentUserId: forParentUserId,
      body: trimmed,
    );
    await _box.put(key, jsonEncode(note.toJson()));
  }
}
