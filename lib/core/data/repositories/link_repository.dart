import 'package:testing_flutter/models/link_request.dart';

/// Contract for link request lifecycle and connection queries.
abstract class LinkRepository {
  /// Send a new link request, generating a unique ID.
  Future<LinkRequest> sendLinkRequest({
    required String fromUserId,
    required String toUserId,
    required String fromUserName,
    required String toUserName,
    required LinkRequestType type,
    String? note,
  });

  /// Persist a link request (create or update, used for seeding).
  Future<void> saveLinkRequest(LinkRequest request);

  /// Accept a pending link request and execute side effects
  /// (e.g., increment broker client count, create conversation).
  Future<LinkRequest> acceptLinkRequest(String requestId);

  /// Decline a pending link request.
  Future<LinkRequest> declineLinkRequest(String requestId);

  /// Get a link request by its unique ID.
  Future<LinkRequest?> getLinkRequest(String id);

  /// Get all link requests, with optional pagination.
  Future<List<LinkRequest>> getAllLinkRequests({int? limit, int? offset});

  /// Get link requests sent by a specific user.
  Future<List<LinkRequest>> getLinkRequestsSentBy(
    String userId, {
    int? limit,
    int? offset,
  });

  /// Get link requests received by a specific user.
  Future<List<LinkRequest>> getLinkRequestsReceivedBy(
    String userId, {
    int? limit,
    int? offset,
  });

  /// Get pending (unanswered) incoming requests for a user.
  Future<List<LinkRequest>> getPendingRequestsFor(
    String userId, {
    int? limit,
    int? offset,
  });

  /// Get accepted connections for a user (both directions).
  Future<List<LinkRequest>> getAcceptedConnectionsFor(String userId);

  /// Get broker user IDs connected to a parent.
  Future<List<String>> getConnectedBrokerIds(String parentUserId);

  /// Get parent user IDs connected to a broker.
  Future<List<String>> getConnectedParentIds(String brokerUserId);

  /// Get the linked child user ID for a parent, or null. Convenience for
  /// the common single-child case; equivalent to the first entry of
  /// [getLinkedChildIds].
  Future<String?> getLinkedChildId(String parentUserId);

  /// All candidate (child) user IDs linked to [parentUserId] via accepted
  /// `childToParent` link requests. Newest accepted first. Returns the empty
  /// list when no child is linked. Supports the "one parent, multiple
  /// unmarried children" case (PRODUCT_PLAN Part 5 #8).
  Future<List<String>> getLinkedChildIds(String parentUserId);

  /// Get the linked parent user ID for a candidate, or null.
  Future<String?> getLinkedParentId(String childUserId);
}
