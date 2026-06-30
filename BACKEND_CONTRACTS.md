# Anuyatra Backend API Contracts (Go)

*Accurate as of the current Go implementation. All JSON examples use the exact field names from Go struct tags.*

---

## Conventions

- All endpoints return JSON with `Content-Type: application/json`.
- All JSON keys are **camelCase** (matching Go struct tags and Flutter models).
- All timestamps are ISO 8601 UTC.
- All IDs are UUIDs.
- Pagination uses `?limit=N&offset=M` query parameters (defaults: limit=20, offset=0, max limit=100).
- Paginated responses use a consistent envelope: `{ "data": [...], "total": N }`.
- Authenticated endpoints require `Authorization: Bearer <JWT>` header.
- Errors follow a standard envelope:

```json
{
  "error": {
    "code": "NOT_FOUND",
    "message": "AppUser user-abc123 not found"
  }
}
```

Error codes: `UNAUTHORIZED`, `FORBIDDEN`, `NOT_FOUND`, `CONFLICT`, `VALIDATION_ERROR`, `INTERNAL_ERROR`, `INVALID_OTP`, `SESSION_NOT_FOUND`.

### JWT details

- Algorithm: HS256
- Claims: `uid` (user ID), `role`, `exp`, `iat`
- Access token expiry: 15 minutes
- Refresh token expiry: 7 days
- Secret: `JWT_SECRET` env var (default: `dev-secret-change-in-production`)

### Middleware stack (applied globally)

1. **Logger** — logs method, path, status, duration
2. **CORS** — allows origins from `ALLOWED_ORIGINS` (default `*`); handles OPTIONS preflight
3. **Recoverer** — panic recovery → 500 with `INTERNAL_ERROR`

---

## 0. Health

### `GET /api/v1/health` — No auth

```json
Response 200: { "status": "ok" }
```

---

## 1. Authentication

All four auth endpoints are **public** (no JWT required).

### `POST /api/v1/auth/send-otp`

```
Request:
{
  "phoneNumber": "+919876543210",
  "role": "parent"              // "parent" | "broker" | "candidate" | "agencyAdmin"
}

Response 200:
{
  "sessionId": "uuid",
  "message": "OTP sent",
  "otp": "123456"               // dev mode only — omitted in production
}

Errors:
  400 VALIDATION_ERROR  — phoneNumber missing or role invalid
```

Dev mode always uses OTP `123456`. Production will use a real SMS provider (not yet wired).

### `POST /api/v1/auth/verify-otp`

Verifies the OTP. If the phone number is new, creates an `AppUser` and returns `needsProfileSetup: true`. If the user already exists, returns the existing user.

```
Request:
{
  "sessionId": "uuid",
  "phoneNumber": "+919876543210",
  "otp": "123456",
  "role": "parent"
}

Response 200 (existing user):
{
  "accessToken": "jwt...",
  "refreshToken": "jwt...",
  "user": { <AppUser> },
  "needsProfileSetup": false
}

Response 200 (new user):
{
  "accessToken": "jwt...",
  "refreshToken": "jwt...",
  "user": { <AppUser with empty displayName> },
  "needsProfileSetup": true
}

Errors:
  401 INVALID_OTP       — wrong code or expired
  401 SESSION_NOT_FOUND  — sessionId invalid
```

### `POST /api/v1/auth/refresh`

```
Request:
{
  "refreshToken": "jwt..."
}

Response 200:
{
  "accessToken": "new-jwt..."
}

Errors:
  401 UNAUTHORIZED — refresh token invalid or expired
```

Note: only returns a new access token. The refresh token itself is not rotated.

### `POST /api/v1/auth/logout`

Stateless — no server-side session to invalidate. Client should discard tokens locally.

```
Response 200:
{
  "message": "logged out"
}
```

---

## 2. Users

### `GET /api/v1/users/me` — Auth required

```json
Response 200:
{
  "uid": "user-uuid",
  "phoneNumber": "+919876543210",
  "displayName": "Priya Sharma",
  "photoUrl": "https://...",
  "role": "parent",
  "agencyId": null,
  "createdAt": "2026-01-15T10:30:00Z",
  "isActive": true
}
```

### `PUT /api/v1/users/me` — Auth required

