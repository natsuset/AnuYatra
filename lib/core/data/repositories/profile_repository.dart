import 'package:testing_flutter/models/candidate_profile.dart';
import 'package:testing_flutter/models/parent_profile.dart';

/// Contract for candidate and parent profile CRUD.
abstract class ProfileRepository {
  // ── Parent Profiles ──

  /// Persist a parent profile (create or update).
  Future<void> saveParentProfile(ParentProfile profile);

  /// Get a parent profile by the parent's user ID.
  Future<ParentProfile?> getParentProfile(String userId);

  /// Get all parent profiles, with optional pagination.
  Future<List<ParentProfile>> getAllParentProfiles({int? limit, int? offset});

  // ── Candidate Profiles ──

  /// Persist a candidate profile (create or update).
  Future<void> saveCandidateProfile(CandidateProfile profile);

  /// Get a candidate profile by its unique ID.
  Future<CandidateProfile?> getCandidateProfile(String id);

  /// Get all candidate profiles, with optional pagination.
  Future<List<CandidateProfile>> getAllCandidateProfiles({
    int? limit,
    int? offset,
  });

  /// Get candidate profiles managed by a specific broker.
  Future<List<CandidateProfile>> getCandidatesByBroker(
    String brokerUserId, {
    int? limit,
    int? offset,
  });

  /// Get candidate profiles shared with a parent (via SharedProfile records).
  Future<List<CandidateProfile>> getSharedCandidatesForParent(
    String parentUserId,
  );
}
