## Flutter Architecture & Best Practices

This document summarizes the **architecture and coding best practices** we want to follow in this Flutter codebase, heavily inspired by the official Flutter app architecture guidance and MVVM pattern described in the Flutter docs (`https://docs.flutter.dev/app-architecture/guide`).

---

## 1. Overall Architecture

- **Layered architecture (MVVM + data layer)**  
  - **UI layer**: Widgets (views) + view models + navigation.
  - **Data layer**: Repositories and services.
  - **Optional domain layer**: Use‑cases / interactors for complex or cross‑cutting business logic.
- **Goal**: Views stay focused on rendering and user interaction; data access, business rules, and side effects live in dedicated classes.  
  See Flutter’s architecture guide for the conceptual model and diagrams: `https://docs.flutter.dev/app-architecture/guide`.

---

## 2. UI Layer: Views & View Models

- **Views (Widgets)**
  - Contain **no business logic** and **no data loading**.
  - Responsibilities:
    - Build the UI tree.
    - Simple `if` checks to show / hide widgets.
    - Layout decisions based on screen size / orientation.
    - Trigger navigation (but not decide *business rules* of navigation).
  - Should receive all data via:
    - Constructor parameters, or
    - Watching a view model/provider.

- **View Models**
  - Own the **state for a screen or feature**.
  - Expose:
    - **Immutable state** (e.g. `AsyncValue<ProfileState>` via Riverpod).
    - **Commands** (methods) that the view can call in response to user actions (button tap, form submit, etc.).
  - Responsibilities:
    - Call repositories / use‑cases to load and update data.
    - Transform raw domain data into **presentation models** suitable for the UI.
    - Contain branching/decision logic that affects data or navigation (but still not direct `Navigator` calls where possible).
  - Must **not** depend on `BuildContext` or widgets.

For details on views and view models in Flutter’s terminology, see the “UI layer” section of the official guide: `https://docs.flutter.dev/app-architecture/guide`.

---

## 3. Data Layer: Repositories & Services

- **Repositories**
  - Source of truth for each **domain concept** (e.g. `ProfileRepository`, `BrokerRepository`).
  - Responsibilities:
    - Fetch data from one or more services (network, local DB, etc.).
    - Map DTOs / raw responses into **domain models** (`Profile`, `Broker`, etc.).
    - Handle:
      - Caching.
      - Error mapping and retry logic.
      - Refreshing / polling.
  - Expose **clear APIs**:
    - `Future<Profile>` / `Stream<List<Profile>>` / domain types, not `dynamic` or raw JSON.
  - Should not know about other repositories (composition happens in view models or domain layer).

- **Services**
  - Lowest‑level data access objects.
  - Wrap individual data sources:
    - REST/HTTP APIs.
    - Firebase/Firestore.
    - Local database.
    - Platform channels.
  - Responsibilities:
    - Perform the I/O and return raw data structures or DTOs.
    - Contain no business rules, no caching policy.

The “Data layer” section in the official guide describes repositories and services in more depth: `https://docs.flutter.dev/app-architecture/guide`.

---

## 4. Optional Domain Layer (Use‑Cases)

- Introduce a domain layer **only when needed**, for example when logic:
  - Combines data from multiple repositories.
  - Becomes too complex to keep in a view model cleanly.
  - Must be reused across multiple view models / features.
- Use‑cases:
  - Take repositories as dependencies.
  - Expose very focused operations, e.g. `GetShortlistedProfiles`, `ToggleProfileInterest`.
  - Make it easier to test complex business logic in isolation.

The Flutter docs present this as an optional “use‑case” layer on top of the data layer: `https://docs.flutter.dev/app-architecture/guide`.

---

## 5. State Management (with Riverpod)

- Use **Riverpod** as the primary state management solution:
  - `Provider` / `Provider.autoDispose` for simple read‑only dependencies.
  - `StateNotifierProvider` (or `Notifier`/`AsyncNotifier` in the newer API) for view models and complex state.
  - `FutureProvider` / `StreamProvider` for async reads where a dedicated notifier is not needed.