Partial update — only provided fields are changed.

```
Request:
{
  "displayName": "Priya Sharma",
  "photoUrl": "https://..."
}

Response 200: { <updated AppUser> }
```

### `POST /api/v1/users/setup-profile` — Auth required

Complete profile setup after first login. Creates the role-specific profile based on the user's role.

```
Request:
{
  "displayName": "Priya Sharma",
  "roleData": {
    // role=parent:
    "lookingFor": "groom",
    "city": "Hyderabad",
    "state": "Telangana"

    // role=broker:
    "bio": "15 years experience..."

    // role=agencyAdmin:
    "agencyName": "Reddy Matrimony",
    "city": "Hyderabad",
    "state": "Telangana",
    "description": "Premium matchmaking..."

    // role=candidate: (no roleData needed)
  }
}

Response 200: { <AppUser with displayName set, agencyId set for admins> }
```

Side effects by role:
- **agencyAdmin** → creates `Agency`, sets `user.agencyId`
- **broker** → creates `BrokerProfile`
- **parent** → creates `ParentProfile`
- **candidate** → no profile created

### `GET /api/v1/users/{id}` — Auth required

```json
Response 200: { <AppUser> }
```

### `GET /api/v1/users` — Auth required

Dual-purpose: phone lookup or paginated list.

```
GET /api/v1/users?phone=+919876543210
Response 200: { <single AppUser> }

GET /api/v1/users?limit=20&offset=0
Response 200: { "data": [ <AppUser>, ... ], "total": N }
```

---

## 3. Parent Profiles

### `GET /api/v1/parent-profiles/me` — Auth required

```json
Response 200: { <ParentProfile — all fields> }
```

### `PUT /api/v1/parent-profiles/me` — Auth required

Full replacement — sends the complete profile. Server preserves `userId` and `createdAt`.

```
Request: { <ParentProfile fields> }
Response 200: { <updated ParentProfile> }
```

### `GET /api/v1/parent-profiles/{userId}` — Auth required

```json
Response 200: { <ParentProfile> }
```

### `GET /api/v1/parent-profiles` — Auth required

```
Query params: ?limit=20&offset=0
Response 200: { "data": [ <ParentProfile>, ... ], "total": N }
```

---

## 4. Broker Profiles

### `GET /api/v1/broker-profiles/me` — Auth required

```json
Response 200: { <BrokerProfile — all fields> }
```

### `PUT /api/v1/broker-profiles/me` — Auth required

Full replacement. Server preserves `userId` and `createdAt`.

```
Request: { <BrokerProfile fields> }
Response 200: { <updated BrokerProfile> }
```

### `GET /api/v1/broker-profiles/{userId}` — Auth required

```json
Response 200: { <BrokerProfile> }
```

### `GET /api/v1/broker-profiles` — Auth required

Search/list brokers. Always uses search path.

```
Query params:
  ?q=rajesh              — name/bio search
  &city=hyderabad        — filter by city
  &minRating=4.0         — minimum rating
  &limit=20&offset=0

Response 200: { "data": [ <BrokerProfile>, ... ], "total": N }
```

### `GET /api/v1/broker-profiles/{userId}/stats` — Auth required

```json
Response 200:
{
  "activeClients": 12,
  "profilesManaged": 8,
  "profilesShared": 24,
  "pendingRequests": 3
}
```

---

## 5. Candidate Profiles

### `POST /api/v1/candidate-profiles` — Auth required

Creates a new candidate profile. Server assigns `id`, `createdByUserId`, timestamps, and defaults `brokerIds` to `[caller]` if empty.

```
Request: { <CandidateProfile fields — id omitted> }
Response 201: { <CandidateProfile with server-assigned fields> }
```

### `GET /api/v1/candidate-profiles/{id}` — Auth required

```json
Response 200: { <CandidateProfile> }
```

### `PUT /api/v1/candidate-profiles/{id}` — Auth required

Full replacement. Server preserves `id`, `createdByUserId`, `createdAt`. Updates `updatedAt`.

```
Request: { <CandidateProfile fields> }
Response 200: { <updated CandidateProfile> }

Errors:
  403 FORBIDDEN — caller is not the creator or a broker in brokerIds
```

