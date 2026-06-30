import 'package:testing_flutter/models/client_engagement.dart';

/// Tracks a broker's commercial relationship with each parent client:
/// engagement stage, payment/subscription snapshot, and stated requirements.
abstract class ClientEngagementRepository {
  Future<ClientEngagement?> get({
    required String brokerUserId,
    required String parentUserId,
  });

  Future<void> save(ClientEngagement engagement);

  /// All engagements owned by a broker, newest-updated first.
  Future<List<ClientEngagement>> getForBroker(String brokerUserId);
}
