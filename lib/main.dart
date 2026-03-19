import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:testing_flutter/core/providers/theme_provider.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/core/theme/app_theme.dart';
import 'package:testing_flutter/core/routing/app_router.dart';
import 'package:testing_flutter/core/data/app_data_module.dart';
import 'package:testing_flutter/core/services/local_storage_service.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/data/seed_data.dart';

void main() async {
  // Wrap everything in error handling to prevent silent crashes
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      // Initialize Hive local storage
      await Hive.initFlutter();

      // Initialize the repository layer (opens all Hive boxes internally)
      final dataModule = await AppDataModule.initLocal();

      // Initialize legacy storage service (shares the same Hive boxes).
      // Screens will be migrated to repository providers incrementally;
      // until then, both coexist reading from the same underlying boxes.
      final storage = LocalStorageService();
      await storage.init();

      // Seed demo data ONLY on first launch (when database is empty)
      // This only runs once - subsequent app opens skip this entirely
      if (storage.isFirstLaunch) {
        debugPrint('First launch detected - seeding demo data...');
        await seedDemoData(storage);
        debugPrint('Demo data seeded successfully');
      }

      // Allow runtime font fetching — on devices with network access,
      // Inter and Poppins will load from Google Fonts CDN.
      // On restricted environments (sandboxed simulators), they gracefully
      // fall back to system default fonts.
      GoogleFonts.config.allowRuntimeFetching = true;

      runApp(
        ProviderScope(
          overrides: [
            // Legacy storage provider (screens still use this)
            localStorageServiceProvider.overrideWithValue(storage),
            // New repository providers
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

class AnuyatraApp extends ConsumerStatefulWidget {
  const AnuyatraApp({super.key});

  @override
  ConsumerState<AnuyatraApp> createState() => _AnuyatraAppState();
}

class _AnuyatraAppState extends ConsumerState<AnuyatraApp> {
  @override
  void initState() {
    super.initState();
    // Check auth status on app start - defer to avoid router race condition
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(authProvider.notifier).checkAuthStatus().catchError((error) {
          debugPrint('Error checking auth status: $error');
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch theme mode from provider for dark mode support
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Anuyatra - The Real Matrimony App',

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
