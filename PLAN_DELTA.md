# Plan Delta — Anuyatra (loving-cray branch)

Validation of three planning documents against the current codebase, recording **only what is still outstanding** per plan. Each open item cites the file the claim is verified against.

Sources audited:

- `~/.cursor/plans/diamond_architecture_overhaul_365b55bb.plan.md`
- `lib/.cursor/plans/multi-language_localization_4d5f8b4f.plan.md`
- `~/.cursor/plans/production_readiness_audit_c20e9fb6.plan.md`

Code state captured on branch **loving-cray**, after the recent dark-mode + lint-fix pass.

---

## Audit summary

| Plan | Done | Outstanding | Verdict |
|---|---|---|---|
| Diamond Architecture | repos / DI / async + pagination contracts / typed exceptions / phone regex / `errorBuilder` / `kDebugMode` / `@Deprecated` / `app_strings.dart` | seeding still on `LocalStorageService`, messaging storage format, dual `AppTheme`, dual widgets tree, root scripts, unused deps, auth init still in `initState`, dead screens | ~60% executed |
| Multi-language Localization | ARBs / `gen-l10n` / `flutter_localizations` / `LocaleProvider` / `LanguagePickerTile` / `context.l10n` / `AuthErrorType` / Haskoy fonts removed | `AppStrings` still referenced; ~95 hardcoded `Text('...')` literals; missing `userNotFound` enum case | Infrastructure done, migration unfinished |
| Production Readiness | overflow fix / agency city–state persistence / parent shared profiles flow / forward-to-child wired / broker chat wired / models enriched / photo picker | legacy `MockData` screens, real auth/backend/notifications, shimmer + pull-to-refresh, T&C/privacy, rate-limiting, encryption | ~50% addressed, rest is product backlog |

---

## 1. Diamond Architecture Overhaul — Outstanding Work

### 1.1 Seeding still wired to deprecated `LocalStorageService`

- `lib/main.dart:33` constructs `final storage = LocalStorageService();`
- `lib/main.dart:54` overrides `localStorageServiceProvider.overrideWithValue(storage)`
- `lib/data/seed_data.dart:22` signature: `Future<void> seedDemoData(LocalStorageService storage) async`

Plan said the seeder should run on repository interfaces (Phase 3) and there should be a `SeedConfig` toggle.

**To do:**
- [ ] Add `lib/data/seed_config.dart` with `enabled` + `forceReseed` toggles.
- [ ] Rewrite `seedDemoData(...)` to accept `AppDataModule` (or individual repositories), not `LocalStorageService`.
- [ ] Drive the first-launch check off `userRepository.getAllUsers()` instead of `storage.isFirstLaunch`.
- [ ] Remove the `localStorageServiceProvider` override from `main.dart`.
- [ ] Delete `LocalStorageService` once nothing imports it (or move it under `lib/data/legacy/` for archival).

### 1.2 Messaging storage still uses JSON-array per conversation

- `lib/core/data/local/hive_messaging_repository.dart:13-15` comment confirms the "messages are stored per-conversation as a JSON array … individual keys deferred."

Plan called for `{conversationId}_{messageId}` keys (O(1) sends).

**To do:**
- [ ] Migrate to individual-key writes (`'${conversationId}_${msg.id}'`).
- [ ] Add a one-time migration on app start that reads the old array, writes individual keys, then deletes the array key.
- [ ] Update `getMessages(conversationId, {limit})` to filter keys by prefix and sort by timestamp.

### 1.3 Dual `AppTheme` files

- `lib/core/theme/app_theme.dart` — canonical, used by `main.dart` for `MaterialApp.router`.
- `lib/theme/app_theme.dart` — "legacy bridge" still imported by **27 files** (e.g. `lib/screens/financial_compatibility_screen.dart:5`, `lib/screens/trust_verification_screen.dart:5`, `lib/screens/profile_detail_screen.dart:6`, `lib/screens/main_navigation.dart:9` and many more).

Plan (2E) said: delete `lib/theme/app_theme.dart` and consolidate.

**To do:**
- [ ] Lift the context-aware helpers (`primaryText`, `secondaryText`, `cardSurface`, `divider`, `isDark`, `appBarBackground`, `cardShadow`, `getStatusColor`, `getChatBubbleColor`) onto `lib/core/theme/app_theme.dart` or a sibling `theme_extensions.dart`.
- [ ] Rewrite all 27 imports to point at `lib/core/theme/...`.
- [ ] Delete `lib/theme/app_theme.dart`.

