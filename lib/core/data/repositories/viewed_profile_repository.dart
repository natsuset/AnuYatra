import 'package:testing_flutter/models/viewed_profile.dart';

/// Contract for tracking which profiles a user has opened.
///
/// Implementations should be idempotent on re-view (update `viewedAt`,
/// don't insert a second row) and self-evict to keep the box small —
/// recommended cap: most-recent 50 per user.
abstract class ViewedProfileRepository {
  /// Record that [userId] opened [profileId] just now.
  /// If a record already exists, only `viewedAt` is bumped.
  Future<void> recordView({
    required String userId,
    required String profileId,
  });

  /// Most-recently viewed first, capped to [limit] (default 50).
  Future<List<ViewedProfile>> getRecentViews(
    String userId, {
    int limit = 50,
  });

  /// How many profiles the user has viewed (post-eviction count).
  Future<int> getViewCount(String userId);

  /// Clear all view history for [userId].
  Future<void> clearHistory(String userId);
}