### `DELETE /api/v1/candidate-profiles/{id}` — Auth required

```
Response 204: No Content

Errors:
  403 FORBIDDEN — caller is not the creator or a broker in brokerIds
```

### `GET /api/v1/candidate-profiles` — Auth required

Search/list with filters.

```
Query params:
  ?brokerId=uuid          — filter by managing broker
  &gender=bride           — filter by gender
  &city=hyderabad
  &religion=hindu
  &minAge=24&maxAge=30
  &q=anita                — name/education/profession search
  &limit=20&offset=0

Response 200: { "data": [ <CandidateProfile>, ... ], "total": N }
```

### `GET /api/v1/candidate-profiles/{id}/activity` — Auth required

Activity timeline for a profile. Server-recorded events, not client-posted.

```
Query params: ?limit=50 (default)

Response 200:
{
  "data": [
    {
      "id": "act-uuid",
      "profileId": "cp-uuid",
      "actorUserId": "broker-uuid",
      "actorName": "Rajesh Kumar",
      "kind": "brokerSharedProfile",
      "at": "2026-05-30T14:00:00Z",
      "meta": { "sharedWith": "Priya Sharma" }
    }
  ]
}
```

Activity kinds: `brokerSharedProfile`, `brokerSentMessage`, `parentMarkedInterested`, `parentMarkedPass`, `parentSavedProfile`, `parentForwardedToChild`, `childMarkedInterested`, `childMarkedPass`, `meetingScheduled`, `meetingCompleted`, `meetingCancelled`, `brokerNoteAdded`, `parentNoteAdded`, `profileViewed`.

---

## 6. Agencies

### `POST /api/v1/agencies` — Auth required

Creates an agency and sets the caller's `agencyId`.

```
Request: { <Agency fields — id omitted> }
Response 201: { <Agency with server-assigned fields> }
```

### `GET /api/v1/agencies/{id}` — Auth required

```json
Response 200: { <Agency> }
```

### `PUT /api/v1/agencies/{id}` — Auth required

```
Request: { <Agency fields> }
Response 200: { <updated Agency> }

Errors:
  403 FORBIDDEN — caller is not the admin
```

### `GET /api/v1/agencies` — Auth required

```
Query params: ?q=reddy&city=hyderabad&minRating=4.0&limit=20&offset=0
Response 200: { "data": [ <Agency>, ... ], "total": N }
```

### `GET /api/v1/agencies/{id}/stats` — Auth required

```json
Response 200:
{
  "totalBrokers": 5,
  "totalClients": 34,
  "totalProfiles": 120
}
```

### `GET /api/v1/agencies/{id}/brokers` — Auth required

```
Query params: ?limit=20&offset=0
Response 200: { "data": [ <BrokerProfile>, ... ], "total": N }
```

---

## 7. Link Requests (Connections)

### `POST /api/v1/link-requests` — Auth required

```
Request:
{
  "toUserId": "user-uuid",
  "type": "parentToBroker",    // "parentToBroker" | "parentToAgency" | "agencyToBroker" | "childToParent"
  "note": "I found your profile on..."
}

Response 201: { <LinkRequest> }

Errors:
  400 VALIDATION_ERROR — toUserId missing or equals caller
  409 CONFLICT — pending request already exists for this (from, to, type)
```

### `POST /api/v1/link-requests/{id}/accept` — Auth required

Only the recipient (`toUserId`) can accept. Must be pending.

Side effect: for `parentToBroker` type, auto-creates a conversation.

```
Response 200: { <LinkRequest with status="accepted"> }

Errors:
  403 FORBIDDEN — caller is not the recipient
  400 VALIDATION_ERROR — request is not pending
```

### `POST /api/v1/link-requests/{id}/decline` — Auth required

Only the recipient can decline. Must be pending.

```
Response 200: { <LinkRequest with status="declined"> }
```

### `POST /api/v1/link-requests/{id}/revoke` — Auth required

Only the **sender** (`fromUserId`) can revoke. **Only works on pending requests** — this is for cancelling a request before it's answered, not for disconnecting accepted links.

```
Response 200: { <LinkRequest with status="revoked"> }

Errors:
  403 FORBIDDEN — caller is not the sender
  400 VALIDATION_ERROR — request is not pending
```

