# Code Review — Anuyatra Flutter App
**Date:** March 2026
**Reviewer:** Thorough audit of 100 Dart files across the full codebase
**Goal:** Diamond-standard code quality — reusable components, production-grade architecture, world-class UI

---

## The Vision vs. The Reality

The codebase has real bones. The design system (colors, spacing, typography, shadows) is well-thought-out. The multi-role architecture is conceptually sound. The atomic widget structure exists. But the execution has significant gaps — architectural shortcuts, security holes, performance landmines, and inconsistencies that will compound into serious problems.

**Current state: A strong scaffold with weak foundations.**

This document categorizes every issue found, explains why it matters, and defines what diamond-standard looks like for each.

---

## CRITICAL — Fix Before Anything Else

These are bugs, security vulnerabilities, or stability issues that would cause data loss, crashes, or security breaches.

---

### C1. Hardcoded OTP Exposed in Source Code
**File:** `lib/core/auth/auth_provider.dart:9`, `lib/screens/auth/login_screen.dart:61`

```dart
// auth_provider.dart
const _mockOtpCode = '123456';

// login_screen.dart — displayed to user on screen
"Demo mode: Any phone number works.\nUse OTP code: 123456"
```

**What's wrong:** The authentication bypass is hardcoded as a constant and also printed on-screen. This is not just "demo code" — it's the _entire_ auth system. Any user who opens the app can log in as anyone with any phone number.

**Diamond standard:** Auth is a backend concern. OTP generation and validation must happen server-side. For the interim demo period, at minimum: remove the UI hint, randomize the code each session in memory, and never commit secrets to source control.

---

### C2. No Error Handling in checkAuthStatus — App Crashes on Storage Failure
**File:** `lib/core/auth/auth_provider.dart:19-27`

```dart
Future<void> checkAuthStatus() async {
  state = const AuthLoading();
  final user = _storage.currentUser; // Can throw, no try-catch
  if (user != null) {
    state = AuthAuthenticated(user: user);
  } else {
    state = const AuthInitial();
  }
}
```

**What's wrong:** If Hive is corrupted, locked, or fails to deserialize, this throws an unhandled exception. The app goes to a black screen. Users lose sessions.

**Diamond standard:**
```dart
Future<void> checkAuthStatus() async {
  state = const AuthLoading();
  try {
    final user = _storage.currentUser;
    state = user != null ? AuthAuthenticated(user: user) : const AuthInitial();
  } catch (e, stack) {
    _log.error('Auth check failed', e, stack);
    state = const AuthInitial(); // Fail gracefully to login
  }
}
```

---

### C3. Router Race Condition on Cold Start
**File:** `lib/main.dart:78-85`

```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (mounted) {
    ref.read(authProvider.notifier).checkAuthStatus().catchError(...);
  }
});
```

**What's wrong:** The GoRouter's `redirect` function runs _before_ `checkAuthStatus()` completes. On cold start, `authProvider` is `AuthInitial` — so all users get bounced to the role selection screen for a frame, then redirected to their actual screen. This causes a visible flash and potentially incorrect routing.

**Diamond standard:** Auth state must be resolved _before_ the router attempts a redirect. Use a splash/loading screen gated on auth resolution, or initialize auth before `runApp`.

---

### C4. No Hive Schema Versioning — Guaranteed Data Loss on Schema Changes
**File:** `lib/core/services/local_storage_service.dart`

**What's wrong:** Hive boxes are opened with no version tracking. When any model field is added, removed, or renamed, existing persisted data will fail to deserialize — silently returning null or throwing a `TypeError`. There is no migration path.

**Diamond standard:** Every model must have a version field. `LocalStorageService.init()` must check the stored schema version and run migrations before any read.

---

## HIGH — Architecture and Performance

These will cause serious problems at scale and make the codebase impossible to maintain as it grows.

---

### H1. LocalStorageService is a God Object (831 Lines, 50+ Methods)
**File:** `lib/core/services/local_storage_service.dart`

**What's wrong:** A single class manages Users, Agencies, Brokers, Parents, Candidates, Link Requests, Shared Profiles, Conversations, Messages, Sessions, and Dashboard Statistics. This violates the Single Responsibility Principle aggressively. Adding a feature to messages requires modifying the same class as adding a feature to agency management.

**Diamond standard:**
```
services/
  user_service.dart         — CRUD for AppUser, session
  profile_service.dart      — BrokerProfile, ParentProfile, CandidateProfile
  agency_service.dart       — Agency management
  messaging_service.dart    — Conversations, messages
  link_service.dart         — LinkRequests, SharedProfiles
```

