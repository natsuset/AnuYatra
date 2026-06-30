import 'package:testing_flutter/models/broker_follow_up.dart';
import 'package:testing_flutter/models/candidate_profile.dart';
import 'package:testing_flutter/models/client_engagement.dart';
import 'package:testing_flutter/models/link_request.dart';
import 'package:testing_flutter/models/shared_profile.dart';

/// The category of a broker "needs attention" item. Drives the icon, accent
/// colour, and the set of actions shown on the dashboard feed.
enum BrokerAttentionKind {
  pendingConnection,
  clientInterested,
  clientPassed,
  awaitingClient,
  paymentPending,
  sharingStartsSoon,
  followUpDue,
}

/// A single actionable item in the broker's inbox / action feed.
///
/// Pure data — the UI decides how to render each [kind] and which buttons to
/// show. Built by [buildBrokerInbox] from already-fetched repository data so it
/// stays easy to test and reuse across the dashboard and client hub.
class BrokerAttentionItem {
  final BrokerAttentionKind kind;
  final String title;
  final String subtitle;
  final DateTime at;

  /// The client (parent) this item concerns, when applicable.
  final String? clientUserId;

  /// The candidate profile this item concerns, when applicable.
  final String? candidateProfileId;

  /// The originating link request id (for connection requests).
  final String? linkRequestId;

  /// The originating shared-profile id (for responses).
  final String? sharedProfileId;

  /// The follow-up id (for follow-up reminders).
  final String? followUpId;

  const BrokerAttentionItem({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.at,
    this.clientUserId,
    this.candidateProfileId,
    this.linkRequestId,
    this.sharedProfileId,
    this.followUpId,
  });

  /// Higher = more urgent. Used for ordering the feed.
  int get _priority => switch (kind) {
        BrokerAttentionKind.pendingConnection => 100,
        BrokerAttentionKind.clientInterested => 90,
        BrokerAttentionKind.followUpDue => 80,
        BrokerAttentionKind.paymentPending => 70,
        BrokerAttentionKind.clientPassed => 50,
        BrokerAttentionKind.sharingStartsSoon => 40,
        BrokerAttentionKind.awaitingClient => 20,
      };
}

/// How long a shared profile can sit without a response before it surfaces as
/// "awaiting client".
const _staleAfter = Duration(days: 4);

/// Builds the ordered list of attention items for a broker.
///
/// All inputs are pre-fetched so this function is synchronous and pure.
/// [userNames] maps userId → display name; [profiles] maps profileId → profile.
List<BrokerAttentionItem> buildBrokerInbox({
  required List<LinkRequest> pendingRequests,
  required List<SharedProfile> sharedByBroker,
  required List<ClientEngagement> engagements,
  required List<BrokerFollowUp> followUps,
  required Map<String, String> userNames,
  required Map<String, CandidateProfile> profiles,
}) {
  final items = <BrokerAttentionItem>[];
  final now = DateTime.now();

  String nameOf(String? id) =>
      id == null ? 'someone' : (userNames[id] ?? 'a client');
  String profileName(String? id) =>
      id == null ? 'a profile' : (profiles[id]?.name ?? 'a profile');

  // 1) Pending connection requests
  for (final r in pendingRequests) {
    items.add(BrokerAttentionItem(
      kind: BrokerAttentionKind.pendingConnection,
      title: '${r.fromUserName} wants to connect',
      subtitle: (r.note?.trim().isNotEmpty ?? false)
          ? r.note!.trim()
          : 'New connection request',
      at: r.createdAt,
      clientUserId: r.fromUserId,
      linkRequestId: r.id,
    ));
  }

  // 2) Responses to profiles the broker shared
  for (final s in sharedByBroker) {
    final client = nameOf(s.sharedWithUserId);
    final pName = profileName(s.profileId);
    switch (s.parentResponse) {
      case SharedProfileResponse.interested:
        items.add(BrokerAttentionItem(
          kind: BrokerAttentionKind.clientInterested,
          title: '$client is interested in $pName',
          subtitle: 'Relay the interest to the other party',
          at: s.sharedAt,
          clientUserId: s.sharedWithUserId,
          candidateProfileId: s.profileId,
          sharedProfileId: s.id,
        ));
      case SharedProfileResponse.pass:
        items.add(BrokerAttentionItem(
          kind: BrokerAttentionKind.clientPassed,
          title: '$client passed on $pName',
          subtitle: 'Suggest an alternative profile',
          at: s.sharedAt,
          clientUserId: s.sharedWithUserId,
          candidateProfileId: s.profileId,
          sharedProfileId: s.id,
        ));
      default:
        // pending (or deprecated 'maybe') — surface only once stale
        if (now.difference(s.sharedAt) >= _staleAfter) {
          items.add(BrokerAttentionItem(
            kind: BrokerAttentionKind.awaitingClient,
            title: '$client hasn\'t responded on $pName',
            subtitle: 'Shared ${_ago(s.sharedAt)} · nudge them',
            at: s.sharedAt,
            clientUserId: s.sharedWithUserId,
            candidateProfileId: s.profileId,
            sharedProfileId: s.id,
          ));
        }
    }
  }

  // 3) Payment pending / sharing starting soon
  for (final e in engagements) {
    final client = nameOf(e.parentUserId);
    if (e.stage == EngagementStage.connected && !e.hasPaid) {
      items.add(BrokerAttentionItem(
        kind: BrokerAttentionKind.paymentPending,
        title: '$client hasn\'t paid yet',
        subtitle: 'Profile sharing is gated until payment',
        at: e.createdAt,
        clientUserId: e.parentUserId,
      ));
    } else if (e.stage == EngagementStage.paid && !e.sharingStarted) {
      final days = e.daysUntilSharing;
      items.add(BrokerAttentionItem(
        kind: BrokerAttentionKind.sharingStartsSoon,
        title: 'Sharing for $client starts ${_inDays(days)}',
        subtitle: 'Line up profiles to share on day one',
        at: e.paidAt ?? e.createdAt,
        clientUserId: e.parentUserId,
      ));
    }
  }

  // 4) Follow-ups due today or overdue
  for (final f in followUps) {
    if (f.isDone) continue;
    if (f.isOverdue || f.isDueToday) {
      items.add(BrokerAttentionItem(
        kind: BrokerAttentionKind.followUpDue,
        title: f.title,
        subtitle: f.isOverdue
            ? 'Overdue · ${_ago(f.dueAt)}'
            : 'Due today',
        at: f.dueAt,
        clientUserId: f.clientUserId,
        candidateProfileId: f.candidateProfileId,
        followUpId: f.id,
      ));
    }
  }

  items.sort((a, b) {
    final p = b._priority.compareTo(a._priority);
    if (p != 0) return p;
    return b.at.compareTo(a.at);
  });

  return items;
}

String _ago(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inDays >= 1) return '${d.inDays}d ago';
  if (d.inHours >= 1) return '${d.inHours}h ago';
  return 'just now';
}

String _inDays(int? days) {
  if (days == null) return 'soon';
  if (days <= 0) return 'today';
  if (days == 1) return 'tomorrow';
  return 'in $days days';
}
