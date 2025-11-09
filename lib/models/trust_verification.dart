enum VerificationLevel { gold, silver, bronze, unverified }

enum EndorserType { familyFriend, professional, educational, communityLeader }

enum VerificationStatus { pending, verified, rejected }

class TrustVerification {
  final String userId;
  final int trustScore;
  final VerificationLevel level;
  final List<Endorsement> endorsements;
  final Map<String, bool> verificationChecks;
  final DateTime lastUpdated;
  final bool isProfileVerified;
  final int totalEndorsements;

  TrustVerification({
    required this.userId,
    required this.trustScore,
    required this.level,
    required this.endorsements,
    required this.verificationChecks,
    required this.lastUpdated,
    this.isProfileVerified = false,
    this.totalEndorsements = 0,
  });

  String get levelDisplayName {
    switch (level) {
      case VerificationLevel.gold:
        return 'GOLD VERIFIED';
      case VerificationLevel.silver:
        return 'SILVER VERIFIED';
      case VerificationLevel.bronze:
        return 'BRONZE VERIFIED';
      case VerificationLevel.unverified:
        return 'UNVERIFIED';
    }
  }

  String get levelEmoji {
    switch (level) {
      case VerificationLevel.gold:
        return '🥇';
      case VerificationLevel.silver:
        return '🥈';
      case VerificationLevel.bronze:
        return '🥉';
      case VerificationLevel.unverified:
        return '❌';
    }
  }

  int get familyFriendsCount =>
      endorsements.where((e) => e.type == EndorserType.familyFriend).length;

  int get professionalCount =>
      endorsements.where((e) => e.type == EndorserType.professional).length;

  int get communityLeaderCount =>
      endorsements.where((e) => e.type == EndorserType.communityLeader).length;
}

class Endorsement {
  final String id;
  final String endorserId;
  final String endorserName;
  final EndorserType type;
  final String relationship;
  final String message;
  final int yearsKnown;
  final List<String> verificationPoints;
  final DateTime createdAt;
  final VerificationStatus status;
  final String? endorserPhoto;

  Endorsement({
    required this.id,
    required this.endorserId,
    required this.endorserName,
    required this.type,
    required this.relationship,
    required this.message,
    required this.yearsKnown,
    required this.verificationPoints,
    required this.createdAt,
    this.status = VerificationStatus.pending,
    this.endorserPhoto,
  });

  String get typeDisplayName {
    switch (type) {
      case EndorserType.familyFriend:
        return 'Family Friend';
      case EndorserType.professional:
        return 'Professional';
      case EndorserType.educational:
        return 'Educational';
      case EndorserType.communityLeader:
        return 'Community Leader';
    }
  }

  String get typeIcon {
    switch (type) {
      case EndorserType.familyFriend:
        return '👨‍👩‍👧‍👦';
      case EndorserType.professional:
        return '💼';
      case EndorserType.educational:
        return '🎓';
      case EndorserType.communityLeader:
        return '🏛️';
    }
  }
}

class VerificationRequest {
  final String id;
  final String requesterId;
  final String recipientId;
  final String recipientName;
  final String recipientContact;
  final EndorserType type;
  final String relationship;
  final String customMessage;
  final List<String> requestedVerifications;
  final DateTime sentAt;
  final VerificationStatus status;

  VerificationRequest({
    required this.id,
    required this.requesterId,
    required this.recipientId,
    required this.recipientName,
    required this.recipientContact,
    required this.type,
    required this.relationship,
    required this.customMessage,
    required this.requestedVerifications,
    required this.sentAt,
    this.status = VerificationStatus.pending,
  });
}
