# Flutter + Go Backend Integration Guide

*Complete reference for connecting the Anuyatra Flutter app to the Go REST API.*

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter App                             │
│                                                              │
│  ┌──────────┐    ┌────────────────┐    ┌─────────────────┐  │
│  │ Screens  │───▸│ Riverpod       │───▸│ Repository      │  │
│  │          │    │ Providers      │    │ Interfaces      │  │
│  └──────────┘    └────────────────┘    └────────┬────────┘  │
│                                                  │           │
│                          ┌───────────────────────┼──────┐   │
│                          │                       │      │   │
│                 ┌────────▼─────┐       ┌─────────▼────┐ │   │
│                 │ Hive Local   │       │ Remote HTTP  │ │   │
│                 │ Repositories │       │ Repositories │ │   │
│                 └──────────────┘       └──────┬───────┘ │   │
│                                               │         │   │
│                                    ┌──────────▼──────┐  │   │
│                                    │   ApiClient     │  │   │
│                                    │  (JWT, retry,   │  │   │
│                                    │   error map)    │  │   │
│                                    └────────┬────────┘  │   │
└─────────────────────────────────────────────┼───────────┘   │
                                              │               │
                                    ┌─────────▼────────┐      │
                                    │  HTTP / JSON     │      │
                                    └─────────┬────────┘      │
                                              │               │
┌─────────────────────────────────────────────┼───────────────┘
│                     Go Backend              │
│                                             │
│  ┌──────────────┐    ┌──────────────────┐   │
│  │   Handlers   │◂───│  net/http Mux    │◂──┘
│  └──────┬───────┘    └──────────────────┘
│         │
│  ┌──────▼───────┐    ┌──────────────────┐
│  │   Services   │───▸│  In-Memory Repos │
│  │  (Container) │    │  (→ Postgres)    │
│  └──────────────┘    └──────────────────┘
└─────────────────────────────────────────
```

**The key design principle:** Screens never know whether data comes from Hive or the API. The swap happens at the DI root (`AppDataModule`) and nowhere else.

---

## How the Swap Works

### Current state (local mode)

```dart
// main.dart
final dataModule = await AppDataModule.initLocal();
```

Opens 18 Hive boxes, creates Hive repository implementations, wires cross-repo dependencies.

### To switch to remote mode

```dart
// main.dart
final dataModule = await AppDataModule.initRemote(
  apiBaseUrl: 'http://localhost:8080',  // or 10.0.2.2 for Android emulator
);
```

Creates an `ApiClient`, restores stored JWT tokens, instantiates 16 remote repository implementations. **Zero screen or widget changes.**

### Configuration

`lib/core/data/remote/app_config.dart` provides presets:

| Preset | `apiBaseUrl` | Use case |
|--------|-------------|----------|
| `AppConfig.iosSimulator` | `http://localhost:8080` | iOS sim / macOS desktop |
| `AppConfig.androidEmulator` | `http://10.0.2.2:8080` | Android emulator |
| Custom | Any URL | Physical device, staging, prod |

---

## API Client (`lib/core/data/remote/api_client.dart`)

The `ApiClient` is a thin wrapper around `package:http` that handles:

| Concern | How |
|---------|-----|
| **Auth headers** | Injects `Authorization: Bearer <token>` on every request |
| **Token storage** | `FlutterSecureStorage` for `access_token` and `refresh_token` |
| **Token restore** | `restoreTokens()` on app start — seamless session resume |
| **Auto-refresh** | On 401, attempts `/api/v1/auth/refresh` once, retries original request |
| **Error mapping** | HTTP 400→`ValidationException`, 401→`AuthException`, 404→`NotFoundException`, 409→`DuplicateException` |
| **JSON encoding** | `Content-Type: application/json` on all requests |

### Key methods

```dart
Future<Map<String, dynamic>> get(String path, {Map<String, String>? queryParams});
Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body});
Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body});
Future<void> delete(String path);

Future<void> setTokens({required String accessToken, required String refreshToken});
Future<void> clearTokens();
Future<void> restoreTokens();
bool get hasTokens;
```

---

## Endpoint-to-Repository Mapping

### 1. Authentication

