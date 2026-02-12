import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:testing_flutter/core/providers/theme_provider.dart';
import 'package:testing_flutter/core/theme/app_theme.dart';
import 'package:testing_flutter/core/routing/app_router.dart';
import 'package:testing_flutter/core/services/local_storage_service.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/data/seed_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive local storage
  await Hive.initFlutter();

  // Initialize storage service and seed data
  final storage = LocalStorageService();
  await storage.init();
  await seedDemoData(storage);

  // Allow runtime font fetching — on devices with network access,
  // Inter and Poppins will load from Google Fonts CDN.
  // On restricted environments (sandboxed simulators), they gracefully
  // fall back to system default fonts.
  GoogleFonts.config.allowRuntimeFetching = true;

  runApp(
    ProviderScope(
      overrides: [
        // Provide the already-initialized storage service
        localStorageServiceProvider.overrideWithValue(storage),
      ],
      child: const AnuyatraApp(),
    ),
  );
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
    // Check auth status on app start
    Future.microtask(() {
      ref.read(authProvider.notifier).checkAuthStatus();
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
