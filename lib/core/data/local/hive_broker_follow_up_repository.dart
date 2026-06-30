import 'dart:convert';

import 'package:hive_ce/hive.dart';

import 'package:testing_flutter/core/data/repositories/broker_follow_up_repository.dart';
import 'package:testing_flutter/models/broker_follow_up.dart';

class HiveBrokerFollowUpRepository implements BrokerFollowUpRepository {
  final Box<String> _box;

  HiveBrokerFollowUpRepository({required Box<String> brokerFollowUpsBox})
      : _box = brokerFollowUpsBox;

  @override
  Future<void> save(BrokerFollowUp followUp) async {
    await _box.put(followUp.id, jsonEncode(followUp.toJson()));
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  List<BrokerFollowUp> _all() => _box.values
      .map((raw) =>
          BrokerFollowUp.fromJson(jsonDecode(raw) as Map<String, dynamic>))
      .toList();

  @override
  Future<List<BrokerFollowUp>> getForBroker(String brokerUserId) async {
    final results = _all()
        .where((f) => f.brokerUserId == brokerUserId)
        .toList()
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return results;
  }

  @override
  Future<List<BrokerFollowUp>> getForClient({
    required String brokerUserId,
    required String clientUserId,
  }) async {
    final results = _all()
        .where((f) =>
            f.brokerUserId == brokerUserId && f.clientUserId == clientUserId)
        .toList()
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return results;
  }
}
