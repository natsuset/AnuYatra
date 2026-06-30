import 'package:testing_flutter/core/data/remote/api_client.dart';
import 'package:testing_flutter/core/data/repositories/saved_profile_repository.dart';
import 'package:testing_flutter/core/data/repositories/viewed_profile_repository.dart';
import 'package:testing_flutter/core/data/repositories/activity_repository.dart';
import 'package:testing_flutter/core/data/repositories/parent_note_repository.dart';
import 'package:testing_flutter/core/data/repositories/broker_note_repository.dart';
import 'package:testing_flutter/core/data/repositories/meeting_repository.dart';
import 'package:testing_flutter/core/data/repositories/client_engagement_repository.dart';
import 'package:testing_flutter/core/data/repositories/broker_follow_up_repository.dart';
import 'package:testing_flutter/core/errors/app_exceptions.dart';
import 'package:testing_flutter/models/saved_profile.dart';
import 'package:testing_flutter/models/viewed_profile.dart';
import 'package:testing_flutter/models/profile_activity.dart';
import 'package:testing_flutter/models/parent_note.dart';
import 'package:testing_flutter/models/broker_note.dart';
import 'package:testing_flutter/models/meeting.dart';
import 'package:testing_flutter/models/client_engagement.dart';
import 'package:testing_flutter/models/broker_follow_up.dart';

// ── Saved Profiles ──────────────────────────────────────────────────

class RemoteSavedProfileRepository implements SavedProfileRepository {
  final ApiClient _api;
  RemoteSavedProfileRepository(this._api);

  @override
  Future<bool> isSaved({required String userId, required String profileId}) async {
    final data = await _api.get('/api/v1/saved-profiles/check/$profileId');
    return data['saved'] as bool? ?? false;
  }

  @override
  Future<SavedProfile> save({required String userId, required String profileId}) async {
    final data = await _api.post('/api/v1/saved-profiles', body: {
      'profileId': profileId,
    });
    return SavedProfile.fromJson(data);
  }

  @override
  Future<void> unsave({required String userId, required String profileId}) async {
    await _api.delete('/api/v1/saved-profiles/$profileId');
  }

  @override
  Future<bool> toggle({required String userId, required String profileId}) async {
    final saved = await isSaved(userId: userId, profileId: profileId);
    if (saved) {
      await unsave(userId: userId, profileId: profileId);
      return false;
    } else {
      await save(userId: userId, profileId: profileId);
      return true;
    }
  }

  @override
  Future<List<SavedProfile>> getSavedProfilesForUser(
    String userId, {
    int? limit,
    int? offset,
  }) async {
    final params = <String, String>{};
    if (limit != null) params['limit'] = '$limit';
    if (offset != null) params['offset'] = '$offset';
    final data = await _api.get('/api/v1/saved-profiles', queryParams: params);
    final items = data['data'] as List<dynamic>? ?? [];
    return items.cast<Map<String, dynamic>>().map(SavedProfile.fromJson).toList(growable: false);
  }

  @override
  Future<int> getSavedCount(String userId) async {
    final all = await getSavedProfilesForUser(userId, limit: 0);
    return all.length;
  }
}

// ── Viewed Profiles ─────────────────────────────────────────────────

class RemoteViewedProfileRepository implements ViewedProfileRepository {
  final ApiClient _api;
  RemoteViewedProfileRepository(this._api);

  @override
  Future<void> recordView({required String userId, required String profileId}) async {
    await _api.post('/api/v1/viewed-profiles', body: {'profileId': profileId});
  }

  @override
  Future<List<ViewedProfile>> getRecentViews(String userId, {int limit = 50}) async {
    final data = await _api.get(
      '/api/v1/viewed-profiles',
      queryParams: {'limit': '$limit'},
    );
    final items = data['data'] as List<dynamic>? ?? [];
    return items.cast<Map<String, dynamic>>().map(ViewedProfile.fromJson).toList(growable: false);
  }

  @override
  Future<int> getViewCount(String userId) async {
    final views = await getRecentViews(userId);
    return views.length;
  }

  @override
  Future<void> clearHistory(String userId) async {
    await _api.delete('/api/v1/viewed-profiles');
  }
}

// ── Activity ────────────────────────────────────────────────────────

class RemoteActivityRepository implements ActivityRepository {
  final ApiClient _api;
  RemoteActivityRepository(this._api);

  @override
  Future<void> record(ProfileActivity event) async {
    // Activity recording is done server-side as a side-effect of
    // share, respond, forward, etc. No client-side recording needed.
  }

  @override
  Future<List<ProfileActivity>> getActivityForProfile(
    String profileId, {
    int limit = 50,
  }) async {
    final data = await _api.get(
      '/api/v1/candidate-profiles/$profileId/activity',
      queryParams: {'limit': '$limit'},
    );
    final items = data['data'] as List<dynamic>? ?? [];
    return items.cast<Map<String, dynamic>>().map(ProfileActivity.fromJson).toList(growable: false);
  }
}

// ── Parent Notes ────────────────────────────────────────────────────

class RemoteParentNoteRepository implements ParentNoteRepository {
  final ApiClient _api;
  RemoteParentNoteRepository(this._api);

  @override
  Future<List<ParentNote>> getNotesForProfile({
    required String parentUserId,
    required String candidateProfileId,
  }) async {
    try {
      final data = await _api.get(
        '/api/v1/notes/parent',
        queryParams: {'profileId': candidateProfileId},
      );
      return [ParentNote.fromJson(data)];
    } on NotFoundException {
      return [];
    }
  }

