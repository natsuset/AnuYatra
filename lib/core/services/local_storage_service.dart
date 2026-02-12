import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:testing_flutter/models/app_user.dart';
import 'package:testing_flutter/models/user_role.dart';
import 'package:testing_flutter/models/agency.dart';
import 'package:testing_flutter/models/broker_profile.dart';
import 'package:testing_flutter/models/parent_profile.dart';
import 'package:testing_flutter/models/candidate_profile.dart';
import 'package:testing_flutter/models/link_request.dart';
import 'package:testing_flutter/models/shared_profile.dart';
import 'package:testing_flutter/models/chat_message.dart';

const _uuid = Uuid();

/// Hive-backed local database that acts as a mini server.
/// Multiple accounts on one device can interact with each other.
class LocalStorageService {
  static const String _usersBox = 'users';
  static const String _agenciesBox = 'agencies';
  static const String _brokerProfilesBox = 'brokerProfiles';
  static const String _parentProfilesBox = 'parentProfiles';
  static const String _candidateProfilesBox = 'candidateProfiles';
  static const String _linkRequestsBox = 'linkRequests';
  static const String _sharedProfilesBox = 'sharedProfiles';
  static const String _conversationsBox = 'conversations';
  static const String _messagesBox = 'messages';
  static const String _sessionBox = 'session';

  late Box<String> _users;
  late Box<String> _agencies;
  late Box<String> _brokerProfiles;
  late Box<String> _parentProfiles;
  late Box<String> _candidateProfiles;
  late Box<String> _linkRequests;
  late Box<String> _sharedProfiles;
  late Box<String> _conversations;
  late Box<String> _messages;
  late Box<String> _session;

  bool _initialized = false;

  /// Initialize all Hive boxes
  Future<void> init() async {
    if (_initialized) return;

    _users = await Hive.openBox<String>(_usersBox);
    _agencies = await Hive.openBox<String>(_agenciesBox);
    _brokerProfiles = await Hive.openBox<String>(_brokerProfilesBox);
    _parentProfiles = await Hive.openBox<String>(_parentProfilesBox);
    _candidateProfiles = await Hive.openBox<String>(_candidateProfilesBox);
    _linkRequests = await Hive.openBox<String>(_linkRequestsBox);
    _sharedProfiles = await Hive.openBox<String>(_sharedProfilesBox);
    _conversations = await Hive.openBox<String>(_conversationsBox);
    _messages = await Hive.openBox<String>(_messagesBox);
    _session = await Hive.openBox<String>(_sessionBox);

    _initialized = true;
  }

  /// Check if this is the first launch (no data seeded yet)
  bool get isFirstLaunch => _users.isEmpty;

  // ─── SESSION ──────────────────────────────────────────────

  /// Get the currently logged-in user's UID
  String? get currentUserId => _session.get('currentUserId');

  /// Get the currently logged-in user
  AppUser? get currentUser {
    final uid = currentUserId;
    if (uid == null) return null;
    return getUser(uid);
  }

  /// Set the current session
  Future<void> setCurrentUser(String uid) async {
    await _session.put('currentUserId', uid);
  }

  /// Clear the current session (logout)
  Future<void> clearSession() async {
    await _session.delete('currentUserId');
  }

  // ─── USERS ──────────────────────────────────────────────

  /// Register a new user
  Future<AppUser> registerUser({
    required String phoneNumber,
    required String displayName,
    required UserRole role,
    String? photoUrl,
  }) async {
    final uid = _uuid.v4();
    final user = AppUser(
      uid: uid,
      phoneNumber: phoneNumber,
      displayName: displayName,
      photoUrl: photoUrl,
      role: role,
      createdAt: DateTime.now(),
    );
    await _users.put(uid, jsonEncode(user.toJson()));
    return user;
  }

  /// Save a user (for seeding or updates)
  Future<void> saveUser(AppUser user) async {
    await _users.put(user.uid, jsonEncode(user.toJson()));
  }