### 1.4 Two widget trees

- `lib/widgets/` (10 files) still imported from screens such as `lib/screens/vivaha_samskara_home_screen.dart:6-8`, `lib/screens/broker_screen.dart:9-10`, `lib/screens/profile_detail_screen.dart:9`, the three `lib/screens/services/*.dart` files.
- `lib/common/widgets/atoms/` + `lib/common/widgets/molecules/` exist (the canonical tree).

Plan (2G) said: move everything into `lib/common/widgets/` and delete `lib/widgets/`.

**To do:**
- [ ] Classify each of `lib/widgets/{appointment_card,chat_bubble,premium_service_card,profile_action_bar,profile_list_item,profile_message_card,service_appointment_card,service_feature_card,service_progress_card,task_card}.dart` as atom / molecule / organism.
- [ ] Move them under `lib/common/widgets/...`.
- [ ] Update all importers (12 known import sites).
- [ ] Delete `lib/widgets/`.

### 1.5 Root-level non-Dart scripts still present

- `_gen.py`, `_gen.sh`, `_gen_models.py`, `_w.sh`, `_d.b64` at the repo root.

Plan (4C) said: delete these.

**To do:**
- [ ] Verify nothing in CI or developer docs references them, then delete.

### 1.6 Potentially unused dependencies

`pubspec.yaml` still declares deps the plan (2L) flagged for removal. Current usage:

| Dep | Used by |
|---|---|
| `shared_preferences` | `lib/core/providers/locale_provider.dart`, `lib/core/providers/theme_provider.dart` — **legitimately used** (locale + theme persistence) |
| `cached_network_image` | `lib/screens/brokers_list_screen.dart`, `lib/screens/shortlist_screen.dart`, `lib/screens/broker_screen.dart`, `lib/screens/profile_detail_screen.dart`, `lib/widgets/profile_message_card.dart` — **only legacy screens** |
| `flutter_staggered_grid_view` | `lib/screens/shortlist_screen.dart` only — **only legacy screen** |

**To do:**
- [ ] After Phase 4.2 below (delete legacy `MockData` screens), drop `cached_network_image` and `flutter_staggered_grid_view` from `pubspec.yaml`.
- [ ] Keep `shared_preferences`; the plan's removal note is now stale.

### 1.7 Auth init still kicked from `initState`

- `lib/main.dart:103-108`: `AnuyatraApp.initState` calls `WidgetsBinding.instance.addPostFrameCallback((_) { ref.read(authProvider.notifier).checkAuthStatus()... })`.

Plan (2B) wanted auth resolved **before** `runApp` so the router sees the right state on frame 1.

Note: the current pattern with `refreshListenable` + the router's `redirect` largely papers over the race condition, but a brief flash of the login screen for already-signed-in users is still possible on a cold start.

**To do (optional — only if the flash is observed):**
- [ ] In `main()`, before `runApp`, build a temporary `ProviderContainer`, call `authProvider.notifier.checkAuthStatus()` to completion, then read the resulting state, then call `runApp` with a fresh `ProviderScope` (or transfer the state).
- [ ] Or: keep the current pattern and close this item as "superseded by refreshListenable" once verified on device.

### 1.8 `AppStrings` is a near-empty husk

- `lib/core/constants/app_strings.dart` is 129 lines, only **one** reference remains in the app: `lib/main.dart:122` (`title: AppStrings.appTitle`).

This is the bridge between the Diamond plan (which created `AppStrings`) and the l10n plan (which wants it deleted). See §2.1.

### 1.9 Dead screen in `lib/screens/`

- `lib/screens/main_navigation.dart` (`MainNavigationScreen`, 471 lines) — **zero references** outside its own file (`grep -rn 'MainNavigationScreen' lib` returns only self-references). It still imports `AppColors`, `app_theme`, and instantiates `HomeScreen`, `ShortlistScreen`, `BrokersListScreen`, `VivahaSamskaraHomeScreen`, `TrustVerificationScreen`, `FinancialCompatibilityScreen`, `VirtualMeetingScreen`.

Not explicitly named in the Diamond plan but matches its "delete dead legacy entry points" theme (2F).

