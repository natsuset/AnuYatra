# Anuyatra Project Index

*Last updated: 2026-06-01 | Branch: loving-cray*

This document is the single source of truth for all documentation, artifacts, and project state. Any AI agent (Cursor, Claude Code, or otherwise) starting work on this repo should **read this file first** before making changes.

---

## 1. Repo Structure

```
loving-cray/
  lib/                        # Flutter app source (active code)
    core/                     # Architecture layer (auth, data, routing, theme, providers)
    common/widgets/           # Shared widgets (atoms, molecules)
    models/                   # Data models (16 files)
    screens/                  # All role-based screens
    l10n/                     # Generated localization files
    data/seed_data.dart       # Demo data seeder
    main.dart                 # Entry point
  backend/                    # Go API server (initialized, stubs only)
  _archive/                   # Dead code moved here by prior agents
  test/                       # Flutter tests (currently empty)
  .cursor/plans/              # Cursor plan files
```

---

## 2. Active Documents (Read These)

These are the current, authoritative documents. They supersede anything older.

| Document | Purpose | When to read |
|----------|---------|--------------|
| **PROJECT_INDEX.md** (this file) | Master index of everything | Always read first |
| **PRODUCT_AUDIT.md** | Complete audit of all roles, screens, flows, bugs, and gaps. 12 sections, 7 P0s, 12 P1s, 8 bad designs. | Before fixing any bug or adding any feature |
| **PRODUCT_PLAN.md** | Product-level plan covering boot-time flash, outstanding issues, and recommended attack order | For product direction |
| **PLAN_DELTA.md** | Delta between three prior planning docs and actual code. Verified file:line references. | For understanding what's been done vs. what's still open |
| **BACKEND_CONTRACTS.md** | Complete Go backend API spec — 60+ endpoints, all request/response shapes, auth matrix | Before implementing any backend endpoint |
| **WIRING_GUIDE.md** | How to connect Flutter frontend to Go backend — feasibility, step-by-step plan, vertical slices | Before starting any frontend-to-backend integration |
| **ARCHITECTURE.md** | Code patterns, file structure, naming conventions, engineering standards | Before writing any Flutter code |

---

## 3. Historical Documents (Reference Only)

These were created during earlier development sessions. They are **not wrong** but have been superseded by the documents above. Don't treat them as the current plan.

| Document | What it was | Status |
|----------|-------------|--------|
| `PRD_Anuyatra_Current_State.md` | Original PRD describing the app vision | Superseded by PRODUCT_AUDIT.md for actual state |
| `PRD_Complete_App.md` | Full feature PRD for the complete platform | Reference for future features |
| `PRD_Revolutionary_Features.md` | PRD for Trust/Financial/Virtual Meeting features | These are mock-data screens currently; see PRODUCT_AUDIT BD-2 |
| `UI_specs_parent.md` | UI specifications for parent profile screens | Reference |
| `CODE_REVIEW.md` | Earlier code review (March 2026) | Superseded by PRODUCT_AUDIT.md |
| `IMPROVEMENT_PLAN.md` | Incremental improvement plan | Partially completed; see PLAN_DELTA.md |
| `BACKEND_TODO.md` | Earlier list of backend migration tasks | Superseded by BACKEND_CONTRACTS.md |
| `CHAT_IMPROVEMENTS.md` | WhatsApp-style chat redesign notes | Implemented; reference only |
| `CONVERSATIONAL_PROFILE_DESIGN.md` | Conversational profile view design | Reference |
| `CONVERSATIONAL_PROFILE_IMPLEMENTATION.md` | Implementation summary of conversational profile | Completed |
| `CRASH_FIX_DOCUMENTATION.md` | Root cause analysis for white screen crash | Fixed; reference only |
| `IMPLEMENTATION_COMPLETE.md` | Summary of refactoring completion | Historical |
| `MULTIPLE_IMAGES_UPDATE.md` | Multiple image support changes | Completed |
| `SUCCESS_SUMMARY.md` | Phase 1 fix summary | Historical |
| `WHATSAPP_TRANSFORMATION_COMPLETE.md` | WhatsApp UI transformation summary | Completed |
| `README.md` | Default Flutter README | Needs rewriting |

