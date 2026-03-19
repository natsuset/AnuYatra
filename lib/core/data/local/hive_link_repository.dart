import 'dart:convert';

import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

import 'package:testing_flutter/core/data/repositories/broker_repository.dart';
import 'package:testing_flutter/core/data/repositories/link_repository.dart';
import 'package:testing_flutter/core/data/repositories/messaging_repository.dart';
import 'package:testing_flutter/core/data/repositories/user_repository.dart';
import 'package:testing_flutter/core/data/repositories/agency_repository.dart';
import 'package:testing_flutter/models/link_request.dart';

const _uuid = Uuid();

/// Hive-backed implementation of [LinkRepository].
///
/// Accept/decline side effects (updating broker client count, creating
/// conversations) require other repositories, injected via [init].
class HiveLinkRepository implements LinkRepository {
  final Box<String> _linkRequests;

  late final UserRepository _userRepo;
  late final BrokerRepository _brokerRepo;
  late final AgencyRepository _agencyRepo;
  late final MessagingRepository _messagingRepo;

  HiveLinkRepository({required Box<String> linkRequestsBox})
      : _linkRequests = linkRequestsBox;

  /// Must be called after all repositories are constructed.
  void init({
    required UserRepository userRepo,
    required BrokerRepository brokerRepo,
    required AgencyRepository agencyRepo,
    required MessagingRepository messagingRepo,
  }) {
    _userRepo = userRepo;
    _brokerRepo = brokerRepo;
    _agencyRepo = agencyRepo;
    _messagingRepo = messagingRepo;
  }

  @override
  Future<LinkRequest> sendLinkRequest({
    required String fromUserId,
    required String toUserId,
    required String fromUserName,
    required String toUserName,
    required LinkRequestType type,
    String? note,
  }) async {
    final id = _uuid.v4();
    final request = LinkRequest(
      id: id,
      fromUserId: fromUserId,
      toUserId: toUserId,
      fromUserName: fromUserName,
      toUserName: toUserName,
      type: type,
      createdAt: DateTime.now(),
      note: note,
    );
    await _linkRequests.put(id, jsonEncode(request.toJson()));
    return request;
  }

  @override
  Future<void> saveLinkRequest(LinkRequest request) async {
    await _linkRequests.put(request.id, jsonEncode(request.toJson()));
  }

  @override
  Future<LinkRequest> acceptLinkRequest(String requestId) async {
    final request = await getLinkRequest(requestId);
    if (request == null) throw Exception('Link request not found');

    final updated = request.copyWith(
      status: LinkRequestStatus.accepted,
      respondedAt: DateTime.now(),
    );
    await _linkRequests.put(requestId, jsonEncode(updated.toJson()));

    await _handleLinkRequestAccepted(updated);

    return updated;
  }

  @override
  Future<LinkRequest> declineLinkRequest(String requestId) async {
    final request = await getLinkRequest(requestId);
    if (request == null) throw Exception('Link request not found');

    final updated = request.copyWith(
      status: LinkRequestStatus.declined,
      respondedAt: DateTime.now(),
    );
    await _linkRequests.put(requestId, jsonEncode(updated.toJson()));
    return updated;
  }

  Future<void> _handleLinkRequestAccepted(LinkRequest request) async {
    switch (request.type) {
      case LinkRequestType.agencyToBroker:
        final broker = await _brokerRepo.getBrokerProfile(request.toUserId);
        if (broker != null) {
          final user = await _userRepo.getUser(request.fromUserId);
          final agencyId = user?.agencyId;
          if (agencyId != null) {
            await _brokerRepo
                .saveBrokerProfile(broker.copyWith(agencyId: agencyId));
          }
        }
        break;

      case LinkRequestType.parentToBroker:
        final broker = await _brokerRepo.getBrokerProfile(request.toUserId);
        if (broker != null) {
          await _brokerRepo.saveBrokerProfile(
            broker.copyWith(clientCount: broker.clientCount + 1),
          );
        }
        await _messagingRepo.getOrCreateConversation(
            request.fromUserId, request.toUserId);
        break;

      case LinkRequestType.parentToAgency:
        final agencies = await _agencyRepo.getAllAgencies();
        final agency = agencies.where((a) {
          return a.adminUserId == request.toUserId;
        }).firstOrNull;
        if (agency != null) {
          await _messagingRepo.getOrCreateConversation(
              request.fromUserId, agency.adminUserId);
        }
        break;

      case LinkRequestType.childToParent:
        break;
    }
  }