### `GET /api/v1/link-requests/received` — Auth required

```
Query params:
  ?status=pending          — filter by status
  &type=parentToBroker     — filter by type
  &limit=20&offset=0

Response 200: { "data": [ <LinkRequest>, ... ], "total": N }
```

### `GET /api/v1/link-requests/sent` — Auth required

```
Query params: same as received
Response 200: { "data": [ <LinkRequest>, ... ], "total": N }
```

### `GET /api/v1/link-requests/connections` — Auth required

All accepted connections for the caller (both directions).

```json
Response 200: { "data": [ <LinkRequest>, ... ] }
```

### `GET /api/v1/link-requests/connected-brokers` — Auth required

Broker user IDs connected to the authenticated parent.

```json
Response 200: { "data": ["broker-001", "broker-002"] }
```

### `GET /api/v1/link-requests/connected-parents` — Auth required

```json
Response 200: { "data": ["parent-001", "parent-003"] }
```

### `GET /api/v1/link-requests/linked-children` — Auth required

```json
Response 200: { "data": ["candidate-001"] }
```

### `GET /api/v1/link-requests/linked-parent` — Auth required

```json
Response 200: { "data": "parent-001" }
```

---

## 8. Shared Profiles

### `POST /api/v1/shared-profiles` — Auth required

Broker shares a candidate profile with a parent. Validates: profile exists, no duplicate (profileId, sharedWithUserId).

Records `brokerSharedProfile` activity.

```
Request:
{
  "profileId": "cp-uuid",
  "sharedWithUserId": "parent-uuid",
  "parentNote": "Good match"           // optional
}

Response 201: { <SharedProfile> }

Errors:
  404 NOT_FOUND — profile doesn't exist
  409 CONFLICT — already shared with this user
```

### `GET /api/v1/shared-profiles/for-me` — Auth required

Profiles shared with the caller.

```
Query params:
  ?response=pending        — filter by parentResponse
  &limit=20&offset=0

Response 200: { "data": [ <SharedProfile>, ... ], "total": N }
```

### `GET /api/v1/shared-profiles/by-me` — Auth required

Profiles shared by the caller (broker).

```
Query params:
  ?profileId=cp-uuid       — filter to a specific profile
  &response=interested
  &limit=20&offset=0

Response 200: { "data": [ <SharedProfile>, ... ], "total": N }
```

### `GET /api/v1/shared-profiles/forwarded` — Auth required

Profiles forwarded to the caller's linked children.

```
Query params: ?limit=20&offset=0
Response 200: { "data": [ <SharedProfile>, ... ], "total": N }
```

### `PUT /api/v1/shared-profiles/{id}/respond` — Auth required

Parent responds to a shared profile. Only the `sharedWithUserId` can respond.

Records `parentMarkedInterested` or `parentMarkedPass` activity.

```
Request:
{
  "response": "interested",       // "interested" | "pass"
  "parentNote": "Good match"      // optional
}

Response 200: { <updated SharedProfile> }

Errors:
  403 FORBIDDEN — caller is not the recipient
```

### `POST /api/v1/shared-profiles/{id}/forward` — Auth required

Parent forwards a shared profile to their linked child. No request body needed.

Records `parentForwardedToChild` activity.

```
Response 200: { <SharedProfile with forwardedToChild=true> }

Errors:
  403 FORBIDDEN — caller is not the sharedWithUserId
```

---

## 9. Messaging

### `POST /api/v1/conversations` — Auth required

Get or create a conversation between the caller and another user.

```
Request:
{
  "otherUserId": "user-uuid"
}

Response 200: { <Conversation> }
```

### `GET /api/v1/conversations` — Auth required

List conversations for the caller.

```
Query params: ?limit=20&offset=0
Response 200: { "data": [ <Conversation>, ... ], "total": N }
```

### `GET /api/v1/conversations/{id}/messages` — Auth required

```
Query params: ?limit=20&offset=0
Response 200: { "data": [ <ChatMessage>, ... ], "total": N }
```

### `POST /api/v1/conversations/{id}/messages` — Auth required

Send a message. If `recipientId` is omitted, server auto-derives from conversation participants.

