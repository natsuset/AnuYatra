import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:testing_flutter/core/providers/theme_provider.dart';
import 'package:testing_flutter/core/providers/locale_provider.dart';
import 'package:testing_flutter/core/providers/palette_provider.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/core/theme/app_theme.dart';
import 'package:testing_flutter/core/routing/app_router.dart';
import 'package:testing_flutter/core/data/app_data_module.dart';
import 'package:testing_flutter/core/data/remote/app_config.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/l10n/l10n_extension.dart';
import 'package:testing_flutter/data/seed_data.dart';
import 'package:testing_flutter/l10n/app_localizations.dart';

// ┌─────────────────────────────────────────────────────────────────┐
// │  CONFIGURATION                                                  │
// │  Flip between local seed-data mode and live Go backend here.    │
// │  Everything else (screens, providers, routing) is unaware.      │
// └─────────────────────────────────────────────────────────────────┘
const _config = AppConfig(
  dataSource: DataSource.local, // ← change to DataSource.remote to use backend
  apiBaseUrl: 'http://localhost:8080',
);

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      final AppDataModule dataModule;

      if (_config.isLocal) {
        await Hive.initFlutter();
        dataModule = await AppDataModule.initLocal();

        if (await dataModule.userRepository.isEmpty) {
          debugPrint('First launch detected - seeding demo data...');
          await seedDemoData(dataModule);
          debugPrint('Demo data seeded successfully');
        }
      } else {
        dataModule = await AppDataModule.initRemote(
          apiBaseUrl: _config.apiBaseUrl,
        );
      }

      final currentUser = await dataModule.userRepository.getCurrentUser();
      final AuthState initialAuthState = currentUser != null
          ? AuthAuthenticated(user: currentUser)
          : const AuthInitial();

      // Allow runtime font fetching — on devices with network access,
      // Inter and Poppins will load from Google Fonts CDN.
      // On restricted environments (sandboxed simulators), they gracefully
      // fall back to system default fonts.
      GoogleFonts.config.allowRuntimeFetching = true;

      runApp(
        ProviderScope(
          overrides: [
            authInitialStateProvider.overrideWithValue(initialAuthState),
            authRepositoryProvider
                .overrideWithValue(dataModule.authRepository),
            userRepositoryProvider
                .overrideWithValue(dataModule.userRepository),
            agencyRepositoryProvider
                .overrideWithValue(dataModule.agencyRepository),
            brokerRepositoryProvider
                .overrideWithValue(dataModule.brokerRepository),
            profileRepositoryProvider
                .overrideWithValue(dataModule.profileRepository),
            linkRepositoryProvider
                .overrideWithValue(dataModule.linkRepository),
            sharedProfileRepositoryProvider
                .overrideWithValue(dataModule.sharedProfileRepository),
            messagingRepositoryProvider
                .overrideWithValue(dataModule.messagingRepository),
            savedProfileRepositoryProvider
                .overrideWithValue(dataModule.savedProfileRepository),
            viewedProfileRepositoryProvider
                .overrideWithValue(dataModule.viewedProfileRepository),
            activityRepositoryProvider
                .overrideWithValue(dataModule.activityRepository),
            parentNoteRepositoryProvider
                .overrideWithValue(dataModule.parentNoteRepository),
            brokerNoteRepositoryProvider
                .overrideWithValue(dataModule.brokerNoteRepository),
            meetingRepositoryProvider
                .overrideWithValue(dataModule.meetingRepository),
            clientEngagementRepositoryProvider
                .overrideWithValue(dataModule.clientEngagementRepository),
            brokerFollowUpRepositoryProvider
                .overrideWithValue(dataModule.brokerFollowUpRepository),
          ],
          child: const AnuyatraApp(),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Error initializing app: $error');
      debugPrint('Stack trace: $stackTrace');
      // Show error screen
      runApp(MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Error initializing app: $error'),
          ),
        ),
      ));
    }
  }, (error, stackTrace) {
    debugPrint('Uncaught error: $error');
    debugPrint('Stack trace: $stackTrace');
  });
}

class AnuyatraApp extends ConsumerWidget {
  const AnuyatraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final palette = ref.watch(paletteProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      // Resolved at the localized layer so the OS task-switcher title
      // honours the active locale.
      onGenerateTitle: (ctx) => ctx.l10n.appTitle,

      // Localization
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

      // Material Design 3 themes — projected from the active palette so
      // live tinkerer edits trigger a single MaterialApp rebuild.
      theme: AppTheme.lightTheme(palette),
      darkTheme: AppTheme.darkTheme(palette),
      themeMode: themeMode,

      // GoRouter for declarative role-based navigation
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
