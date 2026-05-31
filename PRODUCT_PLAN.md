# Anuyatra Product Plan

A working document covering: (1) the product-level issues you raised, (2) the boot-time flash you just noticed, (3) issues I'm flagging that you haven't called out yet, and (4) the recommended order of attack.

Code citations use `path:line` against the **loving-cray** branch state today.

---

## Part 1 — Issues you raised

### 1.1 Parent landing-page profile cards are wrong

> "Profiles list in the landing page: with swappable photos (how it was before) and some important details."

**Current state.** [home_screen.dart:497-509](lib/screens/home_screen.dart#L497) renders each shared candidate as a `Card` with a `CircleAvatar` containing the first letter of the name. There is **no photo carousel**, even though `CandidateProfile.photos` is a populated `List<String>` ([candidate_profile.dart:55](lib/models/candidate_profile.dart#L55)) and the seed data sets URLs for every candidate.

**Detail fields surfaced today**: name, age, profession, education snippet, broker name, response chip. Missing on the card: photos, location prominence, religion/community, height, key tags (Manglik, diet, etc.).

**Approach.**

- Replace the `CircleAvatar` with a horizontally-swappable photo strip (`PageView.builder` over `profile.photos`, with page indicator dots; fallback to a placeholder Container when `photos` is empty).
- Promote the most decision-relevant fields to the card surface: name, age, height, profession, city, community/religion. Defer rarely-scanned fields (siblings, family background) to the detail screen.
- Add a "more on detail" affordance (the whole card is already tappable to `RouteNames.profileView`; keep that).

**New widget**: `lib/common/widgets/molecules/profile_photo_carousel.dart` (atom-flavored molecule — photo swipe + dot indicator + tap-to-open-fullscreen).

### 1.2 Action set: Save · Interested · Pass (drop "Maybe")

> "Save, send a like i.e. inform the broker that we are interested, or not interested (PASS) … existing Maybe button doesn't make sense."

**Current state.** [home_screen.dart:229-245](lib/screens/home_screen.dart#L229) wires four buttons: Interested, Maybe, Pass, Forward. The `SharedProfileResponse` enum has `pending / interested / maybe / pass` ([shared_profile.dart](lib/models/shared_profile.dart)). There is **no Save action at all** — saving is conceptually a different verb from any of the response choices.

**Approach.**

1. **Add `Save`** as an independent dimension from `SharedProfileResponse`. A profile can be saved without yet having a response. New model `SavedProfile` (`{userId, profileId, savedAt}`) + repository + provider. Storage box `savedProfiles`.
2. **Drop `Maybe` from the UI.** Don't delete the enum value (existing seed/data depends on it); add `@Deprecated` and stop offering it as an action. Migrate displayed `maybe` records to `pending`.
3. **Wire the new action row**: `Save` (toggle) · `Interested` · `Pass`. Forward-to-child stays as a secondary action (icon button or three-dot menu).
4. **Notify broker on Interested.** This is a real loop: when the parent taps Interested, the broker's `_pendingRequests` / activity feed should reflect it. Currently the SharedProfile carries `parentResponse` but no notification or activity-feed entry. Solution: emit an activity record (new model) on response change; broker dashboard reads it.
5. **Undo on Pass.** Pass is the most destructive: show a `SnackBarAction(label: 'Undo')` for ~6 seconds before persisting (or persist + offer 6-second revert).
6. **Response is never final.** Once a parent marks Interested or Pass, the response can still be changed later. The action buttons disappear from the *list card* (it's a one-tap commit there) but remain on the *profile detail screen* as a switchable segmented control: `[Interested · Pass · Reset]`. Tapping a different value updates `parentResponse` and re-notifies the broker. Important because parents change their mind after seeing more details, talking to the family, etc. Implementation: the `_ParentProfileCard` only renders the three-button row when `parentResponse == pending`; the `ProfileViewScreen` always renders the segmented control with the current value selected.

### 1.3 Increase font size of the whole app

> "Increase the FONT SIZE of the entire app."

**Current state.** Base body sizes in [app_typography.dart](lib/core/constants/app_typography.dart): 12 / 14 / 16. Title sizes: 14 / 16 / 22. Small for parents/grandparents reading on a 5-6" phone.

**Approach.** Bump the body, title, and label scales in `AppTypography` by 1-2pts each (table below). Leave headlines/display alone — they're already large. Many inline `fontSize: 11/12/14` literals exist in product screens; those won't change with the token bump, but the screens being rebuilt (1.1, 1.5, 1.6) will be cleaned up to use tokens.


| Token           | Before → After            |
| --------------- | ------------------------- |
| bodySmall       | 12 → 13                   |
| bodyMedium      | 14 → 16 *(dominant size)* |
| bodyLarge       | 16 → 18                   |
| titleSmall      | 14 → 16                   |
| titleMedium     | 16 → 18                   |
| titleLarge      | 22 → 24                   |
| labelSmall      | 11 → 12                   |
| labelMedium     | 12 → 13                   |
| labelLarge      | 14 → 15                   |
| profileSubtitle | 14 → 16                   |
| caption         | 12 → 13                   |


### 1.4 Large search bar with text + audio search and filters

> "Large Search Bar with text and audio based search for fields like profession, location and such… with filters that also work with audio."

**Current state.** [discovery_screen.dart:196](lib/screens/search/discovery_screen.dart#L196) has a small inline `TextField` with `hintText: 'Search brokers, agencies, cities...'`. No mic, no audio. Filters not yet present.

**Approach.**

- Add `speech_to_text: ^7.x` package dependency.
- **Recognition locale = device locale by default** (decision confirmed). `speech_to_text` accepts a `localeId`; we pass `Localizations.localeOf(context).toLanguageTag()`. Falls back to `en-IN` if the device locale isn't supported. The app's active locale (from §2.3 / `LocaleNotifier`) takes precedence over device when the user has explicitly chosen one. Surface a small locale chip next to the mic ("Listening in हिन्दी") so users know what's being recognised.
- Build `AppVoiceSearchBar` (molecule): large rounded search input (52-56px tall), mic icon button on the right, mic press triggers an animated listening state, finalized transcript fills the input.
- Build a filter sheet (`SearchFiltersSheet`) with sections for Profession, Location, Age range, Community, etc. Each text-input filter gets its own mic icon for per-field voice input.
- Wire to `BrokerRepository.searchBrokers` / `AgencyRepository.searchAgencies` / a new `ProfileRepository.searchCandidates` (the candidate search method exists conceptually but not as a screen entrypoint).
- Persist last 5 search terms in `SharedPreferences` and show as chips below the bar.

### 1.5 Astrology section (in-app match + offline manual entry)

> "Astrology match section. Our app's astrology matching section. Offline Astrology section where they can enter the astrology details themselves."

**Current state.** All astrology fields are already on the model:

- `CandidateProfile.rashi / nakshatra / gotra / birthTime / birthPlace / manglikStatus` ([candidate_profile.dart:78-79](lib/models/candidate_profile.dart#L78))
- `ParentProfile.childRashi / childNakshatra / childGotra / ...` ([parent_profile.dart:50-54](lib/models/parent_profile.dart#L50))

But there is **no matching screen** and **no matching algorithm**. The "Anuyatra Hub" → "Trust Verification" / "Financial Compatibility" cards exist; astrology is conceptually adjacent but absent.

**Approach.**

1. `**AstrologyMatchScreen`** — pick two profiles (one your own / your child, one a candidate) → show point-by-point compatibility table on the 8 standard kootas/gunas (Varna, Vashya, Tara, Yoni, Graha Maitri, Gana, Bhakoot, Nadi). Score out of 36. **v1 = rule-based Quick Match** (decision confirmed): rashi-level compatibility + nakshatra exclusion list + manglik match. No panchang library yet. **UI must be production-quality even though the logic is simplified** — that means: large prominent overall score with a circular gauge, per-koota row with name/score/icon and a one-line explainer, traffic-light colour states (green/amber/red), a "What does this mean?" expandable explainer per koota, and a clear "Quick Match — based on rashi + nakshatra + manglik only" caveat banner so users know the score is indicative, not authoritative. The UI bar to clear: looks like something a paying user would screenshot and share with their family.
2. `**OfflineAstrologyScreen`** — a form where a parent enters their own + a candidate's birth details (DOB, time, place, rashi, nakshatra, gotra) without that candidate being in the system. Runs the same matcher. Useful for evaluating a profile that came from outside the app (a relative's referral).
3. **Service**: `lib/core/services/astrology_matcher.dart` — pure-function compatibility scorer that takes two `AstrologyDetails` records. Testable.

### 1.6 Saved profiles + Viewed section

> "Saved profiles, Viewed section."

**Current state.** Neither exists. There is no place in the app where a parent can see "profiles I starred" or "profiles I've opened recently."

**Approach.**

- `SavedProfileRepository` (from 1.2) → backs `SavedProfilesScreen` accessible from the home dashboard tile (see 1.8 below).
- `ViewedProfileRepository` — records a `(userId, profileId, viewedAt)` row each time the parent opens a profile detail. Show "Recently Viewed" as a horizontal scrollable row on home, plus a "Viewed" tab inside the SavedProfilesScreen (or as a sibling screen).
- Cap viewed history at e.g. 50 rows; oldest evicted.

### 1.7 Self-upload profile (single profile management space)

> "Upload the profile into the app's local system, so as to have a single profile management space."

**Current state.** Today the only way a candidate profile gets created is through a broker via [profile_create_edit_screen.dart](lib/screens/broker/profile_create_edit_screen.dart). Parents and candidates have no self-create flow. The candidate's own profile is set up minimally at signup ([profile_setup_screen.dart](lib/screens/auth/profile_setup_screen.dart)) but lacks the rich matrimony fields the model supports.

**Approach.**

- **Parent self-create**: "Create my child's profile" entry point in the parent profile management area. Reuses the rich `ProfileCreateEditScreen` but in parent mode. The resulting `CandidateProfile` is owned by the parent (`createdByUserId = parentUid`, `parentUserId = parentUid`).
- **Photo limits (decision confirmed): max 6 photos per candidate, max 3 MB per file** (after client-side resize). Use `image_picker` (already in pubspec) → resize to 1080px on the long edge via `image` package (or `flutter_image_compress` if we want hardware encoders) → save to app sandbox via `path_provider` → store the file path in `CandidateProfile.photos`. The 3 MB cap is enforced before save so users can't pad the box with raw camera files. Show progress + count ("4 of 6") in the upload widget.
- **Auto-create + invite the candidate user via phone number** (decision confirmed). When a parent creates a profile for their child, the form collects the child's phone number; the app auto-creates a `candidateUser` (`registerUser` with role `UserRole.candidate`) and sets `candidateUserId` on the profile. On the candidate's first OTP login with that phone, they inherit ownership of the profile. **Note:** this is MVP logic for the local Hive build; once a real backend lands, this flow is replaced with an invite-link / SMS-deep-link pattern (server-side identity resolution). The frontend abstraction (`AuthRepository.registerOrLookupByPhone`) hides the difference.
- **Candidate self-create**: same flow inside the candidate shell. Result: `createdByUserId = candidateUid`, `candidateUserId = candidateUid`. If a profile already exists for the candidate's phone (created by a parent), the candidate is linked to the existing record on login rather than creating a duplicate.
- **Profile management hub** (new): a screen listing all profiles owned by the current user, with edit/share/delete actions. For parents this is "my children's profiles" (one or more — see below) + any external profiles they're tracking; for candidates it's their own profile + any drafts.
- **Multiple candidates per parent (decision confirmed).** A parent account supports an arbitrary number of child profiles (parents with two or three unmarried kids are real). Today `ParentProfile.linkedChildId: String?` is one-to-one; this becomes `linkedCandidateIds: List<String>` (or `linkedCandidateProfileIds: List<String>` if we want to be precise about whether we mean user-IDs or profile-IDs — recommend profile-IDs since a parent can manage a child's profile before the child user exists). The model migration is a one-shot at first launch (existing single `linkedChildId` values get wrapped into a list of length 0 or 1). For MVP this lives in local Hive; backend will replicate the shape. **UX implication for the parent home dashboard**: when a parent has more than one child profile, the home tab shows a small chip-row at the top to switch between them ("Ananya" · "Rohan"), or a single "All children" combined view. Default to combined view, with the chip-row scoped to the Shared Profiles list.

### 1.8 "Linked Child" dashboard tile is wasted space

> "'Linked Child' in the landing page (Dashboard card) is wasting space… Instead, we will show the Saved profiles and upon clicking it, we move to the saved profiles section."

**Current state.** [home_screen.dart:308-314](lib/screens/home_screen.dart#L308) — the third dashboard tile is `_DashboardStat(icon: child_care, label: 'Child', value: linked|none)`. For most parents this is a one-time status with no actionable value.

**Approach.**

- Replace with: `_DashboardStat(icon: bookmark, label: 'Saved', value: '<count>', onTap: → SavedProfilesScreen)`.
- Move the "linked child" status to a less-prominent badge inside the parent profile screen (where it's already shown — [parent_profile_screen.dart:219-240](lib/screens/parent/parent_profile_screen.dart#L219)).
- Make all four dashboard tiles tappable (Brokers → MyBrokers, Profiles → ShareProfiles tab below it, Saved → SavedProfilesScreen, fourth slot reserved).

### 1.9 Differentiated UX for parent vs candidate

> "Parents and the kid's UI preferences and the things they like will be different in terms of their functionality usage and even the aesthetics."

**Current state.** Parent and candidate shells share the same widget building blocks. Same density. Same color emphasis.

**Approach.**

- **Parent tokens (denser, decision-heavy)**: larger fonts (already covered in 1.3), serif-ish accent for headlines (Poppins stays), more chrome — explicit labels under icons, count badges, status chips.
- **Candidate tokens (visual, social)**: same base fonts but tighter line-height for body, more whitespace, more rounded radii, larger imagery, fewer chrome elements.
- **Implementation**: introduce a `UserPersona` enum (`parent` | `candidate`) and gate styling decisions through a `ThemePersona` extension on `BuildContext`. Or simpler: a `PersonaTokens` class with two static `forParent()` / `forCandidate()` token bundles. Wire the active persona from `authState.user.role` near `MaterialApp`.

### 1.10 Color scheme feels off + need a debug-mode theme tinkerer

> "The colour schema should be improved a lot. It isn't looking as clean. In fact the Financial Compatibility screen looks better in terms of colour schema. There should be a better way for me to configure the colour schema in debug mode so that I can experiment."

**Why Financial Compatibility looks cleaner.** That screen leans on a **single dominant feature color** (Financial Green: `AppColors.successDark → success → successLight` gradient) instead of fighting the dual brand pair. It also uses:

- A SliverAppBar with a 3-stop gradient hero — adds depth without busy chrome
- Cards have feature-tinted shadows (green-tinted, not generic black) — see [financial_compatibility_screen.dart:328-333](lib/screens/financial_compatibility_screen.dart#L328)
- Section headers use a tinted icon-chip + bold title (not a saffron icon next to maroon text)
- Generous whitespace and consistent 16/20/24 radii

**Why the rest of the app feels busy.** The default scheme has **two saturated warm colors competing for attention**:

- Primary: `sacredSaffron` (#FF8C42) — bright orange
- Secondary: `deepMaroon` (#8B2635) — dark red

Both are warm, both are saturated, neither yields visual focus. Worse, screens scatter both colors at low alpha (`sacredSaffron.withValues(alpha: 0.1)` for one tile, `deepMaroon.withValues(alpha: 0.12)` for the next), so every card row reads as "vaguely matrimony-themed" rather than designed. The AppBar in light mode is the deep maroon which then forces white iconography — high contrast but heavy.

**Two-part solution: build the tinkerer first, then redesign with it.**

#### Part A — Runtime Theme Tinkerer (debug-only)

A small debug-mode screen that lets you pick colors live, see the whole app update, save a preset.

**Architecture:**

1. `**AppPalette` value class** at `lib/core/theme/app_palette.dart`. Holds every brand + semantic color the app uses today (`primary, primaryLight, primaryDark, secondary, secondaryLight, secondaryDark, success/error/warning/info × 3 shades, surface/background/text/divider/border × light+dark, plus feature accents trustBlue, meetingPurple, etc.`). Each as a `Color` field. One static `AppPalette.defaultSaffron` preset matches today's `AppColors` exactly so behavior is unchanged before the user opens the tinkerer.
2. `**paletteProvider`** (Riverpod `Notifier<AppPalette>`). Default state = `AppPalette.defaultSaffron`. Persists overrides to `SharedPreferences` keyed by `'debug_palette_v1'`.
3. `**AppTheme.lightTheme` / `darkTheme` become parameterized** to take an `AppPalette` and project it onto `ColorScheme` + `AppBarTheme` + `CardTheme` etc. `AppColors` static constants become *defaults* the palette starts from — existing screens that reference `AppColors.sacredSaffron` keep working unchanged.
4. `**MaterialApp` watches `paletteProvider`** and rebuilds the theme when it changes. One rebuild, no jank — same mechanism as the existing theme-mode toggle.
5. `**ThemeTinkererScreen`** at `lib/screens/debug/theme_tinkerer_screen.dart`:
  - Grouped sliders/swatches: **Brand** (primary + secondary), **Semantic** (success / warning / error / info), **Feature accents** (trust blue, meeting purple, financial green), **Neutrals** (light/dark surface, divider, border).
  - Each slot opens a `flutter_colorpicker`-style swatch + HSL slider. Cheapest path: use the existing `showDialog` with a `ColorPicker` from a tiny package (or hand-roll one — three sliders for HSL + a swatch grid is ~80 LOC).
  - **Quick mode**: a single seed color → Material 3 generates the whole `ColorScheme.fromSeed`. Lets you experiment by typing one hex code.
  - **Power mode**: slot-by-slot fine control.
  - **Compare**: side-by-side preview tile showing a sample card + section header + button + chip rendered with the active palette.
  - **Presets dropdown**: "Default Saffron", "Financial Green", "Cool Blue", and any user-saved palettes. Save / rename / delete a preset.
  - **Export / import as JSON**: copy the current palette as a JSON blob to paste back later or share.

**Access (debug-only, no chrome in release):**

- Wrapped in `if (kDebugMode) { ... }` so the entry point only exists in debug builds.
- Entry point: long-press on the AppBar logo, *or* a shake-to-open gesture, *or* a hidden debug FAB on a `?debug=1` query. Recommend long-press on logo — discoverable for you, invisible to users.

**What this costs to build**: roughly a day. ~250-400 LOC across the palette class, provider, theme parameterization, and the tinkerer screen. Adds 1 small dependency (`flutter_colorpicker`) or zero deps if I hand-roll the picker.

**What it lets you do**: live-experiment until the palette feels right, save the winner, then commit the new defaults to `AppPalette.defaultX` so end users see the new scheme.

#### Part B — Specific scheme improvements you can apply (with or without the tinkerer)

Even before the tinkerer ships, the worst offenders today are concrete and fixable:

1. **Demote `deepMaroon` from primary chrome.** Use it for the AppBar in light mode only as a strong header, but stop using it for body card accents, list-tile icons, and CTAs. Replace those uses with `colorScheme.primary` (saffron) or a softer neutral. Effect: one dominant warm, the maroon becomes special-occasion.
2. **Lighten the light-mode AppBar.** Today it's `AppColors.deepMaroon` with white text — high-impact but it makes every screen feel formal. Try `colorScheme.surface` with `colorScheme.onSurface` text and a 1px bottom divider. Matches Material 3 defaults and feels modern. Keep deep maroon as the dark-mode accent.
3. **Adopt feature accents per section** (the Financial Compatibility pattern). Each major feature gets its own accent color used in its hero + cards + section headers + icon chips:
  - Discovery / Search → saffron (default brand)
  - Saved Profiles → cool blue (`#2563EB` family)
  - Viewed → muted purple
  - Astrology → teal (`#0891B2` family)
  - Financial → green (existing)
  - Trust → blue (existing)
4. **Standardize card surface treatment.** Pick one shadow recipe and apply everywhere — currently shadows vary between screens (`alpha: 0.04`, `0.06`, `0.08`, `0.25`). Recommend: light mode `Colors.black.withValues(alpha: 0.05)` 16-blur 4-offset; dark mode same but `alpha: 0.25`. Wrap in `AppShadows.card(context)` so it's a single import.
5. **Tighten the border radii to two values**: `roundedSm = 8` (chips, small buttons) and `roundedLg = 16` (cards, sheets, dialogs). Today radii are scattered across 6/8/10/12/14/16/20.
6. **Use `ColorScheme.fromSeed` instead of manual slot assignment** in `AppTheme.lightTheme` / `darkTheme`. Material 3's algorithm produces harmonious primary-container, secondary-container, tertiary, on-surface-variant, etc. derivations from one seed. Today every slot is hand-assigned and a few combinations are slightly off-balance (the `primaryContainer = sacredSaffronLight` clashes with `onPrimaryContainer = lightPrimaryText` in some buttons).

Items 1-5 are work that can ship on their own; item 6 is part of the tinkerer wiring.

### 1.11 Missing features explicitly called out

> "Profile management section for parents, saved profiles for parents, profiles that liked them, profiles that are being talked to — a lot of things are not present yet."

Mapping each to a build:


| Missing                                         | Where it lives                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| ----------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Profile management for parents                  | 1.7 above (Profile management hub)                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| Saved profiles                                  | 1.6 + 1.8                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| Profiles that liked us (incoming interest)      | **New** — surface mutual interest. When a *candidate* (or candidate's parent) marks a parent-shared profile as interested, the originating broker sees it. But there's no surface for the *receiving parent* to see "who has expressed interest in my child." This requires a reciprocal SharedProfile flow (broker shares my-child's profile with another parent → that parent expresses interest → the originating broker shows me). Build as a "Mutual Matches" tab. |
| Profiles being talked to (active conversations) | Already partially built — `MessagingRepository.getAllConversations` exists. Surface as a "Conversations" tab on the parent shell (or in a tab inside the home screen).                                                                                                                                                                                                                                                                                                  |


### 1.12 Candidate profile detail page is too basic — make it the "completion" surface

> "The profile page when selecting this card is very basic and lacks many things. Also, there are no profile pictures in the profile page... when inside the profile of a candidate, the parents should also be able to see the events like updates from the broker and also their notes... When have they talked, what was discussed, is the meeting setup... if so when and where... a lot of other things... including the parent's personal notes as well."

**Current state.** [profile_view_screen.dart](lib/screens/profile/profile_view_screen.dart) renders the candidate's static fields (name, age, profession, etc.) but is purely a record view. It has:

- A small avatar with the first letter — **no photo carousel** even though `CandidateProfile.photos` is populated.
- No action surface — `parentResponse` is shown but cannot be **changed** from this screen.
- No timeline / activity feed — when the broker shared the profile, when they sent a message, when a meeting was set up, none of this is visible.
- No broker notes — `SharedProfile` has no field for them today.
- No parent notes — there's no place for the parent to write "spoke to my sister, she thinks the family is good" or "asked broker about the salary range, waiting for reply."
- No meeting tracker — `VirtualMeeting` model exists in `lib/models/virtual_meeting.dart` but the parent never sees a "next meeting" surface tied to a specific candidate.

**Why this matters.** The parent's mental model of "evaluating a profile" includes everything that has happened *around* the profile, not just the profile fields. A matrimony decision unfolds over weeks of back-and-forth with the broker, family discussions, calls. The profile detail page is where all of that should converge — without it, the app forces the parent to remember context across screens.

**Approach.** Redesign the profile detail screen as a multi-section page. Top to bottom:

1. **Photo carousel** — same `ProfilePhotoCarousel` widget from §1.1, full-width, slightly taller (240-280px) than the card variant. Tap to open fullscreen viewer.
2. **Identity header** — name, age, profession, height, city. Compact, readable, no chrome.
3. **Quick actions row** — Save (toggle) · the segmented response control from §1.2 item 6 (`[Interested · Pass · Reset]`) · Share/Forward (icon). The response control replaces the four-button list-card row here and is *always* visible regardless of current state.
4. **Key details cards** — religion / community / caste, family, education, lifestyle, partner preferences. Existing fields, reorganized into 3-4 swipeable or stacked cards.
5. **Astrology summary card** (when both sides have astrology data) — small inline preview with overall Quick Match score and "View full match →" linking to the AstrologyMatchScreen (§1.5).
6. **Conversation & meetings** — a section showing:
  - "Last spoke with broker: " (read from `MessagingRepository.getConversation(brokerId, parentId)`)
  - "Next meeting: <date, location>" or "No meeting scheduled" (read from a new `MeetingRepository`, see below).
  - "Schedule meeting" CTA — opens a sheet where the current viewer (parent / candidate / broker) picks date, time, location, type (in-person / virtual / phone), and optional notes.

  **Meeting model — three-way visibility (decision confirmed).** A meeting is owned by whoever schedules it, and visibility follows that ownership:
  - Broker-scheduled meeting → visible to broker + parent + candidate (the three parties).
  - Parent-scheduled meeting → visible to that parent + their linked candidate (the "party"). Broker doesn't see it.
  - Candidate-scheduled meeting → same as parent-scheduled (the parent/candidate pair are one party).
  - Conceptual roles: there are **two parties** — `(parent + candidate)` and `(broker)`. A meeting can be intra-party (party-only, only the scheduler's side sees it) or inter-party (broker schedules; both sides see it).

  This implies the meeting record shape:
  ```
  Meeting {
    id, candidateProfileId, parentId, brokerId,
    scheduledByUserId,              // who created it
    scheduledByRole,                // parent | candidate | broker
    visibility: { brokerVisible, parentPartyVisible },
    when, durationMin,
    location, type: inPerson | virtual | phone,
    virtualLink?,                   // for virtual meetings
    status: scheduled | completed | cancelled,
    notes?
  }
  ```
  When `scheduledByRole == broker`, both visibility flags are true. When parent or candidate schedules, only `parentPartyVisible` is true. `MeetingRepository.getMeetingsFor(viewerId, ...)` filters by visibility at read time.
7. **Activity timeline** — chronological feed of `ProfileActivity` events:
  - `BrokerSharedProfile { timestamp, brokerName }`
  - `BrokerSentMessage { timestamp, snippet }`
  - `MeetingScheduled { timestamp, when, where }`
  - `MeetingCompleted { timestamp, durationMin }`
  - `ParentMarkedInterested / Pass { timestamp }`
  - `BrokerNoteAdded { timestamp, snippet }`
  - `ParentNoteAdded { timestamp, snippet }`
   Most recent first, "Show all" expand if more than 5.
8. **Broker notes** — text shown verbatim from broker. Read-only here. Editable by the broker on their `broker_clients_screen` view of the same profile.
9. **My notes (parent's personal notes)** — free-form text box, autosaved, never shared with broker. Stored as a new `ParentNote { parentId, candidateProfileId, body, updatedAt }` record.
10. **Footer actions** — Block, Report (deferred until moderation is needed).

**New models / repos this needs.**

- `ProfileActivity` model + `ActivityRepository` (event-sourced; appended whenever any of the trigger actions fire — sharing, messaging, responding, scheduling). Capped at the last **50 events per profile** (decision confirmed); older entries pruned on write. This also powers §1.10 "events feed" and §1.6 "viewed history".
- `ParentNote` model + `NoteRepository` (per parent × candidate-profile, single text body, last-write-wins).
- `BrokerNote` field on `SharedProfile` (or separate model — separate is cleaner since notes may be edited many times and we want history later).
- New `Meeting` model (replacing the mock-only `VirtualMeeting`) + `MeetingRepository`. The model carries `scheduledByRole` + the two visibility flags described in item 6. Listed as a top-level Hive box (not nested inside `SharedProfile`) because meetings exist independently of the share record and there can be many per match.

**Why this becomes a substantial slice on its own.** This is "the completion feeling" the user is asking for. It is conceptually paired with §1.1 (parent landing redesign) because the card → detail flow is one user experience, but in code it touches a different screen, four new models/repos, and several writers (broker, parent, system). Slated as a slice between current 7 (parent landing) and 8 (photo upload) — see Part 4.

---

## Part 2 — Boot-time flash (new, confirmed)

> "There is quite a noticeable time when opening the app, it first shows the landing page that shows the profile setup screen i.e. the screen where you select the type of profile … then it changes to the dashboard."

**Root cause.** The auth check is deferred until after the first frame:

1. [main.dart:27-65](lib/main.dart#L27) — initializes the data module, then `runApp(ProviderScope(...))`. `authProvider` starts in `AuthInitial`.
2. [app_router.dart:67](lib/core/routing/app_router.dart#L67) — `initialLocation: RouteNames.roleSelectionPath`. With auth still `AuthInitial`, the redirect closure routes to role-selection.
3. [main.dart:91-103](lib/main.dart#L91) — `_AnuyatraAppState.initState` schedules `checkAuthStatus()` inside `addPostFrameCallback`. This runs **after** the first frame has already painted `RoleSelectionScreen`.
4. `checkAuthStatus` reads the session box, finds the user, transitions to `AuthAuthenticated`.
5. The `refreshListenable` in the router fires; GoRouter re-evaluates the redirect; the user is bounced to their role's shell.

**Effective UX**: role-selection screen appears for ~100-300ms (or longer if Hive is cold-warm), then snaps to the dashboard.

**Approach (in order of effort).**

**Option A — Pre-resolve auth before runApp (recommended).** In `main()`, after `AppDataModule.initLocal()`, call `final user = await dataModule.userRepository.getCurrentUser();`. Use the result to override the `authProvider` initial state through `ProviderScope.overrides` — provide an `AsyncValue.data(AuthAuthenticated(user))` if non-null, else leave default. Then the router's first redirect already sees the right state. No flash. Cost: one extra await before runApp (~10-50ms), zero in exchange for the flash. **Sub-cost**: needs a small refactor of `AuthNotifier` to accept an initial state instead of always starting at `AuthInitial`.

**Option B — Hide UI until auth resolves.** Show a splash widget while `checkAuthStatus` is running, hide the actual `MaterialApp.router` until it's done. Cleaner UX but adds a splash transition. Easier to implement than A.

**Option C — Make `roleSelectionPath` initial-render conditional.** In the router, compute `initialLocation` based on whether a session exists in the session box (read synchronously via the data module). This is essentially Option A but encapsulated inside the router builder.

**Recommendation: Option A.** It is the right architecture (auth state truly resolved before the first frame) and the fix is contained to `main.dart` + a small `AuthNotifier` constructor change. Also closes PLAN_DELTA §1.7.

**Secondary boot-time concern: parallel box opens.** [app_data_module.dart:60-71](lib/core/data/app_data_module.dart#L60) opens 10 Hive boxes sequentially with `await`. Hive box opens are I/O-bound; running them in parallel via `Future.wait` cuts cold-start by 50-70%. Risk: low — boxes are independent. Worth a separate small fix.

**Third boot-time concern: first-launch seeding.** On first launch only, [main.dart:31-35](lib/main.dart#L31) awaits `seedDemoData(dataModule)`. That writes ~25 records sequentially. On subsequent launches this branch is skipped (cheap check). Acceptable as-is; first launch is a one-time cost.

---

## Part 3 — Issues I'm flagging that you haven't raised

These are gaps I see independent of your feedback. Each has a severity rating and a one-line fix sketch.

### Critical / user-blocking

**P3.1 — No undo on destructive Pass action.** As noted in 1.2. Once a parent taps Pass, the profile disappears from the active list with no recovery. Add 6-second snackbar undo.

**P3.2 — Form state lost on navigation.** [profile_setup_screen.dart](lib/screens/auth/profile_setup_screen.dart) has 30 `TextEditingController` instances. If the user tabs away mid-form or accidentally pops, everything is lost. Add a draft auto-save (`SharedPreferences`, keyed by screen + user). PLAN_DELTA §3.5 #4.

**P3.3 — Photo storage is undefined.** `CandidateProfile.photos` is `List<String>` of URLs. Today's seed data uses Unsplash URLs. There is no implemented path for **uploaded** photos. Need either:

- Save to app sandbox via `path_provider`, store local path strings (works today, OK until backend).
- Base64 → Hive (bad for >100KB images).
- Cloud upload (only once backend lands).
Recommend: app-sandbox path with `image_picker` already in pubspec. Add this as part of 1.7.

### High / quality-of-experience

**P3.4 — Sequential async chains during dashboard load.** [home_screen.dart:48-67](lib/screens/home_screen.dart#L48) — loads shared profiles, then for each one awaits a candidate fetch and a broker fetch in sequence. For 10 shared profiles that's 20 sequential Hive reads. Parallelize the inner loop with `Future.wait`.

**P3.5 — No loading shimmers anywhere.** `ShimmerLoading` widget exists in [common/animations/app_animations.dart:283](lib/common/animations/app_animations.dart#L283) but zero screens use it. All screens go from blank → populated, which looks like an empty state. Wire shimmer skeletons into the four main dashboards (parent home, broker dashboard, candidate home, agency dashboard).

**P3.6 — No "profiles that liked us" surface.** Mutual interest discovery is invisible. Build the "Mutual Matches" tab from 1.11. **Routing decision (confirmed):** since the connection flows through a broker, mutual interest is **broker-mediated** by default — the originating broker sees both sides' Interested state and surfaces it to each parent in their respective dashboards. The receiving parent doesn't *directly* see the candidate-side parent. **Plus an auto-forward setting** on the broker's settings screen (`broker_own_profile_screen.dart` / `agency_settings_screen.dart`): toggle `'Auto-forward mutual interest to both parties'`. When ON, the broker side relays mutual-interest notifications automatically. When OFF (default), the broker manually confirms each forward, giving them more control over pacing.

**P3.7 — Onboarding lacks an intro.** First-time user lands on role selection with zero context about what each role does or what the app is for. Add a 2-3 page swipeable intro before role selection on first launch. Skippable.

**P3.8 — Chat is half-built.** [chat_screen.dart](lib/screens/chat/chat_screen.dart) shows messages but: no typing indicator, no read receipts surfaced in UI (data has `isRead`), no attachments, no profile-share-as-message (only text). For a matrimony broker ↔ parent flow, sending a profile as a chat message is core. Add `ChatMessageType.profileShare` rendering.

**P3.9 — Avatar inconsistency.** Parents and brokers show initials throughout (`parent_profile_screen.dart:99`, broker cards). Only candidates have photos. For an app that's photo-driven, parents and brokers should have avatars too — at minimum a `photoUrl` field on `AppUser` and a `selectPhoto` flow in the own-profile screens.

**P3.10 — Profile state machine post-"Interested" is unspecified.** Parent marks Interested → what happens next? Currently: `SharedProfile.parentResponse = interested`. The broker sees it on their dashboard. No automatic conversation kickoff, no scheduled call, no "introduce families" action. Define the next state transitions.

### Medium / polish

**P3.11 — No pull-to-refresh on most list screens.** Only home_screen has `RefreshIndicator`. Add to discovery, my-brokers, broker-clients, link-requests, shared-profiles screens.

**P3.12 — No profile-completeness indicator on own-profile screens.** `CandidateProfile.profileCompleteness` getter exists; only `ProfileViewScreen` shows it. Add to `CandidateOwnProfileScreen` and equivalent.

**P3.13 — No rate limiting on link requests / response actions.** A user can spam the Interested button → multiple records. Add idempotency in the repository: `respondToProfile(id, response)` should be no-op if response already matches.

**P3.14 — Empty hardcoded English in the 18 plan-flagged screens.** PLAN_DELTA §2.3. ~94 hardcoded strings remain (`'Financial Compatibility'`, section subtitles, etc.). Sweep as part of each redesign.

### Low / nice-to-have

**P3.15 — No widget tests for the molecules.** PLAN_DELTA §3.5 #5. `AppointmentCard`, `DetailTile`, `ProfilePhotoCarousel` (new) — these are pure, easy to test, would catch regressions cheaply.

**P3.16 — Doc comments missing on 13 of 14 common widgets.** PLAN_DELTA §3.5 row 6.

**P3.17 — `revolutionary_features_data.dart` and `premium_services_data.dart` ship demo data in production builds.** The Anuyatra Hub (Vivaha Samskara / Trust Verification / Financial Compatibility) is reachable and shows mock content. Either gate behind `kDebugMode` (PLAN_DELTA §3.1 option b) or wire to a real `PremiumServiceRepository`.

**P3.18 — `getSharedProfilesByBroker(id).take(3)` patterns still load-all-decode-all.** Hive-side performance debt; irrelevant once the backend swap happens.

**P3.19 — Search bar in discovery has no autocomplete, no recent-searches.** Comes naturally with 1.4.

**P3.20 — No internet/offline indicator.** Only matters once a backend exists. Park.

---

## Part 4 — Recommended sequencing

Each slice is independently shippable. Slices in **bold** are blockers for later slices.


| #     | Slice                                                                                          | Why this order                                                                                                                                                                                                                                                                                                            | Files touched (rough)                                        |
| ----- | ---------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| **1** | **Font-size bump (1.3)**                                                                       | One-file change. Visible everywhere. Sets the visual baseline before any layout work. Reverting later is a one-line revert                                                                                                                                                                                                | 1                                                            |
| **2** | **Boot-flash fix (Part 2 Option A)**                                                           | Independent of everything else; user is observing this *now*. Also unblocks any subsequent screen redesign from being measured against a janky cold start                                                                                                                                                                 | 2-3                                                          |
| **3** | **Parallel Hive box opens (P3.4-adjacent)**                                                    | One-line fix while we're in `main.dart`. Cuts cold start further                                                                                                                                                                                                                                                          | 1                                                            |
| **4** | **Theme tinkerer infrastructure (1.10 Part A)**                                                | `AppPalette` value class, `paletteProvider`, parameterize `AppTheme.light/darkTheme` to consume it, debug-only `ThemeTinkererScreen` accessed by long-press on the AppBar logo. Lets you experiment live with brand/semantic/feature colors. Ships zero visible change until you open it                                  | 1 new file (palette), 1 new screen, edits to `AppTheme`      |
| **5** | **Apply specific scheme cleanups (1.10 Part B)**                                               | Use the tinkerer from slice 4 to dial in the new defaults: demote maroon from primary chrome, lighten light-mode AppBar, adopt feature accents per section, standardize card shadow recipe, tighten radii to two values, migrate to `ColorScheme.fromSeed`. Commit the resulting palette as the new `AppPalette.defaultX` | edits to `AppTheme`, `AppColors`, 4-6 screens                |
| **6** | **Data foundation: `SavedProfile` + `ViewedProfile` + drop Maybe from action set (1.2 / 1.6)** | Several screens depend on Save/View existing                                                                                                                                                                                                                                                                              | 4 new files, 1 enum edit                                     |
| **7** | **Parent landing redesign (1.1 / 1.2 / 1.8)**                                                  | The most user-visible piece. Depends on slices 5 + 6. Includes photo carousel widget, action row, dashboard tile swap, undo-on-pass                                                                                                                                                                                       | 1 screen rewrite, 1 new screen (SavedProfiles), 1 new widget |
| **8** | **Profile detail page redesign (1.12)**                                                        | The "completion feeling" surface — photo carousel, switchable response control, activity timeline, broker notes, parent notes, meetings section. Paired with slice 7 since card → detail is one UX flow. Needs new `ProfileActivity`, `ParentNote`, `BrokerNote` records + a Hive `MeetingRepository` to back the section | 1 screen rewrite, 3-4 new models/repos, activity-emit hooks  |
| 9     | Photo storage + self-upload (1.7 / P3.3)                                                       | Unlocks parent + candidate self-create. Auto-creates candidate user via phone (decision 3)                                                                                                                                                                                                                                | 1 new screen, repo changes                                   |
| 10    | Large search + audio (1.4)                                                                     | Adds `speech_to_text` dependency, rebuilds discovery screen, device-locale recognition                                                                                                                                                                                                                                    | 1 dep, 1 screen rewrite, 1 new widget                        |
| 11    | Astrology (1.5) — rule-based v1                                                                | Pure-function matcher + 2 screens. **UI must be production-quality** per decision 2                                                                                                                                                                                                                                       | 1 service, 2 screens, 1 model                                |
| 12    | Mutual interest (P3.6)                                                                         | Reciprocal flow. Broker-mediated default + auto-forward setting per decision 4. Needs slice 6 + a new "incoming interest" repo method                                                                                                                                                                                     | 1 new screen, repo extension, settings toggle                |
| 13    | Chat completion (P3.8)                                                                         | Typing indicator, read receipts, profile-share message type                                                                                                                                                                                                                                                               | chat_screen rewrite                                          |
| 14    | Persona differentiation (1.9)                                                                  | Final polish layer; bundles small adjustments rather than a single feature. Uses the tinkerer to define parent vs candidate palette presets                                                                                                                                                                               | tokens + small per-screen tweaks                             |
| 15    | Onboarding intro (P3.7)                                                                        | Once core flows feel right, add the 2-3 page intro                                                                                                                                                                                                                                                                        | 1 new screen                                                 |
| 16    | Form draft auto-save (P3.2)                                                                    | Strict UX fix; not a feature, but worth doing before too many more forms exist                                                                                                                                                                                                                                            | 1 new util + 3-4 form hookups                                |
| 17    | Shimmers (P3.5), pull-to-refresh (P3.11), idempotent responses (P3.13)                         | Quality pass                                                                                                                                                                                                                                                                                                              | per-screen                                                   |


**My recommendation: do slices 1-8 first, in order, with a checkpoint after each.** That delivers every concrete ask you've made (bigger fonts, no boot flash, live theme tinkerer + cleaner colour scheme, photo-carousel cards on landing, Save/Interested/Pass, Saved Profiles tile, **the "completion-feeling" profile detail page with activity timeline + notes + meetings**) without committing to the much-larger search/astrology work yet. Slices 7 and 8 are paired and ship together — the card and the detail page are one user experience. The tinkerer at slice 4 means slices 5, 7, and 8 (all visible UI work) can be tuned in real time rather than guessed at. After slice 8 you'll see whether the core parent flow actually feels right and we can adjust.

---

## Part 5 — Decisions log + remaining open questions

### Resolved (input from you)

1. ✅ **Save vs Interested vs Forward.** Mental model confirmed: Save (private), Interested (notifies broker), Forward-to-child (secondary). Plus *response is never final* — switchable on the profile detail page (§1.2 item 6).
2. ✅ **Astrology depth.** Rule-based "Quick Match" for v1. **UI must be production-quality** despite the simplified logic (§1.5).
3. ✅ **Self-upload ownership.** Auto-create candidate user via phone number; first OTP login inherits the profile. Frontend abstraction `AuthRepository.registerOrLookupByPhone` hides the local-vs-backend difference (§1.7).
4. ✅ **Mutual interest visibility.** Broker-mediated by default. Plus an **auto-forward toggle** in broker settings (P3.6).
5. ✅ **Audio search language.** Device locale by default; app's active locale (when explicitly chosen) takes precedence (§1.4).

### Resolved (round 2)

6. ✅ **Meetings model.** Any of the three roles (parent / candidate / broker) can schedule. Visibility follows the scheduler: broker-scheduled meetings are visible to all three parties; parent- or candidate-scheduled meetings are visible only to the parent+candidate party (broker doesn't see them). Implemented as a top-level `MeetingRepository` with explicit visibility flags on the record (§1.12 item 6).
7. ✅ **Photo limits.** Max 6 photos per candidate, max 3 MB per file (post client-side resize to 1080px long-edge). `image_picker` + `flutter_image_compress` (or the `image` package), saved to app sandbox via `path_provider` (§1.7).
8. ✅ **Multiple candidate profiles per parent.** Yes — supported even in MVP local Hive. `ParentProfile.linkedChildId` becomes `linkedCandidateProfileIds: List<String>`. One-shot migration on first launch wraps the existing single value into a list. Parent home dashboard surfaces a chip-row to switch / combined view to span (§1.7).
9. ✅ **Activity timeline retention.** Last 50 events per profile, oldest pruned on write (§1.12).
10. ✅ **Target platforms.** Both Android and iOS. Audit `image_picker` (iOS NSPhotoLibraryUsageDescription, NSCameraUsageDescription), `speech_to_text` (NSMicrophoneUsageDescription, NSSpeechRecognitionUsageDescription) Info.plist entries before slice 9/10 ships. Android: runtime permissions are already handled by the packages.
11. ✅ **Parent notes privacy.** Private to the writing parent only. The linked candidate cannot see them — if a candidate wants their own notes, they keep their own (§1.12 item 9).

### Remaining open (none blocking slices 1-8)

Threading round-2 answers raised three small follow-ups. None block work; recommended defaults below.

A. **iOS-specific OTP demo footprint.** App Store reviewers may reject a build that ships with hardcoded OTP `123456`. You said earlier "forget the hardcoded OTP security issue" — that's fine for development, but the *first* iOS TestFlight build will hit this. Recommend: gate the hardcoded OTP behind `kDebugMode` so release builds use a real OTP path (or a clearly-labeled "Demo Mode" toggle on the login screen for review). Not urgent; flag for the day you submit.

B. **Meeting "accept / decline" flow.** When the broker schedules a meeting visible to both parent and candidate, do they need to confirm? Or does broker-scheduling auto-accept? Recommend: auto-visible, with a per-party "Confirm attendance" pill on the meeting card so the broker knows who's coming. No hard-blocking accept flow at MVP.

C. **Multiple children — broker-side surface.** When a broker shares profiles with a parent who has two children, today the share goes to the parent generically. The broker should be able to pick *which child* the share is for. UX: when the broker opens the "Share with parent" sheet, if the parent has >1 linked candidate, show a child selector. The `SharedProfile` record gets a new `targetCandidateProfileId` field. Recommend including this when slice 7 rewires the share flow.

If A/B/C all sound right, I'll execute with those defaults and call out anything edge-case I trip on.

---

## Appendix — Cross-references

- [PLAN_DELTA.md](PLAN_DELTA.md) — code-quality / architecture deltas (Sections A-E completed, F+ open)
- [ARCHITECTURE.md](ARCHITECTURE.md) — overall architecture (still accurate)
- [_archive/](_archive/) — preserved deleted screens (broker_screen, shortlist_screen, etc.) for future re-use

