# Anuyātrā App - Architecture Documentation

## 🎯 Overview

This document describes the production-ready architecture implemented for the Anuyātrā matrimony application. The architecture follows industry best practices including **Atomic Design**, **Riverpod State Management**, **Material Design 3**, and **SOLID principles**.

---

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point (use main_new.dart for new arch)
├── main_new.dart                # New architecture entry point
│
├── core/                        # Core application infrastructure
│   ├── constants/               # Design system constants
│   │   ├── app_colors.dart      # Complete color palette
│   │   ├── app_typography.dart  # Typography system
│   │   ├── app_spacing.dart     # Spacing & sizing system
│   │   └── app_shadows.dart     # Shadow & elevation system
│   │
│   ├── theme/                   # Theme configuration
│   │   ├── app_theme.dart       # Light & dark theme definitions
│   │   └── theme_extensions.dart # Context extensions for easy access
│   │
│   └── providers/               # Global providers
│       └── theme_provider.dart  # Theme mode management
│
├── common/                      # Shared/reusable code
│   ├── widgets/                 # Atomic design components
│   │   ├── atoms/              # Basic building blocks
│   │   │   ├── app_button.dart
│   │   │   ├── app_avatar.dart
│   │   │   └── app_loading.dart
│   │   ├── molecules/          # Composite components
│   │   └── organisms/          # Complex components
│   │
│   ├── animations/              # Animation utilities
│   │   └── app_animations.dart
│   │
│   └── utils/                   # Utility functions
│
├── features/                    # Feature modules (Future)
│   ├── auth/
│   ├── profiles/
│   └── chat/
│
├── screens/                     # Existing screens (Legacy)
│   ├── home_screen.dart
│   ├── shortlist_screen.dart
│   └── ...
│
├── models/                      # Data models (Legacy)
├── widgets/                     # Custom widgets (Legacy)
├── data/                        # Mock data
└── theme/                       # Old theme (Legacy)
```

---

## 🎨 Design System

### 1. Colors (`app_colors.dart`)

The app uses a semantic color system that adapts to both light and dark themes:

**Brand Colors:**
- `sacredSaffron` (#FF8C42) - Primary CTA color
- `deepMaroon` (#8B2635) - Secondary/header color

**Theme-Aware Colors:**
- Light: `lightBackground`, `lightSurface`, `lightPrimaryText`, etc.
- Dark: `darkBackground`, `darkSurface`, `darkPrimaryText`, etc.

**Semantic Colors:**
- `success` - Green for positive actions
- `error` - Red for errors
- `warning` - Amber for pending states
- `info` - Blue for information

**Usage:**
```dart
// Direct access
Container(color: AppColors.sacredSaffron)

// Via context extension
Container(color: context.primaryColor)

// Via theme
Container(color: theme.colorScheme.primary)
```

### 2. Typography (`app_typography.dart`)

Material Design 3 type scale using Google Fonts (Inter & Poppins):

**Display Styles** - Large, expressive text
- `displayLarge` (57px) → Hero headlines
- `displayMedium` (45px) → Large headlines
- `displaySmall` (36px) → Small headlines

**Headline Styles** - High emphasis
- `headlineLarge` (32px)
- `headlineMedium` (28px)
- `headlineSmall` (24px)

**Title Styles** - Medium emphasis
- `titleLarge` (22px)
- `titleMedium` (16px)
- `titleSmall` (14px)

**Body Styles** - Main content
- `bodyLarge` (16px)
- `bodyMedium` (14px)
- `bodySmall` (12px)

**Usage:**
```dart
// Via extension
Text('Hello', style: context.headlineMedium)

// Direct access
Text('Hello', style: AppTypography.headlineMedium())

