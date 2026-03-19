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
    // Open all boxes
    final usersBox = await Hive.openBox<String>('users');
    final sessionBox = await Hive.openBox<String>('session');
    final agenciesBox = await Hive.openBox<String>('agencies');
    final brokerProfilesBox = await Hive.openBox<String>('brokerProfiles');
    final parentProfilesBox = await Hive.openBox<String>('parentProfiles');
    final candidateProfilesBox =
        await Hive.openBox<String>('candidateProfiles');
    final linkRequestsBox = await Hive.openBox<String>('linkRequests');
    final sharedProfilesBox = await Hive.openBox<String>('sharedProfiles');
    final conversationsBox = await Hive.openBox<String>('conversations');
    final messagesBox = await Hive.openBox<String>('messages');

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