```
Request:
{
  "content": "Hello, I have some profiles to share",
  "type": "text",                // "text" | "profileShare" | "image" | "system" (default: "text")
  "recipientId": "user-uuid",   // optional — auto-derived if omitted
  "profileId": null,             // for profileShare type
  "attachmentUrl": null          // for image type
}

Response 201: { <ChatMessage> }
```

### `POST /api/v1/conversations/{id}/read` — Auth required

Mark all messages in a conversation as read for the caller.

```json
Response 200: { "message": "marked as read" }
```

---

## 10. Saved Profiles (Bookmarks)

### `POST /api/v1/saved-profiles` — Auth required

```
Request:
{
  "profileId": "cp-uuid"
}

Response 201: { <SavedProfile> }
```

### `DELETE /api/v1/saved-profiles/{profileId}` — Auth required

```
Response 204: No Content
```

### `GET /api/v1/saved-profiles` — Auth required

```
Query params: ?limit=20&offset=0
Response 200: { "data": [ <SavedProfile>, ... ], "total": N }
```

### `GET /api/v1/saved-profiles/check/{profileId}` — Auth required

```json
Response 200: { "saved": true }
```

---

## 11. Viewed Profiles

### `POST /api/v1/viewed-profiles` — Auth required

```
Request:
{
  "profileId": "cp-uuid"
}

Response 201: { <ViewedProfile> }
```

### `GET /api/v1/viewed-profiles` — Auth required

```
Query params: ?limit=50 (default)
Response 200: { "data": [ <ViewedProfile>, ... ] }
```

### `DELETE /api/v1/viewed-profiles` — Auth required

Clear all view history for the caller.

```
Response 204: No Content
```

---

## 12. Notes

### `GET /api/v1/notes/parent?profileId=:cpId` — Auth required

Get the caller's note on a specific profile.

```json
Response 200: { <ParentNote> }
```

### `GET /api/v1/notes/parent/all` — Auth required

All of the caller's notes.

```json
Response 200: { "data": [ <ParentNote>, ... ] }
```

### `PUT /api/v1/notes/parent` — Auth required

Upsert. Server assigns `id` and `parentUserId` from JWT.

```
Request:
{
  "candidateProfileId": "cp-uuid",
  "body": "Good family background..."
}

Response 200: { <ParentNote> }
```

### `DELETE /api/v1/notes/parent/{id}` — Auth required

```
Response 204: No Content
```

### `GET /api/v1/notes/broker?profileId=:cpId&forParentId=:parentId` — Auth required

```json
Response 200: { <BrokerNote> }
```

### `PUT /api/v1/notes/broker` — Auth required

Upsert. Server assigns `id` and `brokerUserId` from JWT.

```
Request:
{
  "candidateProfileId": "cp-uuid",
  "forParentUserId": "parent-uuid",
  "body": "Family met last week..."
}

Response 200: { <BrokerNote> }
```

---

## 13. Meetings

### `POST /api/v1/meetings` — Auth required

Server assigns `id`, `scheduledByUserId` from JWT, `status=scheduled`, `createdAt`.

```
Request:
{
  "candidateProfileId": "cp-uuid",
  "parentUserId": "parent-uuid",
  "brokerUserId": "broker-uuid",
  "scheduledByRole": "broker",           // "parent" | "candidate" | "broker"
  "brokerVisible": true,
  "parentPartyVisible": true,
  "when": "2026-06-15T18:00:00Z",
  "durationMinutes": 30,
  "type": "virtual",                     // "inPerson" | "virtual" | "phone"
  "location": "Zoom",
  "virtualLink": "https://zoom.us/j/...",
  "notes": "First introduction call"
}

Response 201: { <Meeting> }
```

### `GET /api/v1/meetings/{id}` — Auth required

```json
Response 200: { <Meeting> }
```

### `GET /api/v1/meetings` — Auth required

Both `parentUserId` and `profileId` are required. Results are filtered by the caller's visibility.

```
Query params:
  ?parentUserId=uuid
  &profileId=uuid
  &limit=20&offset=0

Response 200: { "data": [ <Meeting>, ... ], "total": N }
```

### `GET /api/v1/meetings/next` — Auth required