// Via theme
Text('Hello', style: theme.textTheme.headlineMedium)
```

### 3. Spacing (`app_spacing.dart`)

4px baseline grid system:

**Spacing Values:**
- `xxxs` (2px), `xxs` (4px), `xs` (8px)
- `sm` (12px), `md` (16px), `lg` (24px)
- `xl` (32px), `xxl` (48px), `xxxl` (64px)

**Presets:**
```dart
EdgeInsets.all(AppSpacing.md)          // All sides
AppSpacing.horizontalMd                 // Horizontal only
AppSpacing.cardPadding                  // Card padding
AppSpacing.screenPadding                // Screen edges
```

**Extensions:**
```dart
16.verticalSpace     // SizedBox(height: 16)
24.horizontalSpace   // SizedBox(width: 24)
```

**Border Radius:**
```dart
AppSpacing.roundedSm       // 8px radius
AppSpacing.cardRadius      // 12px radius
AppSpacing.buttonRadius    // Pill shape
```

### 4. Shadows (`app_shadows.dart`)

Elevation system with semantic names:

```dart
AppShadows.card      // Default card shadow
AppShadows.button    // Subtle button shadow
AppShadows.dialog    // Strong dialog shadow
AppShadows.primary   // Colored shadow (saffron)
```

---

## 🧩 Atomic Design Components

### Atoms (Basic Building Blocks)

#### `AppButton`
```dart
// Primary button
AppButton.primary(
  label: 'Continue',
  onPressed: () {},
  leadingIcon: Icons.arrow_forward,
  size: AppButtonSize.large,
  isLoading: false,
  isFullWidth: true,
)

// Outline button
AppButton.outline(
  label: 'Cancel',
  onPressed: () {},
)

// Danger button
AppButton.danger(
  label: 'Delete',
  onPressed: () {},
  leadingIcon: Icons.delete,
)
```

#### `AppAvatar`
```dart
AppAvatar(
  imageUrl: 'https://...',
  name: 'John Doe',
  size: AvatarSize.md,
  showBadge: true,          // Online indicator
  badgeColor: AppColors.success,
  showBorder: true,
  onTap: () {},
)
```

#### `AppLoadingIndicator`
```dart
// Simple loader
AppLoadingIndicator()

// With message
AppLoadingIndicator.large(
  message: 'Loading profiles...',
)

// Fullscreen overlay
AppLoadingOverlay(
  message: 'Please wait...',
)
```

---

## 🔄 State Management (Riverpod)

### Theme Management

```dart
// Theme provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

// Usage in widgets
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);
    
    // Toggle theme
    IconButton(
      icon: Icon(Icons.dark_mode),
      onPressed: () => themeNotifier.toggleTheme(),
    );
  }
}
```

### Creating New Providers

```dart
// 1. Define state notifier
class ProfilesNotifier extends StateNotifier<AsyncValue<List<Profile>>> {
  ProfilesNotifier() : super(const AsyncValue.loading()) {
    loadProfiles();
  }
  
  Future<void> loadProfiles() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await repository.getProfiles();
    });
  }
}

// 2. Create provider
final profilesProvider = StateNotifierProvider<ProfilesNotifier, AsyncValue<List<Profile>>>(
  (ref) => ProfilesNotifier(),
);

// 3. Use in widgets
class ProfileList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);
    
    return profilesAsync.when(
      data: (profiles) => ListView.builder(...),
      loading: () => AppLoadingIndicator(),
      error: (err, stack) => ErrorView(message: err.toString()),
    );
  }
}
```

---

## 🎭 Theme System

### Light & Dark Themes

The app automatically adapts to light/dark mode:

```dart
// In main.dart
MaterialApp(
  theme: AppTheme.lightTheme,        // Light theme config
  darkTheme: AppTheme.darkTheme,     // Dark theme config
  themeMode: themeMode,              // User preference
)
```

### Context Extensions

Easy access to theme properties:

```dart
// Colors
context.primaryColor
context.backgroundColor
context.primaryTextColor
context.dividerColor

// Typography
context.headlineLarge
context.bodyMedium
context.labelSmall

// Spacing
context.md          // 16.0
context.paddingMd   // EdgeInsets.all(16)
context.roundedMd   // BorderRadius.circular(12)

// Screen info
context.screenWidth
context.screenHeight
context.isDarkMode
context.isMobile
context.isTablet
```

### Responsive Design

```dart
// Get responsive value
final padding = context.responsive(
  mobile: 16.0,
  tablet: 24.0,
  desktop: 32.0,
);

