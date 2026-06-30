# Anuyatra — Complete Product & Code Audit

*Branch: loving-cray | Audit date: 2026-05-31*

This document is a complete product-manager-level audit of every role, every screen, every user flow, and every data connectivity path in the Anuyatra app. It identifies broken flows, design gaps, bad product decisions, and missing connectivity — with concrete solutions for each.

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Role & Screen Inventory](#2-role--screen-inventory)
3. [Critical Flow Breaks (P0)](#3-critical-flow-breaks-p0)
4. [User Flow Gaps by Role (P1)](#4-user-flow-gaps-by-role-p1)
5. [Data Model & Connectivity Issues](#5-data-model--connectivity-issues)
6. [Bad Design Decisions](#6-bad-design-decisions)
7. [Navigation & Routing Gaps](#7-navigation--routing-gaps)
8. [Cross-Role Interaction Gaps](#8-cross-role-interaction-gaps)
9. [UX Polish & Missing Feedback](#9-ux-polish--missing-feedback)
10. [Feature Screens Running on Mock Data](#10-feature-screens-running-on-mock-data)
11. [Recommended Fix Priority](#11-recommended-fix-priority)

---

## 1. Executive Summary

Anuyatra is a multi-role matchmaking platform with four roles: **Parent**, **Broker**, **Candidate**, and **Agency Admin**. The architecture (GoRouter shells, Riverpod DI, Hive repositories) is sound, but the product has significant connectivity holes — many user flows start but don't complete, roles have actions that don't propagate to other roles, and several screens are islands with no data flowing in or out.

### Severity Breakdown

| Severity | Count | Description |
|----------|-------|-------------|
| **P0 — Broken flows** | 7 | User hits dead end, data doesn't arrive, action has no effect |
| **P1 — Missing connectivity** | 12 | Flow exists on one side but not the other, or key navigation missing |
| **P2 — Bad design** | 8 | Conceptually wrong, confusing, or misleading design choices |
| **P3 — Polish gaps** | 10 | Missing feedback, loading states, confirmations |

---

## 2. Role & Screen Inventory

### 2.1 What Each Role Has

| Role | Shell Tabs | Total Screens | Core Flow |
|------|-----------|---------------|-----------|
| **Parent** | Home, Search, My Brokers, Anuyatra Hub, Profile | 5 tabs + 4 overlay | Receive profiles from brokers → review → forward to child |
| **Broker** | Dashboard, Clients, Profiles, Messages, Profile | 5 tabs + 3 overlay | Create candidate profiles → share with parents → chat with parents |
| **Candidate** | Home, Shared Profiles, Anuyatra Hub, Profile | 4 tabs + 2 overlay | Link to parent → see forwarded profiles → respond |
| **Agency Admin** | Dashboard, Brokers, Clients, Settings | 4 tabs + 0 overlay | Manage agency → invite brokers → view aggregate stats |

### 2.2 Shared/Overlay Screens

| Screen | Route | Used By |
|--------|-------|---------|
| `ProfileViewScreen` | `/profile/:id` | Broker (view managed profiles), Parent (view shared profiles), Candidate (view shared profiles) |
| `ChatScreen` | `/chat/:conversationId` | Broker → Parent messaging |
| `LinkRequestsScreen` | `/link-requests` | All roles — view incoming/outgoing link requests |
| `LinkToParentScreen` | `/link-to-parent` | Candidate only |
| `AppSettingsScreen` | `/settings` | All roles |
| `SavedProfilesScreen` | `/saved-profiles` | Parent only |

---

## 3. Critical Flow Breaks (P0)

### P0-1: Candidate sees ALL shared profiles, not just forwarded ones

**The bug:** `CandidateSharedProfilesScreen` calls `sharedProfileRepo.getSharedProfilesForUser(uid)` where `uid` is the candidate's ID. But profiles are shared with the **parent** (the `sharedWithUserId` is the parent's ID, not the candidate's). The candidate should only see profiles that were **forwarded** by the parent (`forwardedToChild == true`).

**What happens:** The candidate's "Shared Profiles" tab is either empty (because nothing was shared *with* the candidate's userId directly) or shows incorrect data if the candidate's userId happens to match.

**The fix:** Change `CandidateSharedProfilesScreen._loadProfiles()` to:
1. Get the linked parent's ID via `linkRepo.getLinkedParentId(uid)`
2. Call `sharedProfileRepo.getForwardedProfiles(parentUserId)` — this method already exists and filters for `forwardedToChild == true`
3. Show only those profiles

**File:** `lib/screens/candidate/candidate_shared_profiles_screen.dart:40`

---

### P0-2: Candidate home shows wrong shared profile count

**The bug:** `CandidateHomeScreen._loadData()` calls `sharedProfileRepo.getSharedProfilesForUser(uid)` with the candidate's own ID. Same issue as P0-1 — this returns nothing useful because profiles are shared with the parent, not the candidate.

**What happens:** The "Profiles Shared With You" counter always shows 0 (or wrong data).

**The fix:** Same pattern — look up linked parent ID first, then call `getForwardedProfiles()`.

**File:** `lib/screens/candidate/candidate_home_screen.dart:46`

---

### P0-3: ShareProfileSheet is a stub — broker cannot share from ProfileViewScreen

**The bug:** `lib/screens/broker/share_profile_sheet.dart` is a 14-line file that just shows a single text label. It has no actual sharing functionality. It's not even used anywhere — the real sharing is done inline in `BrokerProfilesScreen._showShareDialog()`.

**What happens:** There's no way to share a profile from the `ProfileViewScreen` (the detail view). A broker must go back to the profiles list to share.

**The fix:** Either:
- Delete the stub `ShareProfileSheet` and add a "Share" FAB or action button to `ProfileViewScreen` when the viewer is the profile's managing broker
- Or: build out `ShareProfileSheet` with the same connected-parents-picker logic from `BrokerProfilesScreen._showShareDialog()`

**File:** `lib/screens/broker/share_profile_sheet.dart`

---

### P0-4: No edit path for candidate profiles

**The bug:** `RouteNames.brokerEditProfile` and `RouteNames.brokerEditProfilePath` are defined (`/broker/profiles/edit/:id`) but **no route is registered in `app_router.dart`**. The `ProfileCreateEditScreen` has no way to receive an existing profile ID. Brokers can create profiles but never edit them.

**What happens:** After a broker creates a profile with errors, there's no way to fix it.

**The fix:**
1. Add the edit route to `app_router.dart` under the broker profiles branch
2. Pass the profile ID via `pathParameters` or `extra`
3. In `ProfileCreateEditScreen`, detect edit mode, load existing profile, pre-fill fields

**Files:** `lib/core/routing/app_router.dart`, `lib/screens/broker/profile_create_edit_screen.dart`

---

### P0-5: No delete/archive for candidate profiles

**The bug:** There is no delete, archive, or deactivate action for candidate profiles anywhere in the app. Grep for `delete`, `remove`, `archive` in broker screens returns zero results.

**What happens:** Once a profile is created, it exists forever. A broker can't remove a profile they accidentally created or that's no longer relevant.

**The fix:** Add a delete/archive action to `ProfileViewScreen` (when viewed by the managing broker) or to the profile card's context menu in `BrokerProfilesScreen`.

---

### P0-6: Parent has no way to initiate chat with broker

**The bug:** Chat is wired for broker → parent (via `BrokerClientsScreen._openChat`), but there is no chat initiation from the parent side. The parent's `MyBrokersScreen` lists connected brokers but has no "Message" action.

**What happens:** A parent connects with a broker but can only wait for the broker to message first. There's no two-way communication initiation.

**The fix:** Add a "Chat" button to each broker card in `MyBrokersScreen` that calls `messagingRepo.getOrCreateConversation(parentId, brokerId)` then navigates to `RouteNames.chat`.

**File:** `lib/screens/parent/my_brokers_screen.dart`

---

### P0-7: Notification bell buttons are no-ops

**The bug:** Both `BrokerDashboardScreen` (line 403) and `HomeScreen` (line 228, 234) show notification icon buttons with `onPressed: () {}` — they do nothing.

**What happens:** Users see a notification icon, tap it, nothing happens. This creates a perception of a broken app.

**The fix:** Either:
- Remove the notification icons until notifications are implemented
- Or: build a simple notification list screen that aggregates recent link requests, shared profiles, and messages

---

## 4. User Flow Gaps by Role (P1)

### 4.1 Parent Role

#### P1-P1: Parent cannot see broker's profile details

**Gap:** When a parent views their connected brokers in `MyBrokersScreen`, tapping a broker card navigates to... nothing useful. There's no broker profile detail view. The parent can't see the broker's bio, experience, specializations, or ratings.

**Fix:** Add a "Broker Profile View" screen or reuse a card-detail pattern. Navigate via `context.pushNamed(RouteNames.profileView, pathParameters: {'id': brokerId})` — but `ProfileViewScreen` only supports `CandidateProfile`, not `BrokerProfile`.

**Deeper fix:** `ProfileViewScreen` should be polymorphic or there should be a separate `BrokerProfileViewScreen`.

---

#### P1-P2: Parent cannot search/filter shared profiles

**Gap:** The parent home screen shows all shared profiles in a flat list with no filtering, sorting, or search. With 10+ shared profiles, this becomes unusable.

**Fix:** Add filter chips (by response status: pending/interested/pass) and a search bar (by name, city, education).

---

#### P1-P3: Parent cannot add notes when responding to shared profiles

**Gap:** The `SharedProfile` model has a `parentNote` field, but no screen exposes it. When a parent marks a profile as "Interested", they can't explain why or add context for the broker.

**Fix:** Show a text input in a dialog when the parent taps "Interested" or "Pass" to optionally add a note.

---

#### P1-P4: Parent "Save" / bookmark flow is incomplete

**Gap:** `SavedProfilesScreen` is registered as a route (`/saved-profiles`) and imported in the router, but there's no save/bookmark button on any profile card in the parent home screen. The `SavedProfile` model and `SavedProfileRepository` exist but are never wired to UI.

**Fix:** Add a bookmark icon to each shared profile card. Wire it to `savedProfileRepository.saveProfile()`. Make the "Saved Profiles" screen accessible from the parent's profile tab or a dedicated nav action.

---

### 4.2 Broker Role

#### P1-B1: Broker cannot see a parent's response to shared profiles

**Gap:** When a broker shares a profile with a parent and the parent responds (interested/pass), there is no screen or indicator on the broker side that shows the parent's response. The broker has no feedback loop.

**Fix:** On the broker's dashboard or profiles screen, show response status badges on shared profiles. Add a "Shared History" section that shows: "Profile X shared with Parent Y → Interested" or "→ Pass".

---

#### P1-B2: Broker Messages tab only shows conversations, no way to start new ones

**Gap:** `BrokerMessagesScreen` lists existing conversations. But the only way to start a conversation is through `BrokerClientsScreen._openChat()`. If a broker wants to message a specific parent, they must navigate to Clients → find the parent → tap chat.

**Fix:** Add a "New Message" FAB on the messages screen that shows connected parents to start a new conversation with.

---

#### P1-B3: Broker has no way to manage their own profile fields

**Gap:** `BrokerOwnProfileScreen` shows the broker's professional info (bio, specializations, fee structure, etc.) but there appears to be no edit mode for updating these fields after initial setup. The screen is read-only.

**Fix:** Add an "Edit Profile" action that navigates to an edit form for broker professional details.

---

#### P1-B4: No deduplication check when sharing profiles

**Gap:** A broker can share the same profile with the same parent multiple times. `HiveSharedProfileRepository.shareProfile()` creates a new `SharedProfile` every time with no uniqueness check.

**What happens:** Parent sees duplicate cards. Multiple responses can exist for the same profile-parent pair.

**Fix:** Check for existing `(profileId, sharedWithUserId)` pair before creating. Show "Already shared with [name]" if duplicate.

---

### 4.3 Candidate Role

#### P1-C1: Candidate has almost nothing to do

**Gap:** The candidate role has 4 tabs but only 2 have functional data:
- **Home:** Shows link status + profile count (both broken per P0-1/P0-2)
- **Shared Profiles:** Shows forwarded profiles (broken per P0-1)
- **Anuyatra Hub:** Shows mock feature screens (trust/financial/virtual meeting — all mock data)
- **Own Profile:** Shows profile info

The candidate cannot: search for brokers, search for profiles, manage their own candidate profile, communicate with anyone, view their own matchmaking progress.

**Fix:** This is a fundamental product design question. Either:
- Enrich the candidate role with own-profile editing, preference setting, and direct communication
- Or: acknowledge the candidate role is intentionally passive (read-only consumer of parent's forwarded profiles) and simplify the UI accordingly

---

#### P1-C2: Candidate cannot respond to forwarded profiles with notes

**Gap:** Same as P1-P3 but for candidate side. The candidate can mark interested/pass but can't add context.

---

#### P1-C3: No parent-candidate communication channel

**Gap:** There's no messaging between parent and candidate. A parent forwards a profile, the candidate responds, but neither can discuss it. The parent has to check the candidate's responses by looking at the profile cards.

**Fix:** Add a simple notification/comment system on shared profiles, or enable parent-candidate chat.

---

### 4.4 Agency Admin Role

#### P1-A1: Admin cannot actually add brokers to agency

**Gap:** `AdminBrokersScreen` lists brokers in the agency. The "Invite Broker" action (`sendLinkRequest` with type `agencyToBroker`) sends a link request, but when the broker accepts, their `BrokerProfile.agencyId` is never updated. The `_handleLinkRequestAccepted` in `HiveLinkRepository` handles `parentToBroker` and `childToParent` but has **no specific handling for `agencyToBroker`** — it falls through to a generic conversation creation.

**What happens:** The "invite" goes through, the broker "accepts," but they're never actually associated with the agency in the data layer.

**Fix:** Add `agencyToBroker` case to `_handleLinkRequestAccepted` that updates `brokerProfile.agencyId` and increments agency broker counts.

**File:** `lib/core/data/local/hive_link_repository.dart`

---

#### P1-A2: Admin clients screen shows broker clients, not agency's

**Gap:** Need to verify, but the admin "Clients" tab likely shows individual parent profiles connected to specific brokers, without an agency-wide aggregation view.

---

#### P1-A3: Admin cannot remove or deactivate a broker

**Gap:** No remove/deactivate action for brokers in the admin panel.

---

## 5. Data Model & Connectivity Issues

### 5.1 The Parent ↔ Child Linking Has a One-to-One Limit

**Issue:** `getLinkedChildId` and `getLinkedParentId` both return a single `String?`. A parent can only have ONE linked child, and a child can only have ONE parent. In Indian matchmaking, a family often has multiple children looking for matches.

**Impact:** A parent with two children needing matchmaking must create two separate accounts.

**Fix:** Change to `Future<List<String>> getLinkedChildIds(String parentUserId)` and adjust the forward-to-child sheet to show a child picker when multiple exist.

---

### 5.2 SharedProfile Only Links to Parent, Not Child

**Issue:** `SharedProfile.sharedWithUserId` is always the parent's ID. The `forwardedToChild` flag marks forwarding, but there's no `childUserId` field. If a parent has multiple children (see 5.1), there's no way to know which child the profile was forwarded to.

**Fix:** Add `String? forwardedToChildUserId` to `SharedProfile`.

---

### 5.3 CandidateProfile Ownership Is Ambiguous

**Issue:** `CandidateProfile` has three ownership fields:
- `createdByUserId` — who created it (usually broker)
- `parentUserId` — optional link to parent
- `candidateUserId` — optional link to candidate user

But `parentUserId` is only set during seed data, never through any UI flow. `candidateUserId` is similarly never set by any screen. These are dead fields.

**Impact:** There's no way to navigate from a candidate's app to "their" profile. The candidate role can't view or edit their own matchmaking profile.

**Fix:** During profile setup for candidates, or when a parent forwards a profile and the candidate claims it, set `candidateUserId`. Or let candidates create their own profile (not just brokers).

---

### 5.4 BrokerProfile.clientCount / profilesManaged Are Manually Maintained

**Issue:** These are stored as integers on `BrokerProfile` and manually incremented/decremented. They can drift from reality if any code path forgets to update them. For example, `_handleLinkRequestAccepted` in `HiveLinkRepository` (line ~116) increments `clientCount`, but there's no decrement path if a parent disconnects.

**Fix:** Compute these dynamically: `clientCount` = count of accepted link requests where broker is `toUserId`, `profilesManaged` = count of profiles where broker's `userId` is in `brokerIds`.

---

### 5.5 No Disconnect / Unlink Flow

**Issue:** Once a parent-broker or child-parent link is established, there's no way to disconnect. No "Unlink" button, no "Remove Broker" action, no repository method for it.

**Impact:** If a parent wants to switch brokers, they're stuck.

**Fix:** Add `unlinkBroker(parentId, brokerId)` and `unlinkChild(parentId, childId)` methods that revoke the accepted link request and clean up.

---

### 5.6 Messaging Has No Real-Time Updates

**Issue:** `ChatScreen` loads messages once in `_loadMessages()` and only refreshes when the user sends a message. There's no polling, no stream, no push. In a conversation between a broker and parent, the parent won't see new messages until they leave and re-enter the chat screen.

**Fix short-term:** Add a periodic timer (every 5s) that re-fetches messages.
**Fix long-term:** Move to Firestore or WebSocket streams.

---

## 6. Bad Design Decisions

### BD-1: Gender Enum Uses "Bride" and "Groom" Instead of Male/Female

**Issue:** `Gender.bride` and `Gender.groom` in `CandidateProfile`. Gender and marital intent are different concepts. A groom is not a gender; it's a role in a wedding. This creates confusion when displaying profiles — "Gender: Bride" reads oddly.

**Fix:** Rename to `Gender.female` and `Gender.male` (or keep `bride`/`groom` as a separate `LookingFor` / `MarriageRole` enum). The `ParentProfile` already has a separate `LookingFor` enum — consolidate.

---

### BD-2: Anuyatra Hub Screens Are Product Islands

**Issue:** The "Anuyatra Hub" tab (in both Parent and Candidate shells) links to three screens:
- **Vivaha Samskara** — shows premium services (beauty, health, cultural learning) with mock data and no booking flow
- **Trust Verification** — shows trust scores with hardcoded mock data, no real verification
- **Financial Compatibility** — shows financial matching with hardcoded mock data, no real computation

These are completely disconnected from the core matchmaking flow. They use `RevolutionaryFeaturesData` (static mock data), have no interaction with repositories, and provide no actionable value.

**Impact:** Users see impressive-looking features that don't actually work. This erodes trust.

**Fix:** Either:
- Remove the Hub tab until these features are real
- Or: relabel as "Coming Soon" with clear indicators that these are preview/concept screens
- Or: build real integrations (trust scores from profile completeness + verified documents, financial compatibility from actual income/asset data in profiles)

---

### BD-3: Hub Uses `MaterialPageRoute` Instead of GoRouter

**Issue:** `AnuyatraHubScreen` navigates to `VivahaSamskaraHomeScreen`, `TrustVerificationScreen`, and `FinancialCompatibilityScreen` using `Navigator.push(context, MaterialPageRoute(...))` instead of GoRouter named routes.

**Impact:** Back button behavior may be inconsistent with the rest of the app. Deep linking is impossible. These screens exist outside the GoRouter routing tree.

**Fix:** Register these screens as GoRouter routes (either as children of the hub branch or as overlay routes) and use `context.pushNamed()`.

---

### BD-4: Discovery Screen Serves Two Different Use Cases Poorly

**Issue:** `DiscoveryScreen` is the parent's "Search" tab. It shows three tabs: Browse Profiles, Agencies, and Brokers. But:
- **Browse Profiles** shows ALL candidate profiles in the system, not filtered by the parent's preferences. No matching algorithm, no relevance ranking.
- **Agencies** and **Brokers** tabs let parents send link requests, but the parent can't see broker reviews, success rates, or compare brokers.

**Impact:** The discovery experience is a raw dump of all data, not a curated search.

**Fix:**
- Filter profiles by parent's preferences (stored in `ParentProfile`: preferredCommunities, preferredMinAge, preferredMaxAge, religion, caste, etc.)
- Add match score/relevance indicator
- On broker/agency tabs, show ratings, success rates, and specialization filters

---

### BD-5: Same Profile Can Exist Under Multiple Brokers With No Dedup

**Issue:** `CandidateProfile.brokerIds` is a list, and `listedWithBrokersCount` shows how many brokers manage it. But there's no deduplication when a parent views profiles from different brokers. The parent could see the same candidate shared by two different brokers as two separate entries.

**Impact:** Confusing UX — parent might respond differently to the same profile from different brokers.

**Fix:** Use `deduplicationKey` (already exists on the model but never set) to detect and merge duplicate profiles in the UI.

---

### BD-6: Auth Flow Doesn't Carry Role Context Properly

**Issue:** The auth flow is: Role Selection → Login (phone) → OTP → Profile Setup → Authenticated. But the phone number entry (`LoginScreen`) doesn't record which role was selected. If a user selects "Parent" but their phone number is already registered as a "Broker", the app silently logs them in as a Broker.

**Impact:** Role selection is meaningless for existing users. New users might not understand this.

**Fix:** After login, if the user exists with a different role, show a dialog: "This number is registered as a [Broker]. Would you like to continue as [Broker] or create a new [Parent] account?"

---

### BD-7: Profile Setup Collects Minimal Data

**Issue:** `ProfileSetupScreen` only collects `displayName` and `role-specific basics (city, state for parents; nothing extra for broker/candidate beyond name)`. For brokers, it doesn't collect bio, specializations, fee structure, or experience — all the fields that make `BrokerProfile` useful.

**Impact:** A new broker's profile is nearly empty. They have to somehow edit it later (which has no UI — see P1-B3).

**Fix:** Make profile setup a multi-step wizard that collects role-appropriate information. For brokers: bio, specializations, experience, contact info. For parents: child details, preferences.

---

### BD-8: "Maybe" Response Deprecated But Still Shows in Some Codepaths

**Issue:** `SharedProfileResponse.maybe` is marked `@Deprecated` with a comment saying "Use Save (SavedProfile) instead." But `home_screen.dart` still has `onMaybe` action buttons for parents. The `candidate_shared_profiles_screen` correctly only shows Interested/Pass.

**Impact:** Inconsistent UX — parent sees three options, candidate sees two.

**Fix:** Remove the `onMaybe` action from `home_screen.dart` parent response buttons. Keep only Interested / Pass / Save.

---

## 7. Navigation & Routing Gaps

### 7.1 Defined But Unregistered Routes

| Route Name | Path | Status |
|-----------|------|--------|
| `brokerEditProfile` | `/broker/profiles/edit/:id` | Path and name defined in `RouteNames` but NO `GoRoute` registered in `app_router.dart` |

### 7.2 Screens Without Routes

| Screen | Current Access | Issue |
|--------|---------------|-------|
| `VivahaSamskaraHomeScreen` | `MaterialPageRoute` from Hub | Not in GoRouter — no deep link, inconsistent nav |
| `TrustVerificationScreen` | `MaterialPageRoute` from Hub | Same |
| `FinancialCompatibilityScreen` | `MaterialPageRoute` from Hub | Same |
| `DesignSystemDemoScreen` | Unknown — no route, no navigation to it | Completely orphaned; only accessible if you know it exists |
| `MainNavigationScreen` | None — 0 references | Dead code, 471 lines |
| `ShortlistScreen` | Only from `MainNavigationScreen` | Dead code |
| `BrokersListScreen` | Only from `MainNavigationScreen` | Dead code |
| `BrokerScreen` | Only from `BrokersListScreen` | Dead code |
| `ProfileDetailScreen` | Only from `ShortlistScreen` + `ProfileMessageCard` (legacy widget) | Dead code |

### 7.3 Missing Navigation Links

| From | To | Missing |
|------|----|---------|
| Parent Home (shared profiles list) | Profile detail | ✅ Works — taps go to `ProfileViewScreen` |
| Parent MyBrokers | Broker detail | **Missing** — no tap action shows broker info |
| Parent MyBrokers | Chat with broker | **Missing** — no message button |
| Broker Profiles | Edit profile | **Missing** — no edit route registered |
| Broker Dashboard | Specific activity item | **Missing** — activity tiles are not tappable |
| Candidate Home | Own candidate profile | **Missing** — candidate can't view their matchmaking profile |
| Any screen | App Settings | Via profile/settings screens only |

### 7.4 Back Navigation Issues

The hub screens (`VivahaSamskara`, `TrustVerification`, `FinancialCompatibility`) are pushed via `MaterialPageRoute`, which means they render with a back arrow in the AppBar. But they exist within the shell's tab context, so the AppBar back button may behave unexpectedly with the bottom navigation bar still visible.

---

## 8. Cross-Role Interaction Gaps

### 8.1 The Core Flow: Broker → Parent → Candidate

This is the app's primary value chain. Here's the expected flow and where it breaks:

```
Broker creates candidate profile     ✅ Works
    ↓
Broker shares profile with parent    ✅ Works (via BrokerProfilesScreen._showShareDialog)
    ↓
Parent receives shared profile       ✅ Works (HomeScreen shows shared profiles)
    ↓
Parent reviews and responds           ✅ Works (Interested/Maybe/Pass)
    ↓
Broker sees parent's response         ❌ BROKEN — no feedback mechanism
    ↓
Parent forwards to child              ✅ Works (ForwardToChildSheet)
    ↓
Child sees forwarded profile          ❌ BROKEN — queries wrong userId (P0-1)
    ↓
Child responds                        ❓ Code exists but unreachable due to P0-1
    ↓
Parent sees child's response          ✅ Works (if child response were set, it shows in parent's home)
    ↓
Broker sees child's response          ❌ BROKEN — no visibility
    ↓
Next steps (meeting, etc.)            ❌ NOT IMPLEMENTED
```

### 8.2 The Link Request Lifecycle

```
Parent sends link request to broker   ✅ Works (DiscoveryScreen → sendLinkRequest)
    ↓
Broker sees pending request            ✅ Works (LinkRequestsScreen)
    ↓
Broker accepts                         ✅ Works (creates conversation, updates broker client count)
    ↓
Parent sees accepted request           ✅ Works (LinkRequestsScreen status update)
    ↓
Parent and broker can now chat         ❌ ONE-SIDED — only broker can initiate chat
    ↓
Broker can share profiles with parent  ✅ Works
    ↓
Disconnect / end relationship          ❌ NOT IMPLEMENTED
```

### 8.3 Agency ↔ Broker Relationship

```
Admin invites broker to agency        ✅ Sends link request
    ↓
Broker accepts invitation             ⚠️ PARTIAL — request accepted but agencyId not set on broker profile
    ↓
Broker appears in agency dashboard     ❌ BROKEN — depends on agencyId being set
    ↓
Admin sees broker's stats              ⚠️ Partially works if broker was seeded with agencyId
    ↓
Admin can manage broker settings       ❌ NOT IMPLEMENTED
    ↓
Admin removes broker                   ❌ NOT IMPLEMENTED
```

---

## 9. UX Polish & Missing Feedback

### 9.1 Loading States

| Screen | Loading State | Quality |
|--------|--------------|---------|
| All ConsumerStateful screens | `CircularProgressIndicator` center | Functional but bland |
| Shimmer loading | Widget exists (`ShimmerLoading` in `app_animations.dart`) | **Never used** — 0 screen usages |

**Fix:** Replace bare `CircularProgressIndicator` with shimmer skeletons that match the layout of the loaded state.

### 9.2 Empty States

| Screen | Empty State | Quality |
|--------|------------|---------|
| Broker Profiles | "No Profiles Yet" with icon + CTA | ✅ Good |
| Broker Messages | "No conversations yet" | ✅ Good |
| Candidate Shared Profiles | "No shared profiles yet" | ✅ Good |
| Parent Home (no shared profiles) | None — just empty sliver | ❌ Missing |
| Parent MyBrokers (no brokers) | Unknown | Needs check |
| Link Requests (none pending) | Unknown | Needs check |

### 9.3 Destructive Action Confirmations

| Action | Has Confirmation? |
|--------|------------------|
| Logout (all 5 screens) | ✅ Yes — `showDialog` with title/message |
| Decline link request | ❌ No — immediate action |
| Pass on shared profile (parent) | ❌ No — immediate action |
| Pass on shared profile (candidate) | ❌ No — immediate action |
| Delete profile | N/A — not implemented |
| Disconnect from broker | N/A — not implemented |

### 9.4 Pull-to-Refresh

| Screen | Has RefreshIndicator? |
|--------|---------------------|
| Parent Home | ✅ Yes |
| Candidate Shared Profiles | ✅ Yes |
| Link Requests | ✅ Yes |
| Broker Profiles | ❌ No |
| Broker Clients | ❌ No |
| Broker Messages | ❌ No |
| Broker Dashboard | ❌ No |
| Discovery Screen | ❌ No |
| Parent MyBrokers | ❌ No |

### 9.5 Success/Error Feedback

| Action | Feedback |
|--------|----------|
| Share profile with parent | ✅ SnackBar |
| Send link request | ✅ SnackBar |
| Accept/Decline link request | ✅ SnackBar |
| Respond to shared profile (parent) | ✅ SnackBar |
| Forward to child | ✅ SnackBar |
| Send chat message | ❌ No feedback (message just appears) |
| Create candidate profile | Unknown — need to verify |
| Save agency settings | ❌ Appears to save silently |

### 9.6 Offline / Error Handling

- No offline detection or messaging
- No retry mechanisms on failed loads
- No error boundaries — if a repository call throws, the screen likely shows a red error or goes blank
- No "Something went wrong" fallback screens

---

## 10. Feature Screens Running on Mock Data

These screens look polished but are completely fake:

| Screen | Mock Data Source | What It Shows |
|--------|-----------------|---------------|
| `TrustVerificationScreen` | `RevolutionaryFeaturesData.mockTrustVerifications` | Trust scores, endorsements, verification breakdown — all hardcoded |
| `FinancialCompatibilityScreen` | `RevolutionaryFeaturesData.mockFinancialCompatibilities` + `mockFinancialProfiles` | Financial profile, asset analysis, compatibility matching — all fake |
| `VirtualMeetingScreen` | `RevolutionaryFeaturesData.mockVirtualMeetings` | Video meeting scheduling and history — all fake |
| `VivahaSamskaraHomeScreen` | `PremiumServicesData` | Premium service catalog with appointments and tasks — all fake |
| `ShortlistScreen` | `MockData.profiles` | Legacy shortlist grid — dead code |
| `BrokersListScreen` | `MockData.brokers` | Legacy broker list — dead code |
| `BrokerScreen` | `MockData.getChatMessages()` | Legacy broker detail + chat — dead code |
| `DesignSystemDemoScreen` | Inline constants | Design system showcase — dev-only |

**Impact:** 5 of these are accessible through the live Anuyatra Hub tab. Users interact with them thinking they're real features.

---

## 11. Recommended Fix Priority

### Tier 1 — Fix Broken Core Flows (1-2 days)

1. **P0-1/P0-2:** Fix candidate shared profiles query to use `getForwardedProfiles(parentId)` instead of `getSharedProfilesForUser(candidateId)`
2. **P0-4:** Register the edit-profile route and wire `ProfileCreateEditScreen` to support edit mode
3. **P0-6:** Add chat initiation from parent's MyBrokers screen
4. **P1-A1:** Handle `agencyToBroker` link request acceptance (set `brokerProfile.agencyId`)
5. **P0-7:** Remove notification bell no-ops or replace with a simple notification list

### Tier 2 — Close Feedback Loops (2-3 days)

6. **P1-B1:** Show parent response status on broker's shared profile history
7. **P1-P4:** Wire SavedProfile bookmark to parent UI
8. **P1-B4:** Add deduplication check for profile sharing
9. **BD-8:** Remove `onMaybe` from parent response buttons — align with `@Deprecated` enum

### Tier 3 — Design Fixes (3-5 days)

10. **BD-2:** Label hub feature screens as "Coming Soon" or disable them
11. **BD-3:** Migrate hub navigation to GoRouter
12. **BD-4:** Add preference-based filtering to Discovery
13. **P0-5:** Add profile delete/archive for brokers
14. **5.5:** Add disconnect/unlink flow

### Tier 4 — UX Polish (ongoing)

15. Replace `CircularProgressIndicator` with shimmer skeletons
16. Add `RefreshIndicator` to all list screens
17. Add confirmation dialogs for destructive actions (decline, pass)
18. Add empty states where missing
19. Add periodic message polling in ChatScreen

### Tier 5 — Structural / Long-term

20. **BD-1:** Rename `Gender.bride/groom` to proper gender enum
21. **5.1:** Support multiple children per parent
22. **5.3:** Wire `candidateUserId` so candidates can see their own matchmaking profile
23. **BD-6:** Handle role mismatch during login
24. **BD-7:** Multi-step profile setup wizard
25. **5.6:** Real-time messaging (Firestore streams or WebSockets)

---

## 12. Additional Findings from Deep Audit (Agent-Discovered)

The following issues were surfaced by deep per-file analysis across all roles, auth flows, and data layer.

### 12.1 Auth Flow — Critical Gaps

| Issue | Severity | Detail |
|-------|----------|--------|
| **Orphaned users after app kill post-OTP** | P0 | If the app is killed after OTP verification but before profile setup, the user record exists in Hive with an empty display name and no session. On re-login with the same phone, `verifyOtp` finds the existing user and emits `AuthAuthenticated` — **skipping profile setup entirely**. The user lands in their role shell with a blank name and no role profile. |
| **Login screen has no error listener** | P1 | `sendOtp` failures (`invalidPhone` regex, `sendOtpFailed`) from `AuthNotifier` are **never shown** to the user. Only local length validation shows a SnackBar. The Indian regex (must start with 6-9) is provider-only. |
| **Profile setup screen has no error listener** | P1 | `profileSetupFailed` error from `completeProfileSetup` is invisible — no `ref.listen` for `AuthError`. |
| **OTP back navigation is broken** | P1 | `goBackToInitial()` resets auth state to `AuthInitial` but **no navigation** occurs. Router allows `AuthInitial` on auth routes, so the user stays on `/otp-verify` with a blank phone label. |
| **Candidate setup data discarded** | P1 | Age/gender collected in `CandidateSetupData` on the setup wizard are **never persisted** — `auth_provider.dart:215-217` does nothing with them. |
| **Enriched fields save race** | P2 | `_saveEnrichedFields` fires 600ms after submit regardless of whether `completeProfileSetup` succeeded — can write partial data on auth failure. |
| **Role immutable; re-login ignores role selection** | P2 | Selecting "Parent" on role selection but entering a phone registered as "Broker" silently logs in as Broker with **no warning**. |

### 12.2 Data Layer — Unwired Repositories & Structural Issues

| Issue | Detail |
|-------|--------|
| **4 providers not overridden in `main.dart`** | `activityRepositoryProvider`, `parentNoteRepositoryProvider`, `brokerNoteRepositoryProvider`, `meetingRepositoryProvider` — reading them throws `UnimplementedError`. Their `AppDataModule` instances exist but aren't wired. |
| **`viewedProfileRepository` wired but unused** | Provider overridden in `main.dart` but `recordView` / `getRecentViews` never called from any screen. |
| **6 entity types have no seed data** | SavedProfile, ViewedProfile, ProfileActivity, ParentNote, BrokerNote, Meeting — all empty on first launch. |
| **Enum name collisions** | `VerificationStatus` defined in both `broker_profile.dart` (unverified/pending/verified) and `trust_verification.dart` (pending/verified/rejected). `MeetingType` and `MeetingStatus` defined differently in `meeting.dart` vs `virtual_meeting.dart`. Import hazards if both are used in the same file. |
| **No delete/cascade anywhere** | No delete API for users, profiles, links, messages, conversations, agencies, or any entity. Orphan records accumulate. |
| **`parentUserId` never set on seed candidate profiles** | Despite `candidate-001` being linked to `parent-001` via `childToParent` link request, `cp-001.parentUserId` is null. |
| **`SharedProfile.childResponse` uses `byName` (throws)** | If an unknown response value is in stored JSON, deserialization crashes. Other enums use safe `firstWhere+orElse`. |

### 12.3 Link Request Pipeline — Additional Bugs

| Issue | Detail |
|-------|--------|
| **Agency connect sends to `agency.id`, accept expects `adminUserId`** | Discovery sends `toUserId: agency.id`. Accept handler looks up agency by `adminUserId == request.toUserId`. Since `agency.id != agency.adminUserId`, agency link acceptance side effects never run. |
| **My Brokers "Incoming Pending" filters wrong types** | `MyBrokersScreen` filters `getPendingRequestsFor(parent)` to `parentToBroker | parentToAgency` — but those types are **outgoing** from parent (parent is `fromUserId`). The section is effectively always empty. Should show `childToParent` incoming requests instead. |
| **`LinkRequestsScreen` Received tab crash** | `late List<LinkRequest> _requests` is read in first `build()` before async `_loadRequests` completes → `LateInitializationError`. Sent tab correctly initializes `_requests = []`. |
| **Duplicate link requests allowed** | No dedup check in `sendLinkRequest`. A parent can spam connection requests to the same broker. |
| **`childToParent` accept is a no-op** | Unlike `parentToBroker` (creates conversation, increments client count) and `agencyToBroker` (sets agencyId), accepting a `childToParent` request does **nothing** — no conversation, no notification, no profile sync. |

### 12.4 Messaging — Structural Issues

| Issue | Detail |
|-------|--------|
| **Unread count increments for sender too** | `sendMessage` always increments `conv.unreadCount` without checking if the sender is the recipient — sender's conversation list shows incorrect unread badges. |
| **Chat `conversationId` fallback** | If `GoRouterState.pathParameters['conversationId']` is missing, chat falls back to hardcoded `'conv-001'` — could show wrong conversation. |
| **Always shows "Online"** | Chat app bar hardcodes online status for all contacts regardless of actual presence. |
| **Video/call/attach/camera are all no-ops** | 5 `IconButton`s with `onPressed: () {}` in chat screen. |

### 12.5 Cross-Screen State Freshness

All screens use **local `setState` + one-shot `initState` loads** — no Riverpod stream providers, no cross-screen listeners. `StatefulShellRoute.indexedStack` keeps tabs mounted with stale data.

| Screen | Refreshes when? |
|--------|-----------------|
| Parent Home | Pull-to-refresh only + forward sheet callback |
| Parent MyBrokers | Never (no `RefreshIndicator`, no reload on tab re-select) |
| Parent Profile | Never |
| Broker Dashboard | Never |
| Broker Profiles | Never (stale after create/share) |
| Broker Messages | Never (stale after chat) |
| Broker Clients | After accept/decline only |
| Candidate Home | Never (stale after link/forward) |
| Discovery | Never |
| All admin screens | Never (stale after broker invite) |

### 12.6 Hardcoded English Strings (Beyond L10n Migration)

The agent audit found **87 `Text('...')` literals** in screens + 7 `hintText/labelText` literals = **94 total** hardcoded English strings across 23 files. Highest concentrations: financial compatibility (10), trust verification (9), virtual meeting (9), profile detail (7).

Additionally, shell tab labels in `candidate_shell.dart` and several section titles in broker screens are hardcoded English, not using `context.l10n`.

### 12.7 No Route-Based Authorization

GoRouter redirect only checks auth state (authenticated vs not), **not role**. Any authenticated user can manually navigate to `/admin`, `/broker`, `/parent`, or `/candidate` URLs regardless of their actual role. Similarly, `ProfileViewScreen` has no access control — any user with a profile ID can see full candidate details.

### 12.8 Legacy Code Status

The agents confirmed that `lib/screens/main_navigation.dart`, `lib/screens/shortlist_screen.dart`, `lib/screens/brokers_list_screen.dart`, `lib/screens/broker_screen.dart`, `lib/screens/profile_detail_screen.dart`, all 10 `lib/widgets/` files, `lib/theme/app_theme.dart`, `lib/data/mock_data.dart`, and `lib/core/services/local_storage_service.dart` have been **moved to `_archive/`** by the parallel coding agent and are no longer in the active compilation tree. The `PRODUCT_AUDIT.md` references to these as "legacy" are now references to archived code that doesn't compile into the app.

---

*End of audit. This document covers the state of the codebase as of 2026-05-31 on the loving-cray branch. Some files may have been modified by a parallel coding agent during this audit.*
