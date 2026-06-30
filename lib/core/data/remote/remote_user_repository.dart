import 'package:testing_flutter/core/data/remote/api_client.dart';
import 'package:testing_flutter/core/data/repositories/user_repository.dart';
import 'package:testing_flutter/core/errors/app_exceptions.dart';
import 'package:testing_flutter/models/app_user.dart';
import 'package:testing_flutter/models/user_role.dart';

/// [UserRepository] backed by the Go REST API.
///
/// Session management is handled via JWT tokens in [ApiClient].
/// `setCurrentUser` and `clearSession` delegate to token operations.
class RemoteUserRepository implements UserRepository {
  final ApiClient _api;

  RemoteUserRepository(this._api);

  @override
  Future<String?> getCurrentUserId() async {
    final user = await getCurrentUser();
    return user?.uid;
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    if (!_api.hasTokens) return null;
    try {
      final data = await _api.get('/api/v1/users/me');
      return AppUser.fromJson(data);
    } on AuthException {
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> setCurrentUser(String uid) async {
    // In remote mode, setting the "current user" is handled by storing
    // the JWT tokens — which happens in verifyOtp. This is a no-op.
  }

  @override
  Future<void> clearSession() async {
    try {
      await _api.post('/api/v1/auth/logout');
    } catch (_) {
      // Best-effort — stateless JWT, client-side token removal is sufficient.
    }
    await _api.clearTokens();
  }

  @override
  Future<bool> get isEmpty async {
    // Remote mode is never "empty" in the seed sense — seed data
    // lives on the server or doesn't apply.
    return false;
  }

  @override
  Future<AppUser> registerUser({
    required String phoneNumber,
    required String displayName,
    required UserRole role,
    String? photoUrl,
  }) async {
    // Registration happens via verifyOtp on the backend. This is called
    // by AuthNotifier after OTP verification creates a new user.
    // At this point the user already exists on the server.
    final user = await getCurrentUser();
    if (user != null) return user;
    throw const AppException('User registration failed: no authenticated user');
  }

  @override
  Future<AppUser> registerOrLookupByPhone({
    required String phoneNumber,
    required String displayName,
    required UserRole role,
  }) async {
    final existing = await getUserByPhone(phoneNumber);
    if (existing != null) return existing;
    return registerUser(
      phoneNumber: phoneNumber,
      displayName: displayName,
      role: role,
    );
  }

  @override
  Future<void> saveUser(AppUser user) async {
    await _api.put('/api/v1/users/me', body: {
      'displayName': user.displayName,
      'photoUrl': user.photoUrl,
    });
  }

  @override
  Future<AppUser?> getUser(String uid) async {
    try {
      final data = await _api.get('/api/v1/users/$uid');
      return AppUser.fromJson(data);
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<AppUser?> getUserByPhone(String phoneNumber) async {
    try {
      final data = await _api.get(
        '/api/v1/users',
        queryParams: {'phone': phoneNumber},
      );
      return AppUser.fromJson(data);
    } on NotFoundException {
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<AppUser>> getAllUsers({int? limit, int? offset}) async {
    final params = <String, String>{};
    if (limit != null) params['limit'] = '$limit';
    if (offset != null) params['offset'] = '$offset';
    final data = await _api.get('/api/v1/users', queryParams: params);
    final items = data['data'] as List<dynamic>? ?? [];
    return items
        .cast<Map<String, dynamic>>()
        .map(AppUser.fromJson)
        .toList(growable: false);
  }
}
