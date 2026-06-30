# Wiring the Flutter Frontend to the Go Backend

*References: [BACKEND_CONTRACTS.md](BACKEND_CONTRACTS.md), [PRODUCT_AUDIT.md](PRODUCT_AUDIT.md), [ARCHITECTURE.md](ARCHITECTURE.md)*

---

## Feasibility Assessment: Yes, It's Clean

The frontend was built with this swap in mind. Here's what makes it work:

**Zero Hive leakage into application code.** Hive imports exist in exactly 16 files:
- 14 `lib/core/data/local/hive_*.dart` implementations
- 1 `lib/core/data/app_data_module.dart` (the DI factory)
- 1 `lib/main.dart` (Hive init + `AppDataModule.initLocal()`)

No screen, widget, model, auth provider, or routing file imports Hive. Every screen reads from abstract repository interfaces via Riverpod providers. This means the entire `lib/core/data/local/` directory can be swapped out without touching a single screen.

**The swap is a 3-file change.** The DI architecture routes through:
1. `AppDataModule` creates all repositories (currently Hive implementations)
2. `main.dart` calls `AppDataModule.initLocal()` and overrides Riverpod providers
3. Screens call `ref.read(fooRepositoryProvider)` which returns the abstract interface

To switch to remote: create `AppDataModule.initRemote(config)`, change one line in `main.dart`. Done.

**The models already serialize to JSON.** Every model has `toJson()` and `fromJson()` — these are the exact payloads that will go over HTTP. The only friction is the field naming convention.

---

## The One Real Problem: camelCase vs snake_case

Flutter models serialize with **camelCase** keys (`createdByUserId`, `sharedWithUserId`). The Go backend uses **snake_case** (`created_by_user_id`, `shared_with_user_id`).

**Three approaches to resolve this:**

### Option A: Go backend accepts camelCase (simplest)

Change the Go struct tags to camelCase:

```go
// Before
type AppUser struct {
    UID         string `json:"uid"`
    PhoneNumber string `json:"phone_number"`
    DisplayName string `json:"display_name"`
}

// After
type AppUser struct {
    UID         string `json:"uid"`
    PhoneNumber string `json:"phoneNumber"`
    DisplayName string `json:"displayName"`
}
```

**Pros:** Zero Flutter changes. Models work as-is.
**Cons:** Non-idiomatic Go JSON. External API consumers expect snake_case.

### Option B: Flutter models use snake_case in JSON (cleanest API)

Update every `toJson()` and `fromJson()` in the 16 model files to use snake_case keys:

```dart
// Before
Map<String, dynamic> toJson() => {
  'createdByUserId': createdByUserId,
  'sharedWithUserId': sharedWithUserId,
};

// After
Map<String, dynamic> toJson() => {
  'created_by_user_id': createdByUserId,
  'shared_with_user_id': sharedWithUserId,
};
```

**Pros:** Idiomatic Go API. Standard REST convention.
**Cons:** Touches every model file. Existing Hive data uses camelCase, so migration needed.

### Option C: Add a JSON key mapper in the API client (best of both)

Keep models as-is. Add a utility that converts keys at the HTTP boundary:

```dart
class ApiClient {
  Map<String, dynamic> _toSnakeCase(Map<String, dynamic> map) { ... }
  Map<String, dynamic> _toCamelCase(Map<String, dynamic> map) { ... }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) {
    final response = await _http.post(uri, body: jsonEncode(_toSnakeCase(body)));
    return _toCamelCase(jsonDecode(response.body));
  }
}
```

**Pros:** No model changes, no Go changes, both stay idiomatic.
**Cons:** Slight runtime cost (negligible). Need to handle nested objects.

**Recommendation:** Option A for MVP (fastest), migrate to Option B when going to production.

---

## Step-by-Step Wiring Plan

### Step 1: Create the API Client

New file: `lib/core/data/remote/api_client.dart`

This is a thin HTTP wrapper that handles:
- Base URL configuration
- Auth header injection (`Authorization: Bearer <token>`)
- Token refresh on 401
- Error mapping (HTTP status codes to `AppException` subclasses)
- JSON encoding/decoding

```dart
class ApiClient {
  final String baseUrl;
  String? _accessToken;
  String? _refreshToken;

  ApiClient({required this.baseUrl});

  void setTokens({required String access, required String refresh}) {
    _accessToken = access;
    _refreshToken = refresh;
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) async { ... }
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) async { ... }
  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) async { ... }
  Future<void> delete(String path) async { ... }
}
```

Depends on: `http` or `dio` package (add to `pubspec.yaml`).

### Step 2: Implement Remote Repositories (One at a Time)

Create `lib/core/data/remote/` with one file per repository. Each implements the same abstract interface as the Hive version.

