import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:testing_flutter/core/data/repositories/auth_repository.dart';
import 'package:testing_flutter/core/data/repositories/user_repository.dart';
import 'package:testing_flutter/core/data/repositories/agency_repository.dart';
import 'package:testing_flutter/core/data/repositories/broker_repository.dart';
import 'package:testing_flutter/core/data/repositories/profile_repository.dart';
import 'package:testing_flutter/core/data/repositories/link_repository.dart';
import 'package:testing_flutter/core/data/repositories/shared_profile_repository.dart';
import 'package:testing_flutter/core/data/repositories/messaging_repository.dart';
import 'package:testing_flutter/core/data/repositories/saved_profile_repository.dart';
import 'package:testing_flutter/core/data/repositories/viewed_profile_repository.dart';
import 'package:testing_flutter/core/data/repositories/activity_repository.dart';
import 'package:testing_flutter/core/data/repositories/parent_note_repository.dart';
import 'package:testing_flutter/core/data/repositories/broker_note_repository.dart';
import 'package:testing_flutter/core/data/repositories/meeting_repository.dart';
import 'package:testing_flutter/core/data/repositories/client_engagement_repository.dart';
import 'package:testing_flutter/core/data/repositories/broker_follow_up_repository.dart';

/// All repository providers throw [UnimplementedError] by default.
/// They MUST be overridden in [ProviderScope] using values from
/// [AppDataModule] before any widget reads them.
///
/// ```dart
/// ProviderScope(
///   overrides: [
///     authRepositoryProvider.overrideWithValue(module.authRepository),
///     userRepositoryProvider.overrideWithValue(module.userRepository),
///     // ...
///   ],
///   child: const MyApp(),
/// )
/// ```

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  throw UnimplementedError(
      'authRepositoryProvider must be overridden in ProviderScope');
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  throw UnimplementedError(
      'userRepositoryProvider must be overridden in ProviderScope');
});

final agencyRepositoryProvider = Provider<AgencyRepository>((ref) {
  throw UnimplementedError(
      'agencyRepositoryProvider must be overridden in ProviderScope');
});

final brokerRepositoryProvider = Provider<BrokerRepository>((ref) {
  throw UnimplementedError(
      'brokerRepositoryProvider must be overridden in ProviderScope');
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  throw UnimplementedError(
      'profileRepositoryProvider must be overridden in ProviderScope');
});

final linkRepositoryProvider = Provider<LinkRepository>((ref) {
  throw UnimplementedError(
      'linkRepositoryProvider must be overridden in ProviderScope');
});

final sharedProfileRepositoryProvider =
    Provider<SharedProfileRepository>((ref) {
  throw UnimplementedError(
      'sharedProfileRepositoryProvider must be overridden in ProviderScope');
});

final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  throw UnimplementedError(
      'messagingRepositoryProvider must be overridden in ProviderScope');
});

final savedProfileRepositoryProvider = Provider<SavedProfileRepository>((ref) {
  throw UnimplementedError(
      'savedProfileRepositoryProvider must be overridden in ProviderScope');
});

final viewedProfileRepositoryProvider =
    Provider<ViewedProfileRepository>((ref) {
  throw UnimplementedError(
      'viewedProfileRepositoryProvider must be overridden in ProviderScope');
});

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  throw UnimplementedError(
      'activityRepositoryProvider must be overridden in ProviderScope');
});

final parentNoteRepositoryProvider = Provider<ParentNoteRepository>((ref) {
  throw UnimplementedError(
      'parentNoteRepositoryProvider must be overridden in ProviderScope');
});

final brokerNoteRepositoryProvider = Provider<BrokerNoteRepository>((ref) {
  throw UnimplementedError(
      'brokerNoteRepositoryProvider must be overridden in ProviderScope');
});

final meetingRepositoryProvider = Provider<MeetingRepository>((ref) {
  throw UnimplementedError(
      'meetingRepositoryProvider must be overridden in ProviderScope');
});

final clientEngagementRepositoryProvider =
    Provider<ClientEngagementRepository>((ref) {
  throw UnimplementedError(
      'clientEngagementRepositoryProvider must be overridden in ProviderScope');
});

final brokerFollowUpRepositoryProvider =
    Provider<BrokerFollowUpRepository>((ref) {
  throw UnimplementedError(
      'brokerFollowUpRepositoryProvider must be overridden in ProviderScope');
});