Each service gets its own Riverpod provider. Screens depend only on what they need.

---

### H2. Screens Directly Access Storage — No Repository Layer
**File:** `lib/screens/home_screen.dart:39`, and nearly every other screen

```dart
final storage = ref.read(localStorageServiceProvider);
final sharedProfiles = storage.getSharedProfilesForParent(userId);
```

**What's wrong:** The UI layer is tightly coupled to the persistence layer. There is no abstraction. This makes it impossible to:
- Switch to a real backend without rewriting every screen
- Unit test any screen logic
- Cache data between calls
- Add optimistic updates

**Diamond standard:** Use the Repository pattern. Screens consume repositories. Repositories consume services. Services consume data sources (Hive today, Firebase tomorrow).

```dart
// Screen
final profiles = ref.watch(sharedProfilesProvider(userId));

// Provider
final sharedProfilesProvider = FutureProvider.family<List<SharedProfile>, String>(...);

// Repository
class ProfileRepository {
  Future<List<SharedProfile>> getSharedProfiles(String userId) { ... }
}
```

---

### H3. Full Table Scans on Every Read — O(n) Everywhere
**File:** `lib/core/services/local_storage_service.dart:122-128`, and many other methods

```dart
AppUser? getUserByPhone(String phoneNumber) {
  for (final raw in _users.values) {
    final user = AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    if (user.phoneNumber == phoneNumber) return user; // Linear scan
  }
  return null;
}
```

The same pattern repeats for `searchAgencies()`, `searchBrokers()`, `getBrokerClients()`, and dashboard stat calculations. Every read decodes all records from JSON.

**Diamond standard:** Maintain secondary indices for all frequently-queried fields. Phone lookups, broker ID lookups, and agency searches should be O(1). If staying with Hive, use a separate index box. If moving to Firebase, use proper query indices.

---

### H4. Message Storage Re-encodes Entire Conversation on Every Send
**File:** `lib/core/services/local_storage_service.dart:720-745`

```dart
Future<void> _saveMessage(ChatMessage message) async {
  final existing = _messages.get(key);
  List<dynamic> messageList = [];
  if (existing != null) {
    messageList = jsonDecode(existing) as List<dynamic>; // Decode all messages
  }
  messageList.add(message.toJson());
  await _messages.put(key, jsonEncode(messageList)); // Re-encode all messages
}
```

**What's wrong:** Sending message #1000 in a conversation reads, decodes, appends, and re-encodes all 1000 previous messages. This is O(n) for every send. Chats will become unusably slow.

**Diamond standard:** Each message is its own Hive key: `messages_box.put('${conversationId}_${messageId}', ...)`. Use Hive's built-in sorted keys for ordering. Never store arrays as single encoded strings.

---

### H5. Duplicate Theme System
**Files:** `lib/core/theme/app_theme.dart` (551 lines), `lib/theme/app_theme.dart` (166 lines)

**What's wrong:** Two theme files. Different screens import different ones. Making a theme change requires finding which file applies to which screen. This will cause visual inconsistencies and makes future theming work chaotic.

**Diamond standard:** One theme file. One import. The legacy `lib/theme/` directory must be deleted. All imports updated. Any bridges or re-exports removed.

---

### H6. Unsafe Model Deserialization — No Null Checks
**File:** `lib/models/candidate_profile.dart:299-366`, `lib/models/broker_profile.dart`, others

```dart
factory CandidateProfile.fromJson(Map<String, dynamic> json) => CandidateProfile(
  id: json['id'] as String,           // Throws if 'id' is missing
  age: json['age'] as int,             // Throws if 'age' is null
  gender: Gender.values.byName(json['gender'] as String), // StateError on invalid
```

**What's wrong:** If any field is missing or has an unexpected type, `fromJson` throws. Old stored data that doesn't have a new field will crash deserialization. This is guaranteed data loss after any schema update.

**Diamond standard:**
```dart
id: json['id'] as String? ?? '',
age: (json['age'] as num?)?.toInt() ?? 0,
gender: Gender.values.byNameOrNull(json['gender'] as String? ?? '') ?? Gender.male,
```

All `fromJson` methods must handle missing and null fields gracefully.

---

### H7. No Input Validation on Phone Number
**File:** `lib/screens/auth/login_screen.dart:38-44`

