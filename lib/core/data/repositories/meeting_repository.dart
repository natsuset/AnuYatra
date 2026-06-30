import 'package:testing_flutter/models/meeting.dart';

/// CRUD for `Meeting` records with built-in visibility filtering.
///
/// Read methods accept the [viewerUserId] so the implementation can hide
/// meetings the viewer shouldn't see (see [Meeting] visibility rules).
abstract class MeetingRepository {
  Future<void> save(Meeting meeting);

  Future<Meeting?> get(String id);

  /// All meetings tied to a `(parentId, candidateProfileId)` pair visible
  /// to [viewerUserId]. Sorted by `when` ascending (upcoming first).
  Future<List<Meeting>> getMeetingsFor({
    required String parentUserId,
    required String candidateProfileId,
    required String viewerUserId,
    int? limit,
  });

  /// The next upcoming visible meeting, or `null` if none scheduled.
  Future<Meeting?> getNextMeeting({
    required String parentUserId,
    required String candidateProfileId,
    required String viewerUserId,
  });

  Future<void> cancel(String meetingId);
}