| Go Endpoint | Flutter Remote Repo | Method |
|------------|-------------------|--------|
| `POST /api/v1/auth/send-otp` | `RemoteAuthRepository` | `sendOtp(phoneNumber, selectedRole)` |
| `POST /api/v1/auth/verify-otp` | `RemoteAuthRepository` | `verifyOtp(phoneNumber, otpCode)` |
| `POST /api/v1/auth/refresh` | `ApiClient` (internal) | Auto-triggered on 401 |
| `POST /api/v1/auth/logout` | `RemoteUserRepository` | `clearSession()` |

**Auth flow:**
1. Flutter calls `sendOtp` → Go returns `sessionId`, `message`, and `otp` (dev mode only)
2. Flutter calls `verifyOtp` with `sessionId` + `otp` + `phoneNumber` + `role` → Go returns `accessToken`, `refreshToken`, `user`, and `needsProfileSetup`
3. `ApiClient.setTokens()` stores both tokens in `FlutterSecureStorage`
4. All subsequent requests auto-include `Authorization: Bearer <token>`
5. On 401, `ApiClient` tries refresh via `POST /auth/refresh`. If refresh fails, tokens are cleared → user sees login.

**JSON keys (camelCase on both sides):**

```json
// sendOtp request
{ "phoneNumber": "+919876543210", "role": "parent" }

// sendOtp response
{ "sessionId": "sess-uuid", "message": "OTP sent", "otp": "123456" }

// verifyOtp request
{ "sessionId": "sess-uuid", "phoneNumber": "+919876543210", "otp": "123456", "role": "parent" }

// verifyOtp response
{ "accessToken": "jwt...", "refreshToken": "jwt...", "user": {...}, "needsProfileSetup": true }

// refresh request / response
{ "refreshToken": "jwt..." }  →  { "accessToken": "new-jwt..." }
```

Note: refresh only returns a new access token — the refresh token itself is not rotated.

### 2. Users

| Go Endpoint | Flutter Remote Repo | Method |
|------------|-------------------|--------|
| `GET /api/v1/users/me` | `RemoteUserRepository` | `getCurrentUser()`, `getCurrentUserId()` |
| `PUT /api/v1/users/me` | `RemoteUserRepository` | `saveUser(user)` |
| `POST /api/v1/users/setup-profile` | `RemoteUserRepository` | *(called during auth flow)* |
| `GET /api/v1/users/{id}` | `RemoteUserRepository` | `getUser(uid)` |
| `GET /api/v1/users?phone=...` | `RemoteUserRepository` | `getUserByPhone(phone)` |
| `GET /api/v1/users` | `RemoteUserRepository` | `getAllUsers(limit, offset)` |

**Notes:**
- `setCurrentUser(uid)` is a no-op in remote mode (JWT handles session)
- `clearSession()` calls `POST /auth/logout` then clears tokens locally
- `isEmpty` always returns `false` (remote DB is never empty in the seed sense)
- `registerUser()` is effectively a no-op — the user already exists after OTP verification

### 3. Profiles (Parent + Candidate)

