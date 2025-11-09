import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:testing_flutter/core/providers/theme_provider.dart';
import 'package:testing_flutter/core/theme/app_theme.dart';
import 'package:testing_flutter/screens/main_navigation.dart';

void main() {
  runApp(const ProviderScope(child: AnuyatraApp()));
}

class AnuyatraApp extends ConsumerWidget {
  const AnuyatraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch theme mode from provider for dark mode support
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Anuyātrā - The Real Matrimony App',

      // New comprehensive themes with Material Design 3
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode, // User-controlled theme mode

      home: const MainNavigationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
