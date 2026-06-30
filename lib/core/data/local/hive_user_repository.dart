import 'dart:convert';

import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

import 'package:testing_flutter/core/data/repositories/user_repository.dart';
import 'package:testing_flutter/core/errors/app_exceptions.dart';
import 'package:testing_flutter/models/app_user.dart';
import 'package:testing_flutter/models/user_role.dart';

const _uuid = Uuid();

/// Hive-backed implementation of [UserRepository].
///
/// Reads are synchronous internally (Hive is memory-mapped) but wrapped
/// in [Future] to honour the async contract, ensuring screens never
/// assume synchronous data access.
class HiveUserRepository implements UserRepository {
  final Box<String> _users;
  final Box<String> _session;

  HiveUserRepository({
    required Box<String> usersBox,
    required Box<String> sessionBox,
  })  : _users = usersBox,
        _session = sessionBox;

  @override
  Future<String?> getCurrentUserId() async {
    return _session.get('currentUserId');
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final uid = _session.get('currentUserId');
    if (uid == null) return null;
    return await getUser(uid);
  }

  @override
  Future<void> setCurrentUser(String uid) async {
    await _session.put('currentUserId', uid);
  }

  @override
  Future<void> clearSession() async {
    await _session.delete('currentUserId');
  }

  @override
  Future<bool> get isEmpty async => _users.isEmpty;

  @override
  Future<AppUser> registerUser({
    required String phoneNumber,
    required String displayName,
    required UserRole role,
    String? photoUrl,
  }) async {
    // Reject duplicates so the call site can surface a clear error instead
    // of silently creating a second account for the same phone number.
    final existing = await getUserByPhone(phoneNumber);
    if (existing != null) {
      throw DuplicateException(
        entityType: 'User',
        message: 'A user with phone $phoneNumber already exists.',
      );
    }
    final uid = _uuid.v4();
    final user = AppUser(
      uid: uid,
      phoneNumber: phoneNumber,
      displayName: displayName,
      photoUrl: photoUrl,
      role: role,
      createdAt: DateTime.now(),
    );
    await _users.put(uid, jsonEncode(user.toJson()));
    return user;
  }

  @override
  Future<AppUser> registerOrLookupByPhone({
    required String phoneNumber,
    required String displayName,
    required UserRole role,
  }) async {
    final existing = await getUserByPhone(phoneNumber);
    if (existing != null) return existing;
    // No duplicate guard here — getUserByPhone already returned null.
    final uid = _uuid.v4();
    final user = AppUser(
      uid: uid,
      phoneNumber: phoneNumber,
      displayName: displayName,
      role: role,
      createdAt: DateTime.now(),
    );
    await _users.put(uid, jsonEncode(user.toJson()));
    return user;
  }

  @override
  Future<void> saveUser(AppUser user) async {
    await _users.put(user.uid, jsonEncode(user.toJson()));
  }

  @override
  Future<AppUser?> getUser(String uid) async {
    final raw = _users.get(uid);
    if (raw == null) return null;
    return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<AppUser?> getUserByPhone(String phoneNumber) async {
    for (final raw in _users.values) {
      final user = AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      if (user.phoneNumber == phoneNumber) return user;
    }
    return null;
  }

  @override
  Future<List<AppUser>> getAllUsers({int? limit, int? offset}) async {
    final results = _users.values
        .map((raw) => AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList()
      // Newest first — deterministic order across calls.
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return _paginate(results, limit: limit, offset: offset);
  }
}

List<T> _paginate<T>(List<T> all, {int? limit, int? offset}) {
  Iterable<T> view = all;
  if (offset != null && offset > 0) view = view.skip(offset);
  if (limit != null && limit > 0) view = view.take(limit);
  return identical(view, all) ? all : view.toList();
}