| Go Endpoint | Flutter Remote Repo | Method |
|------------|-------------------|--------|
| `GET /api/v1/parent-profiles/me` | `RemoteProfileRepository` | *(via getParentProfile with user's own ID)* |
| `PUT /api/v1/parent-profiles/me` | `RemoteProfileRepository` | `saveParentProfile(profile)` |
| `GET /api/v1/parent-profiles/{userId}` | `RemoteProfileRepository` | `getParentProfile(userId)` |
| `GET /api/v1/parent-profiles` | `RemoteProfileRepository` | `getAllParentProfiles(limit, offset)` |
| `POST /api/v1/candidate-profiles` | `RemoteProfileRepository` | `saveCandidateProfile(profile)` *(when id is empty)* |
| `GET /api/v1/candidate-profiles/{id}` | `RemoteProfileRepository` | `getCandidateProfile(id)` |
| `PUT /api/v1/candidate-profiles/{id}` | `RemoteProfileRepository` | `saveCandidateProfile(profile)` *(when id exists)* |
| `DELETE /api/v1/candidate-profiles/{id}` | *(not yet wired)* | — |
| `GET /api/v1/candidate-profiles` | `RemoteProfileRepository` | `getAllCandidateProfiles()`, `getCandidatesByBroker(brokerId)` |
| `GET /api/v1/candidate-profiles/{id}/activity` | `RemoteActivityRepository` | `getActivityForProfile(profileId)` |

**Query parameters for candidate search:**

```
?brokerId=uuid          → filter by managing broker (broker's portfolio)
&gender=bride           → filter by gender
&city=hyderabad
&religion=hindu
&minAge=24&maxAge=30
&q=anita                → name/education/profession search
&limit=20&offset=0
```

### 4. Broker Profiles

| Go Endpoint | Flutter Remote Repo | Method |
|------------|-------------------|--------|
| `GET /api/v1/broker-profiles/me` | `RemoteBrokerRepository` | *(via getBrokerProfile with user's own ID)* |
| `PUT /api/v1/broker-profiles/me` | `RemoteBrokerRepository` | `saveBrokerProfile(profile)` |
| `GET /api/v1/broker-profiles/{userId}` | `RemoteBrokerRepository` | `getBrokerProfile(userId)` |
| `GET /api/v1/broker-profiles` | `RemoteBrokerRepository` | `getAllBrokerProfiles()`, `searchBrokers(...)` |
| `GET /api/v1/broker-profiles/{userId}/stats` | `RemoteBrokerRepository` | `getBrokerStats(brokerUserId)` |

**Stats response (camelCase):**

```json
{
  "activeClients": 12,
  "profilesManaged": 8,
  "profilesShared": 24,
  "pendingRequests": 3
}
```

### 5. Agencies

| Go Endpoint | Flutter Remote Repo | Method |
|------------|-------------------|--------|
| `POST /api/v1/agencies` | `RemoteAgencyRepository` | `createAgency(...)` |
| `GET /api/v1/agencies/{id}` | `RemoteAgencyRepository` | `getAgency(id)` |
| `PUT /api/v1/agencies/{id}` | `RemoteAgencyRepository` | `saveAgency(agency)` |
| `GET /api/v1/agencies` | `RemoteAgencyRepository` | `getAllAgencies()`, `searchAgencies(...)` |
| `GET /api/v1/agencies/{id}/stats` | `RemoteBrokerRepository` | `getAgencyStats(agencyId)` |
| `GET /api/v1/agencies/{id}/brokers` | `RemoteBrokerRepository` | `getBrokersByAgency(agencyId)` |

### 6. Link Requests (Connections)

| Go Endpoint | Flutter Remote Repo | Method |
|------------|-------------------|--------|
| `POST /api/v1/link-requests` | `RemoteLinkRepository` | `sendLinkRequest(...)` |
| `POST /api/v1/link-requests/{id}/accept` | `RemoteLinkRepository` | `acceptLinkRequest(id)` |
| `POST /api/v1/link-requests/{id}/decline` | `RemoteLinkRepository` | `declineLinkRequest(id)` |
| `POST /api/v1/link-requests/{id}/revoke` | *(not yet wired)* | — |
| `GET /api/v1/link-requests/received` | `RemoteLinkRepository` | `getLinkRequestsReceivedBy(userId)`, `getPendingRequestsFor(userId)` |
| `GET /api/v1/link-requests/sent` | `RemoteLinkRepository` | `getLinkRequestsSentBy(userId)` |
| `GET /api/v1/link-requests/connections` | `RemoteLinkRepository` | `getAcceptedConnectionsFor(userId)` |
| `GET /api/v1/link-requests/connected-brokers` | `RemoteLinkRepository` | `getConnectedBrokerIds(parentUserId)` |
| `GET /api/v1/link-requests/connected-parents` | `RemoteLinkRepository` | `getConnectedParentIds(brokerUserId)` |
| `GET /api/v1/link-requests/linked-children` | `RemoteLinkRepository` | `getLinkedChildIds(parentUserId)` |
| `GET /api/v1/link-requests/linked-parent` | `RemoteLinkRepository` | `getLinkedParentId(childUserId)` |

**Side effects handled server-side (not by Flutter):**
- Accept `parent_to_broker` → creates conversation, updates broker stats
- Accept `agency_to_broker` → sets broker's `agency_id`
- Accept `child_to_parent` → creates conversation, links candidate profile

### 7. Shared Profiles

| Go Endpoint | Flutter Remote Repo | Method |
|------------|-------------------|--------|
| `POST /api/v1/shared-profiles` | `RemoteSharedProfileRepository` | `shareProfile(profileId, sharedByUserId, sharedWithUserId)` |
| `GET /api/v1/shared-profiles/for-me` | `RemoteSharedProfileRepository` | `getSharedProfilesForUser(userId)` |
| `GET /api/v1/shared-profiles/by-me` | `RemoteSharedProfileRepository` | `getSharedProfilesByBroker(brokerUserId)` |
| `GET /api/v1/shared-profiles/forwarded` | `RemoteSharedProfileRepository` | `getForwardedProfiles(parentUserId)` |
| `PUT /api/v1/shared-profiles/{id}/respond` | `RemoteSharedProfileRepository` | `updateSharedProfile(shared)` |
| `POST /api/v1/shared-profiles/{id}/forward` | `RemoteSharedProfileRepository` | `forwardProfileToChild(sharedProfileId)` |

### 8. Messaging

| Go Endpoint | Flutter Remote Repo | Method |
|------------|-------------------|--------|
| `POST /api/v1/conversations` | `RemoteMessagingRepository` | `getOrCreateConversation(userId1, userId2)` |
| `GET /api/v1/conversations` | `RemoteMessagingRepository` | `getConversationsForUser(userId)` |
| `GET /api/v1/conversations/{id}/messages` | `RemoteMessagingRepository` | `getMessages(conversationId)` |
| `POST /api/v1/conversations/{id}/messages` | `RemoteMessagingRepository` | `sendMessage(...)` |
| `POST /api/v1/conversations/{id}/read` | `RemoteMessagingRepository` | `markMessagesAsRead(conversationId, userId)` |

### 9. Saved Profiles (Bookmarks)

| Go Endpoint | Flutter Remote Repo | Method |
|------------|-------------------|--------|
| `POST /api/v1/saved-profiles` | `RemoteSavedProfileRepository` | `save(userId, profileId)` |
| `DELETE /api/v1/saved-profiles/{profileId}` | `RemoteSavedProfileRepository` | `unsave(userId, profileId)` |
| `GET /api/v1/saved-profiles` | `RemoteSavedProfileRepository` | `getSavedProfilesForUser(userId)` |
| `GET /api/v1/saved-profiles/check/{profileId}` | `RemoteSavedProfileRepository` | `isSaved(userId, profileId)` |

### 10. Viewed Profiles

| Go Endpoint | Flutter Remote Repo | Method |
|------------|-------------------|--------|
| `POST /api/v1/viewed-profiles` | `RemoteViewedProfileRepository` | `recordView(userId, profileId)` |
| `GET /api/v1/viewed-profiles` | `RemoteViewedProfileRepository` | `getRecentViews(userId)` |
| `DELETE /api/v1/viewed-profiles` | `RemoteViewedProfileRepository` | `clearHistory(userId)` |

### 11. Notes

| Go Endpoint | Flutter Remote Repo | Method |
|------------|-------------------|--------|
| `GET /api/v1/notes/parent?profileId=...` | `RemoteParentNoteRepository` | `getNotesForProfile(parentUserId, profileId)` |
| `GET /api/v1/notes/parent/all` | `RemoteParentNoteRepository` | `getAllNotesForParent(parentUserId)` |
| `PUT /api/v1/notes/parent` | `RemoteParentNoteRepository` | `saveNote(note)` |
| `DELETE /api/v1/notes/parent/{id}` | `RemoteParentNoteRepository` | `deleteNote(noteId)` |
| `GET /api/v1/notes/broker?profileId=...&forParentId=...` | `RemoteBrokerNoteRepository` | `get(brokerUserId, profileId, forParentId)` |
| `PUT /api/v1/notes/broker` | `RemoteBrokerNoteRepository` | `upsert(brokerUserId, profileId, forParentId, body)` |

### 12. Meetings

| Go Endpoint | Flutter Remote Repo | Method |
|------------|-------------------|--------|
| `POST /api/v1/meetings` | `RemoteMeetingRepository` | `save(meeting)` |
| `GET /api/v1/meetings?parentUserId=...&profileId=...` | `RemoteMeetingRepository` | `getMeetingsFor(parentUserId, profileId, viewerUserId)` |
| `GET /api/v1/meetings/next?parentUserId=...&profileId=...` | `RemoteMeetingRepository` | `getNextMeeting(parentUserId, profileId, viewerUserId)` |
| `POST /api/v1/meetings/{id}/cancel` | `RemoteMeetingRepository` | `cancel(meetingId)` |

### 13. File Uploads

| Go Endpoint | Flutter Remote Repo | Method |
|------------|-------------------|--------|
| `POST /api/v1/uploads/presigned-url` | *(not yet wired)* | — |

---

## Broker CRM Endpoints

### 14. Client Engagements

| Go Endpoint | Flutter Remote Repo | Method |
|------------|-------------------|--------|
| `GET /api/v1/broker/engagements?parentUserId=...` | `RemoteClientEngagementRepository` | `get(brokerUserId, parentUserId)` |
| `GET /api/v1/broker/engagements/all` | `RemoteClientEngagementRepository` | `getForBroker(brokerUserId)` |
| `PUT /api/v1/broker/engagements` | `RemoteClientEngagementRepository` | `save(engagement)` |

### 15. Broker Follow-ups

| Go Endpoint | Flutter Remote Repo | Method |
|------------|-------------------|--------|
| `GET /api/v1/broker/follow-ups` | `RemoteBrokerFollowUpRepository` | `getForBroker(brokerUserId)` |
| `GET /api/v1/broker/follow-ups?clientUserId=...` | `RemoteBrokerFollowUpRepository` | `getForClient(brokerUserId, clientUserId)` |
| `PUT /api/v1/broker/follow-ups` | `RemoteBrokerFollowUpRepository` | `save(followUp)` |
| `DELETE /api/v1/broker/follow-ups/{id}` | `RemoteBrokerFollowUpRepository` | `delete(id)` |

---

## Remaining Gaps

### Not yet wired in Flutter

| Go Endpoint | Status |
|------------|--------|
| `POST /api/v1/link-requests/{id}/revoke` | Route exists in Go, no Flutter method calls it |
| `DELETE /api/v1/candidate-profiles/{id}` | Route exists in Go, no Flutter method calls it |
| `POST /api/v1/uploads/presigned-url` | Route exists in Go, no Flutter upload logic yet |
| `GET /api/v1/meetings/{id}` | `RemoteMeetingRepository.get(id)` exists but no Go route for single meeting by ID |

---

## JSON Key Convention: camelCase Everywhere

Both the Flutter remote repos and the Go handlers use **camelCase** JSON keys:

```json
// Flutter sends
{ "phoneNumber": "+919876543210", "selectedRole": "parent" }

// Go receives (struct tags)
type SendOTPRequest struct {
    PhoneNumber string `json:"phoneNumber"`
    Role        string `json:"role"`
}
```

This means serialization works without any key transformation layer. The existing `toJson()`/`fromJson()` methods on Flutter models produce camelCase, and the Go struct tags consume camelCase.

---

## Response Envelope Convention

All list endpoints use a consistent envelope:

```json
{
  "data": [ ... ],
  "total": 42
}
```

The Flutter remote repos parse this as:

```dart
final items = response['data'] as List<dynamic>? ?? [];
return items.cast<Map<String, dynamic>>().map(Model.fromJson).toList();
```

Error responses follow:

```json
{
  "error": {
    "code": "NOT_FOUND",
    "message": "User user-123 not found"
  }
}
```

---

## Remote Repository Implementation Pattern

Every remote repository follows the same structure. Here's the template:

```dart
class RemoteFooRepository implements FooRepository {
  final ApiClient _api;
  RemoteFooRepository(this._api);

  @override
  Future<Foo?> get(String id) async {
    try {
      final data = await _api.get('/api/v1/foos/$id');
      return Foo.fromJson(data);
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<List<Foo>> list({int? limit, int? offset}) async {
    final params = <String, String>{};
    if (limit != null) params['limit'] = '$limit';
    if (offset != null) params['offset'] = '$offset';
    final data = await _api.get('/api/v1/foos', queryParams: params);
    final items = data['data'] as List<dynamic>? ?? [];
    return items.cast<Map<String, dynamic>>().map(Foo.fromJson).toList();
  }

  @override
  Future<void> save(Foo foo) async {
    if (foo.id.isEmpty) {
      await _api.post('/api/v1/foos', body: foo.toJson());
    } else {
      await _api.put('/api/v1/foos/${foo.id}', body: foo.toJson());
    }
  }
}
```

**Key differences from Hive repos:**
- No cross-repository dependencies (server handles cascades)
- No `init()` method (each repo only needs `ApiClient`)
- Seeding methods like `saveFoo()` are no-ops
- `userId` params are often ignored (server infers from JWT)

---

## File Inventory

### Remote Layer (already exists)

| File | Purpose |
|------|---------|
| `lib/core/data/remote/api_client.dart` | HTTP client with JWT auth, refresh, error mapping |
| `lib/core/data/remote/app_config.dart` | `DataSource` enum, `AppConfig` with preset URLs |
| `lib/core/data/remote/remote_auth_repository.dart` | OTP send/verify via API |
| `lib/core/data/remote/remote_user_repository.dart` | User CRUD, session management via JWT |
| `lib/core/data/remote/remote_profile_repository.dart` | Parent + Candidate profiles |
| `lib/core/data/remote/remote_broker_repository.dart` | Broker profiles, search, stats |
| `lib/core/data/remote/remote_agency_repository.dart` | Agency CRUD, search |
| `lib/core/data/remote/remote_link_repository.dart` | Connection requests, accept/decline |
| `lib/core/data/remote/remote_shared_profile_repository.dart` | Profile sharing, respond, forward |
| `lib/core/data/remote/remote_messaging_repository.dart` | Conversations + messages |
| `lib/core/data/remote/remote_extras_repository.dart` | Saved/Viewed profiles, Activity, Notes, Meetings, Engagements, Follow-ups |

### DI Wiring (already supports both modes)

| File | Change needed |
|------|--------------|
| `lib/core/data/app_data_module.dart` | Already has `initLocal()` + `initRemote()` |
| `lib/main.dart` | Change `initLocal()` → `initRemote(apiBaseUrl: ...)` |

### Files that need zero changes

Every screen, widget, model, route, and provider declaration.

---

## Running Both Together

### Start the Go backend

```bash
cd backend
cp .env.example .env          # edit if needed
go run ./cmd/server/main.go   # starts on :8080
```

### Switch Flutter to remote mode

In `lib/main.dart`, change:

```dart
// FROM:
final dataModule = await AppDataModule.initLocal();

// TO:
final dataModule = await AppDataModule.initRemote(
  apiBaseUrl: 'http://localhost:8080',
);
```

Then run:

```bash
flutter run
```

### Verify the connection

1. App shows login screen
2. Enter a phone number → Go backend logs OTP
3. Enter OTP → JWT issued → dashboard loads
4. All data now flows through the API

---

## Error Handling Matrix

| HTTP Status | Flutter Exception | User-facing behavior |
|------------|------------------|---------------------|
| 400 | `ValidationException` | Form field error shown |
| 401 | `AuthException` | Auto-refresh attempted; if fails, redirect to login |
| 403 | `AuthException('Forbidden: ...')` | "Not authorized" snackbar |
| 404 | `NotFoundException` | Return `null` / empty list (graceful) |
| 409 | `DuplicateException` | "Already exists" message |
| 5xx | `AppException` | "Server error" snackbar |

---

## Migration Checklist

- [x] Repository interfaces are abstract (no Hive leakage)
- [x] `ApiClient` with JWT, refresh, error mapping
- [x] `AppConfig` with `DataSource.local` / `DataSource.remote`
- [x] `AppDataModule.initRemote()` factory
- [x] All 16 remote repository implementations
- [x] Models have `toJson()` / `fromJson()` with camelCase keys
- [x] Go backend has all 78 routes implemented (in-memory storage)
- [x] Go backend uses camelCase JSON tags matching Flutter
- [x] Go backend has broker engagement/follow-up routes (6 endpoints)
- [x] Go backend has single-meeting-by-ID route (`GET /api/v1/meetings/{id}`)
- [ ] Flutter needs `revokeLinkRequest()` method
- [ ] Flutter needs candidate profile delete method
- [ ] Flutter needs presigned URL upload integration
- [ ] Real-time messaging (WebSocket/SSE) — polling works as interim
- [ ] Offline cache layer (keep Hive as read-through cache behind remote)
