# Anuyatra Architecture & Code Standards

This document describes the code patterns, file structure, naming conventions, and
engineering practices used in the Anuyatra Flutter codebase. Follow these rules for
all future development to maintain diamond-standard code quality.

---

## Table of Contents

1. [Directory Structure](#1-directory-structure)
2. [Repository Pattern & Data Layer](#2-repository-pattern--data-layer)
3. [Dependency Injection via Riverpod](#3-dependency-injection-via-riverpod)
4. [State Management](#4-state-management)
5. [Model Conventions](#5-model-conventions)
6. [Routing & Navigation](#6-routing--navigation)
7. [Screen Architecture](#7-screen-architecture)
8. [Widget Architecture (Atomic Design)](#8-widget-architecture-atomic-design)
9. [Theming & Dark Mode](#9-theming--dark-mode)
10. [Typography System](#10-typography-system)
11. [Animations & Motion](#11-animations--motion)
12. [Constants & Design Tokens](#12-constants--design-tokens)
13. [Theme Extensions & Context Helpers](#13-theme-extensions--context-helpers)
14. [Error Handling](#14-error-handling)
15. [Seed Data & Demo System](#15-seed-data--demo-system)
16. [Naming Conventions](#16-naming-conventions)
17. [Rules & Best Practices](#17-rules--best-practices)
18. [Backend Swap Strategy](#18-backend-swap-strategy)

---

## 1. Directory Structure

```
lib/
├── common/
│   ├── animations/          # Animation constants, curves, and reusable animated widgets
│   └── widgets/
│       ├── atoms/           # Smallest reusable UI units (buttons, avatars, loaders, theme toggle)
│       └── molecules/       # Compositions of atoms (app bars, detail tiles, grids)
├── core/
│   ├── auth/                # Auth state machine (auth_state.dart, auth_provider.dart)
│   ├── constants/           # Design tokens (colors, spacing, strings, typography, shadows)
│   ├── data/
│   │   ├── repositories/    # Abstract interfaces (contracts) — NO implementation details
│   │   ├── local/           # Hive implementations of repository interfaces
│   │   ├── result.dart      # Result<T> sealed type for expected failures
│   │   └── app_data_module.dart  # DI composition root — wires all repositories
│   ├── errors/              # Typed exception hierarchy (AppException, NotFoundException, etc.)
│   ├── providers/           # Riverpod providers (repository providers, theme provider)
│   ├── routing/
│   │   ├── app_router.dart  # GoRouter config with auth-based redirects
│   │   ├── route_names.dart # Centralized route name + path constants
│   │   └── shells/          # StatefulShellRoute wrappers per user role
│   ├── services/            # Legacy LocalStorageService (deprecated, kept for seeding)
│   └── theme/               # ThemeData definitions (light + dark) and context extensions
├── data/
│   ├── seed_data.dart       # First-launch seeder with demo data
│   └── mock_data.dart       # Legacy static data (deprecated)
├── models/                  # Domain models (AppUser, Agency, BrokerProfile, etc.)
└── screens/                 # Feature screens organized by role
    ├── admin/               # Agency admin screens
    ├── auth/                # Login, OTP, role selection, profile setup
    ├── broker/              # Broker dashboard, clients, profiles, messages
    ├── candidate/           # Candidate home, shared profiles, own profile
    ├── chat/                # Chat screen
    ├── parent/              # Parent home, my brokers, profile
    ├── profile/             # Shared profile view screen
    ├── search/              # Discovery/search screen
    └── settings/            # App settings
```

### Placement Rules

| What you're adding | Where it goes |
|---|---|
| New domain model | `lib/models/` |
| New repository interface | `lib/core/data/repositories/` |
| New Hive implementation | `lib/core/data/local/` |
| New remote implementation (future) | `lib/core/data/remote/` |
| New screen for a role | `lib/screens/<role>/` |
| New shared screen (cross-role) | `lib/screens/<feature>/` |
| New reusable small widget | `lib/common/widgets/atoms/` |
| New composed widget | `lib/common/widgets/molecules/` |
| New design token | `lib/core/constants/app_<category>.dart` |
| New user-facing string | `lib/core/constants/app_strings.dart` |
| New animation widget/preset | `lib/common/animations/app_animations.dart` |
| New theme extension | `lib/core/theme/theme_extensions.dart` |
| Theme data modification | `lib/core/theme/app_theme.dart` |

---

## 2. Repository Pattern & Data Layer

### Architecture

```
Screen → ref.read(repositoryProvider) → Abstract Interface → Hive Implementation → Hive Box
```

Every data operation goes through an **abstract repository interface**. The interface
lives in `lib/core/data/repositories/` and knows nothing about Hive, Firebase, or any
storage mechanism. The concrete implementation lives in `lib/core/data/local/`.

### Repositories

| Repository | Responsibility |
|---|---|
| `AuthRepository` | OTP send/verify, demo OTP code |
| `UserRepository` | User CRUD, session management (current user) |
| `AgencyRepository` | Agency CRUD, search, broker count |
| `BrokerRepository` | Broker profile CRUD, search, stats |
| `ProfileRepository` | CandidateProfile + ParentProfile CRUD, search |
| `LinkRepository` | Link request lifecycle, connection queries |
| `SharedProfileRepository` | Share, forward, respond to profiles |
| `MessagingRepository` | Conversations, messages, read receipts |

### Interface Rules

1. **All read methods return `Future<T>`** — even though Hive is synchronous internally.
   This ensures screens use `await`, never blocking `build()`, and allows a zero-change
   swap to a genuinely async backend.

2. **All list methods accept `{int? limit, int? offset}`** — pagination is built into
   every interface from day one. Screens request only the data they display.

3. **No storage imports** — interfaces import only models. No `hive`, no `dart:convert`.

### Example Interface

```dart
abstract class UserRepository {
  Future<String?> getCurrentUserId();
  Future<AppUser?> getCurrentUser();
  Future<AppUser?> getUser(String uid);
  Future<AppUser?> getUserByPhone(String phoneNumber);
  Future<AppUser> registerUser({
    required String phoneNumber,
    required String displayName,
    required UserRole role,
    String? photoUrl,
  });
  Future<void> saveUser(AppUser user);
  Future<void> setCurrentUser(String uid);
  Future<void> clearSession();
  Future<List<AppUser>> getAllUsers({int? limit, int? offset});
}
```

### Example Hive Implementation

```dart
class HiveUserRepository implements UserRepository {
  final Box<String> _users;
  final Box<String> _session;

  HiveUserRepository({
    required Box<String> usersBox,
    required Box<String> sessionBox,
  })  : _users = usersBox,
        _session = sessionBox;

  @override
  Future<AppUser?> getUser(String uid) async {
    final raw = _users.get(uid);
    if (raw == null) return null;
    return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  // ... all methods return Future, even when internally sync
}
```

### AppDataModule — Composition Root

`AppDataModule` is the single factory that opens all Hive boxes and wires all
repositories. It has a private constructor and a static `initLocal()` factory:

```dart
class AppDataModule {
  final AuthRepository authRepository;
  final UserRepository userRepository;
  final AgencyRepository agencyRepository;
  // ... all 8 repositories

  AppDataModule._({ ... });

  static Future<AppDataModule> initLocal() async {
    // Open Hive boxes, create Hive*Repository instances, wire cross-dependencies
    return AppDataModule._( ... );
  }

  // Future: static Future<AppDataModule> initRemote(Config config) async { ... }
}
```

### Message Storage

Messages use **individual Hive keys** per message for O(1) writes:

- Message key: `{conversationId}_{messageId}` → JSON of single message
- Index key: `_idx_{conversationId}` → JSON array of message IDs

This avoids the O(n) decode-append-reencode problem of storing all messages as one blob.

---

## 3. Dependency Injection via Riverpod

### Provider Definition

Each repository has a `Provider<T>` in `lib/core/providers/repository_providers.dart`
that throws `UnimplementedError` by default:

```dart
final userRepositoryProvider = Provider<UserRepository>((ref) {
  throw UnimplementedError('userRepositoryProvider must be overridden in ProviderScope');
});
```

This compile-time safety ensures every provider is explicitly wired in `main.dart`.

### Provider Wiring (main.dart)

```dart
void main() async {
  final dataModule = await AppDataModule.initLocal();

  runApp(ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(dataModule.authRepository),
      userRepositoryProvider.overrideWithValue(dataModule.userRepository),
      // ... all 8 repositories
    ],
    child: const AnuyatraApp(),
  ));
}
```

### Usage in Screens

- **`ref.read(repositoryProvider)`** for one-shot data loading and actions (in `_loadData()`, event handlers)
- **Never `ref.watch` on a repository provider** — repositories are singletons; watching them is a no-op
- **`ref.watch(authProvider)`** for reactive auth state in `build()`
- **`ref.watch(themeModeProvider)`** for reactive theme changes

---

## 4. State Management

### Auth State Machine

Auth uses a **sealed class** with exhaustive pattern matching:

```dart
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState { ... }
class AuthLoading extends AuthState { ... }
class AuthOtpSent extends AuthState { phoneNumber, selectedRole }
class AuthAuthenticated extends AuthState { AppUser user }
class AuthNeedsProfile extends AuthState { uid, phoneNumber, role }
class AuthError extends AuthState { message, previousState? }
```

`AuthNotifier` (a `StateNotifier<AuthState>`) manages transitions. It depends on
repository **interfaces**, not concrete implementations:

```dart
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepo;
  final UserRepository _userRepo;
  final ProfileRepository _profileRepo;
  final AgencyRepository _agencyRepo;
  final BrokerRepository _brokerRepo;
  // ...
}
```

### Screen-Level State

Screens use `ConsumerStatefulWidget` with local state variables:

```dart
class _MyScreenState extends ConsumerState<MyScreen> {
  List<Item> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final repo = ref.read(someRepositoryProvider);
    final data = await repo.getData();
    if (!mounted) return;  // CRITICAL: check before setState
    setState(() {
      _items = data;
      _isLoading = false;
    });
  }
}
```

---

## 5. Model Conventions

### Structure

Every model follows this pattern:

```dart
class AppUser {
  // 1. Final fields (immutable)
  final String uid;
  final String displayName;
  final UserRole role;
  final DateTime createdAt;
  final bool isActive;

  // 2. Const constructor with required + optional fields, defaults where sensible
  const AppUser({
    required this.uid,
    required this.displayName,
    required this.role,
    required this.createdAt,
    this.isActive = true,
  });

  // 3. toJson — plain Map<String, dynamic>
  Map<String, dynamic> toJson() => { ... };

  // 4. fromJson — null-safe with fallbacks (NEVER crashes on bad data)
  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser( ... );

  // 5. copyWith — only mutable fields (identity fields like uid excluded)
  AppUser copyWith({ ... }) => AppUser( ... );
}
```

### fromJson Null-Safety Rules

Every `fromJson` factory must handle corrupted or missing data gracefully:

| Field Type | Pattern |
|---|---|
| Required String | `json['key'] as String? ?? ''` |
| Required int | `(json['key'] as num?)?.toInt() ?? 0` |
| Required DateTime | `DateTime.tryParse(json['key'] as String? ?? '') ?? DateTime.now()` |
| Required enum | `EnumType.values.firstWhere((e) => e.name == (json['key'] as String?), orElse: () => EnumType.defaultValue)` |
| Optional String | `json['key'] as String?` (already safe) |
| Optional bool | `json['key'] as bool? ?? defaultValue` |
| List\<String> | `(json['key'] as List<dynamic>?)?.cast<String>() ?? []` |

---

## 6. Routing & Navigation

### GoRouter with Auth Redirects

The app uses `GoRouter` with `StatefulShellRoute.indexedStack` for role-based navigation shells.

**Key patterns:**

1. **Route names and paths** are centralized in `RouteNames` (private constructor, static const):

   ```dart
   class RouteNames {
     RouteNames._();
     static const parentHome = 'parent-home';
     static const parentHomePath = '/parent/home';
     // ...
   }
   ```

2. **Auth-driven redirects** use `refreshListenable` (a `ValueNotifier<int>` incremented
   on auth state changes) so the redirect runs every time auth changes without recreating
   the `GoRouter` instance.

3. **`redirect` reads auth state fresh** via `ref.read(authProvider)` inside the closure —
   never captured outside it.

4. **`debugLogDiagnostics`** is gated on `kDebugMode` (never logs in release).

5. **`errorBuilder`** provides a user-friendly 404 page.

### Shell Structure

Each user role has a `StatefulShellRoute.indexedStack` with its own `NavigationBar`:

| Shell | Tabs |
|---|---|
| `ParentShell` | Home, Search, My Brokers, Anuyatra Hub, Profile |
| `BrokerShell` | Dashboard, Clients, Profiles, Messages, Profile |
| `CandidateShell` | Home, Shared Profiles, Anuyatra Hub, Profile |
| `AgencyAdminShell` | Dashboard, Brokers, Clients, Settings |

Shared routes (profile view, chat, settings, link requests) use `parentNavigatorKey`
to render as overlays on top of any shell.

---

## 7. Screen Architecture

### Standard Screen Pattern

Every screen follows this lifecycle:

```
ConsumerStatefulWidget
  └─ initState() → addPostFrameCallback → _loadData()
       └─ Read auth state (early return if not authenticated)
       └─ Read repository providers via ref.read()
       └─ await async repository calls
       └─ if (!mounted) return
       └─ setState() with loaded data
  └─ build() → reads local state variables, shows loading/data/empty
```

### Rules

1. **Never call repository methods in `build()`** — all data loading happens in async
   `_loadData()` called from `initState` via `addPostFrameCallback`.

2. **Always check `if (!mounted) return`** or `if (!context.mounted) return` before
   `setState`, `ScaffoldMessenger`, or `Navigator` calls after any `await`.

3. **Use `ref.read()` for repositories** in data loading and event handlers.

4. **Use `ref.watch()` only for reactive state** (auth state, theme mode).

5. **Show `CircularProgressIndicator`** during `_isLoading` state.

6. **Handle empty states** with meaningful messages from `AppStrings`.

---

## 8. Widget Architecture (Atomic Design)

### Atoms (`lib/common/widgets/atoms/`)

Smallest, self-contained UI units with no business logic:

- `AppButton` — multi-variant button (primary, secondary, outline, text, danger)
- `AppAvatar` — consistent avatar with fallback initials
- `AppLoading` — standardized loading indicator
- `ThemeToggleButton` — dark mode toggle

### Molecules (`lib/common/widgets/molecules/`)

Compositions of atoms that form meaningful UI components:

- `BrandedAppBar` — app bar with Anuyatra branding and theme toggle
- `DetailTile` — label/value pair for profile display
- `DetailsGrid` — grid layout for detail tiles
- `PhotoManagerWidget` — photo gallery management

### Rules

- Atoms never depend on other atoms; molecules compose atoms.
- All widgets use `AppSpacing`, `AppColors`, and `AppTypography` from constants.
- Prefer `const` constructors wherever possible.
- Widgets should be stateless unless they manage animation or local interaction state.

---

## 9. Theming & Dark Mode

The app has full light and dark theme support using Material Design 3.

### Theme Architecture

```
lib/core/theme/
├── app_theme.dart          # ThemeData definitions (light + dark), applied in main.dart
└── theme_extensions.dart   # BuildContext extensions for easy theme access

lib/theme/
└── app_theme.dart          # Legacy theme bridge (delegating to AppColors)

lib/core/providers/
└── theme_provider.dart     # ThemeModeNotifier persisting to SharedPreferences

lib/common/widgets/atoms/
└── theme_toggle_button.dart  # Reusable toggle widget with dialog picker
```

### AppTheme (`lib/core/theme/app_theme.dart`)

Defines complete `ThemeData` for both light and dark modes. Every widget theme
is configured — AppBar, Card, Button (elevated/outlined/text/filled), Input,
NavigationBar, Chip, Divider, Dialog, BottomSheet, SnackBar, FAB, IconButton,
ListTile, and Scaffold background.

All values reference `AppColors`, `AppSpacing`, and `AppTypography` — no
hardcoded colors, sizes, or fonts in the theme file.

```dart
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme { ... }  // Full M3 light theme
  static ThemeData get darkTheme { ... }   // Full M3 dark theme
}
```

Applied in `main.dart`:

```dart
MaterialApp.router(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: themeMode,  // Watched from themeModeProvider
)
```

### Legacy Theme Bridge (`lib/theme/app_theme.dart`)

A bridge class imported by many screens. Provides:

- **Brand color aliases**: `AppTheme.sacredSaffron`, `AppTheme.deepMaroon`
- **Theme-aware helpers**: `AppTheme.primaryText(context)`, `AppTheme.cardSurface(context)`,
  `AppTheme.border(context)` — these read `Theme.of(context).brightness` and return
  the appropriate light/dark color
- **Chat bubble colors**: `AppTheme.getChatBubbleColor(isSentByUser:, isDark:)`
- **Status colors**: `AppTheme.getStatusColor(status)` mapping status strings to colors
- **Theme-aware shadows**: `AppTheme.cardShadow(context)` with brightness-based opacity

### Theme Persistence (`ThemeModeNotifier`)

Theme preference is persisted to `SharedPreferences` and restored on app start:

```dart
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _loadThemeMode();  // Reads from SharedPreferences on init
  }

  Future<void> toggleTheme() async { ... }    // Light <-> Dark
  Future<void> setThemeMode(ThemeMode) async { ... }  // Specific mode
  bool isDarkMode(BuildContext context) { ... }  // Resolves system mode
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(...);
final isDarkModeProvider = Provider<bool>(...);
```

### Theme Toggle Widget

`ThemeToggleButton` (`lib/common/widgets/atoms/theme_toggle_button.dart`) is a
`ConsumerWidget` with two modes:

- **Icon-only** (`showLabel: false`): Simple `IconButton` — sun/moon icons. Place in
  any `AppBar` actions list.
- **Labeled** (`showLabel: true`): Full row with icon, "Theme" label, current mode
  subtitle, and chevron. Shows a dialog picker with Light / Dark / System options.

Also available: `ThemeToggleFab` — a `FloatingActionButton.small` for quick toggle.

### Adding Dark Mode Support to a Screen

Screens automatically get dark mode through `Theme.of(context)`. For custom colors:

```dart
// Option 1: Use theme color scheme (preferred)
final color = theme.colorScheme.surface;

// Option 2: Use legacy bridge helpers
final textColor = AppTheme.primaryText(context);
final bgColor = AppTheme.cardSurface(context);

// Option 3: Use context extensions
final isDark = context.isDarkMode;
final borderColor = context.borderColor;

// Option 4: Manual brightness check
final isDark = Theme.of(context).brightness == Brightness.dark;
```

To add the theme toggle to any screen's app bar:

```dart
AppBar(
  actions: const [ThemeToggleButton()],
)
```

---

## 10. Typography System

### Font Families

The app uses Google Fonts with runtime fetching:

| Family | Usage | Fallback |
|---|---|---|
| **Poppins** | Display and headline styles (large, expressive text) | System default |
| **Inter** | Body, title, label, button styles (readable content) | System default |
| **Roboto Mono** | Monospace (OTP codes, technical data) | System default |

`GoogleFonts.config.allowRuntimeFetching = true` is set in `main.dart`.

### Type Scale (Material Design 3)

`AppTypography` (`lib/core/constants/app_typography.dart`) follows the M3 type scale:

| Style | Font | Size | Weight | Usage |
|---|---|---|---|---|
| `displayLarge` | Poppins | 57 | Bold | Hero text |
| `displayMedium` | Poppins | 45 | Bold | Feature titles |
| `displaySmall` | Poppins | 36 | SemiBold | Section headers |
| `headlineLarge` | Poppins | 32 | SemiBold | Page titles |
| `headlineMedium` | Poppins | 28 | SemiBold | Section titles |
| `headlineSmall` | Poppins | 24 | SemiBold | Card titles |
| `titleLarge` | Inter | 22 | SemiBold | App bar titles |
| `titleMedium` | Inter | 16 | SemiBold | List item titles |
| `titleSmall` | Inter | 14 | SemiBold | Subtitles |
| `bodyLarge` | Inter | 16 | Regular | Primary body text |
| `bodyMedium` | Inter | 14 | Regular | Secondary body text |
| `bodySmall` | Inter | 12 | Regular | Captions |
| `labelLarge` | Inter | 14 | Medium | Button text |
| `labelMedium` | Inter | 12 | Medium | Chip/tab text |
| `labelSmall` | Inter | 11 | Medium | Nav bar labels |

### App-Specific Styles

| Style | Usage |
|---|---|
| `profileName` | Poppins 20 SemiBold — candidate/broker profile names |
| `profileSubtitle` | Inter 14 Regular — age, location, profession |
| `button` | Inter 16 SemiBold — button labels |
| `caption` | Inter 12 Regular — timestamps, metadata |
| `overline` | Inter 10 SemiBold — uppercase category labels |
| `badge` | Inter 11 SemiBold — notification badges, chips |

### Usage Patterns

```dart
// Option 1: Through theme (preferred for standard M3 styles)
Text('Title', style: theme.textTheme.headlineSmall)

// Option 2: Direct from AppTypography (when you need a custom color)
Text('Name', style: AppTypography.profileName(color: AppColors.sacredSaffron))

// Option 3: Via context extension (theme-aware colors automatically)
Text('Name', style: context.profileName)
```

### `getTextTheme` Builder

`AppTypography.getTextTheme(color:)` builds a complete `TextTheme` for use in
`ThemeData`. It's called once in each theme definition, not per-widget.

---

## 11. Animations & Motion

### AppAnimations (`lib/common/animations/app_animations.dart`)

Centralized animation constants following Material Design motion guidelines.

#### Duration Scale

| Token | Duration | Usage |
|---|---|---|
| `instant` | 100ms | Very subtle animations (opacity micro-changes) |
| `fast` | 200ms | Simple transitions (fade, color change) |
| `normal` | 300ms | Standard animations (most UI transitions) |
| `medium` | 400ms | Complex animations (multi-property changes) |
| `slow` | 500ms | Emphasis animations (hero, page transitions) |
| `verySlow` | 700ms | Special emphasis (onboarding, celebrations) |

#### Curve Presets

| Token | Curve | Usage |
|---|---|---|
| `standard` | `easeInOut` | Most animations |
| `decelerate` | `easeOut` | Elements entering screen |
| `accelerate` | `easeIn` | Elements leaving screen |
| `sharp` | `easeInOutCubic` | Quick, decisive movement |
| `bounce` | `bounceOut` | Playful entrance effects |
| `elastic` | `elasticOut` | Spring-like motion |
| `emphasized` | `easeInOutCubicEmphasized` | Material 3 emphasized easing |

#### Page Transition Builders

Pre-built transition widgets for navigation:

- `AppAnimations.fadeTransition` — simple opacity
- `AppAnimations.slideFromRightTransition` — standard push
- `AppAnimations.slideFromBottomTransition` — modal/sheet entrance
- `AppAnimations.scaleTransition` — dialog/zoom entrance
- `AppAnimations.fadeScaleTransition` — combined fade + scale (M3 style)

#### Staggered Animation Helpers

For list item entrance animations:

```dart
// Calculate delay per item
final delay = AppAnimations.staggerDelay(index);  // 50ms * index

// Calculate interval for AnimationController
final interval = AppAnimations.staggeredInterval(index, totalItems);
```

### Ready-Made Animation Widgets

#### `FadeInUp`

Wraps any widget to fade in and slide up on first appearance:

```dart
FadeInUp(
  delay: AppAnimations.staggerDelay(index),
  child: MyCard(),
)
```

Parameters: `duration` (default 300ms), `delay`, `curve` (default decelerate), `offset` (default 20px).

#### `ScaleIn`

Wraps any widget to scale in from a smaller size with a fade:

```dart
ScaleIn(
  delay: Duration(milliseconds: 200),
  child: MyAvatar(),
)
```

Parameters: `duration` (default 300ms), `delay`, `curve` (default emphasized), `initialScale` (default 0.8).

#### `ShimmerLoading`

Applies a shimmer effect to a placeholder widget during loading:

```dart
ShimmerLoading(
  child: Container(height: 100, color: Colors.white),
)
```

Automatically adapts to light/dark theme. Customizable `baseColor` and `highlightColor`.

### Rules

- **Use `AppAnimations` duration tokens** — never hardcode `Duration(milliseconds: 300)`
- **Use `AppAnimations` curve presets** — never use `Curves.easeInOut` directly
- **Dispose `AnimationController`** in `dispose()` of every `State` that creates one
- **Check `if (mounted)` before `_controller.forward()`** when using delayed animations
- **Use staggered delays for lists** — each item enters 50ms after the previous

---

## 12. Constants & Design Tokens

All design tokens live in `lib/core/constants/` as classes with **private constructors**
and **static const** members.

### AppSpacing — Layout System

Based on a **4px baseline grid**:

| Token | Value | Usage |
|---|---|---|
| `xxxs` | 2.0 | Hairline spacing |
| `xxs` | 4.0 | Micro spacing |
| `xs` | 8.0 | Extra small |
| `sm` | 12.0 | Small |
| `md` | 16.0 | Medium (base) |
| `lg` | 24.0 | Large |
| `xl` | 32.0 | Extra large |
| `xxl` | 48.0 | Section-level |
| `xxxl` | 64.0 | Page-level |

Includes pre-built `EdgeInsets` presets (`allMd`, `horizontalLg`, `verticalXs`, etc.),
`BorderRadius` presets (`roundedSm`, `roundedMd`, `cardRadius`, etc.),
`const SizedBox` gap widgets (`gapH8`, `gapH16`, `gapW12`, etc.),
and semantic aliases (`screenPadding`, `cardPadding`, `formSpacing`).

### AppColors — Color Palette (`lib/core/constants/app_colors.dart`)

Organized into logical groups:

| Group | Examples | Notes |
|---|---|---|
| **Brand** | `sacredSaffron`, `sacredSaffronLight/Dark`, `deepMaroon`, `deepMaroonLight/Dark` | Primary identity colors |
| **Light Theme** | `lightBackground`, `lightSurface`, `lightSurfaceVariant`, `lightPrimaryText`, `lightSecondaryText`, `lightTertiaryText`, `lightBorder`, `lightDivider` | Used in `AppTheme.lightTheme` |
| **Dark Theme** | `darkBackground`, `darkSurface`, `darkSurfaceVariant`, `darkPrimaryText`, `darkSecondaryText`, `darkTertiaryText`, `darkBorder`, `darkDivider` | Used in `AppTheme.darkTheme` |
| **Semantic** | `success/Light/Dark`, `error/Light/Dark`, `warning/Light/Dark`, `info/Light/Dark` | Status & feedback colors |
| **Chat (WhatsApp)** | `chatGreen`, `chatDarkGreen`, `chatLightGreen`, `chatGray`, `chatDarkGray`, `chatDarkBackground`, `chatLightBackground`, `chatDarkBubble`, `chatDarkSentBubble`, `chatDarkInput`, `chatDarkInputField`, `chatLightInputField` | Full chat interface palette |
| **Feature** | `warmBackground`, `trustBlue`, `meetingPurple/Light/Lighter`, `pink` | Screen-specific accents |
| **Overlay** | `overlay(opacity)`, `scrim`, `barrier` | Modal/dialog overlays |

**Gradient presets**: `primaryGradient` (saffron→maroon), `successGradient`,
`surfaceGradient(isDark)`.

**Helper methods**: `getTextColorForBackground(color)` (luminance-based contrast),
`getStatusColor(status)`, `getChatBubbleColor(isSentByUser:, isDark:)`.

### AppStrings — User-Facing Copy

All UI strings in one file. Static const for simple strings, static methods for
parameterized strings:

```dart
class AppStrings {
  AppStrings._();
  static const appName = 'Anuyatra';
  static const logout = 'Logout';
  static String registeringAs(String role) => 'Registering as: $role';
}
```

### AppTypography — Text Styles

See [§10 Typography System](#10-typography-system) for the full type scale.
Google Fonts-based (Poppins + Inter) with optional color parameters.
Called via `AppTypography.bodyMedium(color:)` or through context extensions.

### AppShadows — Elevation (`lib/core/constants/app_shadows.dart`)

Pre-defined `List<BoxShadow>` for consistent elevation:

| Token | Blur | Usage |
|---|---|---|
| `none` | 0 | Flat elements |
| `sm` | 2 | Subtle elevation (buttons, app bar) |
| `md` | 8+4 | Default cards and surfaces |
| `lg` | 16+8 | Floating elements (FAB, dropdowns) |
| `xl` | 24+12 | Prominent floating elements |
| `xxl` | 32+16 | Dialogs, bottom sheets |

**Semantic aliases**: `AppShadows.card`, `AppShadows.button`, `AppShadows.fab`,
`AppShadows.appBar`, `AppShadows.bottomSheet`, `AppShadows.dialog`, `AppShadows.dropdown`.

**Colored shadows**: `AppShadows.primary` (saffron glow), `AppShadows.secondary` (maroon),
`AppShadows.success`, `AppShadows.error`.

**Special effects**: `AppShadows.glow(color:, intensity:)` for focus/active states,
`AppShadows.softGlow` for badges, `AppShadows.innerShadow(backgroundColor:)` for inset effects.

### Rules

- **Never use literal numbers for spacing** — use `AppSpacing.md`, `AppSpacing.gapH16`, etc.
- **Never hardcode UI strings** — add to `AppStrings` first, then reference.
- **Never hardcode colors** — use `AppColors` or `Theme.of(context).colorScheme`.
- **Always use `const` EdgeInsets/BorderRadius** presets when they match.

---

## 13. Theme Extensions & Context Helpers

`lib/core/theme/theme_extensions.dart` provides `BuildContext` extensions that eliminate
boilerplate throughout the app.

### `ThemeContext` — Theme Accessors

```dart
context.theme          // ThemeData
context.colors         // ColorScheme
context.textTheme      // TextTheme
context.isDarkMode     // bool
context.isLightMode    // bool
context.screenWidth    // double
context.screenHeight   // double
context.isMobile       // < 600px
context.isTablet       // 600–1200px
context.isDesktop      // >= 1200px
```

**Theme-aware semantic colors** (auto-switch light/dark):

```dart
context.primaryTextColor
context.secondaryTextColor
context.tertiaryTextColor
context.borderColor
context.dividerColor
```

**Quick actions:**

```dart
context.showSnackBar('Done');
context.showErrorSnackBar('Failed');
context.showSuccessSnackBar('Saved');
context.unfocus();                      // Dismiss keyboard
context.showAppDialog(child: MyDialog());
context.showAppBottomSheet(child: MySheet());
```

### `ResponsiveContext` — Responsive Layout

```dart
final padding = context.responsive(mobile: 16.0, tablet: 24.0, desktop: 32.0);
final fontSize = context.responsiveFontSize(mobile: 14.0, tablet: 16.0);
final width = context.widthPercent(80);   // 80% of screen width
final height = context.heightPercent(50); // 50% of screen height
```

### `TypographyContext` — Direct Style Access

All `AppTypography` styles are available on context with auto-resolved colors:

```dart
Text('Hello', style: context.headlineSmall)  // Poppins 24, primaryTextColor
Text('Sub', style: context.bodySmall)        // Inter 12, secondaryTextColor
Text('Name', style: context.profileName)     // Poppins 20, primaryTextColor
Text('Btn', style: context.button)           // Inter 16, primaryTextColor
```

### `SpacingContext` — Spacing Shortcuts

```dart
context.md              // 16.0
context.paddingMd       // EdgeInsets.all(16)
context.screenPadding   // EdgeInsets.symmetric(horizontal: 16, vertical: 8)
context.cardRadius      // BorderRadius.circular(12)
context.buttonRadius    // BorderRadius.circular(8)
```

### Rules

- **Prefer context extensions** over `Theme.of(context).colorScheme.primary` for readability.
- **Use `context.isDarkMode`** instead of manually reading `Theme.of(context).brightness`.
- **Use `context.showSnackBar`** instead of `ScaffoldMessenger.of(context)...` boilerplate.
- **Use responsive helpers** when building layouts that must work across phone, tablet, desktop.

---

## 14. Error Handling

### Exception Hierarchy

```
AppException (base)
├── NotFoundException    — entity not found (entityType, id)
├── ValidationException  — input validation failure (field, message)
├── StorageException     — storage read/write failure
├── AuthException        — authentication/authorization failure
└── DuplicateException   — entity already exists (entityType)
```

All exceptions implement `Exception` and carry a `message` and optional `cause`.

### Result\<T> Type

For expected failures where exceptions are too heavy-handed:

```dart
sealed class Result<T> {
  T getOrElse(T fallback);
  T getOrElseMap(T Function(Object error) orElse);
  Result<R> map<R>(R Function(T value) transform);
  Result<R> flatMap<R>(Result<R> Function(T value) transform);
}

class Success<T> extends Result<T> { final T value; }
class Failure<T> extends Result<T> { final Object error; final StackTrace? stackTrace; }
```

### Auth Error Handling

- `checkAuthStatus()` — wraps in try-catch, fails gracefully to `AuthInitial`
- `sendOtp()` — validates phone with regex `^[6-9]\d{9}$` before sending, catches failures
- `verifyOtp()` — full try-catch, returns to `AuthOtpSent` state on failure
- `completeProfileSetup()` — try-catch, shows error message on failure

### Screen Error Handling

- All async operations wrapped in try-catch where user-facing feedback is needed
- `if (!mounted) return` before any context-dependent call after `await`
- `ScaffoldMessenger.of(context).showSnackBar(...)` for error feedback

---

## 15. Seed Data & Demo System

### SeedConfig

```dart
class SeedConfig {
  static const bool enabled = true;       // Set false for production
  static const bool printCredentials = true;  // Print demo logins to console
}
```

### Seeding Flow

1. `main.dart` checks `storage.isFirstLaunch`
2. If true, calls `seedDemoData(storage)`
3. `seedDemoData` checks `SeedConfig.enabled` (second guard)
4. Creates a complete demo graph: agencies, brokers, parents, candidates, profiles,
   link requests (accepted + pending), shared profiles (various responses),
   conversations with messages
5. Prints formatted credential table to console when `SeedConfig.printCredentials` is true

### Demo OTP

The hardcoded OTP `123456` is deliberately visible on the login and OTP screens
to facilitate demos. This is controlled by `HiveAuthRepository.demoOtpCode`.

---

## 16. Naming Conventions

### Files

| Type | Convention | Example |
|---|---|---|
| Model | `snake_case.dart` | `app_user.dart`, `broker_profile.dart` |
| Repository interface | `<domain>_repository.dart` | `user_repository.dart` |
| Hive implementation | `hive_<domain>_repository.dart` | `hive_user_repository.dart` |
| Screen | `<feature>_screen.dart` | `broker_dashboard_screen.dart` |
| Shell | `<role>_shell.dart` | `parent_shell.dart` |
| Constants | `app_<category>.dart` | `app_spacing.dart`, `app_strings.dart` |
| Provider | `<domain>_providers.dart` | `repository_providers.dart` |
| Bottom sheet | `<feature>_sheet.dart` | `share_profile_sheet.dart` |

### Classes

| Type | Convention | Example |
|---|---|---|
| Model | `PascalCase` | `AppUser`, `BrokerProfile` |
| Repository interface | `<Domain>Repository` | `UserRepository` |
| Hive implementation | `Hive<Domain>Repository` | `HiveUserRepository` |
| Screen widget | `<Feature>Screen` | `BrokerDashboardScreen` |
| State notifier | `<Feature>Notifier` | `AuthNotifier` |
| Sealed state | `<Feature><State>` | `AuthAuthenticated`, `AuthOtpSent` |
| Exception | `<Type>Exception` | `NotFoundException` |
| Constants class | `App<Category>` | `AppSpacing`, `AppStrings` |

### Providers

| Type | Convention | Example |
|---|---|---|
| Repository | `<domain>RepositoryProvider` | `userRepositoryProvider` |
| State notifier | `<feature>Provider` | `authProvider` |
| Simple value | `<feature>Provider` | `themeModeProvider` |

### Routes

| Type | Convention | Example |
|---|---|---|
| Route name | `kebab-case` string constant | `'broker-dashboard'` |
| Route path | `/<role>/<feature>` | `'/broker/dashboard'` |
| Constant name | `camelCase` | `RouteNames.brokerDashboard` |
| Path constant | `camelCase` + `Path` suffix | `RouteNames.brokerDashboardPath` |

---

## 17. Rules & Best Practices

### DO

- **Return `Future`** from all repository interface methods, even for locally sync data
- **Accept `{int? limit, int? offset}`** on every list-returning repository method
- **Use `const` constructors** on widgets, models, and state classes wherever possible
- **Use `AppSpacing` constants** for all spacing, padding, border radius, and gap widgets
- **Use `AppStrings` constants** for all user-facing text
- **Use `AppColors`** or `Theme.of(context).colorScheme` for all colors
- **Check `if (!mounted) return`** before `setState` or context usage after `await`
- **Load data in `initState` → `addPostFrameCallback` → `_loadData()`** pattern
- **Use `ref.read()` for repositories**, `ref.watch()` only for reactive UI state
- **Handle errors with try-catch** in all auth and data-mutation methods
- **Validate phone numbers** with `^[6-9]\d{9}$` before auth operations
- **Add `@Deprecated` annotation** before removing any public API, with migration guidance
- **Use sealed classes** for state machines that require exhaustive handling
- **Use `Result<T>`** for expected failures in repository methods (where appropriate)
- **Keep `toJson`/`fromJson` in the model** — no external serialization classes
- **Use `AppAnimations` duration/curve tokens** for all animations — never hardcode `Duration(milliseconds: 300)`
- **Dispose every `AnimationController`** in `dispose()` — no exceptions
- **Use `context.isDarkMode`** (or `ThemeToggleButton`) to support dark mode in every screen
- **Test both light and dark theme** when adding new custom-colored UI
- **Use `ThemeToggleButton` in settings** and `ThemeToggleFab` for debug quick-access

### DON'T

- **Don't call repository methods in `build()`** — always use async `_loadData()`
- **Don't use `ref.watch()` on repository providers** — they're singletons, watching is a no-op
- **Don't use literal numbers** for spacing — `SizedBox(height: 16)` should be `AppSpacing.gapH16`
- **Don't hardcode strings** — add to `AppStrings` first
- **Don't use `as Type` without `?`** in `fromJson` — always use `as Type?` with `??`
- **Don't import Hive or storage** in repository interfaces or screens
- **Don't load all data and `.take(N)`** — use `limit` parameter on repository methods
- **Don't store all messages as one JSON blob** — use individual keys per message
- **Don't use `debugLogDiagnostics: true`** — always gate on `kDebugMode`
- **Don't skip the `mounted` check** after any `await` in a `State` class
- **Don't put Python/shell scripts in `lib/`** — they break the Dart analyzer
- **Don't hardcode `Duration` or `Curves`** — use `AppAnimations.normal`, `AppAnimations.standard`, etc.
- **Don't hardcode light/dark colors inline** — use `context.isDarkMode` ternary or `AppTheme.primaryText(context)`
- **Don't forget `if (mounted)` before `_controller.forward()`** in delayed animations
- **Don't create shadows manually** — use `AppShadows.card`, `AppShadows.primary`, etc.

---

## 18. Backend Swap Strategy

The architecture is designed so swapping from Hive to a remote backend requires
changing exactly **one line** in `main.dart`:

```dart
// Today (local Hive)
final dataModule = await AppDataModule.initLocal();

// Future (remote backend)
final dataModule = await AppDataModule.initRemote(config);
```

### Steps to add a new backend:

1. Create `lib/core/data/remote/` with implementations of all 8 repository interfaces
   (e.g., `FirebaseUserRepository`, `ApiUserRepository`)
2. Add `AppDataModule.initRemote()` (or `initFirebase()`, `initApi()`) that instantiates
   remote repositories instead of Hive ones
3. Change the one `initLocal()` call in `main.dart` to `initRemote(config)`
4. **Every screen, every provider, every test continues to work unchanged**

This works because:
- Screens depend only on abstract interfaces (`UserRepository`), never on `HiveUserRepository`
- All repository methods return `Future` — the async contract is already in place
- Pagination (`limit`/`offset`) is already in every list method
- The `ProviderScope` overrides in `main.dart` are the single wiring point
