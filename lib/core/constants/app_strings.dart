/// Centralized user-facing strings for the Anuyatra app.
///
/// Keeps UI copy in one place so it stays consistent across screens
/// and makes future localization (ARB / intl) straightforward.
class AppStrings {
  AppStrings._();

  // ── Branding ──────────────────────────────────────────────
  static const appName = 'Anuyatra';
  static const appNameStyled = 'Anuyātrā';
  static const appTagline = 'The Real Matrimony Experience';
  static const appTitle = 'Anuyatra - The Real Matrimony App';

  // ── Auth ──────────────────────────────────────────────────
  static const enterPhoneTitle = 'Enter your phone number';
  static const enterPhoneSubtitle = "We'll send you a verification code";
  static const sendOtp = 'Send OTP';
  static const verifyNumber = 'Verify your number';
  static const verifyAndContinue = 'Verify & Continue';
  static const resendCode = 'Resend Code';
  static const completeProfile = 'Complete Your Profile';
  static const demoOtpHint = 'Demo mode: Any phone number works.\nUse OTP code: 123456';
  static const otpHint = 'Hint: The OTP is 123456';
  static const invalidPhoneError = 'Please enter a valid 10-digit phone number';
  static const invalidOtpError = 'Please enter the complete 6-digit code';
  static const nameRequired = 'Name is required';
  static const agencyNameRequired = 'Agency name is required';
  static const welcome = 'Welcome!';
  static String registeringAs(String role) => 'Registering as: $role';
  static String settingUpAs(String role) => 'Setting up as: $role';
  static String otpSentTo(String phone) => 'Enter the 6-digit code sent to $phone';

  // ── Navigation / Section Titles ───────────────────────────
  static const home = 'Home';
  static const dashboard = 'Dashboard';
  static const settings = 'Settings';
  static const messages = 'Messages';
  static const profile = 'Profile';
  static const myProfile = 'My Profile';
  static const search = 'Search';
  static const discover = 'Discover';
  static const sharedProfiles = 'Shared Profiles';
  static const linkRequests = 'Link Requests';
  static const agencySettings = 'Agency Settings';
  static const agencyInformation = 'Agency Information';
  static const brokerRoster = 'Broker Roster';
  static const quickActions = 'Quick Actions';
  static const account = 'Account';
  static const appearance = 'Appearance';
  static const session = 'Session';
  static const anuyatraHub = 'Anuyatra Hub';

  // ── Common Actions ────────────────────────────────────────
  static const save = 'Save';
  static const cancel = 'Cancel';
  static const submit = 'Submit';
  static const done = 'Done';
  static const back = 'Back';
  static const next = 'Next';
  static const getStarted = 'Get Started';
  static const logout = 'Logout';
  static const accept = 'Accept';
  static const decline = 'Decline';
  static const findBrokers = 'Find Brokers';
  static const inviteBroker = 'Invite Broker';
  static const sendInvite = 'Send Invite';
  static const connectWithAgency = 'Connect with Agency';
  static const connectWithBroker = 'Connect with Broker';
  static const viewProfile = 'View Profile';
  static const forwardToChild = 'Forward to Child';

  // ── Profile Responses ─────────────────────────────────────
  static const interested = 'Interested';
  static const maybe = 'Maybe';
  static const pass = 'Pass';
  static const pending = 'Pending';

  // ── Empty States ──────────────────────────────────────────
  static const noProfilesShared = 'No profiles shared yet';
  static const noProfilesSharedHint =
      'Profiles shared by your brokers will appear here';
  static const noResultsFound = 'No results found';
  static const noMessagesYet = 'No messages yet';
  static const noMessagesHint = 'Send a message to start the conversation';
  static const noConversationsYet = 'No conversations yet';
  static const noBrokersInAgency = 'No brokers in your agency';
  static const noClientsYet = 'No clients yet';
  static const noBrokersConnected = 'No Brokers Connected';
  static const noReceivedRequests = 'No received requests';
  static const noSentRequests = 'No sent requests';
  static const noSharedProfilesForCandidate =
      'Profiles shared by your parent will appear here for your review';
  static const profileNotFound = 'Profile not found';

  // ── Error Messages ────────────────────────────────────────
  static const genericError = 'Something went wrong. Please try again.';
  static const sendOtpFailed = 'Failed to send OTP. Please try again.';
  static const verificationFailed = 'Verification failed. Please try again.';
  static const profileSetupFailed = 'Profile setup failed';
  static const userNotFoundByPhone = 'No user found with that phone number';
  static const notRegisteredAsBroker = 'This user is not registered as a broker';

  // ── Confirmation Dialogs ──────────────────────────────────
  static const logoutConfirmTitle = 'Logout';
  static const logoutConfirmMessage = 'Are you sure you want to log out?';
  static const acceptRequestConfirm = 'Accept this request?';
  static const declineRequestConfirm = 'Decline this request?';

  // ── Hub Features ──────────────────────────────────────────
  static const vivahaSamskara = 'Vivaha Samskara';
  static const vivahaSamskaraDesc = 'Premium wedding preparation services';
  static const trustVerification = 'Trust Verification';
  static const financialCompatibility = 'Financial Compatibility';
  static const comingSoon = 'More features coming soon!';
  static const comingSoonHint = 'Virtual meetings, AI matching, and more';

  // ── Dashboard Stats ───────────────────────────────────────
  static const activeBrokers = 'Brokers';
  static const activeClients = 'Clients';
  static const profilesManaged = 'Profiles';
  static const profilesShared = 'Shared';
  static const pendingRequests = 'Pending';

  // ── Misc ──────────────────────────────────────────────────
  static const darkMode = 'Dark Mode';
  static const routeNotFound = 'Route not found';
  static const pageNotFound = 'Page Not Found';
  static const goHome = 'Go Home';
}