---

## 4. Cursor Plans

| File | Purpose |
|------|---------|
| `.cursor/plans/multi-language_localization_4d5f8b4f.plan.md` | L10n migration plan |
| `.cursor/plans/resolution_playbook_fdae7628.plan.md` | Resolution playbook mapping every audit finding to its fix (Phases 1-6) |

---

## 5. App Architecture Summary

- **Framework:** Flutter 3.x with Material Design 3
- **State management:** Riverpod (ProviderScope, StateNotifier, ConsumerStatefulWidget)
- **Navigation:** GoRouter with StatefulShellRoute.indexedStack for role-based tab shells
- **Local storage:** Hive CE (Box<String> with JSON serialization)
- **Localization:** ARB files + gen-l10n (English, Hindi, Telugu); ~94 hardcoded strings remaining
- **Architecture:** Repository pattern with DI via Riverpod providers; 14 repository interfaces

### Roles and Their Shells

| Role | Shell | Tabs | Home Route |
|------|-------|------|------------|
| Parent | `ParentShell` | Home, Search, My Brokers, Hub, Profile | `/parent` |
| Broker | `BrokerShell` | Dashboard, Clients, Profiles, Messages, Profile | `/broker` |
| Candidate | `CandidateShell` | Home, Shared, Hub, Profile | `/candidate` |
| Agency Admin | `AgencyAdminShell` | Dashboard, Brokers, Clients, Settings | `/admin` |

### Core Data Flow

```
Broker creates CandidateProfile
  -> Broker shares with Parent (SharedProfile record)
    -> Parent reviews, responds (interested/pass)
      -> Parent forwards to Child (forwarded_to_child flag)
        -> Child sees profile, responds (child_response)
```

This flow is **broken at two points** (see PRODUCT_AUDIT P0-1, P0-2). Fix these first.

---

## 6. Backend (Go)

**Location:** `backend/`

**Status:** Initialized, compiles, all 60+ routes registered as 501 stubs. No database, no service layer yet.

**Structure:**
- `cmd/server/main.go` — HTTP server with graceful shutdown
- `internal/model/` — 9 files with all domain structs matching Flutter models
- `internal/repository/interfaces.go` — 12 repository interfaces
- `internal/handler/` — Route registration + stub handlers
- `internal/middleware/` — Logger, CORS, Recoverer, JWT auth
- `internal/config/` — Env-var based config
- `Dockerfile` + `docker-compose.yml` — API + Postgres
- `Makefile` — `make run`, `make build`, `make docker-up`

**Next steps for backend:**
1. Pick a database (Postgres recommended) and add migrations
2. Implement repository layer (start with UserRepository + AuthRepository)
3. Implement service layer with business logic (link request side effects, share dedup, etc.)
4. Replace stub handlers one domain at a time
5. On the Flutter side, create `lib/core/data/remote/` HTTP implementations of each repository interface

---

## 7. Known Critical Bugs (Fix First)

These are from PRODUCT_AUDIT.md and the Resolution Playbook. Any agent starting work should tackle these in order:

1. **Candidate shared profiles query broken** — queries by candidate ID instead of linked parent ID (`candidate_shared_profiles_screen.dart:40`, `candidate_home_screen.dart:46`)
2. **LinkRequestsScreen Received tab crash** — `late List` read before async init (`link_requests_screen.dart:65`)
3. **SharedProfile.childResponse byName crash** — unsafe enum deserialization (`shared_profile.dart:76`)
4. **childToParent accept is a no-op** — no side effects on accept (`hive_link_repository.dart:142-143`)
5. **Agency link request ID mismatch** — `parentToAgency` accept handler looks up by wrong ID (`hive_link_repository.dart:131-139`)
6. **MyBrokers incoming pending filters wrong types** — filters for outgoing types instead of incoming (`my_brokers_screen.dart:47-51`)
7. **No edit route for candidate profiles** — route name defined but no GoRoute registered (`app_router.dart`)

