import 'package:hive_ce/hive.dart';

import 'package:testing_flutter/core/data/repositories/auth_repository.dart';
import 'package:testing_flutter/core/data/repositories/user_repository.dart';
import 'package:testing_flutter/core/data/repositories/agency_repository.dart';
import 'package:testing_flutter/core/data/repositories/broker_repository.dart';
import 'package:testing_flutter/core/data/repositories/profile_repository.dart';
import 'package:testing_flutter/core/data/repositories/link_repository.dart';
import 'package:testing_flutter/core/data/repositories/shared_profile_repository.dart';
import 'package:testing_flutter/core/data/repositories/messaging_repository.dart';

import 'package:testing_flutter/core/data/local/hive_auth_repository.dart';
import 'package:testing_flutter/core/data/local/hive_user_repository.dart';
import 'package:testing_flutter/core/data/local/hive_agency_repository.dart';
import 'package:testing_flutter/core/data/local/hive_broker_repository.dart';
import 'package:testing_flutter/core/data/local/hive_profile_repository.dart';
import 'package:testing_flutter/core/data/local/hive_link_repository.dart';
import 'package:testing_flutter/core/data/local/hive_shared_profile_repository.dart';
import 'package:testing_flutter/core/data/local/hive_messaging_repository.dart';

/// Hive box names. Kept as constants so they are referenced by symbol
/// rather than copy-pasted literals — a typo would silently create a new
/// (empty) box instead of opening the existing data.
class _HiveBoxes {
  _HiveBoxes._();
  static const users = 'users';
  static const session = 'session';
  static const agencies = 'agencies';
  static const brokerProfiles = 'brokerProfiles';
  static const parentProfiles = 'parentProfiles';
  static const candidateProfiles = 'candidateProfiles';
  static const linkRequests = 'linkRequests';
  static const sharedProfiles = 'sharedProfiles';
  static const conversations = 'conversations';
  static const messages = 'messages';
}

/// Factory that creates and wires all repository implementations.
///
/// This is the single DI root for the app. To switch from local Hive
/// storage to a remote backend, add an `initRemote()` factory and
/// change one call in `main.dart`.
///
/// ```dart
/// // Today:
/// final module = await AppDataModule.initLocal();
///
/// // Future:
/// final module = await AppDataModule.initRemote(config);
/// ```
class AppDataModule {
  final AuthRepository authRepository;
  final UserRepository userRepository;
  final AgencyRepository agencyRepository;
  final BrokerRepository brokerRepository;
  final ProfileRepository profileRepository;
  final LinkRepository linkRepository;
  final SharedProfileRepository sharedProfileRepository;
  final MessagingRepository messagingRepository;

  AppDataModule._({
    required this.authRepository,
    required this.userRepository,
    required this.agencyRepository,
    required this.brokerRepository,
    required this.profileRepository,
    required this.linkRepository,
    required this.sharedProfileRepository,
    required this.messagingRepository,
  });

  /// Initialize with Hive local storage.
  ///
  /// Opens all required Hive boxes, creates the Hive-backed repository
  /// implementations, and wires cross-repository dependencies.
  static Future<AppDataModule> initLocal() async {
    // Open all boxes in parallel — they're independent, and Hive box
    // opens are I/O-bound. Cuts cold-start vs sequential awaits.
    final boxes = await Future.wait([
      Hive.openBox<String>(_HiveBoxes.users),
      Hive.openBox<String>(_HiveBoxes.session),
      Hive.openBox<String>(_HiveBoxes.agencies),
      Hive.openBox<String>(_HiveBoxes.brokerProfiles),
      Hive.openBox<String>(_HiveBoxes.parentProfiles),
      Hive.openBox<String>(_HiveBoxes.candidateProfiles),
      Hive.openBox<String>(_HiveBoxes.linkRequests),
      Hive.openBox<String>(_HiveBoxes.sharedProfiles),
      Hive.openBox<String>(_HiveBoxes.conversations),
      Hive.openBox<String>(_HiveBoxes.messages),
    ]);
    final usersBox = boxes[0];
    final sessionBox = boxes[1];
    final agenciesBox = boxes[2];
    final brokerProfilesBox = boxes[3];
    final parentProfilesBox = boxes[4];
    final candidateProfilesBox = boxes[5];
    final linkRequestsBox = boxes[6];
    final sharedProfilesBox = boxes[7];
    final conversationsBox = boxes[8];
    final messagesBox = boxes[9];

    // Create repositories (order matters for dependency wiring)
    final authRepo = HiveAuthRepository();

    final userRepo = HiveUserRepository(
      usersBox: usersBox,
      sessionBox: sessionBox,
    );

    final agencyRepo = HiveAgencyRepository(
      agenciesBox: agenciesBox,
      usersBox: usersBox,
    );

    final sharedProfileRepo = HiveSharedProfileRepository(
      sharedProfilesBox: sharedProfilesBox,
    );

    final messagingRepo = HiveMessagingRepository(
      conversationsBox: conversationsBox,
      messagesBox: messagesBox,
    );

    final profileRepo = HiveProfileRepository(
      parentProfilesBox: parentProfilesBox,
      candidateProfilesBox: candidateProfilesBox,
    );

    final brokerRepo = HiveBrokerRepository(
      brokerProfilesBox: brokerProfilesBox,
    );

    final linkRepo = HiveLinkRepository(
      linkRequestsBox: linkRequestsBox,
    );

    // Wire cross-repository dependencies
    profileRepo.init(sharedProfileRepo: sharedProfileRepo);

    brokerRepo.init(
      linkRepo: linkRepo,
      profileRepo: profileRepo,
      sharedProfileRepo: sharedProfileRepo,
    );

    linkRepo.init(
      userRepo: userRepo,
      brokerRepo: brokerRepo,
      agencyRepo: agencyRepo,
      messagingRepo: messagingRepo,
    );

    return AppDataModule._(
      authRepository: authRepo,
      userRepository: userRepo,
      agencyRepository: agencyRepo,
      brokerRepository: brokerRepo,
      profileRepository: profileRepo,
      linkRepository: linkRepo,
      sharedProfileRepository: sharedProfileRepo,
      messagingRepository: messagingRepo,
    );
  }
}
