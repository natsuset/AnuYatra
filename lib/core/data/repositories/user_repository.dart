import 'package:testing_flutter/models/app_user.dart';
import 'package:testing_flutter/models/user_role.dart';

/// Contract for user CRUD and session management.
///
/// Implementations may be backed by Hive, Firebase, REST API, etc.
abstract class UserRepository {
  /// Get the currently logged-in user's UID, or null if no session.
  Future<String?> getCurrentUserId();

  /// Get the currently logged-in user, or null if no session.
  Future<AppUser?> getCurrentUser();

  /// Set the current session to [uid].
  Future<void> setCurrentUser(String uid);

  /// Clear the current session (logout).
  Future<void> clearSession();

  /// Whether the data store has any users (used for first-launch detection).
  Future<bool> get isEmpty;

  /// Register a new user, generating a unique ID.
  Future<AppUser> registerUser({
    required String phoneNumber,
    required String displayName,
    required UserRole role,
    String? photoUrl,
  });

  /// Persist a user (create or update).
  Future<void> saveUser(AppUser user);

  /// Get a user by their unique ID.
  Future<AppUser?> getUser(String uid);

  /// Find a user by phone number.
  Future<AppUser?> getUserByPhone(String phoneNumber);

  /// Get all users, with optional pagination.
  Future<List<AppUser>> getAllUsers({int? limit, int? offset});
}
