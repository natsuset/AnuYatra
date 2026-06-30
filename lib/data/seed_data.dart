import 'package:flutter/foundation.dart';
import 'package:testing_flutter/core/data/app_data_module.dart';
import 'package:testing_flutter/models/app_user.dart';
import 'package:testing_flutter/models/user_role.dart';
import 'package:testing_flutter/models/agency.dart';
import 'package:testing_flutter/models/broker_profile.dart';
import 'package:testing_flutter/models/parent_profile.dart';
import 'package:testing_flutter/models/candidate_profile.dart';
import 'package:testing_flutter/models/link_request.dart';
import 'package:testing_flutter/models/shared_profile.dart';
import 'package:testing_flutter/models/chat_message.dart';
import 'package:testing_flutter/models/client_engagement.dart';
import 'package:testing_flutter/models/broker_follow_up.dart';

/// Toggle to enable/disable seeding on first launch.
/// Set to `false` to skip seeding entirely (e.g. for production).
class SeedConfig {
  static const bool enabled = true;
  static const bool printCredentials = true;
}

/// Seeds the local Hive database with realistic demo data on first launch.
/// Creates agencies, brokers, parents, candidates, connections, and conversations.
///
/// Drives off [AppDataModule] so seeding works against any backend the module
/// has been initialized with (Hive today, Firebase / API in the future).
/// First-launch detection uses `userRepository.isEmpty`.
Future<void> seedDemoData(AppDataModule data) async {
  if (!SeedConfig.enabled) return;
  if (!(await data.userRepository.isEmpty)) return;

  final userRepo = data.userRepository;
  final agencyRepo = data.agencyRepository;
  final brokerRepo = data.brokerRepository;
  final profileRepo = data.profileRepository;
  final linkRepo = data.linkRepository;
  final sharedRepo = data.sharedProfileRepository;
  final messagingRepo = data.messagingRepository;
  final engagementRepo = data.clientEngagementRepository;
  final followUpRepo = data.brokerFollowUpRepository;

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

  // Additional clients for broker-001 (Sunita Verma) — richer demo
  final parentUser3 = AppUser(
    uid: 'parent-003',
    phoneNumber: '+919800001003',
    displayName: 'Suresh Iyer',
    role: UserRole.parent,
    createdAt: now.subtract(const Duration(days: 20)),
  );

  final parentUser4 = AppUser(
    uid: 'parent-004',
    phoneNumber: '+919800001004',
    displayName: 'Lakshmi Menon',
    role: UserRole.parent,
    createdAt: now.subtract(const Duration(days: 9)),
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
    parentUser1, parentUser2, parentUser3, parentUser4,
    candidateUser1,
  ]) {
    await userRepo.saveUser(user);
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

  await agencyRepo.saveAgency(agency1);
  await agencyRepo.saveAgency(agency2);

  // ─── BROKER PROFILES ──────────────────────────────

  await brokerRepo.saveBrokerProfile(BrokerProfile(
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

  await brokerRepo.saveBrokerProfile(BrokerProfile(
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

  await brokerRepo.saveBrokerProfile(BrokerProfile(
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

  await brokerRepo.saveBrokerProfile(BrokerProfile(
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

  await profileRepo.saveParentProfile(ParentProfile(
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

  await profileRepo.saveParentProfile(ParentProfile(
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

  await profileRepo.saveParentProfile(ParentProfile(
    userId: 'parent-003',
    name: 'Suresh Iyer',
    lookingFor: LookingFor.bride,
    city: 'Bangalore',
    state: 'Karnataka',
    preferredCommunities: ['Hindu', 'Tamil', 'Telugu'],
    preferredMinAge: 24,
    preferredMaxAge: 29,
    childName: 'Arjun Iyer',
    childProfession: 'Product Manager',
    childEducation: 'MBA, IIM Bangalore',
    createdAt: now.subtract(const Duration(days: 20)),
  ));

  await profileRepo.saveParentProfile(ParentProfile(
    userId: 'parent-004',
    name: 'Lakshmi Menon',
    lookingFor: LookingFor.groom,
    city: 'Chennai',
    state: 'Tamil Nadu',
    preferredCommunities: ['Hindu', 'Kerala', 'Tamil'],
    preferredMinAge: 28,
    preferredMaxAge: 34,
    childName: 'Divya Menon',
    childProfession: 'Dentist (BDS)',
    childEducation: 'BDS, SRM Chennai',
    createdAt: now.subtract(const Duration(days: 9)),
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
      rashi: 'Taurus',
      nakshatra: 'Rohini',
      manglikStatus: 'No',
      gotra: 'Bharadwaj',
      photos: const [
        // Demo placeholders. Swap with real photo URLs (or local-sandbox paths
        // once self-upload lands in Slice 9) when you have curated assets.
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=600',
        'https://images.unsplash.com/photo-1611601679835-2ea0aebef4e2?w=600',
        'https://images.unsplash.com/photo-1601057434348-c5f29f0d4f70?w=600',
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=600',
      ],
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
      rashi: 'Cancer',
      nakshatra: 'Pushya',
      manglikStatus: 'No',
      gotra: 'Kashyap',
      photos: const [
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=600',
        'https://images.unsplash.com/photo-1623082574085-2acec7cffd00?w=600',
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600',
        'https://images.unsplash.com/photo-1589156280159-27698a70f29e?w=600',
      ],
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
      rashi: 'Virgo',
      nakshatra: 'Hasta',
      manglikStatus: 'No',
      gotra: 'Vatsa',
      photos: const [
        'https://images.unsplash.com/photo-1499996860823-5214fcc65f8f?w=600',
        'https://images.unsplash.com/photo-1552374196-c4e7ffc6e126?w=600',
        'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=600',
        'https://images.unsplash.com/photo-1604072366595-e75dc92d6bdc?w=600',
      ],
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
      rashi: 'Pisces',
      nakshatra: 'Revati',
      manglikStatus: 'No',
      gotra: 'Gautam',
      photos: const [
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=600',
        'https://images.unsplash.com/photo-1610483178922-67d2a45a4f6a?w=600',
        'https://images.unsplash.com/photo-1576766125535-b9b3a0e8e3e6?w=600',
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=600',
      ],
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
      rashi: 'Capricorn',
      nakshatra: 'Shravana',
      manglikStatus: 'Yes',
      gotra: 'Atri',
      photos: const [
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600',
        'https://images.unsplash.com/photo-1599842057874-37393e9342df?w=600',
        'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=600',
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=600',
      ],
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
      photos: const [
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600',
        'https://images.unsplash.com/photo-1567008386577-c70d1eb6e6cf?w=600',
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=600',
        'https://images.unsplash.com/photo-1611601679835-2ea0aebef4e2?w=600',
      ],
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
      rashi: 'Scorpio',
      nakshatra: 'Anuradha',
      manglikStatus: 'No',
      gotra: 'Kaushik',
      photos: const [
        'https://images.unsplash.com/photo-1463453091185-61582044d556?w=600',
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=600',
        'https://images.unsplash.com/photo-1531891437562-4301cf35b7e4?w=600',
        'https://images.unsplash.com/photo-1546961342-ea5f62d5a27b?w=600',
      ],
      brokerIds: ['broker-001'],
      createdAt: now.subtract(const Duration(days: 20)),
      updatedAt: now.subtract(const Duration(days: 1)),
    ),
  ];

  for (final candidate in candidates) {
    await profileRepo.saveCandidateProfile(candidate);
  }

  // ─── LINK REQUESTS (pre-established connections) ──────────────

  // Parent 1 connected to Broker 1
  await linkRepo.saveLinkRequest(LinkRequest(
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
  await linkRepo.saveLinkRequest(LinkRequest(
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
  await linkRepo.saveLinkRequest(LinkRequest(
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
  await linkRepo.saveLinkRequest(LinkRequest(
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
  await linkRepo.saveLinkRequest(LinkRequest(
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
  await linkRepo.saveLinkRequest(LinkRequest(
    id: 'lr-006',
    fromUserId: 'parent-001',
    toUserId: 'broker-003',
    fromUserName: 'Ramesh Kumar',
    toUserName: 'Kavita Reddy',
    type: LinkRequestType.parentToBroker,
    createdAt: now.subtract(const Duration(days: 5)),
    note: 'Looking for matches in South India as well.',
  ));

  // Parent 3 (Suresh Iyer) connected to Broker 1
  await linkRepo.saveLinkRequest(LinkRequest(
    id: 'lr-007',
    fromUserId: 'parent-003',
    toUserId: 'broker-001',
    fromUserName: 'Suresh Iyer',
    toUserName: 'Sunita Verma',
    type: LinkRequestType.parentToBroker,
    status: LinkRequestStatus.accepted,
    createdAt: now.subtract(const Duration(days: 18)),
    respondedAt: now.subtract(const Duration(days: 18)),
  ));

  // Parent 4 (Lakshmi Menon) connected to Broker 1
  await linkRepo.saveLinkRequest(LinkRequest(
    id: 'lr-008',
    fromUserId: 'parent-004',
    toUserId: 'broker-001',
    fromUserName: 'Lakshmi Menon',
    toUserName: 'Sunita Verma',
    type: LinkRequestType.parentToBroker,
    status: LinkRequestStatus.accepted,
    createdAt: now.subtract(const Duration(days: 7)),
    respondedAt: now.subtract(const Duration(days: 7)),
  ));

  // Pending: a new parent wants to connect with Broker 1 (needs attention)
  await linkRepo.saveLinkRequest(LinkRequest(
    id: 'lr-009',
    fromUserId: 'parent-002',
    toUserId: 'broker-001',
    fromUserName: 'Meera Nair',
    toUserName: 'Sunita Verma',
    type: LinkRequestType.parentToBroker,
    createdAt: now.subtract(const Duration(hours: 6)),
    note: 'Referred by Ramesh ji. Looking for a groom for my daughter.',
  ));

  // ─── SHARED PROFILES ──────────────────────────────

  // Broker 1 shared profiles with Parent 1
  await sharedRepo.saveSharedProfile(SharedProfile(
    id: 'sp-001',
    profileId: 'cp-003',
    sharedByUserId: 'broker-001',
    sharedWithUserId: 'parent-001',
    sharedAt: now.subtract(const Duration(days: 15)),
    parentResponse: SharedProfileResponse.interested,
  ));

  await sharedRepo.saveSharedProfile(SharedProfile(
    id: 'sp-002',
    profileId: 'cp-007',
    sharedByUserId: 'broker-001',
    sharedWithUserId: 'parent-001',
    sharedAt: now.subtract(const Duration(days: 10)),
    parentResponse: SharedProfileResponse.pending,
  ));

  // Broker 3 shared profile with Parent 2
  await sharedRepo.saveSharedProfile(SharedProfile(
    id: 'sp-003',
    profileId: 'cp-005',
    sharedByUserId: 'broker-003',
    sharedWithUserId: 'parent-002',
    sharedAt: now.subtract(const Duration(days: 8)),
    // The `maybe` response was retired in Slice 6 — seed-data picks
    // `pending` instead so the new UI doesn't have to render a deprecated state.
    parentResponse: SharedProfileResponse.pending,
  ));

  // Profiles shared directly with candidate-001 (Ananya Kumar) by her parent
  await sharedRepo.saveSharedProfile(SharedProfile(
    id: 'sp-004',
    profileId: 'cp-003',
    sharedByUserId: 'parent-001',
    sharedWithUserId: 'candidate-001',
    sharedAt: now.subtract(const Duration(days: 12)),
    forwardedToChild: true,
    childResponse: SharedProfileResponse.interested,
  ));

  await sharedRepo.saveSharedProfile(SharedProfile(
    id: 'sp-005',
    profileId: 'cp-005',
    sharedByUserId: 'parent-001',
    sharedWithUserId: 'candidate-001',
    sharedAt: now.subtract(const Duration(days: 7)),
    forwardedToChild: true,
    childResponse: SharedProfileResponse.pass,
  ));

  await sharedRepo.saveSharedProfile(SharedProfile(
    id: 'sp-006',
    profileId: 'cp-007',
    sharedByUserId: 'broker-001',
    sharedWithUserId: 'candidate-001',
    sharedAt: now.subtract(const Duration(days: 3)),
    parentResponse: SharedProfileResponse.pending,
  ));

  // Broker 1 → Parent 3 (Suresh Iyer, seeking a bride) — varied statuses
  await sharedRepo.saveSharedProfile(SharedProfile(
    id: 'sp-007',
    profileId: 'cp-002', // Priya Mehta (bride)
    sharedByUserId: 'broker-001',
    sharedWithUserId: 'parent-003',
    sharedAt: now.subtract(const Duration(days: 3)),
    parentResponse: SharedProfileResponse.interested,
  ));

  await sharedRepo.saveSharedProfile(SharedProfile(
    id: 'sp-008',
    profileId: 'cp-001', // Ananya Kumar (bride)
    sharedByUserId: 'broker-001',
    sharedWithUserId: 'parent-003',
    sharedAt: now.subtract(const Duration(days: 4)),
    parentResponse: SharedProfileResponse.pass,
  ));

  await sharedRepo.saveSharedProfile(SharedProfile(
    id: 'sp-009',
    profileId: 'cp-006', // Sneha Singh (bride)
    sharedByUserId: 'broker-001',
    sharedWithUserId: 'parent-003',
    sharedAt: now.subtract(const Duration(days: 1)),
    parentResponse: SharedProfileResponse.pending,
  ));

  // Broker 1 → Parent 4 (Lakshmi Menon, seeking a groom)
  await sharedRepo.saveSharedProfile(SharedProfile(
    id: 'sp-010',
    profileId: 'cp-003', // Rahul Patel (groom)
    sharedByUserId: 'broker-001',
    sharedWithUserId: 'parent-004',
    sharedAt: now.subtract(const Duration(hours: 5)),
    parentResponse: SharedProfileResponse.pending,
  ));

  await sharedRepo.saveSharedProfile(SharedProfile(
    id: 'sp-011',
    profileId: 'cp-005', // Vikram Naidu (groom)
    sharedByUserId: 'broker-001',
    sharedWithUserId: 'parent-004',
    sharedAt: now.subtract(const Duration(days: 1)),
    parentResponse: SharedProfileResponse.interested,
  ));

  // ─── CLIENT ENGAGEMENTS (payment / subscription per broker client) ──────

  // Parent 1 — fully paid & active, sharing live
  await engagementRepo.save(ClientEngagement.create(
    brokerUserId: 'broker-001',
    parentUserId: 'parent-001',
    stage: EngagementStage.active,
    planName: 'Premium · 6 Months',
    amountPaid: 25000,
    paidAt: now.subtract(const Duration(days: 50)),
    sharingStartsAt: now.subtract(const Duration(days: 48)),
    validUntil: now.add(const Duration(days: 132)),
    budgetExpectation: 'Wedding budget ₹30–50 L',
    expectedIncomeMin: '₹18 LPA+',
    requirementNotes:
        'Well-educated groom, Hindu/Gujarati, settled in Mumbai or abroad. '
        'Family values important.',
    createdAt: now.subtract(const Duration(days: 55)),
  ));

  // Parent 3 — connected but NOT paid yet (sharing gated)
  await engagementRepo.save(ClientEngagement.create(
    brokerUserId: 'broker-001',
    parentUserId: 'parent-003',
    stage: EngagementStage.connected,
    budgetExpectation: 'Wedding budget ₹20–30 L',
    expectedIncomeMin: '₹12 LPA+',
    requirementNotes:
        'Bride for son Arjun (PM, IIM-B). Prefers Tamil/Telugu Hindu family, '
        'Bangalore-based.',
    createdAt: now.subtract(const Duration(days: 18)),
  ));

  // Parent 4 — PAID, but sharing scheduled to start in 5 days
  await engagementRepo.save(ClientEngagement.create(
    brokerUserId: 'broker-001',
    parentUserId: 'parent-004',
    stage: EngagementStage.paid,
    planName: 'Standard · 3 Months',
    amountPaid: 12000,
    paidAt: now.subtract(const Duration(days: 2)),
    sharingStartsAt: now.add(const Duration(days: 5)),
    validUntil: now.add(const Duration(days: 88)),
    budgetExpectation: 'Wedding budget ₹15–25 L',
    expectedIncomeMin: '₹10 LPA+',
    requirementNotes:
        'Groom for daughter Divya (Dentist). Kerala/Tamil Hindu, Chennai '
        'preferred.',
    createdAt: now.subtract(const Duration(days: 7)),
  ));

  // Broker 3 — Parent 2 active
  await engagementRepo.save(ClientEngagement.create(
    brokerUserId: 'broker-003',
    parentUserId: 'parent-002',
    stage: EngagementStage.active,
    planName: 'Premium · 6 Months',
    amountPaid: 22000,
    paidAt: now.subtract(const Duration(days: 38)),
    sharingStartsAt: now.subtract(const Duration(days: 36)),
    validUntil: now.add(const Duration(days: 144)),
    budgetExpectation: 'Wedding budget ₹25–40 L',
    expectedIncomeMin: '₹15 LPA+',
    requirementNotes: 'Bride from Kerala/Tamil community, Bangalore or Chennai.',
    createdAt: now.subtract(const Duration(days: 40)),
  ));

  // ─── BROKER FOLLOW-UPS / REMINDERS ──────────────────────────────────────

  await followUpRepo.save(BrokerFollowUp(
    id: 'fu-001',
    brokerUserId: 'broker-001',
    clientUserId: 'parent-001',
    candidateProfileId: 'cp-007',
    title: 'Call Ramesh about Rohan Desai\'s profile',
    notes: 'He wanted to discuss family background before deciding.',
    dueAt: DateTime(now.year, now.month, now.day, 17, 0),
    priority: FollowUpPriority.high,
    createdAt: now.subtract(const Duration(days: 2)),
  ));

  await followUpRepo.save(BrokerFollowUp(
    id: 'fu-002',
    brokerUserId: 'broker-001',
    clientUserId: 'parent-003',
    title: 'Collect payment from Suresh to start sharing',
    notes: 'Connected 18 days ago, still on free tier.',
    dueAt: now.add(const Duration(days: 1)),
    priority: FollowUpPriority.high,
    createdAt: now.subtract(const Duration(days: 1)),
  ));

  await followUpRepo.save(BrokerFollowUp(
    id: 'fu-003',
    brokerUserId: 'broker-001',
    clientUserId: 'parent-004',
    title: 'Shortlist 3 more grooms for Divya',
    notes: 'Sharing goes live in 5 days — line up profiles.',
    dueAt: now.add(const Duration(days: 2)),
    priority: FollowUpPriority.normal,
    createdAt: now.subtract(const Duration(hours: 12)),
  ));

  await followUpRepo.save(BrokerFollowUp(
    id: 'fu-004',
    brokerUserId: 'broker-001',
    clientUserId: 'parent-003',
    candidateProfileId: 'cp-002',
    title: 'Relay Suresh\'s interest in Priya Mehta',
    notes: 'Inform the candidate side and arrange a call.',
    dueAt: now.subtract(const Duration(days: 1)),
    priority: FollowUpPriority.normal,
    createdAt: now.subtract(const Duration(days: 2)),
  ));

  await followUpRepo.save(BrokerFollowUp(
    id: 'fu-005',
    brokerUserId: 'broker-001',
    clientUserId: 'parent-001',
    title: 'Send anniversary wishes to Kumar family',
    dueAt: now.add(const Duration(days: 6)),
    priority: FollowUpPriority.low,
    isDone: true,
    completedAt: now.subtract(const Duration(days: 1)),
    createdAt: now.subtract(const Duration(days: 4)),
  ));

  // ─── CONVERSATIONS ──────────────────────────────

  final conv1 = Conversation(
    id: 'conv-001',
    participantIds: ['parent-001', 'broker-001'],
    lastMessagePreview: 'I\'ve shared two new profiles with you.',
    lastMessageAt: now.subtract(const Duration(hours: 3)),
    unreadCount: 1,
  );
  await messagingRepo.saveConversation(conv1);

  final conv2 = Conversation(
    id: 'conv-002',
    participantIds: ['parent-002', 'broker-003'],
    lastMessagePreview: 'Thank you, we\'ll review Vikram\'s profile.',
    lastMessageAt: now.subtract(const Duration(days: 1)),
    unreadCount: 0,
  );
  await messagingRepo.saveConversation(conv2);

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
    await messagingRepo.saveMessage(msg);
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
    await messagingRepo.saveMessage(msg);
  }

  // Conversation 3: Parent 3 (Suresh) <-> Broker 1 (Sunita) — with a share
  final conv3 = Conversation(
    id: 'conv-003',
    participantIds: ['parent-003', 'broker-001'],
    lastMessagePreview: 'Suresh ji is interested in Priya\'s profile.',
    lastMessageAt: now.subtract(const Duration(days: 3)),
    unreadCount: 2,
  );
  await messagingRepo.saveConversation(conv3);

  final messages3 = [
    ChatMessage(
      id: 'msg-007',
      conversationId: 'conv-003',
      senderId: 'broker-001',
      recipientId: 'parent-003',
      content:
          'Namaste Suresh ji! Happy to help find a bride for Arjun. I\'ll start sharing profiles once we activate your plan.',
      timestamp: now.subtract(const Duration(days: 17)),
      isRead: true,
    ),
    ChatMessage(
      id: 'msg-008',
      conversationId: 'conv-003',
      senderId: 'broker-001',
      recipientId: 'parent-003',
      content: 'Here is a profile I think is a strong match.',
      type: ChatMessageType.profileShare,
      profileId: 'cp-002',
      timestamp: now.subtract(const Duration(days: 3, hours: 2)),
      isRead: true,
    ),
    ChatMessage(
      id: 'msg-009',
      conversationId: 'conv-003',
      senderId: 'parent-003',
      recipientId: 'broker-001',
      content: 'We like Priya\'s profile very much. Please arrange a call.',
      timestamp: now.subtract(const Duration(days: 3)),
      isRead: false,
    ),
  ];

  for (final msg in messages3) {
    await messagingRepo.saveMessage(msg);
  }

  // ─── PRINT DEMO CREDENTIALS ──────────────────────────────

  if (SeedConfig.printCredentials) {
    debugPrint('');
    debugPrint('╔══════════════════════════════════════════════════════╗');
    debugPrint('║           DEMO LOGIN CREDENTIALS (OTP: 123456)      ║');
    debugPrint('╠══════════════════════════════════════════════════════╣');
    debugPrint('║ Agency Admin                                        ║');
    debugPrint('║   Priya Sharma    +91 9876543210  (Shubh Vivah)     ║');
    debugPrint('║   Rajesh Gupta    +91 9876543211  (Pavitra Bandhan) ║');
    debugPrint('║ Brokers                                             ║');
    debugPrint('║   Sunita Verma    +91 9812345001  (agency)          ║');
    debugPrint('║   Amit Patel      +91 9812345002  (agency)          ║');
    debugPrint('║   Kavita Reddy    +91 9812345003  (independent)     ║');
    debugPrint('║   Deepak Mishra   +91 9812345004  (agency)          ║');
    debugPrint('║ Parents                                             ║');
    debugPrint('║   Ramesh Kumar    +91 9800001001  (Broker: Sunita)  ║');
    debugPrint('║   Meera Nair      +91 9800001002  (Broker: Kavita)  ║');
    debugPrint('║   Suresh Iyer     +91 9800001003  (Broker: Sunita)  ║');
    debugPrint('║   Lakshmi Menon   +91 9800001004  (Broker: Sunita)  ║');
    debugPrint('║ Candidates                                          ║');
    debugPrint('║   Ananya Kumar    +91 9700001001                    ║');
    debugPrint('╚══════════════════════════════════════════════════════╝');
    debugPrint('');
  }
}
