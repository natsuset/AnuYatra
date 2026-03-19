import 'dart:convert';

import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

import 'package:testing_flutter/core/data/repositories/user_repository.dart';
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
    var results = _users.values
        .map((raw) => AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList();

    if (offset != null && offset > 0) {
      results = results.skip(offset).toList();
    }
    if (limit != null && limit > 0) {
      results = results.take(limit).toList();
    }

    return results;
  }
}
