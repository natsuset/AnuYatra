import 'package:testing_flutter/models/shared_profile.dart';

/// Contract for sharing candidate profiles between brokers and parents.
abstract class SharedProfileRepository {
  /// Share a candidate profile with a parent, generating a unique ID.
  Future<SharedProfile> shareProfile({
    required String profileId,
    required String sharedByUserId,
    required String sharedWithUserId,
  });

  /// Persist a shared profile (create or update, used for seeding).
  Future<void> saveSharedProfile(SharedProfile shared);

  /// Update a shared profile (e.g., parent sets response).
  Future<void> updateSharedProfile(SharedProfile shared);

  /// Get profiles shared with a specific user (parent view).
  Future<List<SharedProfile>> getSharedProfilesForUser(
    String userId, {
    int? limit,
    int? offset,
  });

  /// Get profiles shared by a specific broker.
  Future<List<SharedProfile>> getSharedProfilesByBroker(
    String brokerUserId, {
    int? limit,
    int? offset,
  });

  /// Mark a shared profile as forwarded to the parent's linked child.
  Future<void> forwardProfileToChild(String sharedProfileId);

  /// Get shared profiles forwarded to a child (child view).
  Future<List<SharedProfile>> getForwardedProfiles(
    String parentUserId, {
    int? limit,
    int? offset,
  });

  /// Get all shared profiles, with optional pagination.
  Future<List<SharedProfile>> getAllSharedProfiles({int? limit, int? offset});
}
