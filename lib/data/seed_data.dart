import 'package:testing_flutter/core/services/local_storage_service.dart';
import 'package:testing_flutter/models/app_user.dart';
import 'package:testing_flutter/models/user_role.dart';
import 'package:testing_flutter/models/agency.dart';
import 'package:testing_flutter/models/broker_profile.dart';
import 'package:testing_flutter/models/parent_profile.dart';
import 'package:testing_flutter/models/candidate_profile.dart';
import 'package:testing_flutter/models/link_request.dart';
import 'package:testing_flutter/models/shared_profile.dart';
import 'package:testing_flutter/models/chat_message.dart';

/// Seeds the local Hive database with realistic demo data on first launch.
/// Creates agencies, brokers, parents, candidates, connections, and conversations.
Future<void> seedDemoData(LocalStorageService storage) async {
  if (!storage.isFirstLaunch) return;

  final now = DateTime.now();

  // ─── AGENCY ADMIN USERS ──────────────────────────────

  final adminUser1 = AppUser(
    uid: 'admin-001',
    phoneNumber: '+919876543210',
    displayName: 'Priya Sharma',
    role: UserRole.agencyAdmin,
    agencyId: 'agency-001',
    createdAt: now.subtract(const Duration(days: 365)),
  );

  final adminUser2 = AppUser(
    uid: 'admin-002',
    phoneNumber: '+919876543211',
    displayName: 'Rajesh Gupta',
    role: UserRole.agencyAdmin,
    agencyId: 'agency-002',
    createdAt: now.subtract(const Duration(days: 200)),
  );

  // ─── BROKER USERS ──────────────────────────────

  final brokerUser1 = AppUser(
    uid: 'broker-001',
    phoneNumber: '+919812345001',
    displayName: 'Sunita Verma',
    role: UserRole.broker,
    agencyId: 'agency-001',
    createdAt: now.subtract(const Duration(days: 300)),
  );

  final brokerUser2 = AppUser(
    uid: 'broker-002',
    phoneNumber: '+919812345002',
    displayName: 'Amit Patel',
    role: UserRole.broker,
    agencyId: 'agency-001',
    createdAt: now.subtract(const Duration(days: 250)),
  );

  final brokerUser3 = AppUser(
    uid: 'broker-003',
    phoneNumber: '+919812345003',
    displayName: 'Kavita Reddy',
    role: UserRole.broker,
    // Independent broker — no agency
    createdAt: now.subtract(const Duration(days: 180)),
  );

  final brokerUser4 = AppUser(
    uid: 'broker-004',
    phoneNumber: '+919812345004',
    displayName: 'Deepak Mishra',
    role: UserRole.broker,
    agencyId: 'agency-002',
    createdAt: now.subtract(const Duration(days: 150)),
  );

  // ─── PARENT USERS ──────────────────────────────

  final parentUser1 = AppUser(
    uid: 'parent-001',
    phoneNumber: '+919800001001',
    displayName: 'Ramesh Kumar',
    role: UserRole.parent,
    createdAt: now.subtract(const Duration(days: 60)),
  );

  final parentUser2 = AppUser(
    uid: 'parent-002',
    phoneNumber: '+919800001002',
    displayName: 'Meera Nair',
    role: UserRole.parent,
    createdAt: now.subtract(const Duration(days: 45)),
  );

  // ─── CANDIDATE USERS ──────────────────────────────

  final candidateUser1 = AppUser(
    uid: 'candidate-001',
    phoneNumber: '+919700001001',
    displayName: 'Ananya Kumar',
    role: UserRole.candidate,
    createdAt: now.subtract(const Duration(days: 30)),
  );

  // Save all users
  for (final user in [
    adminUser1, adminUser2,
    brokerUser1, brokerUser2, brokerUser3, brokerUser4,
    parentUser1, parentUser2,
    candidateUser1,
  ]) {
    await storage.saveUser(user);
  }

  // ─── AGENCIES ──────────────────────────────

  final agency1 = Agency(
    id: 'agency-001',
    adminUserId: 'admin-001',
    name: 'Shubh Vivah Matrimony',
    city: 'Mumbai',
    state: 'Maharashtra',
    description: 'Premium matrimonial services with personalized matchmaking for families across Maharashtra and Gujarat.',
    specializations: ['Hindu', 'Jain', 'Gujarati', 'Marathi'],
    areasServed: ['Mumbai', 'Pune', 'Ahmedabad', 'Surat'],
    rating: 4.7,
    createdAt: now.subtract(const Duration(days: 365)),
  );

  final agency2 = Agency(
    id: 'agency-002',
    adminUserId: 'admin-002',
    name: 'Pavitra Bandhan',
    city: 'Delhi',
    state: 'Delhi',
    description: 'Trusted matchmaking agency specializing in North Indian communities with a network across NCR.',
    specializations: ['Hindu', 'Sikh', 'Rajput', 'Agarwal'],
    areasServed: ['Delhi', 'Noida', 'Gurgaon', 'Jaipur'],
    rating: 4.5,
    createdAt: now.subtract(const Duration(days: 200)),
  );

  await storage.saveAgency(agency1);
  await storage.saveAgency(agency2);

  // ─── BROKER PROFILES ──────────────────────────────

  await storage.saveBrokerProfile(BrokerProfile(
    userId: 'broker-001',
    agencyId: 'agency-001',
    name: 'Sunita Verma',
    phoneNumber: '+919812345001',
    specializations: ['Hindu', 'Gujarati', 'Jain'],
    areasServed: ['Mumbai', 'Thane', 'Navi Mumbai'],
    experienceYears: 12,
    clientCount: 45,
    profilesManaged: 78,
    rating: 4.8,
    bio: 'Dedicated matchmaker with over a decade of experience helping families find the perfect match.',
    isOnline: true,
    lastSeen: now,
    createdAt: now.subtract(const Duration(days: 300)),
  ));

  await storage.saveBrokerProfile(BrokerProfile(
    userId: 'broker-002',
    agencyId: 'agency-001',
    name: 'Amit Patel',
    phoneNumber: '+919812345002',
    specializations: ['Gujarati', 'Patel', 'Jain'],
    areasServed: ['Ahmedabad', 'Surat', 'Vadodara'],
    experienceYears: 8,
    clientCount: 32,
    profilesManaged: 56,
    rating: 4.6,
    bio: 'Specializing in Gujarati and Patel community matches with connections across Gujarat.',
    isOnline: false,
    lastSeen: now.subtract(const Duration(hours: 2)),
    createdAt: now.subtract(const Duration(days: 250)),
  ));

  await storage.saveBrokerProfile(BrokerProfile(
    userId: 'broker-003',
    name: 'Kavita Reddy',
    phoneNumber: '+919812345003',
    specializations: ['Telugu', 'Tamil', 'Reddy', 'Naidu'],
    areasServed: ['Hyderabad', 'Chennai', 'Bangalore'],
    experienceYears: 15,
    clientCount: 60,
    profilesManaged: 120,
    rating: 4.9,
    bio: 'South India\'s most trusted independent matchmaker, serving families for 15+ years.',
    isOnline: true,
    lastSeen: now,
    createdAt: now.subtract(const Duration(days: 180)),
  ));

  await storage.saveBrokerProfile(BrokerProfile(
    userId: 'broker-004',
    agencyId: 'agency-002',
    name: 'Deepak Mishra',
    phoneNumber: '+919812345004',
    specializations: ['Hindu', 'Rajput', 'Brahmin'],
    areasServed: ['Delhi', 'Noida', 'Gurgaon'],
    experienceYears: 6,
    clientCount: 25,
    profilesManaged: 40,
    rating: 4.4,
    bio: 'Personalized matchmaking for North Indian families in the NCR region.',
    isOnline: false,
    lastSeen: now.subtract(const Duration(hours: 5)),
    createdAt: now.subtract(const Duration(days: 150)),
  ));

  // ─── PARENT PROFILES ──────────────────────────────

  await storage.saveParentProfile(ParentProfile(
    userId: 'parent-001',
    name: 'Ramesh Kumar',
    lookingFor: LookingFor.groom,
    city: 'Mumbai',
    state: 'Maharashtra',
    preferredCommunities: ['Hindu', 'Gujarati'],
    preferredMinAge: 26,
    preferredMaxAge: 32,
    createdAt: now.subtract(const Duration(days: 60)),
  ));

  await storage.saveParentProfile(ParentProfile(
    userId: 'parent-002',
    name: 'Meera Nair',
    lookingFor: LookingFor.bride,
    city: 'Bangalore',
    state: 'Karnataka',
    preferredCommunities: ['Kerala', 'Tamil'],
    preferredMinAge: 23,
    preferredMaxAge: 28,
    createdAt: now.subtract(const Duration(days: 45)),
  ));

  // ─── CANDIDATE PROFILES ──────────────────────────────

  final candidates = [
    CandidateProfile(
      id: 'cp-001',
      createdByUserId: 'broker-001',
      name: 'Ananya Kumar',
      age: 26,
      gender: Gender.bride,
      profession: 'Software Engineer',
      education: 'B.Tech, IIT Bombay',
      city: 'Mumbai',
      community: 'Hindu Gujarati',
      height: '5\'5"',
      religion: 'Hindu',
      caste: 'Gujarati',
      motherTongue: 'Gujarati',
      maritalStatus: 'Never Married',
      aboutMe: 'A passionate software engineer who loves traveling, cooking, and exploring new cultures.',
      familyBackground: 'Business family based in Mumbai.',
      interests: ['Travel', 'Cooking', 'Reading', 'Yoga'],
      fatherOccupation: 'Business Owner',
      motherOccupation: 'Homemaker',
      siblings: '1 elder brother (married)',
      photos: ['https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400'],
      brokerIds: ['broker-001'],
      candidateUserId: 'candidate-001',
      createdAt: now.subtract(const Duration(days: 50)),
      updatedAt: now.subtract(const Duration(days: 10)),
    ),
    CandidateProfile(
      id: 'cp-002',
      createdByUserId: 'broker-001',
      name: 'Priya Mehta',
      age: 24,
      gender: Gender.bride,
      profession: 'Chartered Accountant',
      education: 'CA, B.Com (H) Delhi University',
      city: 'Mumbai',
      community: 'Hindu Jain',
      height: '5\'3"',
      religion: 'Jain',
      caste: 'Jain',
      motherTongue: 'Hindi',
      maritalStatus: 'Never Married',
      aboutMe: 'Detail-oriented CA with a love for arts and classical dance.',
      familyBackground: 'Family of chartered accountants.',
      interests: ['Classical Dance', 'Art', 'Finance', 'Music'],
      fatherOccupation: 'CA',
      motherOccupation: 'Teacher',
      siblings: '1 younger sister',
      photos: ['https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400'],
      brokerIds: ['broker-001'],
      createdAt: now.subtract(const Duration(days: 45)),
      updatedAt: now.subtract(const Duration(days: 5)),
    ),
    CandidateProfile(
      id: 'cp-003',
      createdByUserId: 'broker-002',
      name: 'Rahul Patel',
      age: 28,
      gender: Gender.groom,
      profession: 'Doctor (MBBS, MD)',
      education: 'MD Cardiology, AIIMS',
      city: 'Ahmedabad',
      community: 'Hindu Patel',
      height: '5\'10"',
      religion: 'Hindu',
      caste: 'Patel',
      motherTongue: 'Gujarati',
      maritalStatus: 'Never Married',
      aboutMe: 'Cardiologist by profession, adventurer by heart. Looking for someone who values family.',
      familyBackground: 'Established business family in Ahmedabad.',
      interests: ['Trekking', 'Photography', 'Cricket', 'Cooking'],
      fatherOccupation: 'Industrialist',
      motherOccupation: 'Homemaker',
      siblings: '2 sisters (both married)',
      photos: ['https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400'],
      brokerIds: ['broker-002'],
      createdAt: now.subtract(const Duration(days: 40)),
      updatedAt: now.subtract(const Duration(days: 8)),
    ),
    CandidateProfile(
      id: 'cp-004',
      createdByUserId: 'broker-003',
      name: 'Deepa Reddy',
      age: 25,
      gender: Gender.bride,
      profession: 'Marketing Manager',
      education: 'MBA, ISB Hyderabad',
      city: 'Hyderabad',
      community: 'Hindu Telugu',
      height: '5\'4"',
      religion: 'Hindu',
      caste: 'Reddy',
      motherTongue: 'Telugu',
      maritalStatus: 'Never Married',
      aboutMe: 'Creative marketing professional who enjoys working with startups and building brands.',
      familyBackground: 'Agricultural family with roots in Andhra Pradesh.',
      interests: ['Marketing', 'Startups', 'Fitness', 'Movies'],
      fatherOccupation: 'Agriculturist',
      motherOccupation: 'Government Employee',
      siblings: '1 younger brother',
      photos: ['https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400'],
      brokerIds: ['broker-003'],
      createdAt: now.subtract(const Duration(days: 35)),
      updatedAt: now.subtract(const Duration(days: 3)),
    ),
    CandidateProfile(
      id: 'cp-005',
      createdByUserId: 'broker-003',
      name: 'Vikram Naidu',
      age: 30,
      gender: Gender.groom,
      profession: 'Tech Lead',
      education: 'M.Tech, NIT Warangal',
      city: 'Bangalore',
      community: 'Hindu Naidu',
      height: '5\'9"',
      religion: 'Hindu',
      caste: 'Naidu',
      motherTongue: 'Telugu',
      maritalStatus: 'Never Married',
      aboutMe: 'Tech lead at a leading startup, passionate about building products that make a difference.',
      familyBackground: 'Family of educators and professionals.',
      interests: ['Technology', 'Chess', 'Badminton', 'Travel'],
      fatherOccupation: 'Professor',
      motherOccupation: 'Principal',
      siblings: '1 elder sister (married)',
      photos: ['https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400'],
      brokerIds: ['broker-003'],
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now.subtract(const Duration(days: 2)),
    ),
    CandidateProfile(
      id: 'cp-006',
      createdByUserId: 'broker-004',
      name: 'Sneha Singh',
      age: 27,
      gender: Gender.bride,
      profession: 'Architect',
      education: 'B.Arch, SPA Delhi',
      city: 'Delhi',
      community: 'Hindu Rajput',
      height: '5\'6"',
      religion: 'Hindu',
      caste: 'Rajput',
      motherTongue: 'Hindi',
      maritalStatus: 'Never Married',
      aboutMe: 'Architect with a keen eye for design, passionate about sustainable living.',
      familyBackground: 'Defence family background.',
      interests: ['Architecture', 'Sustainability', 'Painting', 'Cycling'],
      fatherOccupation: 'Army Officer (Retd.)',
      motherOccupation: 'Homemaker',
      siblings: '1 elder brother (Army)',
      photos: ['https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400'],
      brokerIds: ['broker-004'],
      createdAt: now.subtract(const Duration(days: 25)),
      updatedAt: now.subtract(const Duration(days: 1)),
    ),
    CandidateProfile(
      id: 'cp-007',
      createdByUserId: 'broker-001',
      name: 'Rohan Desai',
      age: 29,
      gender: Gender.groom,
      profession: 'Investment Banker',
      education: 'MBA, IIM Ahmedabad',
      city: 'Mumbai',
      community: 'Hindu Gujarati',
      height: '5\'11"',
      religion: 'Hindu',
      caste: 'Gujarati',
      motherTongue: 'Gujarati',
      maritalStatus: 'Never Married',
      aboutMe: 'Finance professional who believes in work-life balance and family values.',
      familyBackground: 'Diamond merchant family in Mumbai.',
      interests: ['Finance', 'Golf', 'Wine Tasting', 'Travel'],
      fatherOccupation: 'Diamond Merchant',
      motherOccupation: 'Homemaker',
      siblings: '1 younger brother',
      photos: ['https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400'],
      brokerIds: ['broker-001'],
      createdAt: now.subtract(const Duration(days: 20)),
      updatedAt: now.subtract(const Duration(days: 1)),
    ),
  ];

  for (final candidate in candidates) {
    await storage.saveCandidateProfile(candidate);
  }

  // ─── LINK REQUESTS (pre-established connections) ──────────────

  // Parent 1 connected to Broker 1
  await storage.saveLinkRequest(LinkRequest(
    id: 'lr-001',
    fromUserId: 'parent-001',
    toUserId: 'broker-001',
    fromUserName: 'Ramesh Kumar',
    toUserName: 'Sunita Verma',
    type: LinkRequestType.parentToBroker,
    status: LinkRequestStatus.accepted,
    createdAt: now.subtract(const Duration(days: 55)),
    respondedAt: now.subtract(const Duration(days: 54)),
  ));

  // Parent 2 connected to Broker 3
  await storage.saveLinkRequest(LinkRequest(
    id: 'lr-002',
    fromUserId: 'parent-002',
    toUserId: 'broker-003',
    fromUserName: 'Meera Nair',
    toUserName: 'Kavita Reddy',
    type: LinkRequestType.parentToBroker,
    status: LinkRequestStatus.accepted,
    createdAt: now.subtract(const Duration(days: 40)),
    respondedAt: now.subtract(const Duration(days: 39)),
  ));

  // Agency 1 invited Broker 1 (accepted)
  await storage.saveLinkRequest(LinkRequest(
    id: 'lr-003',
    fromUserId: 'admin-001',
    toUserId: 'broker-001',
    fromUserName: 'Priya Sharma',
    toUserName: 'Sunita Verma',
    type: LinkRequestType.agencyToBroker,
    status: LinkRequestStatus.accepted,
    createdAt: now.subtract(const Duration(days: 300)),
    respondedAt: now.subtract(const Duration(days: 299)),
  ));

  // Agency 1 invited Broker 2 (accepted)
  await storage.saveLinkRequest(LinkRequest(
    id: 'lr-004',
    fromUserId: 'admin-001',
    toUserId: 'broker-002',
    fromUserName: 'Priya Sharma',
    toUserName: 'Amit Patel',
    type: LinkRequestType.agencyToBroker,
    status: LinkRequestStatus.accepted,
    createdAt: now.subtract(const Duration(days: 250)),
    respondedAt: now.subtract(const Duration(days: 249)),
  ));

  // Child linked to Parent 1
  await storage.saveLinkRequest(LinkRequest(
    id: 'lr-005',
    fromUserId: 'candidate-001',
    toUserId: 'parent-001',
    fromUserName: 'Ananya Kumar',
    toUserName: 'Ramesh Kumar',
    type: LinkRequestType.childToParent,
    status: LinkRequestStatus.accepted,
    createdAt: now.subtract(const Duration(days: 28)),
    respondedAt: now.subtract(const Duration(days: 27)),
  ));

  // Pending: Parent 1 wants to connect with Broker 3
  await storage.saveLinkRequest(LinkRequest(
    id: 'lr-006',
    fromUserId: 'parent-001',
    toUserId: 'broker-003',
    fromUserName: 'Ramesh Kumar',
    toUserName: 'Kavita Reddy',
    type: LinkRequestType.parentToBroker,
    createdAt: now.subtract(const Duration(days: 5)),
    note: 'Looking for matches in South India as well.',
  ));

  // ─── SHARED PROFILES ──────────────────────────────

  // Broker 1 shared profiles with Parent 1
  await storage.saveSharedProfile(SharedProfile(
    id: 'sp-001',
    profileId: 'cp-003',
    sharedByUserId: 'broker-001',
    sharedWithUserId: 'parent-001',
    sharedAt: now.subtract(const Duration(days: 15)),
    parentResponse: SharedProfileResponse.interested,
  ));

  await storage.saveSharedProfile(SharedProfile(
    id: 'sp-002',
    profileId: 'cp-007',
    sharedByUserId: 'broker-001',
    sharedWithUserId: 'parent-001',
    sharedAt: now.subtract(const Duration(days: 10)),
    parentResponse: SharedProfileResponse.pending,
  ));

  // Broker 3 shared profile with Parent 2
  await storage.saveSharedProfile(SharedProfile(
    id: 'sp-003',
    profileId: 'cp-005',
    sharedByUserId: 'broker-003',
    sharedWithUserId: 'parent-002',
    sharedAt: now.subtract(const Duration(days: 8)),
    parentResponse: SharedProfileResponse.maybe,
  ));

  // ─── CONVERSATIONS ──────────────────────────────

  final conv1 = Conversation(
    id: 'conv-001',
    participantIds: ['parent-001', 'broker-001'],
    lastMessagePreview: 'I\'ve shared two new profiles with you.',
    lastMessageAt: now.subtract(const Duration(hours: 3)),
    unreadCount: 1,
  );
  await storage.saveConversation(conv1);

  final conv2 = Conversation(
    id: 'conv-002',
    participantIds: ['parent-002', 'broker-003'],
    lastMessagePreview: 'Thank you, we\'ll review Vikram\'s profile.',
    lastMessageAt: now.subtract(const Duration(days: 1)),
    unreadCount: 0,
  );
  await storage.saveConversation(conv2);

  // ─── MESSAGES ──────────────────────────────

  // Conversation 1: Parent 1 <-> Broker 1
  final messages1 = [
    ChatMessage(
      id: 'msg-001',
      conversationId: 'conv-001',
      senderId: 'broker-001',
      recipientId: 'parent-001',
      content: 'Namaste Ramesh ji! Welcome to Shubh Vivah Matrimony. I\'m Sunita, and I\'ll be helping you find the right match for Ananya.',
      timestamp: now.subtract(const Duration(days: 50)),
      isRead: true,
    ),
    ChatMessage(
      id: 'msg-002',
      conversationId: 'conv-001',
      senderId: 'parent-001',
      recipientId: 'broker-001',
      content: 'Namaste Sunita ji. Thank you for accepting our request. We are looking for a well-educated groom from a good family.',
      timestamp: now.subtract(const Duration(days: 50, hours: -2)),
      isRead: true,
    ),
    ChatMessage(
      id: 'msg-003',
      conversationId: 'conv-001',
      senderId: 'broker-001',
      recipientId: 'parent-001',
      content: 'I understand completely. I have some profiles that might be a good match. Let me share them with you.',
      timestamp: now.subtract(const Duration(days: 15)),
      isRead: true,
    ),
    ChatMessage(
      id: 'msg-004',
      conversationId: 'conv-001',
      senderId: 'broker-001',
      recipientId: 'parent-001',
      content: 'I\'ve shared two new profiles with you.',
      type: ChatMessageType.text,
      timestamp: now.subtract(const Duration(hours: 3)),
      isRead: false,
    ),
  ];

  for (final msg in messages1) {
    await storage.saveMessage(msg);
  }

  // Conversation 2: Parent 2 <-> Broker 3
  final messages2 = [
    ChatMessage(
      id: 'msg-005',
      conversationId: 'conv-002',
      senderId: 'broker-003',
      recipientId: 'parent-002',
      content: 'Hello Meera ji! I\'ve been reviewing your preferences and I think I have some excellent matches.',
      timestamp: now.subtract(const Duration(days: 35)),
      isRead: true,
    ),
    ChatMessage(
      id: 'msg-006',
      conversationId: 'conv-002',
      senderId: 'parent-002',
      recipientId: 'broker-003',
      content: 'Thank you, we\'ll review Vikram\'s profile.',
      timestamp: now.subtract(const Duration(days: 1)),
      isRead: true,
    ),
  ];

  for (final msg in messages2) {
    await storage.saveMessage(msg);
  }
}