```dart
void _sendOtp() {
  final phone = _phoneController.text.trim();
  if (phone.length < 10) { // Only checks length
```

**What's wrong:** Accepts any 10-character string. The user could enter `aaaaaaaaaa` and proceed to OTP. No format validation, no digit check.

**Diamond standard:**
```dart
final phoneRegex = RegExp(r'^[6-9]\d{9}$'); // Indian mobile numbers
if (!phoneRegex.hasMatch(phone)) { /* reject */ }
```

---

### H8. No Error Page in GoRouter
**File:** `lib/core/routing/app_router.dart`

**What's wrong:** No `errorPageBuilder` or `errorBuilder` defined. Navigating to an invalid route, or a redirect throwing an exception, produces an unhandled error screen with Flutter's debug red banner.

**Diamond standard:** Define a proper 404/error page. Wrap redirect logic in try-catch. Log navigation errors.

---

## MEDIUM — Code Quality and Maintainability

These don't cause crashes today but accumulate into technical debt that makes every future change harder.

---

### M1. Hard-coded Strings Everywhere — No Localization Foundation
**Files:** `home_screen.dart:170`, `broker_dashboard_screen.dart:96`, `chat_screen.dart:197`, and 40+ other locations

```dart
Text("Shared Profiles")
Text("Quick Actions")
Text("No messages yet")
```

**What's wrong:** No `l10n`, no `AppStrings` constant class. Every user-facing string is a magic literal. Future localization requires grep-and-replace across 40 files.

**Diamond standard:** Even without full i18n, create `lib/core/constants/app_strings.dart` as a single source of truth. Every UI string comes from there.

---

### M2. Magic Numbers Throughout UI
**File:** `lib/screens/home_screen.dart:486,500,121`, and many screens

```dart
CircleAvatar(radius: 26)
SizedBox(width: 14)
width: 32, height: 32
```

`AppSpacing` and `AppSizes` constants already exist and are well-defined. They are simply not being used consistently.

**Diamond standard:** Zero magic numbers in UI code. Every size, padding, and radius references a named constant.

---

### M3. 17 TextEditingControllers in One Screen
**File:** `lib/screens/broker/profile_create_edit_screen.dart:19-38`

```dart
final _nameController = TextEditingController();
final _ageController = TextEditingController();
// ... 15 more
```

**What's wrong:** 17 controllers means 17 listener registrations. While they're disposed correctly, this is an architectural problem. The screen is doing too much. Long forms also lose all data if the user backgrounds the app.

**Diamond standard:** Use `Riverpod` with a `StateNotifier` or `Notifier` to hold form state. The form state survives navigation, can be auto-saved to draft, and is testable without building the widget.

---

### M4. No Pagination — Loads Everything, Shows a Slice
**Files:** `lib/screens/broker/broker_dashboard_screen.dart:168-264`, `lib/screens/home_screen.dart:44`

```dart
final recentShared = storage.getSharedProfilesByBroker(brokerUserId);
// Loads ALL shared profiles...
for (final sp in recentShared.take(3)) { // ...then shows 3
```

**Diamond standard:** The storage layer must support limit/offset. Never load data you don't display. Implement `ListView.builder` with on-demand fetching via `AsyncValue` and Riverpod family providers.

---

### M5. No Logout Confirmation, No Feedback, No Error Handling
**File:** `lib/core/auth/auth_provider.dart:184-192`

```dart
Future<void> logout() async {
  await _storage.clearSession();
  state = const AuthInitial();
}
```

**Diamond standard:** Logout is a destructive action. It needs:
1. Confirmation dialog
2. Loading state while clearing session
3. Error handling if `clearSession()` fails
4. Success feedback

---

### M6. Loose `lib/widgets/` Parallel to `lib/common/widgets/`
**Directories:** `lib/widgets/` and `lib/common/widgets/`

**What's wrong:** Two widget directories. New developers don't know where to put or find widgets. The atomic design structure (`atoms/`, `molecules/`) exists in `common/widgets/` but `lib/widgets/` has 10 standalone widgets outside the system.

**Diamond standard:** One widget directory. Everything under `lib/common/widgets/` following atomic design. `lib/widgets/` deleted, contents migrated and organized properly.

---

### M7. No Form State Persistence — Data Lost on Navigation
**File:** `lib/screens/broker/profile_create_edit_screen.dart`

**What's wrong:** A profile creation form with 17 fields. If the user gets a phone call, switches apps, or accidentally taps Back — all data is gone. No auto-save. No draft. No warning.

