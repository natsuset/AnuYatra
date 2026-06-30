import 'package:testing_flutter/models/broker_follow_up.dart';

/// Broker follow-up / reminder tasks.
abstract class BrokerFollowUpRepository {
  Future<void> save(BrokerFollowUp followUp);

  Future<void> delete(String id);

  /// All follow-ups owned by a broker, soonest-due first.
  Future<List<BrokerFollowUp>> getForBroker(String brokerUserId);

  /// Follow-ups for a specific client, soonest-due first.
  Future<List<BrokerFollowUp>> getForClient({
    required String brokerUserId,
    required String clientUserId,
  });
}