Next upcoming scheduled meeting for a specific pair.

```
Query params: ?parentUserId=uuid&profileId=uuid

Response 200: { <Meeting> }

Errors:
  404 NOT_FOUND — no upcoming meeting
```

### `POST /api/v1/meetings/{id}/cancel` — Auth required

```json
Response 200: { "message": "meeting cancelled" }
```

---

## 14. Broker Client Engagements

Tracks the commercial lifecycle of each broker-parent relationship.

### `GET /api/v1/broker/engagements?parentUserId=:id` — Auth required

```json
Response 200: { <ClientEngagement> }
```

### `GET /api/v1/broker/engagements/all` — Auth required

All engagements for the authenticated broker, newest-updated first.

```json
Response 200: { "data": [ <ClientEngagement>, ... ] }
```

### `PUT /api/v1/broker/engagements` — Auth required

Upsert. Server assigns `brokerUserId` from JWT.

```
Request:
{
  "parentUserId": "parent-uuid",
  "stage": "active",                    // "lead" | "requested" | "connected" | "paid" | "active" | "lapsed"
  "planName": "Premium",
  "amountPaid": 25000,
  "paidAt": "2026-06-01T10:00:00Z",
  "sharingStartsAt": "2026-06-01T10:00:00Z",
  "validUntil": "2027-06-01T10:00:00Z",
  "budgetExpectation": "Wedding budget ₹25–40 L",
  "expectedIncomeMin": "₹15 LPA+",
  "requirementNotes": "Looking for settled groom in IT"
}

Response 200: { <ClientEngagement> }
```

---

## 15. Broker Follow-ups

Broker reminder/task system tied to specific clients or profiles.

### `GET /api/v1/broker/follow-ups` — Auth required

```
Query params:
  ?clientUserId=uuid       — filter to a specific client (optional)

Response 200: { "data": [ <BrokerFollowUp>, ... ] }
```

### `PUT /api/v1/broker/follow-ups` — Auth required

Upsert. Server assigns `brokerUserId` from JWT.

```
Request:
{
  "id": "fu-uuid",                       // omit for new
  "clientUserId": "parent-uuid",
  "candidateProfileId": "cp-uuid",
  "title": "Call Ramesh about Rahul's profile",
  "notes": "Discuss horoscope match results",
  "dueAt": "2026-07-05T10:00:00Z",
  "priority": "high",                   // "low" | "normal" | "high"
  "isDone": false,
  "completedAt": null
}

Response 200: { <BrokerFollowUp> }
```

### `DELETE /api/v1/broker/follow-ups/{id}` — Auth required

```
Response 204: No Content
```

---

## 16. File Uploads

### `POST /api/v1/uploads/presigned-url` — Auth required

Dev mode returns localhost URLs. Production will return cloud storage URLs.

```
Request:
{
  "filename": "photo.jpg",
  "contentType": "image/jpeg"
}

Response 200 (dev):
{
  "uploadUrl": "http://localhost:8080/api/v1/uploads/<key>",
  "publicUrl": "http://localhost:8080/api/v1/uploads/<key>",
  "key": "<uuid>_photo.jpg"
}
```

---

## 17. Authorization Summary

| Endpoint | Who can call |
|----------|-------------|
| `POST candidate-profiles` | Any authenticated user (typically broker) |
| `PUT/DELETE candidate-profiles/{id}` | Creator or broker in `brokerIds` |
| `PUT agencies/{id}` | Agency admin (`adminUserId == caller`) |
| `POST link-requests/{id}/accept` | Recipient (`toUserId`) |
| `POST link-requests/{id}/decline` | Recipient (`toUserId`) |
| `POST link-requests/{id}/revoke` | Sender (`fromUserId`), pending only |
| `PUT shared-profiles/{id}/respond` | Recipient (`sharedWithUserId`) |
| `POST shared-profiles/{id}/forward` | Recipient (`sharedWithUserId`) |

---

## 18. Data Model Reference

### AppUser
```json
{
  "uid": "string",
  "phoneNumber": "string",
  "displayName": "string",
  "photoUrl": "string|null",
  "role": "parent|broker|candidate|agencyAdmin",
  "agencyId": "string|null",
  "createdAt": "ISO8601",
  "isActive": true
}
```