**Diamond standard:** Form state lives in a Riverpod `Notifier`. Each field change is immediately persisted to a "draft" Hive key. On return to the screen, the draft is restored. A discard confirmation appears before clearing.

---

### M8. Inconsistent Error Handling Pattern in Storage Service

**What's wrong:** Some methods `throw Exception('...')` (generic), others return `null`, others return `false`. There is no consistent contract for how failures are communicated.

**Diamond standard:** Define a `Result<T>` type or use proper typed exceptions:
```dart
// All repository methods return Result<T>
sealed class Result<T> {
  const Result();
}
class Success<T> extends Result<T> { final T value; ... }
class Failure<T> extends Result<T> { final Object error; ... }
```

---

### M9. `main_new.dart` — Dead File in Root
**File:** `lib/main_new.dart`

**What's wrong:** A second entry point exists. It's never imported. Its relationship to `main.dart` is undocumented. It creates confusion about what the active entry point is.

**Diamond standard:** Delete it. If it contains relevant experiments, extract those into a branch or a feature file and delete the root-level file.

---

### M10. `debugLogDiagnostics: true` in Production Router
**File:** `lib/core/routing/app_router.dart:31`

```dart
return GoRouter(
  debugLogDiagnostics: true, // Logs every navigation event to console
```

**Diamond standard:** This should be `kDebugMode` gated:
```dart
debugLogDiagnostics: kDebugMode,
```

---

## LOW — Polish and Standards

These are not critical but separate "it works" code from diamond-standard code.

---

### L1. Same Icon Color in Both Dark and Light Chat Empty State
**File:** `lib/screens/chat/chat_screen.dart:191-193`

```dart
color: isDark
    ? AppColors.chatDarkGray
    : AppColors.chatDarkGray.withValues(alpha: 0.5), // Same base color
```

Both branches use `chatDarkGray`. The dark theme empty chat icon is the same color as the light theme background. This is invisible.

---

### L2. `DateFormat.jm()` — Locale Unaware Timestamp
**File:** `lib/screens/chat/chat_screen.dart:337`

`DateFormat.jm()` uses the system locale but ignores timezone. Chat messages from different timezones will show the stored UTC time as local time, producing wrong timestamps.

---

### L3. Unused Dependencies in pubspec.yaml
**File:** `pubspec.yaml`

- `shared_preferences` — not used; Hive handles all persistence
- `flutter_staggered_grid_view` — not found in any reviewed screen
- `cached_network_image` — no network images currently loaded

Clean dependencies reduce build time, bundle size, and security surface.

---

### L4. No Widget Documentation
**What's wrong:** `AppButton`, `AppAvatar`, `BrandedAppBar` have no doc comments explaining their parameters, variants, or intended use. A new developer joining the team cannot understand the component system without reading all the code.

**Diamond standard:** Every component in `lib/common/widgets/` has a doc comment explaining: purpose, variants/modes, required vs optional params, and a usage example.

---

### L5. Inconsistent Enum Extensions
**What's wrong:** Some enums have `.displayName`, others don't. `UserRole` has display logic in one place; `Gender` has it somewhere else. There is no consistent pattern.

**Diamond standard:** Every enum gets an extension with at minimum `.label` and `.description`. All display logic lives in the extension, not in widgets.

---

## What Diamond Standard Looks Like

This is the target. Every item in this section should become a non-negotiable standard.

---

### Architecture

```
lib/
  core/
    auth/           — Auth state, providers (KEEP, refine)
    routing/        — GoRouter (KEEP, add error pages)
    theme/          — ONE theme file (delete lib/theme/)
    constants/      — Colors, spacing, typography, strings, sizes (KEEP, add strings)
    services/       — Split into UserService, ProfileService, etc.
    repositories/   — New layer: abstract over services
    errors/         — Typed exception hierarchy
    utils/          — Pure functions (formatters, validators, helpers)
  models/           — Immutable, versioned, safe fromJson (KEEP, harden)
  features/         — Feature-first organization (migrate toward this)
    auth/
    parent/
    broker/
    candidate/
    admin/
    chat/
    shared/
  common/
    widgets/
      atoms/        — AppButton, AppAvatar, AppChip, AppTextField (KEEP, expand)
      molecules/    — BrandedAppBar, DetailTile, etc. (KEEP, expand)
      organisms/    — Complex composed components
    animations/     — KEEP
    hooks/          — Custom Riverpod hooks
  l10n/             — Localization (add)
```