- Principles:
  - **No direct data fetching in widgets** (`initState` + `MockData` or HTTP calls) — instead, call repositories via providers.
  - Keep side effects (network calls, persistence, timers) in view models / notifiers or use‑cases.
  - Make state **serializable and testable** wherever practical.

For broader options and trade‑offs, see Flutter’s state management docs: `https://docs.flutter.dev/data-and-backend/state-mgmt/intro`.

---

## 6. Widgets, Composition & Reuse

- Keep screens **thin**:
  - Avoid “god widgets” that handle layout, state, and logic in one 1000+ line file.
  - Break large screens into smaller widgets:
    - Atoms, molecules, organisms (as this codebase already starts in `common/widgets`).
- Move **pure UI components** into reusable widgets:
  - Cards, list items, chips, buttons, app bars.
  - Make them stateless where possible, and drive them via parameters.
- Avoid deep nesting by extracting private widgets/methods when:
  - A subtree exceeds ~50–80 lines.
  - A piece of UI is reused in more than one place.

For widget guidance and composition patterns, see: `https://docs.flutter.dev/ui/widgets` and layout docs under `https://docs.flutter.dev/ui/layout`.

---

## 7. Theming, Design System & Styling

- Use a **central theme**:
  - Define `ThemeData` and `ColorScheme` in one place (e.g. `lib/core/theme/app_theme.dart`).
  - Use `Theme.of(context)` and custom `ThemeExtension`s rather than hardcoding colors and text styles.
- Maintain a **design system**:
  - Centralize typography (`TextTheme` or custom classes).
  - Centralize spacing, radii, and elevations.
  - Reuse design tokens from `core/constants` and `core/theme`.
- Prefer **semantic styles** over ad‑hoc ones:
  - For example, `AppTextStyles.body`, `AppColors.primaryBackground`, instead of magic values.

Official theming docs: `https://docs.flutter.dev/ui/design/themes` and Material 3 guidance: `https://docs.flutter.dev/ui/design/material`.

---

## 8. Data, Networking & Persistence

- Separate **API models** (DTOs) from **domain models**:
  - DTOs mirror the API shape and live close to services.
  - Domain models (`Profile`, `Broker`, etc.) are what the app uses internally.
  - Use mapping functions / extension methods between them.
- Error handling:
  - Normalize API errors into domain‑level failures (e.g. `AppFailure`) in repositories.
  - Let view models decide how to surface errors to the user (snackbar, inline message, retry button).
- Caching & offline:
  - Repositories own caching policy (in‑memory and/or local storage).
  - Services are stateless and unaware of caching.

See Flutter’s data & backend section for patterns: `https://docs.flutter.dev/data-and-backend`.

---

## 9. Navigation & Routing

- Use **typed navigation helpers or a routing package** to avoid scattered `MaterialPageRoute` usages.
- Keep navigation **initiated by the view**, but decisions that require business rules should live in the view model/domain.
- For deep links and web URLs, rely on the official navigation & routing guidance: `https://docs.flutter.dev/ui/navigation`.

---

## 10. Testing Strategy

- **Unit tests**:
  - For view models, repositories, and use‑cases.
  - Use mocked services to isolate business logic.
- **Widget tests**:
  - For key screens and reusable widgets.
  - Verify UI reacts correctly to various view model states (loading, success, error, empty).
- **Integration tests**:
  - Cover critical user flows end‑to‑end (onboarding, browsing profiles, shortlist, broker chat).

See Flutter’s testing overview: `https://docs.flutter.dev/testing`.

---

## 11. Code Organization & Naming

- Structure by **feature**, then by layer:
  - `features/profile/presentation/...`
  - `features/profile/domain/...`
  - `features/profile/data/...`
- Keep global/shared utilities in:
  - `core/` (cross‑cutting, app‑level concerns).
  - `shared/` or `common/` for design system widgets and models shared across features.
- Naming:
  - Suffix with roles: `ProfileRepository`, `ProfileService`, `ProfileDetailViewModel`, `ProfileDetailScreen`.
  - Keep file names in `snake_case.dart`, mirroring the type names.

These conventions make the project predictable and align with guidance across Flutter samples and the official architecture docs (`https://docs.flutter.dev/app-architecture/guide`).


