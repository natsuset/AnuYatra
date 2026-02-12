/// Centralized route name constants
class RouteNames {
  RouteNames._();

  // Auth
  static const roleSelection = 'role-selection';
  static const login = 'login';
  static const otpVerify = 'otp-verify';
  static const profileSetup = 'profile-setup';

  // Parent
  static const parentHome = 'parent-home';
  static const parentSearch = 'parent-search';
  static const parentMyBrokers = 'parent-my-brokers';
  static const parentAnuyatra = 'parent-anuyatra';
  static const parentProfile = 'parent-profile';

  // Broker
  static const brokerDashboard = 'broker-dashboard';
  static const brokerClients = 'broker-clients';
  static const brokerProfiles = 'broker-profiles';
  static const brokerMessages = 'broker-messages';
  static const brokerProfile = 'broker-profile';
  static const brokerCreateProfile = 'broker-create-profile';
  static const brokerEditProfile = 'broker-edit-profile';

  // Candidate
  static const candidateHome = 'candidate-home';
  static const candidateShared = 'candidate-shared';
  static const candidateAnuyatra = 'candidate-anuyatra';
  static const candidateProfile = 'candidate-profile';

  // Agency Admin
  static const adminDashboard = 'admin-dashboard';
  static const adminBrokers = 'admin-brokers';
  static const adminClients = 'admin-clients';
  static const adminSettings = 'admin-settings';

  // Shared
  static const profileView = 'profile-view';
  static const chat = 'chat';
  static const appSettings = 'app-settings';
  static const linkRequests = 'link-requests';
  static const linkToParent = 'link-to-parent';

  // Paths
  static const roleSelectionPath = '/role-selection';
  static const loginPath = '/login';
  static const otpVerifyPath = '/otp-verify';
  static const profileSetupPath = '/profile-setup';

  static const parentHomePath = '/parent';
  static const parentSearchPath = '/parent/search';
  static const parentMyBrokersPath = '/parent/my-brokers';
  static const parentAnuyatraPath = '/parent/anuyatra';
  static const parentProfilePath = '/parent/profile';

  static const brokerDashboardPath = '/broker';
  static const brokerClientsPath = '/broker/clients';
  static const brokerProfilesPath = '/broker/profiles';
  static const brokerMessagesPath = '/broker/messages';
  static const brokerProfilePath = '/broker/profile';
  static const brokerCreateProfilePath = '/broker/profiles/create';
  static const brokerEditProfilePath = '/broker/profiles/edit/:id';

  static const candidateHomePath = '/candidate';
  static const candidateSharedPath = '/candidate/shared';
  static const candidateAnuyatraPath = '/candidate/anuyatra';
  static const candidateProfilePath = '/candidate/profile';

  static const adminDashboardPath = '/admin';
  static const adminBrokersPath = '/admin/brokers';
  static const adminClientsPath = '/admin/clients';
  static const adminSettingsPath = '/admin/settings';

  static const profileViewPath = '/profile/:id';
  static const chatPath = '/chat/:conversationId';
  static const appSettingsPath = '/settings';
  static const linkRequestsPath = '/link-requests';
  static const linkToParentPath = '/link-to-parent';
}
