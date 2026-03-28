import 'package:testing_flutter/models/profile.dart';
import 'package:testing_flutter/models/broker.dart';

/// **Deprecated**: This class uses legacy Profile/Broker models.
/// The GoRouter-based flow now uses CandidateProfile/BrokerProfile via
/// repository providers. This MockData is only used by legacy screens
/// which are not part of the main GoRouter navigation.
@Deprecated('Use seed_data.dart and repository providers instead')
class MockData {
  static final Broker broker = Broker(
    id: '1',
    name: 'Rajesh Kumar',
    phoneNumber: '+91 98765 43210',
    profilePhoto:
        'https://ui-avatars.com/api/?name=Rajesh+Kumar&size=200&background=FF8C42&color=fff',
    agencyName: 'Anuyātrā Matrimonials',
    agencyLogo:
        'https://ui-avatars.com/api/?name=A&size=200&background=8B2635&color=fff&bold=true',
    isOnline: true,
    lastSeen: DateTime.now().subtract(const Duration(minutes: 5)),
  );

  static final List<Broker> brokers = [
    broker,
    Broker(
      id: '2',
      name: 'Neha Verma',
      phoneNumber: '+91 98234 56780',
      profilePhoto:
          'https://ui-avatars.com/api/?name=Neha+Verma&size=200&background=EA5455&color=fff',
      agencyName: 'Vivaha Connect',
      agencyLogo:
          'https://ui-avatars.com/api/?name=V&size=200&background=1D3557&color=fff&bold=true',
      isOnline: false,
      lastSeen: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
    ),
    Broker(
      id: '3',
      name: 'Anil Mehta',
      phoneNumber: '+91 98111 22334',
      profilePhoto:
          'https://ui-avatars.com/api/?name=Anil+Mehta&size=200&background=2DCE89&color=fff',
      agencyName: 'Anuyātrā Matrimonials',
      agencyLogo:
          'https://ui-avatars.com/api/?name=A&size=200&background=8B2635&color=fff&bold=true',
      isOnline: true,
      lastSeen: DateTime.now().subtract(const Duration(minutes: 1)),
    ),
    Broker(
      id: '4',
      name: 'Priya Singh',
      phoneNumber: '+91 99000 11223',
      profilePhoto:
          'https://ui-avatars.com/api/?name=Priya+Singh&size=200&background=4ECDC4&color=000',
      agencyName: 'Harmony Matches',
      agencyLogo:
          'https://ui-avatars.com/api/?name=H&size=200&background=FFBE0B&color=000&bold=true',
      isOnline: false,
      lastSeen: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
    ),
  ];