---

## 8. Archived Code

`_archive/` contains code moved out of the active tree by a prior coding agent:

- `_archive/lib/screens/` — Legacy screens: `main_navigation.dart`, `shortlist_screen.dart`, `brokers_list_screen.dart`, `broker_screen.dart`, `profile_detail_screen.dart`
- `_archive/lib/widgets/` — 10 legacy widget files
- `_archive/lib/theme/` — Legacy `app_theme.dart` (replaced by `lib/core/theme/app_theme.dart`)
- `_archive/lib/data/` — `mock_data.dart`
- `_archive/lib/core/` — `local_storage_service.dart`

Root-level scripts also archived: `_gen.py`, `_gen.sh`, `_gen_models.py`, `_w.sh`, `_d.b64`

**Do not import anything from `_archive/`.** If something from there is needed, copy it into the active tree and modernize it.

---

## 9. Rules for Any Agent Working on This Repo

1. **Read PRODUCT_AUDIT.md** before making changes — it maps every screen, every flow, and every bug.
2. **Read ARCHITECTURE.md** before writing Flutter code — it defines the patterns.
3. **Read BACKEND_CONTRACTS.md** before writing any backend code — it defines the API surface.
4. **Don't create new documentation files** unless asked. Update existing docs (especially this file) when you complete work.
5. **Don't import from `_archive/`** — that code is dead.
6. **Don't add mock/fake data screens** — every new screen must connect to a real repository.
7. **Use snake_case for JSON fields** in the Go backend; the Flutter models use camelCase internally but their `toJson()`/`fromJson()` can be adapted.
8. **Run `go build ./...`** after any Go change to verify compilation.
9. **Run `flutter analyze`** after any Dart change to catch lint issues.
10. **Update this file** when you complete a significant milestone (fix a P0, implement a backend domain, etc.).

---

## 10. What's Been Done (Completion Log)

| Date | What | By |
|------|------|----|
| 2026-05-31 | Complete product audit (PRODUCT_AUDIT.md) — 12 sections, all roles/screens/flows mapped | Cursor agent |
| 2026-05-31 | PLAN_DELTA.md verified against codebase | Cursor agent |
| 2026-05-31 | Resolution Playbook created (.cursor/plans/) — 6 phases, 25+ fixes mapped | Cursor agent |
| 2026-05-31 | Legacy code archived to `_archive/` | Parallel coding agent |
| 2026-05-31 | All 14 repository providers wired in `main.dart` (was 10) | Parallel coding agent |
| 2026-06-01 | BACKEND_CONTRACTS.md — complete Go API spec, 60+ endpoints | Cursor agent |
| 2026-06-01 | Go backend project initialized (`backend/`) — models, repos, handlers, middleware, Docker | Cursor agent |
| 2026-06-01 | PROJECT_INDEX.md (this file) created | Cursor agent |

---

## 11. What's Not Done (Priority Order)

1. **Fix 7 P0 bugs** listed in Section 7 above (Flutter, ~1-2 days)
2. **Implement Go backend service + repository layers** (start with auth + users)
3. **Add database migrations** for all 16 entity types
4. **Create Flutter remote repository implementations** (`lib/core/data/remote/`)
5. **Add unit tests** for Flutter repositories and auth flow
6. **Complete L10n migration** — 94 hardcoded English strings across 23 files
7. **Add RefreshIndicator** to all 15+ list screens
8. **Implement disconnect/unlink flow** for parent-broker and parent-child
9. **Add role-based route guards** in GoRouter redirect
10. **Build real notification system** to replace no-op bell icons
