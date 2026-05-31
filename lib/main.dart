import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:testing_flutter/core/providers/theme_provider.dart';
import 'package:testing_flutter/core/providers/locale_provider.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/core/theme/app_theme.dart';
import 'package:testing_flutter/core/routing/app_router.dart';
import 'package:testing_flutter/core/data/app_data_module.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/l10n/l10n_extension.dart';
import 'package:testing_flutter/data/seed_data.dart';
import 'package:testing_flutter/l10n/app_localizations.dart';

void main() async {
  // Wrap everything in error handling to prevent silent crashes
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      // Initialize Hive local storage
      await Hive.initFlutter();

      // Initialize the repository layer (opens all Hive boxes internally)
      final dataModule = await AppDataModule.initLocal();

      // Seed demo data ONLY on first launch (when the user store is empty).
      // The seeder itself re-checks `userRepository.isEmpty` so re-runs are safe.
      if (await dataModule.userRepository.isEmpty) {
        debugPrint('First launch detected - seeding demo data...');
        await seedDemoData(dataModule);
        debugPrint('Demo data seeded successfully');
      }

      // Pre-resolve auth state BEFORE runApp so the router's first redirect
      // already sees the correct authenticated/unauthenticated state.
      // Eliminates the role-selection screen flash on cold start for logged-in users.
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
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      // Resolved at the localized layer so the OS task-switcher title
      // honours the active locale.
      onGenerateTitle: (ctx) => ctx.l10n.appTitle,

      // Localization
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

      // Material Design 3 themes
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // GoRouter for declarative role-based navigation
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
