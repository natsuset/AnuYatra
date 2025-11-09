import '../models/trust_verification.dart';
import '../models/financial_profile.dart';
import '../models/virtual_meeting.dart';

class RevolutionaryFeaturesData {
  // Trust Verification Mock Data
  static List<TrustVerification> get mockTrustVerifications => [
    TrustVerification(
      userId: '1',
      trustScore: 94,
      level: VerificationLevel.gold,
      endorsements: mockEndorsements,
      verificationChecks: {
        'government_id': true,
        'address_verification': true,
        'educational_credentials': true,
        'professional_verification': true,
        'family_verification': true,
      },
      lastUpdated: DateTime.now().subtract(const Duration(days: 2)),
      isProfileVerified: true,
      totalEndorsements: 127,
    ),
    TrustVerification(
      userId: '2',
      trustScore: 82,
      level: VerificationLevel.silver,
      endorsements: mockEndorsements.take(4).toList(),
      verificationChecks: {
        'government_id': true,
        'address_verification': false,
        'educational_credentials': true,
        'professional_verification': true,
        'family_verification': true,
      },
      lastUpdated: DateTime.now().subtract(const Duration(days: 5)),
      isProfileVerified: true,
      totalEndorsements: 73,
    ),
  ];

  static List<Endorsement> get mockEndorsements => [
    Endorsement(
      id: '1',
      endorserId: 'rajesh_uncle',
      endorserName: 'Rajesh Kumar',
      type: EndorserType.familyFriend,
      relationship: 'Family Friend',
      message:
          'Known this wonderful family for over 10 years. Excellent values and character.',
      yearsKnown: 10,
      verificationPoints: [
        'Character & Values',
        'Family Background',
        'Community Standing',
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      status: VerificationStatus.verified,
    ),
    Endorsement(
      id: '2',
      endorserId: 'dr_priya',
      endorserName: 'Dr. Priya Singh',
      type: EndorserType.professional,
      relationship: 'Senior Colleague',
      message: 'Excellent professional with strong work ethics and integrity.',
      yearsKnown: 5,
      verificationPoints: [
        'Professional Reputation',
        'Work Ethics',
        'Leadership',
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      status: VerificationStatus.verified,
    ),
    Endorsement(
      id: '3',
      endorserId: 'pandit_sharma',
      endorserName: 'Pandit Sharma',
      type: EndorserType.communityLeader,
      relationship: 'Temple Priest',
      message:
          'Respected family with strong traditional values and community involvement.',
      yearsKnown: 15,
      verificationPoints: [
        'Traditional Values',
        'Community Service',
        'Religious Values',
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      status: VerificationStatus.verified,
    ),
    Endorsement(
      id: '4',
      endorserId: 'prof_mehta',
      endorserName: 'Prof. Anil Mehta',
      type: EndorserType.educational,
      relationship: 'College Professor',
      message:
          'Outstanding student with excellent academic record and character.',
      yearsKnown: 8,
      verificationPoints: ['Academic Excellence', 'Character', 'Leadership'],
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      status: VerificationStatus.verified,
    ),
    Endorsement(
      id: '5',
      endorserId: 'mrs_lakshmi',
      endorserName: 'Mrs. Lakshmi Devi',
      type: EndorserType.familyFriend,
      relationship: 'Neighbor',
      message: 'Wonderful family, known since childhood. Highly recommend.',
      yearsKnown: 12,
      verificationPoints: ['Family Values', 'Character', 'Community Respect'],
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
      status: VerificationStatus.verified,
    ),
  ];

  // Financial Profile Mock Data
  static List<FinancialProfile> get mockFinancialProfiles => [
    FinancialProfile(
      userId: '1',
      familyIncomeRange: IncomeRange.range15to25L,
      lifestylePreference: LifestyleType.comfortable,
      savingApproach: SavingPhilosophy.balanced,
      careerStatus: CareerStability.stable,
      weddingPlanning: mockWeddingBudgetPlan,
      futureGoals: mockFutureGoals,
      supportsDualIncome: true,
      profileCompleteness: 92,
      lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
    ),
    FinancialProfile(
      userId: '2',
      familyIncomeRange: IncomeRange.range10to15L,
      lifestylePreference: LifestyleType.moderate,
      savingApproach: SavingPhilosophy.conservative,
      careerStatus: CareerStability.growing,
      weddingPlanning: WeddingBudgetPlan(
        totalBudgetRange: '₹12L - ₹16L',
        brideContributions: {
          'Ceremony & Reception': '₹3L - ₹4L',
          'Jewelry & Gold': '₹2L - ₹3L',
          'Clothing & Accessories': '₹1L - ₹1.5L',
        },
        groomContributions: {
          'Photography & Video': '₹1L - ₹1.5L',
          'Transportation': '₹50K - ₹75K',
          'Honeymoon': '₹1.5L - ₹2L',
          'House Setup': '₹3L - ₹4L',
        },
        ceremonyScale: 'Traditional Intimate',
        honeymoonBudget: '₹1.5L - ₹2L',
      ),
      futureGoals: FutureFinancialGoals(
        homePurchaseTimeline: '3-5 years',
        childrenEducationPlan: 'Quality education with savings',
        parentsCareApproach: 'Joint responsibility',
        retirementStrategy: 'PPF & Fixed deposits',
        investmentPreferences: ['PPF', 'Fixed Deposits', 'Gold'],
        hasEmergencyFund: true,
      ),
      supportsDualIncome: true,
      profileCompleteness: 87,
      lastUpdated: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  static WeddingBudgetPlan get mockWeddingBudgetPlan =>
      WeddingBudgetPlan.getDefault();

  static FutureFinancialGoals get mockFutureGoals =>
      FutureFinancialGoals.getDefault();

  static List<FinancialCompatibility> get mockFinancialCompatibilities => [
    FinancialCompatibility(
      userAId: '1',
      userBId: '2',
      overallCompatibility: 87,
      categoryScores: {
        'Income & Career': 92,
        'Lifestyle & Spending': 85,
        'Wedding Expectations': 68,
        'Future Planning': 94,
      },
      alignmentPoints: [
        'Both support dual income philosophy',
        'Similar approach to children\'s education',
        'Aligned retirement planning',
        'Both value family financial security',
      ],
      discussionNeeded: [
        'Wedding budget scale differences',
        'Ceremony expectations alignment',
        'Honeymoon budget planning',
      ],
      calculatedAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
  ];

  // Virtual Meeting Mock Data
  static List<VirtualMeeting> get mockVirtualMeetings => [
    VirtualMeeting(
      meetingId: 'meeting_1',
      participantIds: [
        'user1_father',
        'user1_mother',
        'user1',
        'user2_father',
        'user2_mother',
        'user2',
      ],
      participants: mockMeetingParticipants,
      type: MeetingType.firstIntroduction,
      scheduledTime: DateTime.now().add(const Duration(hours: 4)),
      durationMinutes: 30,
      status: MeetingStatus.scheduled,
      suggestions: mockAISuggestions,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      meetingLink: 'https://meet.anuyatra.com/meeting_1',
    ),
    VirtualMeeting(
      meetingId: 'meeting_2',
      participantIds: [
        'user1_father',
        'user1_mother',
        'user1',
        'user3_father',
        'user3_mother',
        'user3',
      ],
      participants: mockMeetingParticipants2,
      type: MeetingType.culturalExchange,
      scheduledTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
      durationMinutes: 60,
      status: MeetingStatus.scheduled,
      suggestions: mockCulturalSuggestions,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      meetingLink: 'https://meet.anuyatra.com/meeting_2',
    ),
    VirtualMeeting(
      meetingId: 'meeting_3',
      participantIds: [
        'user1_father',
        'user1_mother',
        'user1',
        'user4_father',
        'user4_mother',
        'user4',
      ],
      participants: mockMeetingParticipants3,
      type: MeetingType.firstIntroduction,
      scheduledTime: DateTime.now().subtract(const Duration(days: 3)),
      durationMinutes: 32,
      status: MeetingStatus.completed,
      suggestions: [],
      feedback: mockPostMeetingFeedback,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  static List<MeetingParticipant> get mockMeetingParticipants => [
    MeetingParticipant(
      userId: 'user1_father',
      name: 'Rajesh Sharma',
      role: 'Father',
      familyName: 'Sharma Family',
    ),
    MeetingParticipant(
      userId: 'user1_mother',
      name: 'Sunita Sharma',
      role: 'Mother',
      familyName: 'Sharma Family',
    ),
    MeetingParticipant(
      userId: 'user1',
      name: 'Rahul Sharma',
      role: 'Groom',
      familyName: 'Sharma Family',
      isMainProfile: true,
    ),
    MeetingParticipant(
      userId: 'user2_father',
      name: 'Anil Gupta',
      role: 'Father',
      familyName: 'Gupta Family',
    ),
    MeetingParticipant(
      userId: 'user2_mother',
      name: 'Meera Gupta',
      role: 'Mother',
      familyName: 'Gupta Family',
    ),
    MeetingParticipant(
      userId: 'user2',
      name: 'Priya Gupta',
      role: 'Bride',
      familyName: 'Gupta Family',
      isMainProfile: true,
    ),
  ];

  static List<MeetingParticipant> get mockMeetingParticipants2 => [
    MeetingParticipant(
      userId: 'user1_father',
      name: 'Rajesh Sharma',
      role: 'Father',
      familyName: 'Sharma Family',
    ),
    MeetingParticipant(
      userId: 'user1_mother',
      name: 'Sunita Sharma',
      role: 'Mother',
      familyName: 'Sharma Family',
    ),
    MeetingParticipant(
      userId: 'user1',
      name: 'Rahul Sharma',
      role: 'Groom',
      familyName: 'Sharma Family',
      isMainProfile: true,
    ),
    MeetingParticipant(
      userId: 'user3_father',
      name: 'Vikram Singh',
      role: 'Father',
      familyName: 'Singh Family',
    ),
    MeetingParticipant(
      userId: 'user3_mother',
      name: 'Kavita Singh',
      role: 'Mother',
      familyName: 'Singh Family',
    ),
    MeetingParticipant(
      userId: 'user3',
      name: 'Anita Singh',
      role: 'Bride',
      familyName: 'Singh Family',
      isMainProfile: true,
    ),
  ];

  static List<MeetingParticipant> get mockMeetingParticipants3 => [
    MeetingParticipant(
      userId: 'user1_father',
      name: 'Rajesh Sharma',
      role: 'Father',
      familyName: 'Sharma Family',
    ),
    MeetingParticipant(
      userId: 'user1_mother',
      name: 'Sunita Sharma',
      role: 'Mother',
      familyName: 'Sharma Family',
    ),
    MeetingParticipant(
      userId: 'user1',
      name: 'Rahul Sharma',
      role: 'Groom',
      familyName: 'Sharma Family',
      isMainProfile: true,
    ),
    MeetingParticipant(
      userId: 'user4_father',
      name: 'Suresh Patel',
      role: 'Father',
      familyName: 'Patel Family',
    ),
    MeetingParticipant(
      userId: 'user4_mother',
      name: 'Ritu Patel',
      role: 'Mother',
      familyName: 'Patel Family',
    ),
    MeetingParticipant(
      userId: 'user4',
      name: 'Neha Patel',
      role: 'Bride',
      familyName: 'Patel Family',
      isMainProfile: true,
    ),
  ];

  static List<AIsuggestion> get mockAISuggestions => [
    AIsuggestion(
      id: 'suggestion_1',
      type: AIsuggestionType.conversationStarter,
      title: 'Family Values Discussion',
      suggestion:
          'Tell us about your family\'s favorite festival traditions and how you celebrate them together.',
      followUpQuestions: [
        'What makes your family celebrations special?',
        'How do you involve extended family in celebrations?',
        'What traditions would you like to continue?',
      ],
      createdAt: DateTime.now(),
    ),
    AIsuggestion(
      id: 'suggestion_2',
      type: AIsuggestionType.iceBreaker,
      title: 'Hobbies and Interests',
      suggestion:
          'Share your favorite hobbies and how you like to spend your free time.',
      followUpQuestions: [
        'Do you have any creative hobbies?',
        'What activities do you enjoy as a family?',
        'Are there any new skills you\'d like to learn?',
      ],
      createdAt: DateTime.now(),
    ),
    AIsuggestion(
      id: 'suggestion_3',
      type: AIsuggestionType.conversationStarter,
      title: 'Work-Life Balance',
      suggestion:
          'How do you balance work commitments with family time and personal interests?',
      followUpQuestions: [
        'What does a typical weekend look like for your family?',
        'How do you handle work stress?',
        'What are your career aspirations?',
      ],
      createdAt: DateTime.now(),
    ),
  ];

  static List<AIsuggestion> get mockCulturalSuggestions => [
    AIsuggestion(
      id: 'cultural_1',
      type: AIsuggestionType.culturalBridge,
      title: 'Regional Traditions',
      suggestion:
          'Share the unique customs and traditions from your region that make your culture special.',
      followUpQuestions: [
        'What are the main festivals celebrated in your region?',
        'Are there any special wedding customs you follow?',
        'What regional foods are family favorites?',
      ],
      createdAt: DateTime.now(),
    ),
    AIsuggestion(
      id: 'cultural_2',
      type: AIsuggestionType.activity,
      title: 'Language Exchange',
      suggestion:
          'Teach each other a few words or phrases from your regional languages.',
      followUpQuestions: [
        'What languages are spoken at home?',
        'Are there any funny family phrases or sayings?',
        'How important is it to preserve regional languages?',
      ],
      createdAt: DateTime.now(),
    ),
  ];

  static PostMeetingFeedback get mockPostMeetingFeedback => PostMeetingFeedback(
    meetingId: 'meeting_3',
    userId: 'user1',
    overallRating: 5,
    engagementLevel: 5,
    culturalAlignment: 4,
    conversationFlow: 4,
    privateNotes:
        'Very positive meeting. Both families showed genuine interest and warmth. Strong cultural values alignment. Recommend proceeding to Cultural Exchange meeting.',
    discussionPoints: [
      'Educational backgrounds and career goals',
      'Family values and traditions',
      'Lifestyle preferences and hobbies',
      'Future location preferences',
    ],
    recommendFollowUp: true,
    submittedAt: DateTime.now().subtract(const Duration(days: 2)),
  );

  // Meeting History Data
  static Map<String, dynamic> get meetingHistory => {
    'totalMeetings': 12,
    'averageRating': 4.8,
    'successRate': 85, // percentage that led to in-person meetings
    'completionRate': 95,
  };

  // Market Insights Data
  static Map<String, dynamic> get marketInsights => {
    'averageWeddingBudget': '₹15-22L',
    'dualIncomePreference': 78,
    'homePurchasePriority': 65,
    'educationInvestmentFocus': 89,
  };
}
