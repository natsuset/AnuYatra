import 'dart:convert';

import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

import 'package:testing_flutter/core/data/repositories/agency_repository.dart';
import 'package:testing_flutter/models/agency.dart';

const _uuid = Uuid();

/// Hive-backed implementation of [AgencyRepository].
class HiveAgencyRepository implements AgencyRepository {
  final Box<String> _agencies;
  final Box<String> _users;

  HiveAgencyRepository({
    required Box<String> agenciesBox,
    required Box<String> usersBox,
  })  : _agencies = agenciesBox,
        _users = usersBox;

  @override
  Future<Agency> createAgency({
    required String adminUserId,
    required String name,
    required String city,
    required String state,
    String? logoUrl,
    String description = '',
    List<String> specializations = const [],
    List<String> areasServed = const [],
  }) async {
    final id = _uuid.v4();
    final agency = Agency(
      id: id,
      adminUserId: adminUserId,
      name: name,
      logoUrl: logoUrl,
      city: city,
      state: state,
      description: description,
      specializations: specializations,
      areasServed: areasServed,
      createdAt: DateTime.now(),
    );
    await _agencies.put(id, jsonEncode(agency.toJson()));

    // Update the admin user's agencyId
    final rawUser = _users.get(adminUserId);
    if (rawUser != null) {
      final userJson = jsonDecode(rawUser) as Map<String, dynamic>;
      userJson['agencyId'] = id;
      await _users.put(adminUserId, jsonEncode(userJson));
    }

    return agency;
  }

  @override
  Future<void> saveAgency(Agency agency) async {
    await _agencies.put(agency.id, jsonEncode(agency.toJson()));
  }

  @override
  Future<Agency?> getAgency(String id) async {
    final raw = _agencies.get(id);
    if (raw == null) return null;
    return Agency.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<List<Agency>> getAllAgencies({int? limit, int? offset}) async {
    var results = _agencies.values
        .map((raw) => Agency.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList();

    if (offset != null && offset > 0) {
      results = results.skip(offset).toList();
    }
    if (limit != null && limit > 0) {
      results = results.take(limit).toList();
    }

    return results;
  }

  @override
  Future<List<Agency>> searchAgencies({
    String? query,
    String? city,
    double? minRating,
    int? limit,
    int? offset,
  }) async {
    var results =
        (await getAllAgencies()).where((a) => a.isActive).toList();

    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      results = results
          .where((a) =>
              a.name.toLowerCase().contains(q) ||
              a.description.toLowerCase().contains(q) ||
              a.specializations.any((s) => s.toLowerCase().contains(q)) ||
              a.city.toLowerCase().contains(q))
          .toList();
    }

    if (city != null) {
      results = results
          .where((a) => a.city.toLowerCase() == city.toLowerCase())
          .toList();
    }

    if (minRating != null) {
      results = results.where((a) => a.rating >= minRating).toList();
    }

    if (offset != null && offset > 0) {
      results = results.skip(offset).toList();
    }
    if (limit != null && limit > 0) {
      results = results.take(limit).toList();
    }

    return results;
  }
}