  static final List<Profile> profiles = [
    Profile(
      id: '1',
      name: 'Rohit Sharma',
      age: 28,
      profession: 'Software Engineer',
      education: 'M.Tech from IIT Delhi',
      city: 'Bangalore',
      community: 'Hindu',
      height: '5\'8"',
      religion: 'Hindu',
      caste: 'Brahmin',
      motherTongue: 'Hindi',
      maritalStatus: 'Never Married',
      aboutMe:
          'Passionate about building meaningful products. I enjoy hiking and photography.',
      familyBackground:
          'Father is a Business Owner and mother is a Teacher. Close-knit family values.',
      interests: ['Hiking', 'Photography', 'Classical Music'],
      fatherOccupation: 'Business Owner',
      motherOccupation: 'Teacher',
      siblings: '1 younger sister (married)',
      photos: [
        'https://ui-avatars.com/api/?name=Rohit+1&size=400&background=667eea&color=fff',
        'https://ui-avatars.com/api/?name=Rohit+2&size=400&background=764ba2&color=fff',
        'https://ui-avatars.com/api/?name=Rohit+3&size=400&background=f093fb&color=fff',
      ],
      isNew: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      status: ProfileStatus.pending,
    ),
    Profile(
      id: '2',
      name: 'Arjun Patel',
      age: 26,
      profession: 'Doctor',
      education: 'MBBS from AIIMS',
      city: 'Mumbai',
      community: 'Hindu',
      height: '5\'10"',
      religion: 'Hindu',
      caste: 'Patel',
      motherTongue: 'Gujarati',
      maritalStatus: 'Never Married',
      aboutMe:
          'Caring and calm. Love volunteering and learning new medical research.',
      familyBackground:
          'Parents are in healthcare. We value education and compassion.',
      interests: ['Reading', 'Tennis', 'Volunteering'],
      fatherOccupation: 'Doctor',
      motherOccupation: 'Homemaker',
      siblings: '1 elder brother',
      photos: [
        'https://ui-avatars.com/api/?name=Arjun+1&size=400&background=fa709a&color=fff',
        'https://ui-avatars.com/api/?name=Arjun+2&size=400&background=fee140&color=000',
        'https://ui-avatars.com/api/?name=Arjun+3&size=400&background=30cfd0&color=fff',
        'https://ui-avatars.com/api/?name=Arjun+4&size=400&background=a8edea&color=000',
      ],
      isNew: false,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      status: ProfileStatus.saved,
    ),
    Profile(
      id: '3',
      name: 'Vikram Singh',
      age: 30,
      profession: 'Chartered Accountant',
      education: 'CA from ICAI, B.Com',
      city: 'Delhi',
      community: 'Hindu',
      height: '5\'9"',
      religion: 'Hindu',
      caste: 'Rajput',
      motherTongue: 'Hindi',
      maritalStatus: 'Never Married',
      aboutMe:
          'Detail-oriented and family-focused. I enjoy cooking on weekends.',
      familyBackground:
          'Father is a Government Officer, mother is a Bank Manager.',
      interests: ['Cooking', 'Cricket', 'Travel'],
      fatherOccupation: 'Government Officer',
      motherOccupation: 'Bank Manager',
      siblings: 'Only child',
      photos: [
        'https://ui-avatars.com/api/?name=Vikram+1&size=400&background=ff6e7f&color=fff',
        'https://ui-avatars.com/api/?name=Vikram+2&size=400&background=bfe9ff&color=000',
      ],
      isNew: false,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      status: ProfileStatus.interested,
    ),
    Profile(
      id: '4',
      name: 'Amit Gupta',
      age: 29,
      profession: 'Marketing Manager',
      education: 'MBA from IIM Bangalore',
      city: 'Pune',
      community: 'Hindu',
      height: '5\'7"',
      religion: 'Hindu',
      caste: 'Baniya',
      motherTongue: 'Hindi',
      maritalStatus: 'Never Married',
      aboutMe: 'Ambitious and creative. Love brand strategy and storytelling.',
      familyBackground: 'Entrepreneurial family with progressive outlook.',
      interests: ['Running', 'Movies', 'Startups'],
      fatherOccupation: 'Businessman',
      motherOccupation: 'Social Worker',
      siblings: '1 younger brother',
      photos: [
        'https://ui-avatars.com/api/?name=Profile&size=400&background=random',
      ],
      isNew: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      status: ProfileStatus.pending,
    ),
    Profile(
      id: '5',
      name: 'Raj Malhotra',
      age: 31,
      profession: 'Civil Engineer',
      education: 'B.Tech from NIT Trichy',
      city: 'Chennai',
      community: 'Hindu',
      height: '5\'11"',
      religion: 'Hindu',
      caste: 'Khatri',
      motherTongue: 'Punjabi',
      maritalStatus: 'Never Married',
      aboutMe:
          'Practical and grounded. I enjoy architecture, sketching, and road-trips.',
      familyBackground: 'Father is a retired engineer; mother is a homemaker.',
      interests: ['Sketching', 'Road Trips', 'History'],
      fatherOccupation: 'Retired Engineer',
      motherOccupation: 'Homemaker',
      siblings: '1 elder sister (married)',
      photos: [
        'https://ui-avatars.com/api/?name=Profile&size=400&background=random',
      ],
      isNew: false,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      status: ProfileStatus.notMatch,
    ),
    Profile(
      id: '6',
      name: 'Karan Agarwal',
      age: 27,
      profession: 'Data Scientist',
      education: 'M.Sc. Data Science from ISI',
      city: 'Hyderabad',
      community: 'Hindu',
      height: '5\'8"',
      religion: 'Hindu',
      caste: 'Agarwal',
      motherTongue: 'Hindi',
      maritalStatus: 'Never Married',
      aboutMe:
          'Curious and analytical. I love solving puzzles and exploring ML.',
      familyBackground:
          'Father works in a bank; mother is a teacher. Supportive family.',
      interests: ['Chess', 'Cycling', 'Coding'],
      fatherOccupation: 'Bank Officer',
      motherOccupation: 'Teacher',
      siblings: '2 sisters (both married)',
      photos: [
        'https://ui-avatars.com/api/?name=Profile&size=400&background=random',
      ],
      isNew: false,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      status: ProfileStatus.awaitingResponse,
    ),
    Profile(
      id: '7',
      name: 'Suresh Kumar',
      age: 32,
      profession: 'Business Analyst',
      education: 'MBA Finance',
      city: 'Kolkata',
      community: 'Hindu',
      height: '5\'9"',
      religion: 'Hindu',
      caste: 'Kayastha',
      motherTongue: 'Bengali',
      maritalStatus: 'Never Married',
      aboutMe:
          'Calm and observant. Enjoy reading non-fiction and learning languages.',
      familyBackground: 'Business family; strong emphasis on education.',
      interests: ['Reading', 'Languages', 'Badminton'],
      fatherOccupation: 'Businessman',
      motherOccupation: 'Doctor',
      siblings: '1 younger brother',
      photos: [
        'https://ui-avatars.com/api/?name=Profile&size=400&background=random',
      ],
      isNew: false,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      status: ProfileStatus.mutualInterest,
    ),
  ];