// Breakpoints
context.isMobile    // < 600px
context.isTablet    // 600-1200px
context.isDesktop   // > 1200px

// Percentage of screen
context.widthPercent(50)   // 50% of screen width
context.heightPercent(30)  // 30% of screen height
```

---

## 🎬 Animations

### Built-in Animations

```dart
// Fade in with slide up
FadeInUp(
  delay: Duration(milliseconds: 100),
  child: ProfileCard(...),
)

// Scale in
ScaleIn(
  delay: Duration(milliseconds: 200),
  child: ActionButton(...),
)

// Shimmer loading effect
ShimmerLoading(
  child: Container(...),
)
```

### Animation Constants

```dart
// Durations
AppAnimations.fast      // 200ms
AppAnimations.normal    // 300ms
AppAnimations.slow      // 500ms

// Curves
AppAnimations.standard   // easeInOut
AppAnimations.decelerate // easeOut
AppAnimations.emphasized // Material 3 emphasized
```

---

## 🚀 Usage Guide

### 1. Switching to New Architecture

**Step 1:** Replace `lib/main.dart` content with `lib/main_new.dart`

```dart
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
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Anuyātrā',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const MainNavigationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
```

**Step 2:** Add theme toggle to any screen:

```dart
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          // Theme toggle button
          IconButton(
            icon: Icon(
              context.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
        ],
      ),
      body: ...,
    );
  }
}
```

### 2. Using Components

```dart
import 'package:testing_flutter/common/widgets/atoms/app_button.dart';
import 'package:testing_flutter/core/theme/theme_extensions.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: context.screenPadding,
        children: [
          Text('Welcome', style: context.headlineLarge),
          AppSpacing.md.verticalSpace,
          AppButton.primary(
            label: 'Get Started',
            onPressed: () {},
            leadingIcon: Icons.rocket_launch,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }
}
```

---

## 📋 Migration Checklist

- [x] Setup dependencies (Riverpod, Google Fonts, SharedPreferences)
- [x] Create design system (Colors, Typography, Spacing, Shadows)
- [x] Build theming infrastructure (Light/Dark themes, Extensions)
- [x] Implement theme management (Provider, Persistence)
- [x] Create atomic components (Buttons, Avatars, Loading)
- [x] Add animations system
- [ ] Migrate existing screens to use new components
- [ ] Add more molecules (Cards, Forms, Lists)
- [ ] Add more organisms (Headers, Footers, Complex sections)
- [ ] Implement feature-based architecture
- [ ] Add error handling utilities
- [ ] Add navigation system (GoRouter)

---

## 🎯 Benefits

1. **Consistency** - Design tokens ensure visual consistency
2. **Maintainability** - DRY principle, single source of truth
3. **Scalability** - Easy to add new features and components
4. **Type Safety** - Compile-time checks prevent errors
5. **Developer Experience** - Context extensions make coding faster
6. **Performance** - Riverpod ensures optimal rebuilds
7. **Accessibility** - Material Design 3 built-in accessibility
8. **Dark Mode** - Full dark mode support out of the box
9. **Testability** - Atomic components are easy to test
10. **Documentation** - Self-documenting code with clear naming

---

## 🔧 Next Steps

1. **Add Theme Toggle**: Add a settings screen with theme selection
2. **Create More Components**: Build cards, forms, list items
3. **Migrate Screens**: Gradually migrate existing screens
4. **Add Features**: Implement new features using the architecture
5. **Optimize**: Profile and optimize performance
6. **Test**: Write unit tests for components and providers

---

## 📚 Resources

- [Riverpod Documentation](https://riverpod.dev/)
- [Material Design 3](https://m3.material.io/)
- [Atomic Design](https://bradfrost.com/blog/post/atomic-web-design/)
- [Flutter Best Practices](https://docs.flutter.dev/perf/best-practices)

---

**Author**: AI Assistant
**Date**: October 5, 2025  
**Version**: 1.0.0

