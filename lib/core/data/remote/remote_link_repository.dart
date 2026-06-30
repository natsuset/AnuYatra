import 'package:testing_flutter/core/data/remote/api_client.dart';
import 'package:testing_flutter/core/data/repositories/link_repository.dart';
import 'package:testing_flutter/core/errors/app_exceptions.dart';
import 'package:testing_flutter/models/link_request.dart';

class RemoteLinkRepository implements LinkRepository {
  final ApiClient _api;

  RemoteLinkRepository(this._api);

  @override
  Future<LinkRequest> sendLinkRequest({
    required String fromUserId,
    required String toUserId,
    required String fromUserName,
    required String toUserName,
    required LinkRequestType type,
    String? note,
  }) async {
    final data = await _api.post('/api/v1/link-requests', body: {
      'toUserId': toUserId,
      'type': type.name,
      'note': note,
    });
    return LinkRequest.fromJson(data);
  }

  @override
  Future<void> saveLinkRequest(LinkRequest request) async {
    // Seeding endpoint — not used in remote mode.
  }

  @override
  Future<LinkRequest> acceptLinkRequest(String requestId) async {
    final data = await _api.post('/api/v1/link-requests/$requestId/accept');
    return LinkRequest.fromJson(data);
  }

  @override
  Future<LinkRequest> declineLinkRequest(String requestId) async {
    final data = await _api.post('/api/v1/link-requests/$requestId/decline');
    return LinkRequest.fromJson(data);
  }

  @override
  Future<LinkRequest?> getLinkRequest(String id) async {
    try {
      final data = await _api.get('/api/v1/link-requests/$id');
      return LinkRequest.fromJson(data);
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<List<LinkRequest>> getAllLinkRequests({int? limit, int? offset}) async {
    return getLinkRequestsReceivedBy('', limit: limit, offset: offset);
  }

  @override
  Future<List<LinkRequest>> getLinkRequestsSentBy(
    String userId, {
    int? limit,
    int? offset,
  }) async {
    final data = await _api.get(
      '/api/v1/link-requests/sent',
      queryParams: _pagParams(limit, offset),
    );
    return _parseLinkRequests(data);
  }

  @override
  Future<List<LinkRequest>> getLinkRequestsReceivedBy(
    String userId, {
    int? limit,
    int? offset,
  }) async {
    final data = await _api.get(
      '/api/v1/link-requests/received',
      queryParams: _pagParams(limit, offset),
    );
    return _parseLinkRequests(data);
  }

  @override
  Future<List<LinkRequest>> getPendingRequestsFor(
    String userId, {
    int? limit,
    int? offset,
  }) async {
    final params = _pagParams(limit, offset);
    params['status'] = 'pending';
    final data = await _api.get(
      '/api/v1/link-requests/received',
      queryParams: params,
    );
    return _parseLinkRequests(data);
  }

  @override
  Future<List<LinkRequest>> getAcceptedConnectionsFor(String userId) async {
    final data = await _api.get('/api/v1/link-requests/connections');
    return _parseLinkRequests(data);
  }

  @override
  Future<List<String>> getConnectedBrokerIds(String parentUserId) async {
    final data = await _api.get('/api/v1/link-requests/connected-brokers');
    return (data['data'] as List<dynamic>? ?? []).cast<String>();
  }

  @override
  Future<List<String>> getConnectedParentIds(String brokerUserId) async {
    final data = await _api.get('/api/v1/link-requests/connected-parents');
    return (data['data'] as List<dynamic>? ?? []).cast<String>();
  }

  @override
  Future<String?> getLinkedChildId(String parentUserId) async {
    final ids = await getLinkedChildIds(parentUserId);
    return ids.isNotEmpty ? ids.first : null;
  }

  @override
  Future<List<String>> getLinkedChildIds(String parentUserId) async {
    final data = await _api.get('/api/v1/link-requests/linked-children');
    return (data['data'] as List<dynamic>? ?? []).cast<String>();
  }

  @override
  Future<String?> getLinkedParentId(String childUserId) async {
    final data = await _api.get('/api/v1/link-requests/linked-parent');
    return data['data'] as String?;
  }

  List<LinkRequest> _parseLinkRequests(Map<String, dynamic> response) {
    final items = response['data'] as List<dynamic>? ?? [];
    return items
        .cast<Map<String, dynamic>>()
        .map(LinkRequest.fromJson)
        .toList(growable: false);
  }

  Map<String, String> _pagParams(int? limit, int? offset) {
    final params = <String, String>{};
    if (limit != null) params['limit'] = '$limit';
    if (offset != null) params['offset'] = '$offset';
    return params;
  }
}