  @override
  Future<List<ParentNote>> getAllNotesForParent(String parentUserId) async {
    final data = await _api.get('/api/v1/notes/parent/all');
    final items = data['data'] as List<dynamic>? ?? [];
    return items.cast<Map<String, dynamic>>().map(ParentNote.fromJson).toList(growable: false);
  }

  @override
  Future<void> saveNote(ParentNote note) async {
    await _api.put('/api/v1/notes/parent', body: note.toJson());
  }

  @override
  Future<void> deleteNote(String noteId) async {
    await _api.delete('/api/v1/notes/parent/$noteId');
  }

  @override
  Future<int> getNoteCount({
    required String parentUserId,
    required String candidateProfileId,
  }) async {
    final notes = await getNotesForProfile(
      parentUserId: parentUserId,
      candidateProfileId: candidateProfileId,
    );
    return notes.length;
  }
}

// ── Broker Notes ────────────────────────────────────────────────────

class RemoteBrokerNoteRepository implements BrokerNoteRepository {
  final ApiClient _api;
  RemoteBrokerNoteRepository(this._api);

  @override
  Future<BrokerNote?> get({
    required String brokerUserId,
    required String candidateProfileId,
    required String forParentUserId,
  }) async {
    try {
      final data = await _api.get(
        '/api/v1/notes/broker',
        queryParams: {
          'profileId': candidateProfileId,
          'forParentId': forParentUserId,
        },
      );
      return BrokerNote.fromJson(data);
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<void> upsert({
    required String brokerUserId,
    required String candidateProfileId,
    required String forParentUserId,
    required String body,
  }) async {
    await _api.put('/api/v1/notes/broker', body: {
      'candidateProfileId': candidateProfileId,
      'forParentUserId': forParentUserId,
      'body': body,
    });
  }
}

// ── Meetings ────────────────────────────────────────────────────────

class RemoteMeetingRepository implements MeetingRepository {
  final ApiClient _api;
  RemoteMeetingRepository(this._api);

  @override
  Future<void> save(Meeting meeting) async {
    if (meeting.id.isEmpty) {
      await _api.post('/api/v1/meetings', body: meeting.toJson());
    } else {
      await _api.post('/api/v1/meetings', body: meeting.toJson());
    }
  }

  @override
  Future<Meeting?> get(String id) async {
    try {
      final data = await _api.get('/api/v1/meetings/$id');
      return Meeting.fromJson(data);
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<List<Meeting>> getMeetingsFor({
    required String parentUserId,
    required String candidateProfileId,
    required String viewerUserId,
    int? limit,
  }) async {
    final data = await _api.get(
      '/api/v1/meetings',
      queryParams: {
        'parentUserId': parentUserId,
        'profileId': candidateProfileId,
        if (limit != null) 'limit': '$limit',
      },
    );
    final items = data['data'] as List<dynamic>? ?? [];
    return items.cast<Map<String, dynamic>>().map(Meeting.fromJson).toList(growable: false);
  }

  @override
  Future<Meeting?> getNextMeeting({
    required String parentUserId,
    required String candidateProfileId,
    required String viewerUserId,
  }) async {
    try {
      final data = await _api.get(
        '/api/v1/meetings/next',
        queryParams: {
          'parentUserId': parentUserId,
          'profileId': candidateProfileId,
        },
      );
      return Meeting.fromJson(data);
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<void> cancel(String meetingId) async {
    await _api.post('/api/v1/meetings/$meetingId/cancel');
  }
}

// ── Client Engagements ──────────────────────────────────────────────

class RemoteClientEngagementRepository implements ClientEngagementRepository {
  final ApiClient _api;
  RemoteClientEngagementRepository(this._api);

  @override
  Future<ClientEngagement?> get({
    required String brokerUserId,
    required String parentUserId,
  }) async {
    try {
      final data = await _api.get(
        '/api/v1/broker/engagements',
        queryParams: {'parentUserId': parentUserId},
      );
      return ClientEngagement.fromJson(data);
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<void> save(ClientEngagement engagement) async {
    await _api.put('/api/v1/broker/engagements', body: engagement.toJson());
  }

  @override
  Future<List<ClientEngagement>> getForBroker(String brokerUserId) async {
    final data = await _api.get('/api/v1/broker/engagements/all');
    final items = data['data'] as List<dynamic>? ?? [];
    return items
        .cast<Map<String, dynamic>>()
        .map(ClientEngagement.fromJson)
        .toList(growable: false);
  }
}

// ── Broker Follow-ups ───────────────────────────────────────────────

class RemoteBrokerFollowUpRepository implements BrokerFollowUpRepository {
  final ApiClient _api;
  RemoteBrokerFollowUpRepository(this._api);

  @override
  Future<void> save(BrokerFollowUp followUp) async {
    await _api.put('/api/v1/broker/follow-ups', body: followUp.toJson());
  }

  @override
  Future<void> delete(String id) async {
    await _api.delete('/api/v1/broker/follow-ups/$id');
  }

  @override
  Future<List<BrokerFollowUp>> getForBroker(String brokerUserId) async {
    final data = await _api.get('/api/v1/broker/follow-ups');
    final items = data['data'] as List<dynamic>? ?? [];
    return items
        .cast<Map<String, dynamic>>()
        .map(BrokerFollowUp.fromJson)
        .toList(growable: false);
  }

  @override
  Future<List<BrokerFollowUp>> getForClient({
    required String brokerUserId,
    required String clientUserId,
  }) async {
    final data = await _api.get(
      '/api/v1/broker/follow-ups',
      queryParams: {'clientUserId': clientUserId},
    );
    final items = data['data'] as List<dynamic>? ?? [];
    return items
        .cast<Map<String, dynamic>>()
        .map(BrokerFollowUp.fromJson)
        .toList(growable: false);
  }
}
