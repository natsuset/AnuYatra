// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Anuyatra';

  @override
  String get appNameStyled => 'Anuyātrā';

  @override
  String get appTagline => 'The Real Matrimony Experience';

  @override
  String get appTitle => 'Anuyatra - The Real Matrimony App';

  @override
  String get enterPhoneTitle => 'Enter your phone number';

  @override
  String get enterPhoneSubtitle => 'We\'ll send you a verification code';

  @override
  String get sendOtp => 'Send OTP';

  @override
  String get verifyNumber => 'Verify your number';

  @override
  String get verifyAndContinue => 'Verify & Continue';

  @override
  String get resendCode => 'Resend Code';

  @override
  String get completeProfile => 'Complete Your Profile';

  @override
  String get demoOtpHint =>
      'Demo mode: Any phone number works.\nUse OTP code: 123456';

  @override
  String get otpHint => 'Hint: The OTP is 123456';

  @override
  String get demoOtpAlways => 'Demo: OTP code is always 123456';

  @override
  String get invalidPhoneError => 'Please enter a valid 10-digit phone number';

  @override
  String get invalidOtpError => 'Please enter the complete 6-digit code';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get agencyNameRequired => 'Agency name is required';

  @override
  String get welcome => 'Welcome!';

  @override
  String registeringAs(String role) {
    return 'Registering as: $role';
  }

  @override
  String settingUpAs(String role) {
    return 'Setting up as: $role';
  }

  @override
  String otpSentTo(String phone) {
    return 'Enter the 6-digit code sent to $phone';
  }

  @override
  String get howToUseAnuyatra => 'How would you like to use Anuyatra?';

  @override
  String get home => 'Home';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get settings => 'Settings';

  @override
  String get messages => 'Messages';

  @override
  String get profile => 'Profile';

  @override
  String get myProfile => 'My Profile';

  @override
  String get search => 'Search';

  @override
  String get discover => 'Discover';

  @override
  String get sharedProfiles => 'Shared Profiles';

  @override
  String get linkRequests => 'Link Requests';

  @override
  String get agencySettings => 'Agency Settings';

  @override
  String get agencyInformation => 'Agency Information';

  @override
  String get brokerRoster => 'Broker Roster';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get account => 'Account';

  @override
  String get appearance => 'Appearance';

  @override
  String get session => 'Session';

  @override
  String get anuyatraHub => 'Anuyatra Hub';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get submit => 'Submit';

  @override
  String get done => 'Done';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get Started';

  @override
  String get logout => 'Logout';

  @override
  String get accept => 'Accept';

  @override
  String get decline => 'Decline';

  @override
  String get findBrokers => 'Find Brokers';

  @override
  String get inviteBroker => 'Invite Broker';

  @override
  String get sendInvite => 'Send Invite';

  @override
  String get connectWithAgency => 'Connect with Agency';

  @override
  String get connectWithBroker => 'Connect with Broker';

  @override
  String get viewProfile => 'View Profile';

  @override
  String get forwardToChild => 'Forward to Child';

  @override
  String get interested => 'Interested';

  @override
  String get maybe => 'Maybe';

  @override
  String get pass => 'Pass';

  @override
  String get pending => 'Pending';

  @override
  String get noProfilesShared => 'No profiles shared yet';

  @override
  String get noProfilesSharedHint =>
      'Profiles shared by your brokers will appear here';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get noMessagesHint => 'Send a message to start the conversation';

  @override
  String get noConversationsYet => 'No conversations yet';

  @override
  String get noBrokersInAgency => 'No brokers in your agency';

  @override
  String get noClientsYet => 'No clients yet';

  @override
  String get noBrokersConnected => 'No Brokers Connected';

  @override
  String get noReceivedRequests => 'No received requests';

  @override
  String get noSentRequests => 'No sent requests';

  @override
  String get noSharedProfilesForCandidate =>
      'Profiles shared by your parent will appear here for your review';

  @override
  String get profileNotFound => 'Profile not found';

  @override
  String get profileNotFoundTitle => 'Profile Not Found';

  @override
  String get genericError => 'Something went wrong. Please try again.';

  @override
  String get sendOtpFailed => 'Failed to send OTP. Please try again.';

  @override
  String get verificationFailed => 'Verification failed. Please try again.';

  @override
  String get profileSetupFailed => 'Profile setup failed';

  @override
  String get userNotFoundByPhone => 'No user found with that phone number';

  @override
  String get notRegisteredAsBroker => 'This user is not registered as a broker';

  @override
  String get logoutConfirmTitle => 'Logout';

  @override
  String get logoutConfirmMessage => 'Are you sure you want to log out?';

  @override
  String get logoutConfirmBroker => 'Are you sure you want to logout?';

  @override
  String get acceptRequestConfirm => 'Accept this request?';

  @override
  String get declineRequestConfirm => 'Decline this request?';

  @override
  String get vivahaSamskara => 'Vivaha Samskara';

  @override
  String get vivahaSamskaraDesc => 'Premium wedding preparation services';

  @override
  String get trustVerification => 'Trust Verification';

  @override
  String get financialCompatibility => 'Financial Compatibility';

  @override
  String get comingSoon => 'More features coming soon!';

  @override
  String get comingSoonHint => 'Virtual meetings, AI matching, and more';

  @override
  String get comingSoonShort => 'coming soon!';

  @override
  String get activeBrokers => 'Brokers';

  @override
  String get activeClients => 'Clients';

  @override
  String get profilesManaged => 'Profiles';

  @override
  String get profilesSharedStat => 'Shared';

  @override
  String get pendingRequestsStat => 'Pending';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get darkThemeActive => 'Dark theme active';

  @override
  String get lightThemeActive => 'Light theme active';

  @override
  String get routeNotFound => 'Route not found';

  @override
  String get pageNotFound => 'Page Not Found';

  @override
  String get goHome => 'Go Home';

  @override
  String get pleaseLogIn => 'Please log in';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get roleLabel => 'Role';

  @override
  String get signOutSubtitle => 'Sign out of your account';

  @override
  String get noNameSet => 'No name set';

  @override
  String get authErrorInvalidPhone =>
      'Please enter a valid 10-digit Indian mobile number.';

  @override
  String get authErrorSendOtpFailed => 'Failed to send OTP. Please try again.';

  @override
  String authErrorInvalidOtpWithHint(String hint) {
    return 'Invalid OTP. Use \"$hint\" for demo.';
  }

  @override
  String get authErrorInvalidOtp => 'Invalid OTP. Please try again.';

  @override
  String get authErrorVerificationFailed =>
      'Verification failed. Please try again.';

  @override
  String authErrorProfileSetupFailed(String detail) {
    return 'Profile setup failed: $detail';
  }

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get noRecentActivity => 'No recent activity';

  @override
  String get recentActivityHint =>
      'Activity from shared profiles and connections will appear here';

  @override
  String get profileSharedActivity => 'Profile shared';

  @override
  String get connectionRequestActivity => 'Connection request';

  @override
  String get welcomeBack => 'Welcome back,';

  @override
  String get newBroker => 'New Broker';

  @override
  String get gettingStarted => 'Getting started';

  @override
  String get yrsExperience => 'yrs experience';

  @override
  String get createProfileAction => 'Create Profile';

  @override
  String get shareProfileAction => 'Share Profile';

  @override
  String get viewRequestsAction => 'View Requests';

  @override
  String get connectedClients => 'Connected Clients';

  @override
  String get noConnectedClients => 'No connected clients yet.';

  @override
  String get brokerClientsHint =>
      'When parents connect with you, they will appear here.';

  @override
  String acceptedRequestFrom(String name) {
    return 'Accepted request from $name';
  }

  @override
  String failedToAccept(String error) {
    return 'Failed to accept: $error';
  }

  @override
  String declinedRequestFrom(String name) {
    return 'Declined request from $name';
  }

  @override
  String failedToDecline(String error) {
    return 'Failed to decline: $error';
  }

  @override
  String get lookingFor => 'Looking for';

  @override
  String get lookingForSection => 'Looking For';

  @override
  String get listedWith => 'Listed with';

  @override
  String get brokersLabel => 'brokers';

  @override
  String get brokerConversationsHint =>
      'When parents connect with you, conversations will appear here.';

  @override
  String get managedProfiles => 'Managed Profiles';

  @override
  String get noProfilesYetLabel => 'No Profiles Yet';

  @override
  String get noProfilesYetHint =>
      'No profiles yet. Create your first candidate profile.';

  @override
  String get shareProfileWith => 'Share Profile With';

  @override
  String get noConnectedParents => 'No connected parents to share with';

  @override
  String get agencyLabel => 'Agency';

  @override
  String get experienceLabel => 'Experience';

  @override
  String get areasServedLabel => 'Areas Served';

  @override
  String get specializationsLabel => 'Specializations';

  @override
  String get yearsLabel => 'years';

  @override
  String get linkedToParent => 'Linked to Parent';

  @override
  String get notLinked => 'Not Linked';

  @override
  String get notLinkedHint => 'You are not linked to any parent yet.';

  @override
  String get linkAction => 'Link';

  @override
  String get profilesSharedWithYou => 'Profiles Shared With You';

  @override
  String get profileAvailable => 'profile available';

  @override
  String get profilesAvailable => 'profiles available';

  @override
  String get viewSharedProfiles => 'View Shared Profiles';

  @override
  String get seeProfilesForwardedByParent =>
      'See profiles forwarded by your parent';

  @override
  String get viewConnectionRequests => 'View your connection requests';

  @override
  String get markedAsInterested => 'Marked as Interested';

  @override
  String get markedAsPass => 'Marked as Pass';

  @override
  String get linkToParentTitle => 'Link to Parent';

  @override
  String linkRequestSentTo(String name) {
    return 'Link request sent to $name';
  }

  @override
  String get linkRequestMessage => 'I would like to link my account to yours.';

  @override
  String get received => 'Received';

  @override
  String get sent => 'Sent';

  @override
  String get requestAccepted => 'Request accepted';

  @override
  String get requestDeclined => 'Request declined';

  @override
  String get connectedWith => 'Connected with';

  @override
  String get call => 'Call';

  @override
  String get chat => 'Chat';

  @override
  String get calling => 'Calling';

  @override
  String get cityLabel => 'City';

  @override
  String get stateLabel => 'State';

  @override
  String get connectedBrokers => 'Connected Brokers';

  @override
  String get linkedChild => 'Linked Child';

  @override
  String get viewLinkRequests => 'View Link Requests';

  @override
  String get agencyBrokersTitle => 'Agency Brokers';

  @override
  String notRegisteredBrokerFull(String name) {
    return '$name is not registered as a broker';
  }

  @override
  String inviteSentTo(String phone) {
    return 'Invite sent to $phone';
  }

  @override
  String get agencyClientsTitle => 'Agency Clients';

  @override
  String get viewAll => 'View All';

  @override
  String get addNewBroker => 'Add a new broker to your agency';

  @override
  String get agencySettingsSaved => 'Agency settings saved!';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get yrsExp => 'yrs exp';

  @override
  String get connectionRequestSent => 'Connection request sent!';

  @override
  String profileCreated(String name) {
    return '$name created!';
  }

  @override
  String get bride => 'Bride';

  @override
  String get groom => 'Groom';

  @override
  String get yourName => 'Your Name';

  @override
  String get enterYourFullName => 'Enter your full name';

  @override
  String get agencyNameLabel => 'Agency Name';

  @override
  String get aboutYou => 'About You';

  @override
  String get aboutYouHint =>
      'Tell families about your matchmaking experience...';

  @override
  String get yearsOfExperience => 'Years of Experience';

  @override
  String get lookingForA => 'Looking for a';

  @override
  String get iAmA => 'I am a';

  @override
  String get yourAge => 'Your Age';

  @override
  String get stepBasicInfo => 'Basic Info';

  @override
  String get stepAgencyDetails => 'Agency Details';

  @override
  String get stepContact => 'Contact';

  @override
  String get stepExperience => 'Experience';

  @override
  String get stepBusinessDetails => 'Business Details';

  @override
  String get stepChildDetails => 'Child Details';

  @override
  String get stepFamilyDetails => 'Family Details';

  @override
  String get stepPersonal => 'Personal';

  @override
  String get agencyDetailsSection => 'Agency Details';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get descriptionHint => 'Describe your agency and services...';

  @override
  String get specializationsCommaSeparated =>
      'Specializations (comma-separated)';

  @override
  String get contactInformationSection => 'Contact Information';

  @override
  String get emailLabel => 'Email';

  @override
  String get officePhoneLabel => 'Office Phone';

  @override
  String get websiteOptional => 'Website (optional)';

  @override
  String get addMoreDetailsLater =>
      'You can add more details later from Agency Settings';

  @override
  String get experienceExpertiseSection => 'Experience & Expertise';

  @override
  String get areasServedCommaSeparated => 'Areas Served (comma-separated)';

  @override
  String get languagesSpokenCommaSeparated =>
      'Languages Spoken (comma-separated)';

  @override
  String get businessDetailsSection => 'Business Details';

  @override
  String get officeAddressOptional => 'Office Address (optional)';

  @override
  String get feeStructureOptional => 'Fee Structure (optional)';

  @override
  String get workingHoursOptional => 'Working Hours (optional)';

  @override
  String get childDetailsSection => 'Your Child\'s Details';

  @override
  String get childDetailsHint =>
      'This information helps brokers find suitable matches';

  @override
  String get childNameLabel => 'Child\'s Name';

  @override
  String get fullNameHint => 'Full name';

  @override
  String get heightLabel => 'Height';

  @override
  String get dietLabel => 'Diet';

  @override
  String get dietVegetarian => 'Vegetarian';

  @override
  String get dietNonVeg => 'Non-Veg';

  @override
  String get dietEggetarian => 'Eggetarian';

  @override
  String get dietVegan => 'Vegan';

  @override
  String get dietJain => 'Jain';

  @override
  String get educationLabel => 'Education';

  @override
  String get professionLabel => 'Profession';

  @override
  String get emailOptionalLabel => 'Your Email (optional)';

  @override
  String get familyInformationSection => 'Family Information';

  @override
  String get familyTypeLabel => 'Family Type';

  @override
  String get jointFamilyLabel => 'Joint Family';

  @override
  String get nuclearFamilyLabel => 'Nuclear Family';

  @override
  String get fatherOccupationLabel => 'Father\'s Occupation';

  @override
  String get motherOccupationLabel => 'Mother\'s Occupation';

  @override
  String get aboutFamilyLabel => 'About Family';

  @override
  String get aboutFamilyHint => 'Briefly describe your family background...';

  @override
  String get shareWithChildDesc =>
      'Share this profile with your child for their opinion';

  @override
  String get noChildLinkedMsg =>
      'No child account is linked to your profile yet.';

  @override
  String get askChildToLink =>
      'Ask your child to create an account and link it to yours.';

  @override
  String get linkedChildLabel => 'Linked child';

  @override
  String get noChildLinkedLabel => 'No child linked';

  @override
  String profileForwardedTo(String name) {
    return 'Profile forwarded to $name';
  }

  @override
  String get forwardProfileButton => 'Forward Profile';

  @override
  String get viewBrokerProfile => 'View Broker Profile';

  @override
  String get muteNotifications => 'Mute Notifications';

  @override
  String get clearChat => 'Clear Chat';

  @override
  String get callBroker => 'Call Broker';

  @override
  String get startRecording => 'Start Recording';

  @override
  String get voiceNoteComingSoon => 'Voice note feature coming soon!';

  @override
  String get reportProfile => 'Report Profile';

  @override
  String get contactBroker => 'Contact Broker';

  @override
  String get shareFeatureComingSoon => 'Share feature coming soon!';

  @override
  String get saveFeatureComingSoon => 'Save feature coming soon!';

  @override
  String get saveToDevice => 'Save to device';

  @override
  String get profileShareMessage =>
      'Here\'s a profile I think would be perfect for you. Take a look at the details below.';

  @override
  String get yourShortlist => 'Your Shortlist';

  @override
  String get sortBy => 'Sort by';

  @override
  String get filter => 'Filter';

  @override
  String get exportList => 'Export list';

  @override
  String get noProfilesInShortlist => 'No profiles in shortlist';

  @override
  String get shortlistHint =>
      'Profiles you save or show interest in will appear here';

  @override
  String get browseProfiles => 'Browse Profiles';

  @override
  String get trustAndVerification => 'Trust & Verification';

  @override
  String get inviteVerifiers => 'Invite Verifiers';

  @override
  String get sendInvites => 'Send Invites';

  @override
  String get completeVerification => 'Complete Verification';

  @override
  String get uploadDocuments => 'Upload Documents';

  @override
  String get trustReport => 'Trust Report';

  @override
  String get download => 'Download';

  @override
  String get startingFinancialDiscussion => 'Starting financial discussion...';

  @override
  String get weddingBudgetPlanner => 'Wedding Budget Planner';

  @override
  String get startPlanning => 'Start Planning';

  @override
  String get completeProfileAction => 'Complete Profile';

  @override
  String get completeNow => 'Complete Now';

  @override
  String get financialCounseling => 'Financial Counseling';

  @override
  String get bookSession => 'Book Session';

  @override
  String get start => 'Start';

  @override
  String get later => 'Later';

  @override
  String get bookingInitiated => 'booking initiated!';

  @override
  String get joiningMeeting => 'Joining meeting...';

  @override
  String get rescheduleMeeting => 'Reschedule Meeting';

  @override
  String get rescheduleMeetingDesc =>
      'Choose a new time for your virtual family meet.';

  @override
  String get reschedule => 'Reschedule';

  @override
  String get schedule => 'Schedule';

  @override
  String get openingMeetingScheduler => 'Opening meeting scheduler...';

  @override
  String get helpComingSoon => 'Help & Support coming soon';

  @override
  String get helpLabel => 'Help';

  @override
  String get designSystemDemo => 'Design System Demo';

  @override
  String get language => 'Language';

  @override
  String get systemDefault => 'System Default';

  @override
  String get english => 'English';

  @override
  String get hindi => 'Hindi';

  @override
  String get telugu => 'Telugu';

  @override
  String get notSet => 'Not set';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get none => 'None';

  @override
  String get linked => 'Linked';

  @override
  String get markedAsMaybe => 'Marked as Maybe';

  @override
  String get typeAMessage => 'Type a message';

  @override
  String get community => 'Community';

  @override
  String get caste => 'Caste';

  @override
  String get gotra => 'Gotra';

  @override
  String get manglikStatus => 'Manglik Status';

  @override
  String get annualIncome => 'Annual Income';

  @override
  String get complexion => 'Complexion';

  @override
  String get smoking => 'Smoking';

  @override
  String get drinking => 'Drinking';

  @override
  String get ownHouse => 'Own House';

  @override
  String get ownCar => 'Own Car';

  @override
  String get willingToRelocate => 'Willing to Relocate';

  @override
  String get rashi => 'Rashi';

  @override
  String get nakshatra => 'Nakshatra';

  @override
  String get birthPlace => 'Birth Place';

  @override
  String get birthTime => 'Birth Time';

  @override
  String get familyValues => 'Family Values';

  @override
  String get siblings => 'Siblings';

  @override
  String get brothers => 'Brothers';

  @override
  String get sisters => 'Sisters';

  @override
  String get childLabel => 'Child';

  @override
  String get brokerSharesHint =>
      'Your connected brokers will share profiles here for your review';

  @override
  String lookingForValue(String value) {
    return 'Looking for $value';
  }

  @override
  String resultsCount(String count) {
    return '$count results';
  }

  @override
  String get personalInformationSection => 'Personal Information';

  @override
  String get canCompleteLater =>
      'You can complete more details from your profile later';

  @override
  String get candidateLinkHint =>
      'You can link to your parent later and they can fill detailed profile information';

  @override
  String get candidateInfoBox =>
      'After creating your account, link to your parent from the Home screen. Your parent and broker will manage detailed profile information.';

  @override
  String get welcomeTo => 'Welcome to';

  @override
  String connectedWithName(String name) {
    return 'Connected with $name';
  }

  @override
  String callingName(String name) {
    return 'Calling $name';
  }

  @override
  String profileCreatedFor(String name) {
    return 'Profile for $name created!';
  }

  @override
  String get shareProfileWithClientsButton => 'Share profile with clients';

  @override
  String get toggleThemeTooltip => 'Toggle Theme';

  @override
  String get searchBrokersAgenciesHint => 'Search brokers, agencies, cities...';
}