---

### State Management Rules

1. **No screen reads from `localStorageServiceProvider` directly.** All data goes through a repository provider.
2. **All async data uses `AsyncValue`.** No manual `isLoading` booleans.
3. **Form state lives in a `Notifier`, not in widget `State`.** Forms survive navigation.
4. **One provider per data concern.** No providers that return multiple unrelated things.
5. **`ref.read` is for actions only.** `ref.watch` for reactive data. Never use `ref.read` to subscribe to state.

---

### Widget Rules

1. **No magic numbers.** Every size, padding, radius is a named constant.
2. **No hard-coded strings.** Every user-facing string comes from `AppStrings`.
3. **Every public widget has a doc comment.**
4. **Widgets are pure functions of their inputs.** No internal async calls. Data comes from providers, passed via constructor.
5. **No widget does more than one thing.** Break complex widgets into smaller private helpers.
6. **No `setState` in production screens.** Use Riverpod.

---

### Model Rules

1. **Every model has a `version` field.**
2. **`fromJson` never throws.** All fields have null-safe fallbacks.
3. **Every enum has an extension** with `.label` at minimum.
4. **`copyWith` is always complete** — every field is covered.
5. **No model contains business logic.** Models are data containers only.

---

### Performance Rules

1. **All list queries support limit/offset.** No loading-all-then-slicing.
2. **Messages are stored individually.** Not as encoded arrays.
3. **Frequently queried fields have secondary indices.**
4. **`const` everywhere possible.** Lint rule `prefer_const_constructors` enabled.
5. **No synchronous I/O on the main thread.**

---

### Testing Requirements (Diamond Standard Means Tested)

```
test/
  unit/
    models/           — fromJson, toJson, copyWith for every model
    services/         — Every service method
    repositories/     — Repository logic with mocked services
    auth/             — Auth state machine transitions
  widget/
    atoms/            — AppButton variants, AppAvatar, AppTextField
    molecules/        — BrandedAppBar, DetailTile
    screens/          — Key screens with mocked providers
  integration/
    auth_flow_test.dart
    profile_creation_test.dart
    chat_test.dart
```

No untested auth logic. No untested model deserialization. No untested routing.

---

## Prioritized Fix Plan

### Phase 1 — Foundation (Do Before Anything New Is Built)
1. Wrap all `fromJson` calls in null-safe accessors (C4, H6)
2. Add try-catch to `checkAuthStatus` (C2)
3. Add Hive schema versioning with migration stub (C4)
4. Delete `lib/theme/app_theme.dart`, update all imports (H5)
5. Delete `lib/main_new.dart` (M9)
6. Delete `lib/widgets/`, move contents to `lib/common/widgets/` (M6)
7. Gate `debugLogDiagnostics` on `kDebugMode` (M10)
8. Add `errorBuilder` to GoRouter (H8)

### Phase 2 — Architecture
1. Split `LocalStorageService` into 5 domain services (H1)
2. Introduce repository layer (H2)
3. Convert all screen data access to use repository providers (H2)
4. Fix message storage — individual keys per message (H4)
5. Add secondary indices for phone and broker ID lookups (H3)
6. Move all form state to Riverpod notifiers (M3, M7)

### Phase 3 — Quality and Polish
1. Create `AppStrings` constants file (M1)
2. Replace all magic numbers with named constants (M2)
3. Add doc comments to all `lib/common/widgets/` components (L4)
4. Standardize enum extensions (L5)
5. Remove unused pubspec.yaml dependencies (L3)
6. Fix dark/light theme chat empty state icon (L1)
7. Add `Result<T>` type for consistent error handling (M8)

### Phase 4 — Testing
1. Unit tests for all models
2. Unit tests for auth state machine
3. Widget tests for AppButton, AppAvatar, AppTextField
4. Integration test for auth flow
5. Integration test for profile creation

---

## Current Scores

| Category | Current | Target |
|----------|---------|--------|
| Architecture | 4/10 | 10/10 |
| Security | 2/10 | 10/10 |
| Performance | 4/10 | 10/10 |
| Code Quality | 5/10 | 10/10 |
| Test Coverage | 1/10 | 10/10 |
| UI Consistency | 6/10 | 10/10 |
| **Overall** | **3.7/10** | **10/10** |

The design system, component library, and role-based routing are genuine strengths worth preserving and building on. The path to diamond standard is clear — it requires discipline, not a rewrite.