  static List<ChatMessage> getChatMessages() {
    return [
      ChatMessage(
        id: '1',
        senderId: 'broker',
        content:
            'Here are some new profiles I think would be perfect matches for your daughter.',
        type: ChatMessageType.text,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: true,
      ),
      ChatMessage(
        id: '2',
        senderId: 'broker',
        content: 'Profile shared',
        type: ChatMessageType.profile,
        timestamp: DateTime.now().subtract(
          const Duration(hours: 2, minutes: 5),
        ),
        isRead: true,
        profile: profiles[0],
      ),
      ChatMessage(
        id: '3',
        senderId: 'parent',
        content: 'Interested in this profile',
        type: ChatMessageType.action,
        timestamp: DateTime.now().subtract(
          const Duration(hours: 1, minutes: 30),
        ),
        isRead: true,
      ),
      ChatMessage(
        id: '4',
        senderId: 'broker',
        content:
            'Great! I\'ll coordinate with their family. They seem very interested too.',
        type: ChatMessageType.text,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: true,
      ),
      ChatMessage(
        id: '5',
        senderId: 'broker',
        content:
            'Good news! The Sharma family has shown interest in your daughter\'s profile. Would you like to proceed with the next steps?',
        type: ChatMessageType.text,
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        isRead: false,
      ),
    ];
  }

  static List<Notification> getNotifications() {
    return [
      Notification(
        id: '1',
        title: '5 New Profiles',
        message: 'Your broker has shared 5 new profiles with you.',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: false,
        type: NotificationType.newProfiles,
      ),
      Notification(
        id: '2',
        title: 'Mutual Interest',
        message:
            'Sharma Family has shown interest in your daughter\'s profile.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: false,
        type: NotificationType.mutualInterest,
      ),
      Notification(
        id: '3',
        title: 'Message from Broker',
        message: 'Rajesh Kumar sent you a message.',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        isRead: true,
        type: NotificationType.brokerMessage,
      ),
    ];
  }
}
