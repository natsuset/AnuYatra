import 'dart:convert';

import 'package:hive_ce/hive.dart';

import 'package:testing_flutter/core/data/repositories/client_engagement_repository.dart';
import 'package:testing_flutter/models/client_engagement.dart';

class HiveClientEngagementRepository implements ClientEngagementRepository {
  final Box<String> _box;

  HiveClientEngagementRepository({required Box<String> clientEngagementsBox})
      : _box = clientEngagementsBox;

  String _key(String brokerId, String parentId) => '${brokerId}_$parentId';

  @override
  Future<ClientEngagement?> get({
    required String brokerUserId,
    required String parentUserId,
  }) async {
    final raw = _box.get(_key(brokerUserId, parentUserId));
    if (raw == null) return null;
    return ClientEngagement.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(ClientEngagement engagement) async {
    await _box.put(engagement.id, jsonEncode(engagement.toJson()));
  }

  @override
  Future<List<ClientEngagement>> getForBroker(String brokerUserId) async {
    final results = _box.values
        .map((raw) =>
            ClientEngagement.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .where((e) => e.brokerUserId == brokerUserId)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return results;
  }
}