  @override
  Future<LinkRequest?> getLinkRequest(String id) async {
    final raw = _linkRequests.get(id);
    if (raw == null) return null;
    return LinkRequest.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<List<LinkRequest>> getAllLinkRequests({
    int? limit,
    int? offset,
  }) async {
    var results = _linkRequests.values
        .map((raw) =>
            LinkRequest.fromJson(jsonDecode(raw) as Map<String, dynamic>))
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
  Future<List<LinkRequest>> getLinkRequestsSentBy(
    String userId, {
    int? limit,
    int? offset,
  }) async {
    var results = (await getAllLinkRequests())
        .where((r) => r.fromUserId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (offset != null && offset > 0) {
      results = results.skip(offset).toList();
    }
    if (limit != null && limit > 0) {
      results = results.take(limit).toList();
    }

    return results;
  }

  @override
  Future<List<LinkRequest>> getLinkRequestsReceivedBy(
    String userId, {
    int? limit,
    int? offset,
  }) async {
    var results = (await getAllLinkRequests())
        .where((r) => r.toUserId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (offset != null && offset > 0) {
      results = results.skip(offset).toList();
    }
    if (limit != null && limit > 0) {
      results = results.take(limit).toList();
    }

    return results;
  }

  @override
  Future<List<LinkRequest>> getPendingRequestsFor(
    String userId, {
    int? limit,
    int? offset,
  }) async {
    var results = (await getLinkRequestsReceivedBy(userId))
        .where((r) => r.status == LinkRequestStatus.pending)
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
  Future<List<LinkRequest>> getAcceptedConnectionsFor(String userId) async {
    return (await getAllLinkRequests())
        .where((r) =>
            r.status == LinkRequestStatus.accepted &&
            (r.fromUserId == userId || r.toUserId == userId))
        .toList();
  }

  @override
  Future<List<String>> getConnectedBrokerIds(String parentUserId) async {
    final connections = (await getAcceptedConnectionsFor(parentUserId))
        .where((r) => r.type == LinkRequestType.parentToBroker);

    return connections
        .map((r) =>
            r.fromUserId == parentUserId ? r.toUserId : r.fromUserId)
        .toList();
  }

  @override
  Future<List<String>> getConnectedParentIds(String brokerUserId) async {
    final connections = (await getAcceptedConnectionsFor(brokerUserId))
        .where((r) => r.type == LinkRequestType.parentToBroker);

    return connections
        .map((r) =>
            r.fromUserId == brokerUserId ? r.toUserId : r.fromUserId)
        .toList();
  }

  @override
  Future<String?> getLinkedChildId(String parentUserId) async {
    final connection = (await getAcceptedConnectionsFor(parentUserId))
        .where((r) => r.type == LinkRequestType.childToParent)
        .firstOrNull;
    if (connection == null) return null;
    return connection.fromUserId == parentUserId
        ? connection.toUserId
        : connection.fromUserId;
  }

  @override
  Future<String?> getLinkedParentId(String childUserId) async {
    final connection = (await getAcceptedConnectionsFor(childUserId))
        .where((r) => r.type == LinkRequestType.childToParent)
        .firstOrNull;
    if (connection == null) return null;
    return connection.fromUserId == childUserId
        ? connection.toUserId
        : connection.fromUserId;
  }
}
