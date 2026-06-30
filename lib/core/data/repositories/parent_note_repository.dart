import 'package:testing_flutter/models/parent_note.dart';

/// Per-parent private notes on candidate profiles.
///
/// Multiple notes can exist per (parentUserId, candidateProfileId).
/// Notes are sorted newest-first by default.
abstract class ParentNoteRepository {
  /// All notes for a specific profile, newest first.
  Future<List<ParentNote>> getNotesForProfile({
    required String parentUserId,
    required String candidateProfileId,
  });

  /// All notes across all profiles for this parent, newest first.
  /// Used by the Notes Hub screen.
  Future<List<ParentNote>> getAllNotesForParent(String parentUserId);

  /// Create or update a note. Uses [note.id] as the key.
  Future<void> saveNote(ParentNote note);

  /// Permanently delete a note by id.
  Future<void> deleteNote(String noteId);

  /// Returns the count of notes for a profile — cheaper than loading all bodies.
  Future<int> getNoteCount({
    required String parentUserId,
    required String candidateProfileId,
  });
}
