import 'package:testing_flutter/models/profile_activity.dart';

/// Append-only event log per candidate profile.
///
/// Implementations cap to the last 50 events per profile (decision in
/// PRODUCT_PLAN §1.12). Used to power the timeline section on the profile
/// detail page and the "recently active" feeds downstream.
abstract class ActivityRepository {
  /// Append a new event. Records over the per-profile cap are evicted.
  Future<void> record(ProfileActivity event);

  /// Most-recent first, capped to [limit].
  Future<List<ProfileActivity>> getActivityForProfile(
    String profileId, {
    int limit = 50,
  });
}