  /// Get a user by UID
  AppUser? getUser(String uid) {
    final raw = _users.get(uid);
    if (raw == null) return null;
    return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Find a user by phone number
  AppUser? getUserByPhone(String phoneNumber) {
    for (final raw in _users.values) {
      final user = AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      if (user.phoneNumber == phoneNumber) return user;
    }
    return null;
  }

  /// Get all users
  List<AppUser> getAllUsers() {
    return _users.values
        .map((raw) => AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
  }

  // ─── AGENCIES ──────────────────────────────────────────────

  /// Create a new agency
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
    final id = _uuid.v4();
    final agency = Agency(
      id: id,
      adminUserId: adminUserId,
      name: name,
      logoUrl: logoUrl,
      city: city,
      state: state,
      description: description,
      specializations: specializations,
      areasServed: areasServed,
      createdAt: DateTime.now(),
    );
    await _agencies.put(id, jsonEncode(agency.toJson()));

    // Update user's agencyId
    final user = getUser(adminUserId);
    if (user != null) {
      await saveUser(user.copyWith(agencyId: id));
    }

    return agency;
  }

  /// Save an agency (for seeding or updates)
  Future<void> saveAgency(Agency agency) async {
    await _agencies.put(agency.id, jsonEncode(agency.toJson()));
  }

  /// Get an agency by ID
  Agency? getAgency(String id) {
    final raw = _agencies.get(id);
    if (raw == null) return null;
    return Agency.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Get all agencies
  List<Agency> getAllAgencies() {
    return _agencies.values
        .map((raw) => Agency.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
  }

  /// Search agencies by query
  List<Agency> searchAgencies({String? query, String? city, double? minRating}) {
    var results = getAllAgencies().where((a) => a.isActive);

    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      results = results.where((a) =>
          a.name.toLowerCase().contains(q) ||
          a.description.toLowerCase().contains(q) ||
          a.specializations.any((s) => s.toLowerCase().contains(q)) ||
          a.city.toLowerCase().contains(q));
    }

    if (city != null) {
      results = results.where((a) => a.city.toLowerCase() == city.toLowerCase());
    }

    if (minRating != null) {
      results = results.where((a) => a.rating >= minRating);
    }

    return results.toList();
  }

  // ─── BROKER PROFILES ──────────────────────────────────────

  /// Save a broker profile
  Future<void> saveBrokerProfile(BrokerProfile profile) async {
    await _brokerProfiles.put(profile.userId, jsonEncode(profile.toJson()));
  }

  /// Get a broker profile by userId
  BrokerProfile? getBrokerProfile(String userId) {
    final raw = _brokerProfiles.get(userId);
    if (raw == null) return null;
    return BrokerProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Get all broker profiles
  List<BrokerProfile> getAllBrokerProfiles() {
    return _brokerProfiles.values
        .map((raw) => BrokerProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
  }

  /// Get brokers by agency
  List<BrokerProfile> getBrokersByAgency(String agencyId) {
    return getAllBrokerProfiles()
        .where((b) => b.agencyId == agencyId)
        .toList();
  }

  /// Search brokers by query
  List<BrokerProfile> searchBrokers({String? query, String? city, double? minRating}) {
    var results = getAllBrokerProfiles();

    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      results = results.where((b) =>
          b.name.toLowerCase().contains(q) ||
          b.bio.toLowerCase().contains(q) ||
          b.specializations.any((s) => s.toLowerCase().contains(q)) ||
          b.areasServed.any((a) => a.toLowerCase().contains(q))).toList();
    }

    if (city != null) {
      results = results.where((b) =>
          b.areasServed.any((a) => a.toLowerCase() == city.toLowerCase())).toList();
    }

    if (minRating != null) {
      results = results.where((b) => b.rating >= minRating).toList();
    }

    return results;
  }

  /// Unified search: returns both agencies and brokers as a mixed list
  /// Returns Map with 'agencies' and 'brokers' keys
  Map<String, List<dynamic>> searchBrokersAndAgencies({
    String? query,
    String? city,
    double? minRating,
    String? searchType, // 'all', 'agencies', 'brokers'
  }) {
    List<Agency> agencies = [];
    List<BrokerProfile> brokers = [];

    if (searchType == null || searchType == 'all' || searchType == 'agencies') {
      agencies = searchAgencies(query: query, city: city, minRating: minRating);
    }

    if (searchType == null || searchType == 'all' || searchType == 'brokers') {
      brokers = searchBrokers(query: query, city: city, minRating: minRating);
    }

    return {'agencies': agencies, 'brokers': brokers};
  }

  // ─── PARENT PROFILES ──────────────────────────────────────

  /// Save a parent profile
  Future<void> saveParentProfile(ParentProfile profile) async {
    await _parentProfiles.put(profile.userId, jsonEncode(profile.toJson()));
  }

  /// Get a parent profile by userId
  ParentProfile? getParentProfile(String userId) {
    final raw = _parentProfiles.get(userId);
    if (raw == null) return null;
    return ParentProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Get all parent profiles
  List<ParentProfile> getAllParentProfiles() {
    return _parentProfiles.values
        .map((raw) => ParentProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
  }

  // ─── CANDIDATE PROFILES ──────────────────────────────────────

  /// Save a candidate profile
  Future<void> saveCandidateProfile(CandidateProfile profile) async {
    await _candidateProfiles.put(profile.id, jsonEncode(profile.toJson()));
  }

  /// Get a candidate profile by ID
  CandidateProfile? getCandidateProfile(String id) {
    final raw = _candidateProfiles.get(id);
    if (raw == null) return null;
    return CandidateProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Get all candidate profiles
  List<CandidateProfile> getAllCandidateProfiles() {
    return _candidateProfiles.values
        .map((raw) => CandidateProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
  }

  /// Get candidate profiles managed by a broker
  List<CandidateProfile> getCandidatesByBroker(String brokerUserId) {
    return getAllCandidateProfiles()
        .where((p) => p.brokerIds.contains(brokerUserId) || p.createdByUserId == brokerUserId)
        .toList();
  }

  /// Get candidate profiles for a parent (via shared profiles)
  List<CandidateProfile> getSharedCandidatesForParent(String parentUserId) {
    final shared = getSharedProfilesForUser(parentUserId);
    final profileIds = shared.map((s) => s.profileId).toSet();
    return getAllCandidateProfiles()
        .where((p) => profileIds.contains(p.id))
        .toList();
  }

  // ─── LINK REQUESTS ──────────────────────────────────────

  /// Send a link request
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

  /// Save a link request (for seeding)
  Future<void> saveLinkRequest(LinkRequest request) async {
    await _linkRequests.put(request.id, jsonEncode(request.toJson()));
  }

  /// Accept a link request
  Future<LinkRequest> acceptLinkRequest(String requestId) async {
    final request = getLinkRequest(requestId);
    if (request == null) throw Exception('Link request not found');

    final updated = request.copyWith(
      status: LinkRequestStatus.accepted,
      respondedAt: DateTime.now(),
    );
    await _linkRequests.put(requestId, jsonEncode(updated.toJson()));

    // Handle side effects based on request type
    await _handleLinkRequestAccepted(updated);

    return updated;
  }

  /// Decline a link request
  Future<LinkRequest> declineLinkRequest(String requestId) async {
    final request = getLinkRequest(requestId);
    if (request == null) throw Exception('Link request not found');

    final updated = request.copyWith(
      status: LinkRequestStatus.declined,
      respondedAt: DateTime.now(),
    );
    await _linkRequests.put(requestId, jsonEncode(updated.toJson()));
    return updated;
  }

  /// Handle side effects when a link request is accepted
  Future<void> _handleLinkRequestAccepted(LinkRequest request) async {
    switch (request.type) {
      case LinkRequestType.agencyToBroker:
        // Add broker to agency
        final broker = getBrokerProfile(request.toUserId);
        if (broker != null) {
          final user = getUser(request.fromUserId);
          final agencyId = user?.agencyId;
          if (agencyId != null) {
            await saveBrokerProfile(broker.copyWith(agencyId: agencyId));
          }
        }
        break;

      case LinkRequestType.parentToBroker:
        // Update broker's client count
        final broker = getBrokerProfile(request.toUserId);
        if (broker != null) {
          await saveBrokerProfile(
            broker.copyWith(clientCount: broker.clientCount + 1),
          );
        }
        // Create a conversation between parent and broker
        await _getOrCreateConversation(request.fromUserId, request.toUserId);
        break;

      case LinkRequestType.parentToAgency:
        // Create a conversation between parent and agency admin
        final agency = getAllAgencies().where((a) {
          final admin = getUser(a.adminUserId);
          return admin?.uid == request.toUserId;
        }).firstOrNull;
        if (agency != null) {
          await _getOrCreateConversation(request.fromUserId, agency.adminUserId);
        }
        break;

      case LinkRequestType.childToParent:
        // No additional side effects needed — the link itself is the connection
        break;
    }
  }

  /// Get a link request by ID
  LinkRequest? getLinkRequest(String id) {
    final raw = _linkRequests.get(id);
    if (raw == null) return null;
    return LinkRequest.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Get all link requests
  List<LinkRequest> getAllLinkRequests() {
    return _linkRequests.values
        .map((raw) => LinkRequest.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
  }

  /// Get link requests sent by a user
  List<LinkRequest> getLinkRequestsSentBy(String userId) {
    return getAllLinkRequests()
        .where((r) => r.fromUserId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get link requests received by a user
  List<LinkRequest> getLinkRequestsReceivedBy(String userId) {
    return getAllLinkRequests()
        .where((r) => r.toUserId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get pending link requests for a user (incoming)
  List<LinkRequest> getPendingRequestsFor(String userId) {
    return getLinkRequestsReceivedBy(userId)
        .where((r) => r.status == LinkRequestStatus.pending)
        .toList();
  }

  /// Get accepted connections for a user (both directions)
  List<LinkRequest> getAcceptedConnectionsFor(String userId) {
    return getAllLinkRequests()
        .where((r) =>
            r.status == LinkRequestStatus.accepted &&
            (r.fromUserId == userId || r.toUserId == userId))
        .toList();
  }

  /// Get connected broker user IDs for a parent
  List<String> getConnectedBrokerIds(String parentUserId) {
    final connections = getAcceptedConnectionsFor(parentUserId)
        .where((r) =>
            r.type == LinkRequestType.parentToBroker);

    return connections.map((r) {
      return r.fromUserId == parentUserId ? r.toUserId : r.fromUserId;
    }).toList();
  }

  /// Get connected parent user IDs for a broker
  List<String> getConnectedParentIds(String brokerUserId) {
    final connections = getAcceptedConnectionsFor(brokerUserId)
        .where((r) =>
            r.type == LinkRequestType.parentToBroker);

    return connections.map((r) {
      return r.fromUserId == brokerUserId ? r.toUserId : r.fromUserId;
    }).toList();
  }

  /// Get linked child user ID for a parent
  String? getLinkedChildId(String parentUserId) {
    final connection = getAcceptedConnectionsFor(parentUserId)
        .where((r) => r.type == LinkRequestType.childToParent)
        .firstOrNull;
    if (connection == null) return null;
    return connection.fromUserId == parentUserId
        ? connection.toUserId
        : connection.fromUserId;
  }

  /// Get linked parent user ID for a child/candidate
  String? getLinkedParentId(String childUserId) {
    final connection = getAcceptedConnectionsFor(childUserId)
        .where((r) => r.type == LinkRequestType.childToParent)
        .firstOrNull;
    if (connection == null) return null;
    return connection.fromUserId == childUserId
        ? connection.toUserId
        : connection.fromUserId;
  }

  // ─── SHARED PROFILES ──────────────────────────────────────

  /// Share a profile with a parent
  Future<SharedProfile> shareProfile({
    required String profileId,
    required String sharedByUserId,
    required String sharedWithUserId,
  }) async {
    final id = _uuid.v4();
    final shared = SharedProfile(
      id: id,
      profileId: profileId,
      sharedByUserId: sharedByUserId,
      sharedWithUserId: sharedWithUserId,
      sharedAt: DateTime.now(),
    );
    await _sharedProfiles.put(id, jsonEncode(shared.toJson()));
    return shared;
  }

  /// Save a shared profile (for seeding)
  Future<void> saveSharedProfile(SharedProfile shared) async {
    await _sharedProfiles.put(shared.id, jsonEncode(shared.toJson()));
  }

  /// Update a shared profile (e.g., parent responds)
  Future<void> updateSharedProfile(SharedProfile shared) async {
    await _sharedProfiles.put(shared.id, jsonEncode(shared.toJson()));
  }

  /// Get shared profiles for a user (parent sees profiles shared with them)
  List<SharedProfile> getSharedProfilesForUser(String userId) {
    return getAllSharedProfiles()
        .where((s) => s.sharedWithUserId == userId)
        .toList()
      ..sort((a, b) => b.sharedAt.compareTo(a.sharedAt));
  }

  /// Get shared profiles by a broker
  List<SharedProfile> getSharedProfilesByBroker(String brokerUserId) {
    return getAllSharedProfiles()
        .where((s) => s.sharedByUserId == brokerUserId)
        .toList()
      ..sort((a, b) => b.sharedAt.compareTo(a.sharedAt));
  }

  /// Forward a shared profile to the parent's linked child
  Future<void> forwardProfileToChild(String sharedProfileId) async {
    final all = getAllSharedProfiles();
    final shared = all.where((s) => s.id == sharedProfileId).firstOrNull;
    if (shared == null) return;
    final updated = shared.copyWith(forwardedToChild: true);
    await _sharedProfiles.put(updated.id, jsonEncode(updated.toJson()));
  }

  /// Get shared profiles forwarded to a child (child sees these)
  List<SharedProfile> getForwardedProfiles(String parentUserId) {
    return getAllSharedProfiles()
        .where((s) => s.sharedWithUserId == parentUserId && s.forwardedToChild)
        .toList()
      ..sort((a, b) => b.sharedAt.compareTo(a.sharedAt));
  }

  /// Get all shared profiles
  List<SharedProfile> getAllSharedProfiles() {
    return _sharedProfiles.values
        .map((raw) => SharedProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
  }

  // ─── CONVERSATIONS & MESSAGES ──────────────────────────────

  /// Get or create a conversation between two users
  Future<Conversation> _getOrCreateConversation(String userId1, String userId2) async {
    // Check if conversation already exists
    final existing = getAllConversations().where((c) =>
        c.participantIds.contains(userId1) &&
        c.participantIds.contains(userId2)).firstOrNull;

    if (existing != null) return existing;

    final id = _uuid.v4();
    final conversation = Conversation(
      id: id,
      participantIds: [userId1, userId2],
    );
    await _conversations.put(id, jsonEncode(conversation.toJson()));
    return conversation;
  }

  /// Public: get or create a conversation between two users (sync returns ID)
  String getOrCreateConversation(String userId1, String userId2) {
    final existing = getAllConversations().where((c) =>
        c.participantIds.contains(userId1) &&
        c.participantIds.contains(userId2)).firstOrNull;

    if (existing != null) return existing.id;

    final id = _uuid.v4();
    final conversation = Conversation(
      id: id,
      participantIds: [userId1, userId2],
    );
    _conversations.put(id, jsonEncode(conversation.toJson()));
    return id;
  }

  /// Get a conversation by ID
  Conversation? getConversation(String id) {
    final raw = _conversations.get(id);
    if (raw == null) return null;
    return Conversation.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Get all conversations for a user
  List<Conversation> getConversationsForUser(String userId) {
    return getAllConversations()
        .where((c) => c.participantIds.contains(userId))
        .toList()
      ..sort((a, b) {
        final aTime = a.lastMessageAt ?? DateTime(2000);
        final bTime = b.lastMessageAt ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
  }

  /// Get all conversations
  List<Conversation> getAllConversations() {
    return _conversations.values
        .map((raw) => Conversation.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
  }

  /// Save a conversation (for seeding)
  Future<void> saveConversation(Conversation conversation) async {
    await _conversations.put(conversation.id, jsonEncode(conversation.toJson()));
  }

  /// Send a message
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String senderId,
    required String recipientId,
    required String content,
    ChatMessageType type = ChatMessageType.text,
    String? profileId,
  }) async {
    final id = _uuid.v4();
    final message = ChatMessage(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      recipientId: recipientId,
      content: content,
      type: type,
      timestamp: DateTime.now(),
      profileId: profileId,
    );
    await _saveMessage(message);

    // Update conversation's last message
    final conv = getConversation(conversationId);
    if (conv != null) {
      final updated = conv.copyWith(
        lastMessagePreview: content,
        lastMessageAt: message.timestamp,
        unreadCount: conv.unreadCount + 1,
      );
      await _conversations.put(conversationId, jsonEncode(updated.toJson()));
    }

    return message;
  }

  /// Save a message
  Future<void> _saveMessage(ChatMessage message) async {
    // Store messages in a box keyed by conversationId, each value is a JSON list
    final key = message.conversationId;
    final existing = _messages.get(key);
    List<dynamic> messageList = [];
    if (existing != null) {
      messageList = jsonDecode(existing) as List<dynamic>;
    }
    messageList.add(message.toJson());
    await _messages.put(key, jsonEncode(messageList));
  }

  /// Save a message directly (for seeding)
  Future<void> saveMessage(ChatMessage message) async {
    await _saveMessage(message);
  }

  /// Get messages for a conversation
  List<ChatMessage> getMessages(String conversationId) {
    final raw = _messages.get(conversationId);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    final messages = getMessages(conversationId);
    final updated = messages.map((m) {
      if (m.recipientId == userId && !m.isRead) {
        return m.copyWith(isRead: true);
      }
      return m;
    }).toList();

    final encoded = jsonEncode(updated.map((m) => m.toJson()).toList());
    await _messages.put(conversationId, encoded);

    // Reset unread count on conversation
    final conv = getConversation(conversationId);
    if (conv != null) {
      await _conversations.put(
        conversationId,
        jsonEncode(conv.copyWith(unreadCount: 0).toJson()),
      );
    }
  }

  // ─── DASHBOARD STATS ──────────────────────────────────────

  /// Get stats for a broker dashboard
  Map<String, int> getBrokerStats(String brokerUserId) {
    final clients = getConnectedParentIds(brokerUserId).length;
    final profiles = getCandidatesByBroker(brokerUserId).length;
    final shared = getSharedProfilesByBroker(brokerUserId).length;
    final pending = getPendingRequestsFor(brokerUserId).length;

    return {
      'activeClients': clients,
      'profilesManaged': profiles,
      'profilesShared': shared,
      'pendingRequests': pending,
    };
  }

  /// Get stats for an agency dashboard
  Map<String, int> getAgencyStats(String agencyId) {
    final brokers = getBrokersByAgency(agencyId).length;

    // Count all clients across agency brokers
    int totalClients = 0;
    int totalProfiles = 0;
    for (final broker in getBrokersByAgency(agencyId)) {
      totalClients += getConnectedParentIds(broker.userId).length;
      totalProfiles += getCandidatesByBroker(broker.userId).length;
    }

    return {
      'totalBrokers': brokers,
      'totalClients': totalClients,
      'totalProfiles': totalProfiles,
    };
  }

  // ─── UTILITY ──────────────────────────────────────────────

  /// Clear all data (for testing)
  Future<void> clearAll() async {
    await _users.clear();
    await _agencies.clear();
    await _brokerProfiles.clear();
    await _parentProfiles.clear();
    await _candidateProfiles.clear();
    await _linkRequests.clear();
    await _sharedProfiles.clear();
    await _conversations.clear();
    await _messages.clear();
    await _session.clear();
  }

  /// Generate a new UUID
  String generateId() => _uuid.v4();
}

/// Riverpod provider for LocalStorageService
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});
