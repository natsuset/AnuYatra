import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('te'),
  ];

  /// Brand name — do not translate
  ///
  /// In en, this message translates to:
  /// **'Anuyatra'**
  String get appName;

  /// Styled brand name with diacritics — do not translate
  ///
  /// In en, this message translates to:
  /// **'Anuyātrā'**
  String get appNameStyled;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'The Real Matrimony Experience'**
  String get appTagline;

  /// Browser/OS title — do not translate the brand name
  ///
  /// In en, this message translates to:
  /// **'Anuyatra - The Real Matrimony App'**
  String get appTitle;

  /// No description provided for @enterPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterPhoneTitle;

  /// No description provided for @enterPhoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send you a verification code'**
  String get enterPhoneSubtitle;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @verifyNumber.
  ///
  /// In en, this message translates to:
  /// **'Verify your number'**
  String get verifyNumber;

  /// No description provided for @verifyAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Verify & Continue'**
  String get verifyAndContinue;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get completeProfile;

  /// Shown only in demo/dev builds — keep in English
  ///
  /// In en, this message translates to:
  /// **'Demo mode: Any phone number works.\nUse OTP code: 123456'**
  String get demoOtpHint;

  /// Demo hint — keep in English
  ///
  /// In en, this message translates to:
  /// **'Hint: The OTP is 123456'**
  String get otpHint;

  /// Demo hint — keep in English
  ///
  /// In en, this message translates to:
  /// **'Demo: OTP code is always 123456'**
  String get demoOtpAlways;

  /// No description provided for @invalidPhoneError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 10-digit phone number'**
  String get invalidPhoneError;

  /// No description provided for @invalidOtpError.
  ///
  /// In en, this message translates to:
  /// **'Please enter the complete 6-digit code'**
  String get invalidOtpError;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @agencyNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Agency name is required'**
  String get agencyNameRequired;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcome;

  /// No description provided for @registeringAs.
  ///
  /// In en, this message translates to:
  /// **'Registering as: {role}'**
  String registeringAs(String role);

  /// No description provided for @settingUpAs.
  ///
  /// In en, this message translates to:
  /// **'Setting up as: {role}'**
  String settingUpAs(String role);

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to {phone}'**
  String otpSentTo(String phone);

  /// No description provided for @howToUseAnuyatra.
  ///
  /// In en, this message translates to:
  /// **'How would you like to use Anuyatra?'**
  String get howToUseAnuyatra;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @discover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discover;

  /// No description provided for @sharedProfiles.
  ///
  /// In en, this message translates to:
  /// **'Shared Profiles'**
  String get sharedProfiles;

  /// No description provided for @linkRequests.
  ///
  /// In en, this message translates to:
  /// **'Link Requests'**
  String get linkRequests;

  /// No description provided for @agencySettings.
  ///
  /// In en, this message translates to:
  /// **'Agency Settings'**
  String get agencySettings;

  /// No description provided for @agencyInformation.
  ///
  /// In en, this message translates to:
  /// **'Agency Information'**
  String get agencyInformation;

  /// No description provided for @brokerRoster.
  ///
  /// In en, this message translates to:
  /// **'Broker Roster'**
  String get brokerRoster;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @session.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get session;

  /// No description provided for @anuyatraHub.
  ///
  /// In en, this message translates to:
  /// **'Anuyatra Hub'**
  String get anuyatraHub;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @findBrokers.
  ///
  /// In en, this message translates to:
  /// **'Find Brokers'**
  String get findBrokers;

  /// No description provided for @inviteBroker.
  ///
  /// In en, this message translates to:
  /// **'Invite Broker'**
  String get inviteBroker;

  /// No description provided for @sendInvite.
  ///
  /// In en, this message translates to:
  /// **'Send Invite'**
  String get sendInvite;

  /// No description provided for @connectWithAgency.
  ///
  /// In en, this message translates to:
  /// **'Connect with Agency'**
  String get connectWithAgency;

  /// No description provided for @connectWithBroker.
  ///
  /// In en, this message translates to:
  /// **'Connect with Broker'**
  String get connectWithBroker;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// No description provided for @forwardToChild.
  ///
  /// In en, this message translates to:
  /// **'Forward to Child'**
  String get forwardToChild;

  /// No description provided for @interested.
  ///
  /// In en, this message translates to:
  /// **'Interested'**
  String get interested;

  /// No description provided for @maybe.
  ///
  /// In en, this message translates to:
  /// **'Maybe'**
  String get maybe;

  /// No description provided for @pass.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get pass;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @noProfilesShared.
  ///
  /// In en, this message translates to:
  /// **'No profiles shared yet'**
  String get noProfilesShared;

  /// No description provided for @noProfilesSharedHint.
  ///
  /// In en, this message translates to:
  /// **'Profiles shared by your brokers will appear here'**
  String get noProfilesSharedHint;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @noMessagesHint.
  ///
  /// In en, this message translates to:
  /// **'Send a message to start the conversation'**
  String get noMessagesHint;

  /// No description provided for @noConversationsYet.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noConversationsYet;

  /// No description provided for @noBrokersInAgency.
  ///
  /// In en, this message translates to:
  /// **'No brokers in your agency'**
  String get noBrokersInAgency;

  /// No description provided for @noClientsYet.
  ///
  /// In en, this message translates to:
  /// **'No clients yet'**
  String get noClientsYet;

  /// No description provided for @noBrokersConnected.
  ///
  /// In en, this message translates to:
  /// **'No Brokers Connected'**
  String get noBrokersConnected;

  /// No description provided for @noReceivedRequests.
  ///
  /// In en, this message translates to:
  /// **'No received requests'**
  String get noReceivedRequests;

  /// No description provided for @noSentRequests.
  ///
  /// In en, this message translates to:
  /// **'No sent requests'**
  String get noSentRequests;

  /// No description provided for @noSharedProfilesForCandidate.
  ///
  /// In en, this message translates to:
  /// **'Profiles shared by your parent will appear here for your review'**
  String get noSharedProfilesForCandidate;

  /// No description provided for @profileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Profile not found'**
  String get profileNotFound;

  /// No description provided for @profileNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Not Found'**
  String get profileNotFoundTitle;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get genericError;

  /// No description provided for @sendOtpFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send OTP. Please try again.'**
  String get sendOtpFailed;

  /// No description provided for @verificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed. Please try again.'**
  String get verificationFailed;

  /// No description provided for @profileSetupFailed.
  ///
  /// In en, this message translates to:
  /// **'Profile setup failed'**
  String get profileSetupFailed;

  /// No description provided for @userNotFoundByPhone.
  ///
  /// In en, this message translates to:
  /// **'No user found with that phone number'**
  String get userNotFoundByPhone;

  /// No description provided for @notRegisteredAsBroker.
  ///
  /// In en, this message translates to:
  /// **'This user is not registered as a broker'**
  String get notRegisteredAsBroker;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirmMessage;

  /// No description provided for @logoutConfirmBroker.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmBroker;

  /// No description provided for @acceptRequestConfirm.
  ///
  /// In en, this message translates to:
  /// **'Accept this request?'**
  String get acceptRequestConfirm;

  /// No description provided for @declineRequestConfirm.
  ///
  /// In en, this message translates to:
  /// **'Decline this request?'**
  String get declineRequestConfirm;

  /// Service name — may transliterate but not translate
  ///
  /// In en, this message translates to:
  /// **'Vivaha Samskara'**
  String get vivahaSamskara;

  /// No description provided for @vivahaSamskaraDesc.
  ///
  /// In en, this message translates to:
  /// **'Premium wedding preparation services'**
  String get vivahaSamskaraDesc;

  /// No description provided for @trustVerification.
  ///
  /// In en, this message translates to:
  /// **'Trust Verification'**
  String get trustVerification;

  /// No description provided for @financialCompatibility.
  ///
  /// In en, this message translates to:
  /// **'Financial Compatibility'**
  String get financialCompatibility;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'More features coming soon!'**
  String get comingSoon;

  /// No description provided for @comingSoonHint.
  ///
  /// In en, this message translates to:
  /// **'Virtual meetings, AI matching, and more'**
  String get comingSoonHint;

  /// No description provided for @comingSoonShort.
  ///
  /// In en, this message translates to:
  /// **'coming soon!'**
  String get comingSoonShort;

  /// No description provided for @activeBrokers.
  ///
  /// In en, this message translates to:
  /// **'Brokers'**
  String get activeBrokers;

  /// No description provided for @activeClients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get activeClients;

  /// No description provided for @profilesManaged.
  ///
  /// In en, this message translates to:
  /// **'Profiles'**
  String get profilesManaged;

  /// No description provided for @profilesSharedStat.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get profilesSharedStat;

  /// No description provided for @pendingRequestsStat.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingRequestsStat;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @darkThemeActive.
  ///
  /// In en, this message translates to:
  /// **'Dark theme active'**
  String get darkThemeActive;

  /// No description provided for @lightThemeActive.
  ///
  /// In en, this message translates to:
  /// **'Light theme active'**
  String get lightThemeActive;

  /// No description provided for @routeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Route not found'**
  String get routeNotFound;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page Not Found'**
  String get pageNotFound;

  /// No description provided for @goHome.
  ///
  /// In en, this message translates to:
  /// **'Go Home'**
  String get goHome;

  /// No description provided for @pleaseLogIn.
  ///
  /// In en, this message translates to:
  /// **'Please log in'**
  String get pleaseLogIn;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleLabel;

  /// No description provided for @signOutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account'**
  String get signOutSubtitle;

  /// No description provided for @noNameSet.
  ///
  /// In en, this message translates to:
  /// **'No name set'**
  String get noNameSet;

  /// No description provided for @authErrorInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 10-digit Indian mobile number.'**
  String get authErrorInvalidPhone;

  /// No description provided for @authErrorSendOtpFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send OTP. Please try again.'**
  String get authErrorSendOtpFailed;

  /// No description provided for @authErrorInvalidOtpWithHint.
  ///
  /// In en, this message translates to:
  /// **'Invalid OTP. Use \"{hint}\" for demo.'**
  String authErrorInvalidOtpWithHint(String hint);

  /// No description provided for @authErrorInvalidOtp.
  ///
  /// In en, this message translates to:
  /// **'Invalid OTP. Please try again.'**
  String get authErrorInvalidOtp;

  /// No description provided for @authErrorVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed. Please try again.'**
  String get authErrorVerificationFailed;

  /// No description provided for @authErrorProfileSetupFailed.
  ///
  /// In en, this message translates to:
  /// **'Profile setup failed: {detail}'**
  String authErrorProfileSetupFailed(String detail);

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @noRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get noRecentActivity;

  /// No description provided for @recentActivityHint.
  ///
  /// In en, this message translates to:
  /// **'Activity from shared profiles and connections will appear here'**
  String get recentActivityHint;

  /// No description provided for @profileSharedActivity.
  ///
  /// In en, this message translates to:
  /// **'Profile shared'**
  String get profileSharedActivity;

  /// No description provided for @connectionRequestActivity.
  ///
  /// In en, this message translates to:
  /// **'Connection request'**
  String get connectionRequestActivity;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back,'**
  String get welcomeBack;

  /// No description provided for @newBroker.
  ///
  /// In en, this message translates to:
  /// **'New Broker'**
  String get newBroker;

  /// No description provided for @gettingStarted.
  ///
  /// In en, this message translates to:
  /// **'Getting started'**
  String get gettingStarted;

  /// No description provided for @yrsExperience.
  ///
  /// In en, this message translates to:
  /// **'yrs experience'**
  String get yrsExperience;

  /// No description provided for @createProfileAction.
  ///
  /// In en, this message translates to:
  /// **'Create Profile'**
  String get createProfileAction;

  /// No description provided for @shareProfileAction.
  ///
  /// In en, this message translates to:
  /// **'Share Profile'**
  String get shareProfileAction;

  /// No description provided for @viewRequestsAction.
  ///
  /// In en, this message translates to:
  /// **'View Requests'**
  String get viewRequestsAction;

  /// No description provided for @connectedClients.
  ///
  /// In en, this message translates to:
  /// **'Connected Clients'**
  String get connectedClients;

  /// No description provided for @noConnectedClients.
  ///
  /// In en, this message translates to:
  /// **'No connected clients yet.'**
  String get noConnectedClients;

  /// No description provided for @brokerClientsHint.
  ///
  /// In en, this message translates to:
  /// **'When parents connect with you, they will appear here.'**
  String get brokerClientsHint;

  /// No description provided for @acceptedRequestFrom.
  ///
  /// In en, this message translates to:
  /// **'Accepted request from {name}'**
  String acceptedRequestFrom(String name);

  /// No description provided for @failedToAccept.
  ///
  /// In en, this message translates to:
  /// **'Failed to accept: {error}'**
  String failedToAccept(String error);

  /// No description provided for @declinedRequestFrom.
  ///
  /// In en, this message translates to:
  /// **'Declined request from {name}'**
  String declinedRequestFrom(String name);

  /// No description provided for @failedToDecline.
  ///
  /// In en, this message translates to:
  /// **'Failed to decline: {error}'**
  String failedToDecline(String error);

  /// No description provided for @lookingFor.
  ///
  /// In en, this message translates to:
  /// **'Looking for'**
  String get lookingFor;

  /// No description provided for @lookingForSection.
  ///
  /// In en, this message translates to:
  /// **'Looking For'**
  String get lookingForSection;

  /// No description provided for @listedWith.
  ///
  /// In en, this message translates to:
  /// **'Listed with'**
  String get listedWith;

  /// No description provided for @brokersLabel.
  ///
  /// In en, this message translates to:
  /// **'brokers'**
  String get brokersLabel;

  /// No description provided for @brokerConversationsHint.
  ///
  /// In en, this message translates to:
  /// **'When parents connect with you, conversations will appear here.'**
  String get brokerConversationsHint;

  /// No description provided for @managedProfiles.
  ///
  /// In en, this message translates to:
  /// **'Managed Profiles'**
  String get managedProfiles;

  /// No description provided for @noProfilesYetLabel.
  ///
  /// In en, this message translates to:
  /// **'No Profiles Yet'**
  String get noProfilesYetLabel;

  /// No description provided for @noProfilesYetHint.
  ///
  /// In en, this message translates to:
  /// **'No profiles yet. Create your first candidate profile.'**
  String get noProfilesYetHint;

  /// No description provided for @shareProfileWith.
  ///
  /// In en, this message translates to:
  /// **'Share Profile With'**
  String get shareProfileWith;

  /// No description provided for @noConnectedParents.
  ///
  /// In en, this message translates to:
  /// **'No connected parents to share with'**
  String get noConnectedParents;

  /// No description provided for @agencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Agency'**
  String get agencyLabel;

  /// No description provided for @experienceLabel.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experienceLabel;

  /// No description provided for @areasServedLabel.
  ///
  /// In en, this message translates to:
  /// **'Areas Served'**
  String get areasServedLabel;

  /// No description provided for @specializationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Specializations'**
  String get specializationsLabel;

  /// No description provided for @yearsLabel.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get yearsLabel;

  /// No description provided for @linkedToParent.
  ///
  /// In en, this message translates to:
  /// **'Linked to Parent'**
  String get linkedToParent;

  /// No description provided for @notLinked.
  ///
  /// In en, this message translates to:
  /// **'Not Linked'**
  String get notLinked;

  /// No description provided for @notLinkedHint.
  ///
  /// In en, this message translates to:
  /// **'You are not linked to any parent yet.'**
  String get notLinkedHint;

  /// No description provided for @linkAction.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get linkAction;

  /// No description provided for @profilesSharedWithYou.
  ///
  /// In en, this message translates to:
  /// **'Profiles Shared With You'**
  String get profilesSharedWithYou;

  /// No description provided for @profileAvailable.
  ///
  /// In en, this message translates to:
  /// **'profile available'**
  String get profileAvailable;

  /// No description provided for @profilesAvailable.
  ///
  /// In en, this message translates to:
  /// **'profiles available'**
  String get profilesAvailable;

  /// No description provided for @viewSharedProfiles.
  ///
  /// In en, this message translates to:
  /// **'View Shared Profiles'**
  String get viewSharedProfiles;

  /// No description provided for @seeProfilesForwardedByParent.
  ///
  /// In en, this message translates to:
  /// **'See profiles forwarded by your parent'**
  String get seeProfilesForwardedByParent;

  /// No description provided for @viewConnectionRequests.
  ///
  /// In en, this message translates to:
  /// **'View your connection requests'**
  String get viewConnectionRequests;

  /// No description provided for @markedAsInterested.
  ///
  /// In en, this message translates to:
  /// **'Marked as Interested'**
  String get markedAsInterested;

  /// No description provided for @markedAsPass.
  ///
  /// In en, this message translates to:
  /// **'Marked as Pass'**
  String get markedAsPass;

  /// No description provided for @linkToParentTitle.
  ///
  /// In en, this message translates to:
  /// **'Link to Parent'**
  String get linkToParentTitle;

  /// No description provided for @linkRequestSentTo.
  ///
  /// In en, this message translates to:
  /// **'Link request sent to {name}'**
  String linkRequestSentTo(String name);

  /// No description provided for @linkRequestMessage.
  ///
  /// In en, this message translates to:
  /// **'I would like to link my account to yours.'**
  String get linkRequestMessage;

  /// No description provided for @received.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get received;

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sent;

  /// No description provided for @requestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Request accepted'**
  String get requestAccepted;

  /// No description provided for @requestDeclined.
  ///
  /// In en, this message translates to:
  /// **'Request declined'**
  String get requestDeclined;

  /// No description provided for @connectedWith.
  ///
  /// In en, this message translates to:
  /// **'Connected with'**
  String get connectedWith;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @calling.
  ///
  /// In en, this message translates to:
  /// **'Calling'**
  String get calling;

  /// No description provided for @cityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityLabel;

  /// No description provided for @stateLabel.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get stateLabel;

  /// No description provided for @connectedBrokers.
  ///
  /// In en, this message translates to:
  /// **'Connected Brokers'**
  String get connectedBrokers;

  /// No description provided for @linkedChild.
  ///
  /// In en, this message translates to:
  /// **'Linked Child'**
  String get linkedChild;

  /// No description provided for @viewLinkRequests.
  ///
  /// In en, this message translates to:
  /// **'View Link Requests'**
  String get viewLinkRequests;

  /// No description provided for @agencyBrokersTitle.
  ///
  /// In en, this message translates to:
  /// **'Agency Brokers'**
  String get agencyBrokersTitle;

  /// No description provided for @notRegisteredBrokerFull.
  ///
  /// In en, this message translates to:
  /// **'{name} is not registered as a broker'**
  String notRegisteredBrokerFull(String name);

  /// No description provided for @inviteSentTo.
  ///
  /// In en, this message translates to:
  /// **'Invite sent to {phone}'**
  String inviteSentTo(String phone);

  /// No description provided for @agencyClientsTitle.
  ///
  /// In en, this message translates to:
  /// **'Agency Clients'**
  String get agencyClientsTitle;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @addNewBroker.
  ///
  /// In en, this message translates to:
  /// **'Add a new broker to your agency'**
  String get addNewBroker;

  /// No description provided for @agencySettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Agency settings saved!'**
  String get agencySettingsSaved;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @yrsExp.
  ///
  /// In en, this message translates to:
  /// **'yrs exp'**
  String get yrsExp;

  /// No description provided for @connectionRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Connection request sent!'**
  String get connectionRequestSent;

  /// No description provided for @profileCreated.
  ///
  /// In en, this message translates to:
  /// **'{name} created!'**
  String profileCreated(String name);

  /// No description provided for @bride.
  ///
  /// In en, this message translates to:
  /// **'Bride'**
  String get bride;

  /// No description provided for @groom.
  ///
  /// In en, this message translates to:
  /// **'Groom'**
  String get groom;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your Name'**
  String get yourName;

  /// No description provided for @enterYourFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterYourFullName;

  /// No description provided for @agencyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Agency Name'**
  String get agencyNameLabel;

  /// No description provided for @aboutYou.
  ///
  /// In en, this message translates to:
  /// **'About You'**
  String get aboutYou;

  /// No description provided for @aboutYouHint.
  ///
  /// In en, this message translates to:
  /// **'Tell families about your matchmaking experience...'**
  String get aboutYouHint;

  /// No description provided for @yearsOfExperience.
  ///
  /// In en, this message translates to:
  /// **'Years of Experience'**
  String get yearsOfExperience;

  /// No description provided for @lookingForA.
  ///
  /// In en, this message translates to:
  /// **'Looking for a'**
  String get lookingForA;

  /// No description provided for @iAmA.
  ///
  /// In en, this message translates to:
  /// **'I am a'**
  String get iAmA;

  /// No description provided for @yourAge.
  ///
  /// In en, this message translates to:
  /// **'Your Age'**
  String get yourAge;

  /// No description provided for @stepBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Info'**
  String get stepBasicInfo;

  /// No description provided for @stepAgencyDetails.
  ///
  /// In en, this message translates to:
  /// **'Agency Details'**
  String get stepAgencyDetails;

  /// No description provided for @stepContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get stepContact;

  /// No description provided for @stepExperience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get stepExperience;

  /// No description provided for @stepBusinessDetails.
  ///
  /// In en, this message translates to:
  /// **'Business Details'**
  String get stepBusinessDetails;

  /// No description provided for @stepChildDetails.
  ///
  /// In en, this message translates to:
  /// **'Child Details'**
  String get stepChildDetails;

  /// No description provided for @stepFamilyDetails.
  ///
  /// In en, this message translates to:
  /// **'Family Details'**
  String get stepFamilyDetails;

  /// No description provided for @stepPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get stepPersonal;

  /// No description provided for @agencyDetailsSection.
  ///
  /// In en, this message translates to:
  /// **'Agency Details'**
  String get agencyDetailsSection;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your agency and services...'**
  String get descriptionHint;

  /// No description provided for @specializationsCommaSeparated.
  ///
  /// In en, this message translates to:
  /// **'Specializations (comma-separated)'**
  String get specializationsCommaSeparated;

  /// No description provided for @contactInformationSection.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInformationSection;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @officePhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Office Phone'**
  String get officePhoneLabel;

  /// No description provided for @websiteOptional.
  ///
  /// In en, this message translates to:
  /// **'Website (optional)'**
  String get websiteOptional;

  /// No description provided for @addMoreDetailsLater.
  ///
  /// In en, this message translates to:
  /// **'You can add more details later from Agency Settings'**
  String get addMoreDetailsLater;

  /// No description provided for @experienceExpertiseSection.
  ///
  /// In en, this message translates to:
  /// **'Experience & Expertise'**
  String get experienceExpertiseSection;

  /// No description provided for @areasServedCommaSeparated.
  ///
  /// In en, this message translates to:
  /// **'Areas Served (comma-separated)'**
  String get areasServedCommaSeparated;

  /// No description provided for @languagesSpokenCommaSeparated.
  ///
  /// In en, this message translates to:
  /// **'Languages Spoken (comma-separated)'**
  String get languagesSpokenCommaSeparated;

  /// No description provided for @businessDetailsSection.
  ///
  /// In en, this message translates to:
  /// **'Business Details'**
  String get businessDetailsSection;

  /// No description provided for @officeAddressOptional.
  ///
  /// In en, this message translates to:
  /// **'Office Address (optional)'**
  String get officeAddressOptional;

  /// No description provided for @feeStructureOptional.
  ///
  /// In en, this message translates to:
  /// **'Fee Structure (optional)'**
  String get feeStructureOptional;

  /// No description provided for @workingHoursOptional.
  ///
  /// In en, this message translates to:
  /// **'Working Hours (optional)'**
  String get workingHoursOptional;

  /// No description provided for @childDetailsSection.
  ///
  /// In en, this message translates to:
  /// **'Your Child\'s Details'**
  String get childDetailsSection;

  /// No description provided for @childDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'This information helps brokers find suitable matches'**
  String get childDetailsHint;

  /// No description provided for @childNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Child\'s Name'**
  String get childNameLabel;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullNameHint;

  /// No description provided for @heightLabel.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get heightLabel;

  /// No description provided for @dietLabel.
  ///
  /// In en, this message translates to:
  /// **'Diet'**
  String get dietLabel;

  /// No description provided for @dietVegetarian.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get dietVegetarian;

  /// No description provided for @dietNonVeg.
  ///
  /// In en, this message translates to:
  /// **'Non-Veg'**
  String get dietNonVeg;

  /// No description provided for @dietEggetarian.
  ///
  /// In en, this message translates to:
  /// **'Eggetarian'**
  String get dietEggetarian;

  /// No description provided for @dietVegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get dietVegan;

  /// No description provided for @dietJain.
  ///
  /// In en, this message translates to:
  /// **'Jain'**
  String get dietJain;

  /// No description provided for @educationLabel.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get educationLabel;

  /// No description provided for @professionLabel.
  ///
  /// In en, this message translates to:
  /// **'Profession'**
  String get professionLabel;

  /// No description provided for @emailOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Your Email (optional)'**
  String get emailOptionalLabel;

  /// No description provided for @familyInformationSection.
  ///
  /// In en, this message translates to:
  /// **'Family Information'**
  String get familyInformationSection;

  /// No description provided for @familyTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Family Type'**
  String get familyTypeLabel;

  /// No description provided for @jointFamilyLabel.
  ///
  /// In en, this message translates to:
  /// **'Joint Family'**
  String get jointFamilyLabel;

  /// No description provided for @nuclearFamilyLabel.
  ///
  /// In en, this message translates to:
  /// **'Nuclear Family'**
  String get nuclearFamilyLabel;

  /// No description provided for @fatherOccupationLabel.
  ///
  /// In en, this message translates to:
  /// **'Father\'s Occupation'**
  String get fatherOccupationLabel;

  /// No description provided for @motherOccupationLabel.
  ///
  /// In en, this message translates to:
  /// **'Mother\'s Occupation'**
  String get motherOccupationLabel;

  /// No description provided for @aboutFamilyLabel.
  ///
  /// In en, this message translates to:
  /// **'About Family'**
  String get aboutFamilyLabel;

  /// No description provided for @aboutFamilyHint.
  ///
  /// In en, this message translates to:
  /// **'Briefly describe your family background...'**
  String get aboutFamilyHint;

  /// No description provided for @shareWithChildDesc.
  ///
  /// In en, this message translates to:
  /// **'Share this profile with your child for their opinion'**
  String get shareWithChildDesc;

  /// No description provided for @noChildLinkedMsg.
  ///
  /// In en, this message translates to:
  /// **'No child account is linked to your profile yet.'**
  String get noChildLinkedMsg;

  /// No description provided for @askChildToLink.
  ///
  /// In en, this message translates to:
  /// **'Ask your child to create an account and link it to yours.'**
  String get askChildToLink;

  /// No description provided for @linkedChildLabel.
  ///
  /// In en, this message translates to:
  /// **'Linked child'**
  String get linkedChildLabel;

  /// No description provided for @noChildLinkedLabel.
  ///
  /// In en, this message translates to:
  /// **'No child linked'**
  String get noChildLinkedLabel;

  /// No description provided for @profileForwardedTo.
  ///
  /// In en, this message translates to:
  /// **'Profile forwarded to {name}'**
  String profileForwardedTo(String name);

  /// No description provided for @forwardProfileButton.
  ///
  /// In en, this message translates to:
  /// **'Forward Profile'**
  String get forwardProfileButton;

  /// No description provided for @viewBrokerProfile.
  ///
  /// In en, this message translates to:
  /// **'View Broker Profile'**
  String get viewBrokerProfile;

  /// No description provided for @muteNotifications.
  ///
  /// In en, this message translates to:
  /// **'Mute Notifications'**
  String get muteNotifications;

  /// No description provided for @clearChat.
  ///
  /// In en, this message translates to:
  /// **'Clear Chat'**
  String get clearChat;

  /// No description provided for @callBroker.
  ///
  /// In en, this message translates to:
  /// **'Call Broker'**
  String get callBroker;

  /// No description provided for @startRecording.
  ///
  /// In en, this message translates to:
  /// **'Start Recording'**
  String get startRecording;

  /// No description provided for @voiceNoteComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Voice note feature coming soon!'**
  String get voiceNoteComingSoon;

  /// No description provided for @reportProfile.
  ///
  /// In en, this message translates to:
  /// **'Report Profile'**
  String get reportProfile;

  /// No description provided for @contactBroker.
  ///
  /// In en, this message translates to:
  /// **'Contact Broker'**
  String get contactBroker;

  /// No description provided for @shareFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Share feature coming soon!'**
  String get shareFeatureComingSoon;

  /// No description provided for @saveFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Save feature coming soon!'**
  String get saveFeatureComingSoon;

  /// No description provided for @saveToDevice.
  ///
  /// In en, this message translates to:
  /// **'Save to device'**
  String get saveToDevice;

  /// No description provided for @profileShareMessage.
  ///
  /// In en, this message translates to:
  /// **'Here\'s a profile I think would be perfect for you. Take a look at the details below.'**
  String get profileShareMessage;

  /// No description provided for @yourShortlist.
  ///
  /// In en, this message translates to:
  /// **'Your Shortlist'**
  String get yourShortlist;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @exportList.
  ///
  /// In en, this message translates to:
  /// **'Export list'**
  String get exportList;

  /// No description provided for @noProfilesInShortlist.
  ///
  /// In en, this message translates to:
  /// **'No profiles in shortlist'**
  String get noProfilesInShortlist;

  /// No description provided for @shortlistHint.
  ///
  /// In en, this message translates to:
  /// **'Profiles you save or show interest in will appear here'**
  String get shortlistHint;

  /// No description provided for @browseProfiles.
  ///
  /// In en, this message translates to:
  /// **'Browse Profiles'**
  String get browseProfiles;

  /// No description provided for @trustAndVerification.
  ///
  /// In en, this message translates to:
  /// **'Trust & Verification'**
  String get trustAndVerification;

  /// No description provided for @inviteVerifiers.
  ///
  /// In en, this message translates to:
  /// **'Invite Verifiers'**
  String get inviteVerifiers;

  /// No description provided for @sendInvites.
  ///
  /// In en, this message translates to:
  /// **'Send Invites'**
  String get sendInvites;

  /// No description provided for @completeVerification.
  ///
  /// In en, this message translates to:
  /// **'Complete Verification'**
  String get completeVerification;

  /// No description provided for @uploadDocuments.
  ///
  /// In en, this message translates to:
  /// **'Upload Documents'**
  String get uploadDocuments;

  /// No description provided for @trustReport.
  ///
  /// In en, this message translates to:
  /// **'Trust Report'**
  String get trustReport;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @startingFinancialDiscussion.
  ///
  /// In en, this message translates to:
  /// **'Starting financial discussion...'**
  String get startingFinancialDiscussion;

  /// No description provided for @weddingBudgetPlanner.
  ///
  /// In en, this message translates to:
  /// **'Wedding Budget Planner'**
  String get weddingBudgetPlanner;

  /// No description provided for @startPlanning.
  ///
  /// In en, this message translates to:
  /// **'Start Planning'**
  String get startPlanning;

  /// No description provided for @completeProfileAction.
  ///
  /// In en, this message translates to:
  /// **'Complete Profile'**
  String get completeProfileAction;

  /// No description provided for @completeNow.
  ///
  /// In en, this message translates to:
  /// **'Complete Now'**
  String get completeNow;

  /// No description provided for @financialCounseling.
  ///
  /// In en, this message translates to:
  /// **'Financial Counseling'**
  String get financialCounseling;

  /// No description provided for @bookSession.
  ///
  /// In en, this message translates to:
  /// **'Book Session'**
  String get bookSession;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @bookingInitiated.
  ///
  /// In en, this message translates to:
  /// **'booking initiated!'**
  String get bookingInitiated;

  /// No description provided for @joiningMeeting.
  ///
  /// In en, this message translates to:
  /// **'Joining meeting...'**
  String get joiningMeeting;

  /// No description provided for @rescheduleMeeting.
  ///
  /// In en, this message translates to:
  /// **'Reschedule Meeting'**
  String get rescheduleMeeting;

  /// No description provided for @rescheduleMeetingDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose a new time for your virtual family meet.'**
  String get rescheduleMeetingDesc;

  /// No description provided for @reschedule.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get reschedule;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @openingMeetingScheduler.
  ///
  /// In en, this message translates to:
  /// **'Opening meeting scheduler...'**
  String get openingMeetingScheduler;

  /// No description provided for @helpComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Help & Support coming soon'**
  String get helpComingSoon;

  /// No description provided for @helpLabel.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpLabel;

  /// Dev-only screen title — keep in English
  ///
  /// In en, this message translates to:
  /// **'Design System Demo'**
  String get designSystemDemo;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @telugu.
  ///
  /// In en, this message translates to:
  /// **'Telugu'**
  String get telugu;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @linked.
  ///
  /// In en, this message translates to:
  /// **'Linked'**
  String get linked;

  /// No description provided for @markedAsMaybe.
  ///
  /// In en, this message translates to:
  /// **'Marked as Maybe'**
  String get markedAsMaybe;

  /// No description provided for @typeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message'**
  String get typeAMessage;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @caste.
  ///
  /// In en, this message translates to:
  /// **'Caste'**
  String get caste;

  /// No description provided for @gotra.
  ///
  /// In en, this message translates to:
  /// **'Gotra'**
  String get gotra;

  /// No description provided for @manglikStatus.
  ///
  /// In en, this message translates to:
  /// **'Manglik Status'**
  String get manglikStatus;

  /// No description provided for @annualIncome.
  ///
  /// In en, this message translates to:
  /// **'Annual Income'**
  String get annualIncome;

  /// No description provided for @complexion.
  ///
  /// In en, this message translates to:
  /// **'Complexion'**
  String get complexion;

  /// No description provided for @smoking.
  ///
  /// In en, this message translates to:
  /// **'Smoking'**
  String get smoking;

  /// No description provided for @drinking.
  ///
  /// In en, this message translates to:
  /// **'Drinking'**
  String get drinking;

  /// No description provided for @ownHouse.
  ///
  /// In en, this message translates to:
  /// **'Own House'**
  String get ownHouse;

  /// No description provided for @ownCar.
  ///
  /// In en, this message translates to:
  /// **'Own Car'**
  String get ownCar;

  /// No description provided for @willingToRelocate.
  ///
  /// In en, this message translates to:
  /// **'Willing to Relocate'**
  String get willingToRelocate;

  /// No description provided for @rashi.
  ///
  /// In en, this message translates to:
  /// **'Rashi'**
  String get rashi;

  /// No description provided for @nakshatra.
  ///
  /// In en, this message translates to:
  /// **'Nakshatra'**
  String get nakshatra;

  /// No description provided for @birthPlace.
  ///
  /// In en, this message translates to:
  /// **'Birth Place'**
  String get birthPlace;

  /// No description provided for @birthTime.
  ///
  /// In en, this message translates to:
  /// **'Birth Time'**
  String get birthTime;

  /// No description provided for @familyValues.
  ///
  /// In en, this message translates to:
  /// **'Family Values'**
  String get familyValues;

  /// No description provided for @siblings.
  ///
  /// In en, this message translates to:
  /// **'Siblings'**
  String get siblings;

  /// No description provided for @brothers.
  ///
  /// In en, this message translates to:
  /// **'Brothers'**
  String get brothers;

  /// No description provided for @sisters.
  ///
  /// In en, this message translates to:
  /// **'Sisters'**
  String get sisters;

  /// No description provided for @childLabel.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get childLabel;

  /// No description provided for @brokerSharesHint.
  ///
  /// In en, this message translates to:
  /// **'Your connected brokers will share profiles here for your review'**
  String get brokerSharesHint;

  /// No description provided for @lookingForValue.
  ///
  /// In en, this message translates to:
  /// **'Looking for {value}'**
  String lookingForValue(String value);

  /// No description provided for @resultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} results'**
  String resultsCount(String count);

  /// No description provided for @personalInformationSection.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformationSection;

  /// No description provided for @canCompleteLater.
  ///
  /// In en, this message translates to:
  /// **'You can complete more details from your profile later'**
  String get canCompleteLater;

  /// No description provided for @candidateLinkHint.
  ///
  /// In en, this message translates to:
  /// **'You can link to your parent later and they can fill detailed profile information'**
  String get candidateLinkHint;

  /// No description provided for @candidateInfoBox.
  ///
  /// In en, this message translates to:
  /// **'After creating your account, link to your parent from the Home screen. Your parent and broker will manage detailed profile information.'**
  String get candidateInfoBox;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
