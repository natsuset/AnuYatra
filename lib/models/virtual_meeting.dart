enum MeetingType {
  firstIntroduction,
  valuesDiscussion,
  culturalExchange,
  futurePlanning,
  virtualDinner,
}

enum MeetingStatus { scheduled, inProgress, completed, cancelled, rescheduled }

enum AIsuggestionType {
  conversationStarter,
  iceBreaker,
  activity,
  culturalBridge,
}

class VirtualMeeting {
  final String meetingId;
  final List<String> participantIds;
  final List<MeetingParticipant> participants;
  final MeetingType type;
  final DateTime scheduledTime;
  final int durationMinutes;
  final MeetingStatus status;
  final List<AIsuggestion> suggestions;
  final MeetingRecording? recording;
  final PostMeetingFeedback? feedback;
  final String? meetingLink;
  final DateTime createdAt;

  VirtualMeeting({
    required this.meetingId,
    required this.participantIds,
    required this.participants,
    required this.type,
    required this.scheduledTime,
    required this.durationMinutes,
    required this.status,
    required this.suggestions,
    this.recording,
    this.feedback,
    this.meetingLink,
    required this.createdAt,
  });

  String get typeDisplayName {
    switch (type) {
      case MeetingType.firstIntroduction:
        return 'First Introduction';
      case MeetingType.valuesDiscussion:
        return 'Values & Traditions';
      case MeetingType.culturalExchange:
        return 'Cultural Exchange';
      case MeetingType.futurePlanning:
        return 'Future Planning';
      case MeetingType.virtualDinner:
        return 'Virtual Family Dinner';
    }
  }

  String get typeEmoji {
    switch (type) {
      case MeetingType.firstIntroduction:
        return '👋';
      case MeetingType.valuesDiscussion:
        return '💭';
      case MeetingType.culturalExchange:
        return '🌍';
      case MeetingType.futurePlanning:
        return '🔮';
      case MeetingType.virtualDinner:
        return '🍽️';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case MeetingStatus.scheduled:
        return 'Scheduled';
      case MeetingStatus.inProgress:
        return 'In Progress';
      case MeetingStatus.completed:
        return 'Completed';
      case MeetingStatus.cancelled:
        return 'Cancelled';
      case MeetingStatus.rescheduled:
        return 'Rescheduled';
    }
  }

  bool get isUpcoming =>
      status == MeetingStatus.scheduled &&
      scheduledTime.isAfter(DateTime.now());

  bool get isToday =>
      scheduledTime.day == DateTime.now().day &&
      scheduledTime.month == DateTime.now().month &&
      scheduledTime.year == DateTime.now().year;
}

class MeetingParticipant {
  final String userId;
  final String name;
  final String role; // 'Father', 'Mother', 'Bride', 'Groom', etc.
  final String? photoUrl;
  final bool isMainProfile;
  final String familyName;

  MeetingParticipant({
    required this.userId,
    required this.name,
    required this.role,
    this.photoUrl,
    this.isMainProfile = false,
    required this.familyName,
  });
}

class AIsuggestion {
  final String id;
  final AIsuggestionType type;
  final String title;
  final String suggestion;
  final List<String> followUpQuestions;
  final bool isUsed;
  final DateTime createdAt;

  AIsuggestion({
    required this.id,
    required this.type,
    required this.title,
    required this.suggestion,
    required this.followUpQuestions,
    this.isUsed = false,
    required this.createdAt,
  });

  String get typeIcon {
    switch (type) {
      case AIsuggestionType.conversationStarter:
        return '💬';
      case AIsuggestionType.iceBreaker:
        return '🧊';
      case AIsuggestionType.activity:
        return '🎮';
      case AIsuggestionType.culturalBridge:
        return '🌉';
    }
  }
}

class InteractiveActivity {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int estimatedMinutes;
  final bool requiresScreenShare;

  InteractiveActivity({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.estimatedMinutes,
    this.requiresScreenShare = false,
  });

  static List<InteractiveActivity> getDefaultActivities() {
    return [
      InteractiveActivity(
        id: 'photo_sharing',
        name: 'Family Photo Sharing',
        description: 'Share and discuss family photos and memories',
        icon: '📸',
        estimatedMinutes: 10,
        requiresScreenShare: true,
      ),
      InteractiveActivity(
        id: 'recipe_share',
        name: 'Favorite Recipe Share',
        description: 'Exchange family recipes and cooking traditions',
        icon: '🍽️',
        estimatedMinutes: 15,
      ),
      InteractiveActivity(
        id: 'virtual_tour',
        name: 'Virtual Home Tour',
        description: 'Show your home and living spaces',
        icon: '🏠',
        estimatedMinutes: 15,
        requiresScreenShare: true,
      ),
      InteractiveActivity(
        id: 'cultural_music',
        name: 'Cultural Music Exchange',
        description: 'Share favorite cultural music and songs',
        icon: '🎵',
        estimatedMinutes: 12,
      ),
      InteractiveActivity(
        id: 'values_quiz',
        name: 'Family Values Quiz',
        description: 'Fun quiz about family values and preferences',
        icon: '🧩',
        estimatedMinutes: 20,
      ),
      InteractiveActivity(
        id: 'culture_show',
        name: 'Regional Culture Show',
        description: 'Share regional customs and traditions',
        icon: '🗺️',
        estimatedMinutes: 18,
      ),
    ];
  }
}

class MeetingRecording {
  final String recordingId;
  final String meetingId;
  final String recordingUrl;
  final int durationMinutes;
  final DateTime recordedAt;
  final bool isShared;
  final List<String> sharedWithUserIds;

  MeetingRecording({
    required this.recordingId,
    required this.meetingId,
    required this.recordingUrl,
    required this.durationMinutes,
    required this.recordedAt,
    this.isShared = false,
    this.sharedWithUserIds = const [],
  });
}

class PostMeetingFeedback {
  final String meetingId;
  final String userId;
  final int overallRating;
  final int engagementLevel;
  final int culturalAlignment;
  final int conversationFlow;
  final String? privateNotes;
  final List<String> discussionPoints;
  final bool recommendFollowUp;
  final DateTime submittedAt;

  PostMeetingFeedback({
    required this.meetingId,
    required this.userId,
    required this.overallRating,
    required this.engagementLevel,
    required this.culturalAlignment,
    required this.conversationFlow,
    this.privateNotes,
    required this.discussionPoints,
    this.recommendFollowUp = true,
    required this.submittedAt,
  });

  double get averageScore =>
      (overallRating + engagementLevel + culturalAlignment + conversationFlow) /
      4.0;
}