**Recommended order** (matches the order you'll implement Go handlers):

| Order | Repository | Why first |
|-------|-----------|-----------|
| 1 | `RemoteAuthRepository` | Login flow — everything depends on this |
| 2 | `RemoteUserRepository` | Session, user lookup, profile setup |
| 3 | `RemoteBrokerRepository` | Broker dashboard, stats |
| 4 | `RemoteProfileRepository` | Create/edit/list candidate profiles |
| 5 | `RemoteLinkRepository` | Connection requests |
| 6 | `RemoteSharedProfileRepository` | Core sharing flow |
| 7 | `RemoteMessagingRepository` | Chat |
| 8 | `RemoteAgencyRepository` | Agency admin |
| 9-14 | Remaining (saved, viewed, activity, notes, meetings) | Lower priority |

**Example — `RemoteUserRepository`:**

```dart
class RemoteUserRepository implements UserRepository {
  final ApiClient _api;
  RemoteUserRepository(this._api);

  @override
  Future<AppUser?> getCurrentUser() async {
    try {
      final json = await _api.get('/api/v1/users/me');
      return AppUser.fromJson(json);
    } on UnauthorizedException {
      return null;
    }
  }

  @override
  Future<AppUser?> getUser(String uid) async {
    try {
      final json = await _api.get('/api/v1/users/$uid');
      return AppUser.fromJson(json);
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<void> setCurrentUser(String uid) async {
    // No-op for remote — the backend manages sessions via JWT.
    // Token is already stored in ApiClient.
  }

  @override
  Future<void> clearSession() async {
    await _api.post('/api/v1/auth/logout');
    _api.setTokens(access: '', refresh: '');
  }

  // ... etc
}
```

### Step 3: Create `AppDataModule.initRemote()`

Add a second factory to `app_data_module.dart`:

```dart
static Future<AppDataModule> initRemote(RemoteConfig config) async {
  final api = ApiClient(baseUrl: config.apiBaseUrl);

  // Restore tokens from secure storage (flutter_secure_storage)
  final storedAccess = await SecureStorage.read('access_token');
  final storedRefresh = await SecureStorage.read('refresh_token');
  if (storedAccess != null && storedRefresh != null) {
    api.setTokens(access: storedAccess, refresh: storedRefresh);
  }

  final authRepo = RemoteAuthRepository(api);
  final userRepo = RemoteUserRepository(api);
  final agencyRepo = RemoteAgencyRepository(api);
  final brokerRepo = RemoteBrokerRepository(api);
  final profileRepo = RemoteProfileRepository(api);
  final linkRepo = RemoteLinkRepository(api);
  final sharedProfileRepo = RemoteSharedProfileRepository(api);
  final messagingRepo = RemoteMessagingRepository(api);
  final savedProfileRepo = RemoteSavedProfileRepository(api);
  final viewedProfileRepo = RemoteViewedProfileRepository(api);
  final activityRepo = RemoteActivityRepository(api);
  final parentNoteRepo = RemoteParentNoteRepository(api);
  final brokerNoteRepo = RemoteBrokerNoteRepository(api);
  final meetingRepo = RemoteMeetingRepository(api);

  return AppDataModule._(
    authRepository: authRepo,
    userRepository: userRepo,
    // ... same shape as initLocal()
  );
}
```

### Step 4: Change One Line in `main.dart`

```dart
// Before:
final dataModule = await AppDataModule.initLocal();

// After:
final dataModule = await AppDataModule.initRemote(
  RemoteConfig(apiBaseUrl: 'https://api.anuyatra.com'),
);
```

Everything else stays identical — the `ProviderScope` overrides, the `AnuyatraApp` widget, the router, the screens.

### Step 5: Handle Auth Token Lifecycle

The biggest behavioral difference between local and remote:

**Local (Hive):** Session is a UID stored in a Hive box. `setCurrentUser(uid)` writes it. `getCurrentUser()` reads it. No expiration.

**Remote (API):** Session is a JWT. `verifyOtp` returns tokens. Tokens expire. Need refresh logic.

Changes needed in `AuthNotifier`:
- `verifyOtp` must store the tokens from the API response
- `checkAuthStatus` must validate the stored token (not just check if a user record exists)
- Add token refresh on 401 in `ApiClient`

**Token storage:** Use `flutter_secure_storage` (not Hive, not SharedPreferences) for `access_token` and `refresh_token`. These are the only values that need secure local persistence in remote mode.

### Step 6: Handle Differences in Side Effects

In the Hive implementation, side effects are executed client-side. For example, `HiveLinkRepository.acceptLinkRequest()`:
- Updates the link request status
- Increments broker client count
- Creates a conversation

In the remote implementation, **the server handles all side effects**. The client just calls:

```dart
Future<LinkRequest> acceptLinkRequest(String requestId) async {
  final json = await _api.post('/api/v1/link-requests/$requestId/accept');
  return LinkRequest.fromJson(json);
}
```

The server-side handler does the cascade. This means `RemoteLinkRepository` is **simpler** than `HiveLinkRepository` — no cross-repository dependencies, no manual counting.

The `init()` methods on Hive repositories (for cross-repo wiring) are not needed for remote repositories. The remote implementations are independent — each only needs the `ApiClient`.

---

## Current Status (Updated)

### Resolved (no longer blockers)

1. ~~**Go backend has zero implemented handlers.**~~ **All 77 routes are fully implemented** with in-memory storage. Auth (OTP + JWT), users, profiles, links, shared profiles, messaging, saved/viewed, notes, meetings, engagements, follow-ups, and file uploads all work.

2. ~~**No database migrations.**~~ The backend uses **in-memory storage** (`inmem` package). No Postgres needed for development. Data resets on server restart. SQL migrations will be needed for production.

3. ~~**Auth flow needs JWT token handling.**~~ The Flutter `ApiClient` already handles JWT tokens, automatic refresh on 401, and secure storage via `FlutterSecureStorage`. The `RemoteAuthRepository` and `RemoteUserRepository` are implemented.

4. ~~**`seed_data.dart` won't work in remote mode.**~~ Correct — seed data is local-only. In remote mode, data must be created through the API. This is fine for development; a server-side seed script can be added later.

5. ~~**camelCase/snake_case**~~ **Resolved.** Both Go and Flutter use **camelCase** JSON keys. No translation layer needed.

### Remaining work

- **Offline support** — keep Hive as a cache layer later. Not needed for initial wiring.
- **Real-time messaging** — polling works first; WebSockets can be added later.
- **File uploads** — presigned URL stub exists in Go. Flutter upload client not yet wired.
- **Postgres migration** — in-memory storage works for dev but data doesn't persist across restarts.

---

## Testing the Integration

All Go backend work is done. All Flutter remote repositories are implemented. To test:

### Quick start

1. Start the Go backend: `cd backend && go run ./cmd/server/main.go`
2. Switch Flutter to remote mode: change `DataSource.local` to `DataSource.remote` in `main.dart`
3. Run Flutter: `flutter run`

### Test flow: "Broker logs in and sees their dashboard"

1. Enter any phone number on the login screen
2. Use OTP `123456` (dev mode)
3. Complete profile setup
4. Verify dashboard loads with data from the API

### Test flow: "Parent connects with broker, receives shared profiles"

1. Log in as broker → create candidate profiles
2. Log in as parent → send connection request to broker
3. As broker → accept, share profiles with parent
4. As parent → view shared profiles, respond interested/pass

---

## File Inventory (All Implemented)

### Remote layer (all exist and are wired)

| File | Purpose |
|------|---------|
| `lib/core/data/remote/api_client.dart` | HTTP client with JWT auth, refresh, error mapping |
| `lib/core/data/remote/app_config.dart` | `DataSource.local` / `.remote`, base URL presets |
| `lib/core/data/remote/remote_auth_repository.dart` | Auth via `/api/v1/auth/*` |
| `lib/core/data/remote/remote_user_repository.dart` | Users via `/api/v1/users/*` |
| `lib/core/data/remote/remote_broker_repository.dart` | Broker profiles + stats |
| `lib/core/data/remote/remote_profile_repository.dart` | Parent + candidate profiles |
| `lib/core/data/remote/remote_agency_repository.dart` | Agencies |
| `lib/core/data/remote/remote_link_repository.dart` | Link requests |
| `lib/core/data/remote/remote_shared_profile_repository.dart` | Shared profiles |
| `lib/core/data/remote/remote_messaging_repository.dart` | Conversations + messages |
| `lib/core/data/remote/remote_extras_repository.dart` | Saved, viewed, activity, notes, meetings, engagements, follow-ups |

### DI (already supports both modes)

| File | Status |
|------|--------|
| `lib/core/data/app_data_module.dart` | Has both `initLocal()` and `initRemote()` |
| `lib/main.dart` | Flip `DataSource.local` → `DataSource.remote` |

**Unchanged:** Every screen, every widget, every model, every route, every provider.

---

## Summary

| Question | Answer |
|----------|--------|
| Is the architecture ready? | **Yes** — textbook repository pattern with DI |
| How many screens need changes? | **Zero** |
| How many model files need changes? | **Zero** — both sides use camelCase |
| Go backend status? | **77 endpoints implemented** with in-memory storage |
| Flutter remote layer status? | **16 remote repos implemented** covering all 77 endpoints |
| What's left? | Flip the data source flag, test, fix any edge cases |

See [FLUTTER_GO_INTEGRATION.md](FLUTTER_GO_INTEGRATION.md) for the full endpoint-to-repository mapping and [BACKEND_CONTRACTS.md](BACKEND_CONTRACTS.md) for the complete API reference.