**To do:**
- [ ] Delete `lib/screens/main_navigation.dart`.

### 1.10 Diamond-plan items already done — confirmed

- `lib/core/data/result.dart` exists. ✅
- 8 abstract interfaces in `lib/core/data/repositories/`. ✅
- 8 Hive implementations in `lib/core/data/local/`. ✅
- `lib/core/data/app_data_module.dart`. ✅
- `lib/core/providers/repository_providers.dart`. ✅
- All read methods are `Future`-returning; list methods accept `{int? limit, int? offset}` (`lib/core/data/repositories/broker_repository.dart:12-27`, `link_repository.dart:29-49`, `messaging_repository.dart:14-41`, `profile_repository.dart:15-35`). ✅
- `AuthNotifier` depends on `AuthRepository` / `UserRepository` / `ProfileRepository`, not `LocalStorageService` (`lib/core/auth/auth_provider.dart`). ✅
- Indian phone regex `^[6-9]\d{9}$` (`lib/core/auth/auth_provider.dart:15`). ✅
- `checkAuthStatus` wrapped in try/catch → `AuthInitial` (`lib/core/auth/auth_provider.dart:45-54`). ✅
- `lib/core/services/local_storage_service.dart:24` is `@Deprecated(...)`. ✅
- No screen calls `ref.watch(localStorageServiceProvider)` (grep clean). ✅
- `lib/core/routing/app_router.dart:68` has `debugLogDiagnostics: kDebugMode` and `:111` has `errorBuilder`. ✅
- `main_new.dart` no longer exists. ✅
- `lib/core/errors/app_exceptions.dart` exists. ✅
- Typography uses Inter/Poppins via `GoogleFonts`; Haskoy fonts removed from `pubspec.yaml`. ✅

---

## 2. Multi-Language Localization — Outstanding Work

### 2.1 `AppStrings` deprecation not finished

- File still exists: `lib/core/constants/app_strings.dart` (129 lines).
- Only consumer is `lib/main.dart:122` (`AppStrings.appTitle` for the `MaterialApp.router` title).
- No `@Deprecated` annotation; plan's `deprecate-appstrings` todo is not done.

**To do:**
- [ ] Add `appTitle` to `lib/l10n/app_en.arb`, `app_hi.arb`, `app_te.arb`.
- [ ] Change `lib/main.dart:122` to read from `AppLocalizations` for the title (`onGenerateTitle: (ctx) => ctx.l10n.appTitle`).
- [ ] Annotate `AppStrings` with `@Deprecated('Use context.l10n.* instead')`.
- [ ] Verify zero remaining imports, then delete the file.

### 2.2 `AuthErrorType` enum missing one case

Plan listed 7 cases including `userNotFound`. Implementation in `lib/core/auth/auth_state.dart:8-15` has 6 (missing `userNotFound`).

**To do:**
- [ ] Decide whether `userNotFound` is needed. If a phone number with no registered user attempts OTP, the current `AuthNotifier` probably emits `verificationFailed` — confirm and either add `userNotFound` + an ARB string, or formally retire the plan's claim.

### 2.3 ~94 hardcoded English `Text('...')` strings still in screens

