import 'package:testing_flutter/models/saved_profile.dart';

/// Contract for "saved" / bookmarked profiles.
///
/// Saving is a private bookmark: it does NOT notify the broker and is
/// orthogonal to `SharedProfileResponse`. A profile can be both saved and
/// have a response set.
abstract class SavedProfileRepository {
  /// Whether [userId] has saved [profileId].
  Future<bool> isSaved({required String userId, required String profileId});

  /// Save (idempotent — no-op if already saved). Returns the resulting record.
  Future<SavedProfile> save({
    required String userId,
    required String profileId,
  });

  /// Unsave (idempotent — no-op if not saved).
  Future<void> unsave({required String userId, required String profileId});

  /// Toggle the saved state. Returns the new state (true = now saved).
  Future<bool> toggle({required String userId, required String profileId});

  /// All saves by [userId], newest first.
  Future<List<SavedProfile>> getSavedProfilesForUser(
    String userId, {
    int? limit,
    int? offset,
  });

  /// How many profiles [userId] has saved (for dashboard tile counts).
  Future<int> getSavedCount(String userId);
}
