import 'package:testing_flutter/models/broker_note.dart';

/// Broker-authored notes about a candidate, surfaced to one specific parent.
///
/// Read by the parent on the profile detail page; edited by the broker
/// from their client/profile management screens.
abstract class BrokerNoteRepository {
  Future<BrokerNote?> get({
    required String brokerUserId,
    required String candidateProfileId,
    required String forParentUserId,
  });

  /// Upsert. Empty body deletes the row.
  Future<void> upsert({
    required String brokerUserId,
    required String candidateProfileId,
    required String forParentUserId,
    required String body,
  });
}