`grep -rn "Text('[^']" lib/screens lib/widgets | wc -l` → **87** `Text(...)` literals, plus **7** translatable `hintText:`/`labelText:`/`tooltip:` literals (the 8th raw match in [admin_brokers_screen.dart:194](lib/screens/admin/admin_brokers_screen.dart#L194), [login_screen.dart:166](lib/screens/auth/login_screen.dart#L166), [link_to_parent_screen.dart:174](lib/screens/candidate/link_to_parent_screen.dart#L174) — three phone-number format placeholders like `'9876543210'` / `'+91 XXXXX XXXXX'` — are non-translatable and stay hardcoded). Net translatable backlog ≈ **94**. Highest concentrations:

| File | Hardcoded `Text(...)` literals |
|---|---|
| `lib/screens/financial_compatibility_screen.dart` | 10 |
| `lib/screens/trust_verification_screen.dart` | 9 |
| `lib/screens/virtual_meeting_screen.dart` | 9 |
| `lib/screens/profile_detail_screen.dart` | 7 |
| `lib/screens/services/beauty_transformation_screen.dart` | 3 |
| `lib/screens/services/health_wellness_screen.dart` | 3 |
| `lib/screens/services/cultural_learning_screen.dart` | 3 |
| 18 other screens (auth, broker, parent, candidate, admin) | balance |

Plan named exactly these as the migration backlog.

**To do:**
- [ ] Add the missing keys to `app_en.arb` (+ hi / te). Reuse plan's camelCase convention.
- [ ] Replace each literal with `context.l10n.<key>`.
- [ ] Snapshot the count after each screen so progress is visible.

### 2.4 `l10n.yaml` config drift vs plan

Plan specified `synthetic-package: true`. Actual `l10n.yaml`:

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-dir: lib/l10n
output-class: AppLocalizations
nullable-getter: false
```

Outputs to `lib/l10n/` (committed to source) instead of `.dart_tool/flutter_gen/`. **This is acceptable** — committed generated files mean `dart analyze` works without `flutter`. No action required; mark this divergence resolved in the plan if revisited.

### 2.5 L10n items already done — confirmed

- `flutter_localizations` + `intl ^0.20.2` + `generate: true` in `pubspec.yaml`. ✅
- `lib/l10n/app_en.arb` + `app_hi.arb` + `app_te.arb`. ✅
- Generated `lib/l10n/app_localizations*.dart`. ✅
- `lib/core/l10n/l10n_extension.dart` exposes `context.l10n`. ✅
- `lib/core/providers/locale_provider.dart` (Riverpod `Notifier` pattern). ✅
- `lib/common/widgets/atoms/language_picker_tile.dart`. ✅
- `MaterialApp.router` wired with `locale` / `localizationsDelegates` / `supportedLocales` (`lib/main.dart:124-127`). ✅
- `AuthErrorType` enum drives error messages via `context.l10n` (e.g. `lib/screens/auth/otp_verify_screen.dart:42-43`). ✅

---

## 3. Production Readiness — Outstanding Work

### 3.1 Three legacy screens still consume `MockData` + two transitive orphans

**Direct `MockData` consumers:**
- [shortlist_screen.dart:30](lib/screens/shortlist_screen.dart#L30) — `MockData.profiles`
- [brokers_list_screen.dart:14](lib/screens/brokers_list_screen.dart#L14) — `MockData.brokers`
- [broker_screen.dart:26](lib/screens/broker_screen.dart#L26) — `MockData.getChatMessages()`

**Transitive legacy-model consumers** (only reachable via the trio above):
- [profile_detail_screen.dart:4-5](lib/screens/profile_detail_screen.dart#L4) — imports `models/profile.dart` + `models/broker.dart`; only opened from [shortlist_screen.dart:122](lib/screens/shortlist_screen.dart#L122) and [widgets/profile_message_card.dart:464,479](lib/widgets/profile_message_card.dart#L464).
- [widgets/profile_message_card.dart:3-4](lib/widgets/profile_message_card.dart#L3) — same legacy models; only used from [broker_screen.dart:156](lib/screens/broker_screen.dart#L156).

**Live entry point that still ships mock content:**
- [anuyatra_hub_screen.dart](lib/screens/anuyatra_hub_screen.dart) **is reachable** through GoRouter for both Parent ([app_router.dart:192](lib/core/routing/app_router.dart#L192)) and Candidate ([app_router.dart:279](lib/core/routing/app_router.dart#L279)) shells. From the Hub the user can navigate into `VivahaSamskaraHomeScreen`, `TrustVerificationScreen`, and `FinancialCompatibilityScreen` — all three read from static mock data ([revolutionary_features_data.dart](lib/data/revolutionary_features_data.dart), [premium_services_data.dart](lib/data/premium_services_data.dart)). `VivahaSamskaraHomeScreen` in turn opens the three `lib/screens/services/*` screens, also mock-fed.

Note: the Hub flow does **not** pull from `MockData` (which is the legacy `Profile`/`Broker` mock); it uses its own feature-mock data files. Deletion plan for the trio does not impact the Hub — they are independent mock systems. But the Hub flow is still "demo data shipped as production" and belongs on the cleanup ledger.

The three `MockData` screens are only reachable from `main_navigation.dart` (dead code, §1.9). `grep -rn 'BrokerScreen\|ShortlistScreen\|BrokersListScreen' lib` returns only declarations + the `main_navigation` references.

**To do:**
- [ ] Delete [main_navigation.dart](lib/screens/main_navigation.dart) first (§1.9). That makes the trio unreachable.
- [ ] Delete the trio: `shortlist_screen.dart`, `brokers_list_screen.dart`, `broker_screen.dart`.
- [ ] Delete the transitive orphans: `lib/screens/profile_detail_screen.dart`, `lib/widgets/profile_message_card.dart`.
- [ ] Delete legacy models: `lib/models/profile.dart`, `lib/models/broker.dart`.
- [ ] Delete `lib/data/mock_data.dart`.
- [ ] Drop `cached_network_image` + `flutter_staggered_grid_view` from `pubspec.yaml` (their only consumers are the files above).
- [ ] Separately: decide what to do with the Hub flow. Options: (a) keep as-is and label "demo / coming soon", (b) gate behind a `kDebugMode` flag in `app_router.dart`, (c) gut the static mock data and wire it to a real `PremiumServiceRepository` when backend lands.

### 3.2 Authentication is mocked

- `lib/core/auth/auth_provider.dart` accepts any phone, OTP hardcoded to `123456`.

Plan acknowledged this is intentional for demo; it's listed under "Missing Features for Production." Still true. No code change planned — flag for backend integration when ready.

### 3.3 No backend

- Firebase commented out in `pubspec.yaml`. Hive is the only store.
- All repository interfaces are async-by-contract, so backend swap is a one-line `main.dart` change once a `FirebaseXRepository` set exists.

**To do (long-term, not in current scope):**
- [ ] Add `lib/core/data/remote/firebase_*_repository.dart` implementations.
- [ ] Add `AppDataModule.initRemote(Config)`.

### 3.4 No push notifications

- Link requests, shared profiles, and incoming chat messages have no push or local notification surface.

**To do:**
- [ ] Wire `flutter_local_notifications` + FCM (once backend lands) to surface `LinkRequest` and `SharedProfile` writes.

### 3.5 UX polish gaps

| Item | Status |
|---|---|
| Loading shimmer | `ShimmerLoading` widget exists at [lib/common/animations/app_animations.dart:283](lib/common/animations/app_animations.dart#L283) but **zero screens instantiate it** — `grep ShimmerLoading lib` only matches the widget's own file. Most screens still show blank during load |
| Pull-to-refresh | 3 `RefreshIndicator` references — sparse |
| Destructive confirmations | Logout has a confirm dialog on **5 of 5** profile screens (`candidate_own_profile_screen.dart:266`, `app_settings_screen.dart:165`, `broker_own_profile_screen.dart:433`, `parent_profile_screen.dart:323`, `agency_settings_screen.dart:303`). ✅ Decline/reject link requests do NOT have confirms — to add |
| Profile completeness indicator | Wired on [ProfileViewScreen](lib/screens/profile/profile_view_screen.dart#L171) only (uses `CandidateProfile.profileCompleteness` getter). **None of the own-profile screens** (candidate / parent / broker) surface it. `FinancialCompatibilityScreen` shows a separate `FinancialProfile.profileCompleteness` chip — unrelated |
| Search/filter on shared profiles | Parent + candidate shared-profile screens have no filter UI |
| Pagination UI | Repositories accept `limit`/`offset`, but no screen exposes "load more" or infinite scroll |
| Offline mode indicator | Not present |
| Terms of Service / Privacy Policy screens | Not present |
| Onboarding walkthrough | Not present |
| Rate limiting on link requests | Not present (a parent can spam `sendLinkRequest`) |
| Hive data encryption for PII | Not present (using `Box<String>` plaintext) |

**To do (prioritized order if you take a UX pass):**
- [ ] Add `RefreshIndicator` on every list screen that reads from a repository: discovery, my-brokers, broker-clients, parent-shared-profiles, candidate-shared-profiles, link-requests.
- [ ] Replace blank loading states with a shared `AppShimmer` (atom under `lib/common/widgets/atoms/`).
- [ ] Add confirm dialog on `LinkRequest.decline` and `SharedProfile` "Pass" actions.
- [ ] Add a profile-completeness chip to each role's own-profile screen.
- [ ] Add filter chips on shared-profile lists.
- [ ] Implement pagination UI on discovery (request `limit: 20`, append on scroll).
- [ ] Add rate-limit guard in `LinkRepository.sendLinkRequest` (drop or queue duplicates within a window).
- [ ] Add Terms/Privacy stub screens, link from Settings.
- [ ] Add `hive` AES encryption (`Hive.openBox<String>('users', encryptionCipher: ...)`) and store the key in `flutter_secure_storage` — only worth doing once backend is in scope.

### 3.6 Production-plan items already done — confirmed

- Discovery card overflow (1A) — `lib/screens/search/discovery_screen.dart` uses `Flexible` + `maxLines: 1` + `overflow: TextOverflow.ellipsis` (e.g. lines 503-504, 534, 541-542). ✅
- Agency city/state persistence (1B) — `lib/models/agency.dart:123-124,148-149` `copyWith` includes city/state; `lib/screens/admin/agency_settings_screen.dart:82` calls `agencyRepo.saveAgency(updated)`. ✅
- Parent shared profiles flow (2A) — `lib/screens/home_screen.dart:41,80` uses `sharedProfileRepositoryProvider`, not `MockData.profiles`. ✅
- Forward-to-child trigger (2C) — `lib/screens/home_screen.dart:106-112` opens `ForwardToChildSheet`; line 247 wires the button. ✅
- Broker chat wiring (2D) — `lib/screens/broker/broker_clients_screen.dart:252,268-275` opens `RouteNames.chat`. ✅
- `ParentProfile` enrichment — `lib/models/parent_profile.dart` adds 30+ fields (child details, horoscope, family, lifestyle, partner preferences, contact). ✅
- `CandidateProfile` enrichment — `lib/models/candidate_profile.dart:67+` adds DOB, income, complexion, weight, blood group, diet, smokes/drinks, manglik, gotra, rashi, nakshatra, birth time. ✅
- `BrokerProfile` enrichment — `lib/models/broker_profile.dart` adds email/licenseNumber/languages/feeStructure/workingHours/socialMediaLinks/totalSuccessfulMatches/verificationStatus. ✅
- `Agency` enrichment — `lib/models/agency.dart` adds email/licenseNumber/languagesServed/feeStructure/verificationStatus. ✅
- Photo manager — `lib/common/widgets/molecules/photo_manager_widget.dart` exists and is wired in `lib/screens/broker/profile_create_edit_screen.dart:233`. ✅

---

## Recommended sequencing if you tackle this next

A. **Cheap, high-clarity deletions** (low risk, large code-tree shrink)
   1. Delete `lib/screens/main_navigation.dart` (§1.9).
   2. Delete root scripts `_gen.py`, `_gen.sh`, `_gen_models.py`, `_w.sh`, `_d.b64` (§1.5).
   3. Delete the legacy demo flow (now unreachable once A.1 lands): `lib/screens/{shortlist_screen,brokers_list_screen,broker_screen,profile_detail_screen}.dart` + `lib/widgets/profile_message_card.dart` + `lib/models/{profile,broker}.dart` + `lib/data/mock_data.dart` (§3.1). Drop `cached_network_image` + `flutter_staggered_grid_view` from `pubspec.yaml` (§1.6).

B. **Theme consolidation** (high-leverage cleanup; touches 27 files)
   4. Merge `lib/theme/app_theme.dart` into `lib/core/theme/app_theme.dart`, rewrite imports, delete the legacy file (§1.3).

C. **Widget tree consolidation** (12 importers)
   5. Move `lib/widgets/*` under `lib/common/widgets/{atoms,molecules,organisms}/`, rewrite imports, delete `lib/widgets/` (§1.4).

D. **Seeding migration** (clears most remaining deprecation lints)
   6. Add `lib/data/seed_config.dart`, refactor `seedDemoData` to repository interfaces, remove `LocalStorageService` from `main.dart` (§1.1).

E. **Localization completion** (mechanical sweep)
   7. Migrate `appTitle` then sweep the ~95 hardcoded `Text('...')` literals (§2.3), then delete `AppStrings` (§2.1).

F. **Messaging storage migration** (performance correctness)
   8. Switch `HiveMessagingRepository` to individual keys with a one-shot migration on first run (§1.2).

G. **Polish + product items** (ongoing)
   9. Empty-state shimmers, pull-to-refresh, decline confirms, profile completeness, pagination UI (§3.5).