### LinkRequest
```json
{
  "id": "string",
  "fromUserId": "string",
  "toUserId": "string",
  "fromUserName": "string",
  "toUserName": "string",
  "type": "parentToBroker|parentToAgency|agencyToBroker|childToParent",
  "status": "pending|accepted|declined|revoked",
  "createdAt": "ISO8601",
  "respondedAt": "ISO8601|null",
  "note": "string|null"
}
```

### SharedProfile
```json
{
  "id": "string",
  "profileId": "string",
  "sharedByUserId": "string",
  "sharedWithUserId": "string",
  "sharedAt": "ISO8601",
  "parentResponse": "pending|interested|pass",
  "forwardedToChild": false,
  "childResponse": "interested|pass|null",
  "parentNote": "string|null"
}
```

### Conversation
```json
{
  "id": "string",
  "participantIds": ["string", "string"],
  "lastMessagePreview": "string",
  "lastMessageAt": "ISO8601",
  "unreadCount": 0
}
```

### ChatMessage
```json
{
  "id": "string",
  "conversationId": "string",
  "senderId": "string",
  "recipientId": "string",
  "content": "string",
  "type": "text|profileShare|image|system",
  "timestamp": "ISO8601",
  "isRead": false,
  "profileId": "string|null",
  "attachmentUrl": "string|null"
}
```

### SavedProfile
```json
{ "id": "string", "userId": "string", "profileId": "string", "savedAt": "ISO8601" }
```

### ViewedProfile
```json
{ "id": "string", "userId": "string", "profileId": "string", "viewedAt": "ISO8601" }
```

### ParentNote
```json
{ "id": "string", "parentUserId": "string", "candidateProfileId": "string", "body": "string", "updatedAt": "ISO8601" }
```

### BrokerNote
```json
{ "id": "string", "brokerUserId": "string", "candidateProfileId": "string", "forParentUserId": "string", "body": "string", "updatedAt": "ISO8601" }
```

### Meeting
```json
{
  "id": "string",
  "candidateProfileId": "string",
  "parentUserId": "string",
  "brokerUserId": "string",
  "scheduledByUserId": "string",
  "scheduledByRole": "parent|candidate|broker",
  "brokerVisible": true,
  "parentPartyVisible": true,
  "when": "ISO8601",
  "durationMinutes": 30,
  "type": "inPerson|virtual|phone",
  "location": "string",
  "virtualLink": "string|null",
  "status": "scheduled|completed|cancelled",
  "notes": "string|null",
  "createdAt": "ISO8601"
}
```

### ClientEngagement
```json
{
  "id": "string",
  "brokerUserId": "string",
  "parentUserId": "string",
  "stage": "lead|requested|connected|paid|active|lapsed",
  "planName": "string|null",
  "amountPaid": 25000.0,
  "paidAt": "ISO8601|null",
  "sharingStartsAt": "ISO8601|null",
  "validUntil": "ISO8601|null",
  "budgetExpectation": "string|null",
  "expectedIncomeMin": "string|null",
  "requirementNotes": "string|null",
  "createdAt": "ISO8601",
  "updatedAt": "ISO8601"
}
```

### BrokerFollowUp
```json
{
  "id": "string",
  "brokerUserId": "string",
  "clientUserId": "string|null",
  "candidateProfileId": "string|null",
  "title": "string",
  "notes": "string",
  "dueAt": "ISO8601",
  "priority": "low|normal|high",
  "isDone": false,
  "createdAt": "ISO8601",
  "completedAt": "ISO8601|null"
}
```

---

## 19. Route Count Summary

| Group | Count |
|-------|-------|
| Health | 1 |
| Auth (public) | 4 |
| Users | 5 |
| Parent profiles | 4 |
| Broker profiles | 5 |
| Candidate profiles | 6 |
| Agencies | 6 |
| Link requests | 11 |
| Shared profiles | 6 |
| Messaging | 5 |
| Saved profiles | 4 |
| Viewed profiles | 3 |
| Notes | 6 |
| Meetings | 5 |
| Broker engagements | 3 |
| Broker follow-ups | 3 |
| File uploads | 1 |
| **Total** | **78** |
