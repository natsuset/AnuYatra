import 'package:testing_flutter/core/data/remote/api_client.dart';
import 'package:testing_flutter/core/data/repositories/agency_repository.dart';
import 'package:testing_flutter/core/errors/app_exceptions.dart';
import 'package:testing_flutter/models/agency.dart';

class RemoteAgencyRepository implements AgencyRepository {
  final ApiClient _api;

  RemoteAgencyRepository(this._api);

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
    final data = await _api.post('/api/v1/agencies', body: {
      'name': name,
      'city': city,
      'state': state,
      'logoUrl': logoUrl,
      'description': description,
      'specializations': specializations,
      'areasServed': areasServed,
    });
    return Agency.fromJson(data);
  }

  @override
  Future<void> saveAgency(Agency agency) async {
    await _api.put('/api/v1/agencies/${agency.id}', body: agency.toJson());
  }

  @override
  Future<Agency?> getAgency(String id) async {
    try {
      final data = await _api.get('/api/v1/agencies/$id');
      return Agency.fromJson(data);
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<List<Agency>> getAllAgencies({int? limit, int? offset}) async {
    final params = <String, String>{};
    if (limit != null) params['limit'] = '$limit';
    if (offset != null) params['offset'] = '$offset';
    final data = await _api.get('/api/v1/agencies', queryParams: params);
    final items = data['data'] as List<dynamic>? ?? [];
    return items
        .cast<Map<String, dynamic>>()
        .map(Agency.fromJson)
        .toList(growable: false);
  }

  @override
  Future<List<Agency>> searchAgencies({
    String? query,
    String? city,
    double? minRating,
    int? limit,
    int? offset,
  }) async {
    final params = <String, String>{};
    if (query != null) params['q'] = query;
    if (city != null) params['city'] = city;
    if (minRating != null) params['minRating'] = '$minRating';
    if (limit != null) params['limit'] = '$limit';
    if (offset != null) params['offset'] = '$offset';
    final data = await _api.get('/api/v1/agencies', queryParams: params);
    final items = data['data'] as List<dynamic>? ?? [];
    return items
        .cast<Map<String, dynamic>>()
        .map(Agency.fromJson)
        .toList(growable: false);
  }
}
