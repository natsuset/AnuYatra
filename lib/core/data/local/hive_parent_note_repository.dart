import 'dart:convert';

import 'package:hive_ce/hive.dart';

import 'package:testing_flutter/core/data/repositories/parent_note_repository.dart';
import 'package:testing_flutter/models/parent_note.dart';

/// Hive-backed multi-note implementation.
///
/// Storage key strategy: each note is stored under its UUID [ParentNote.id].
/// An index key `_idx_{parentId}_{profileId}` holds a JSON list of note IDs
/// belonging to that (parent, profile) pair, enabling O(k) lookups where k
/// is the number of notes per profile rather than a full box scan.
///
/// Legacy single-note records (key was `{parentId}_{profileId}`) are
/// transparently migrated on first read.
class HiveParentNoteRepository implements ParentNoteRepository {
  final Box<String> _box;

  HiveParentNoteRepository({required Box<String> parentNotesBox})
      : _box = parentNotesBox;

  // ── Key helpers ────────────────────────────────────────────────────────────

  String _idxKey(String parentId, String profileId) =>
      '_idx_${parentId}_$profileId';

  /// Legacy key used by the old single-note upsert. If found, the record is
  /// migrated to the new multi-note format and deleted.
  String _legacyKey(String parentId, String profileId) =>
      '${parentId}_$profileId';

  // ── Migration ──────────────────────────────────────────────────────────────

  /// Migrates a legacy single-note entry if present, returning the resulting
  /// new note (or null if nothing to migrate).
  Future<ParentNote?> _migrateIfNeeded(
    String parentId,
    String profileId,
  ) async {
    final legacyKey = _legacyKey(parentId, profileId);
    final raw = _box.get(legacyKey);
    if (raw == null) return null;

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      // Old records had id == legacyKey and no 'type' field; detect by absence.
      if (json.containsKey('type') && json['id'] != legacyKey) return null;

      final note = ParentNote.fromLegacy(json);
      await _box.delete(legacyKey);
      await saveNote(note);
      return note;
    } catch (_) {
      return null;
    }
  }

  // ── Index helpers ──────────────────────────────────────────────────────────

  Future<List<String>> _readIndex(String parentId, String profileId) async {
    final raw = _box.get(_idxKey(parentId, profileId));
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>).cast<String>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeIndex(
    String parentId,
    String profileId,
    List<String> ids,
  ) async {
    await _box.put(_idxKey(parentId, profileId), jsonEncode(ids));
  }

  // ── ParentNoteRepository ───────────────────────────────────────────────────

  @override
  Future<List<ParentNote>> getNotesForProfile({
    required String parentUserId,
    required String candidateProfileId,
  }) async {
    // Migrate legacy record first (no-op if already migrated)
    await _migrateIfNeeded(parentUserId, candidateProfileId);

    final ids = await _readIndex(parentUserId, candidateProfileId);
    final notes = <ParentNote>[];
    for (final id in ids) {
      final raw = _box.get(id);
      if (raw == null) continue;
      try {
        notes.add(ParentNote.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {}
    }
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }

  @override
  Future<List<ParentNote>> getAllNotesForParent(String parentUserId) async {
    final allNotes = <ParentNote>[];
    for (final raw in _box.values) {
      // Skip index entries
      if (raw.startsWith('[')) continue;
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        if (json['parentUserId'] == parentUserId && json.containsKey('type')) {
          allNotes.add(ParentNote.fromJson(json));
        }
      } catch (_) {}
    }
    allNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return allNotes;
  }

  @override
  Future<void> saveNote(ParentNote note) async {
    await _box.put(note.id, jsonEncode(note.toJson()));

    // Update the index
    final ids = await _readIndex(note.parentUserId, note.candidateProfileId);
    if (!ids.contains(note.id)) {
      ids.add(note.id);
      await _writeIndex(note.parentUserId, note.candidateProfileId, ids);
    }
  }

  @override
  Future<void> deleteNote(String noteId) async {
    final raw = _box.get(noteId);
    if (raw == null) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final parentId = json['parentUserId'] as String? ?? '';
      final profileId = json['candidateProfileId'] as String? ?? '';
      final ids = await _readIndex(parentId, profileId);
      ids.remove(noteId);
      await _writeIndex(parentId, profileId, ids);
    } catch (_) {}
    await _box.delete(noteId);
  }

  @override
  Future<int> getNoteCount({
    required String parentUserId,
    required String candidateProfileId,
  }) async {
    final ids = await _readIndex(parentUserId, candidateProfileId);
    return ids.length;
  }
}
