# Backend Migration TODO

This document tracks all deferred backend work. The app currently uses **Hive CE local storage** as a mini-server — multiple accounts on one device can interact with each other. When migrating to a real backend (Firebase, Supabase, custom API, etc.), replace local storage calls with API calls.

---

## 1. Authentication

| Item | Current (Local) | Backend Needed |
|------|-----------------|----------------|
| Phone + OTP | Mock OTP "123456" always accepted | Firebase Auth / Twilio / MSG91 for real SMS OTP |
| Session management | Hive box `session` stores current user UID | JWT tokens / Firebase Auth session |
| Multi-device login | Not applicable (single device) | Token-based auth with refresh tokens |
| Account deletion | Not implemented | GDPR-compliant account + data deletion |

---

## 2. User & Profile Storage

| Item | Current (Local) | Backend Needed |
|------|-----------------|----------------|
| User records | Hive box `users` | Firestore `users` collection or PostgreSQL `users` table |
| Agency profiles | Hive box `agencies` | Firestore `agencies` collection |
| Broker profiles | Hive box `brokerProfiles` | Firestore `broker_profiles` collection |
| Parent profiles | Hive box `parentProfiles` | Firestore `parent_profiles` collection |
| Candidate profiles | Hive box `candidateProfiles` | Firestore `candidate_profiles` collection |
| Profile photos | Not implemented (using initials) | Firebase Storage / S3 / Cloudinary |
| Photo upload + crop | Not implemented | Image picker + crop + upload to cloud storage |

---

## 3. Link Requests (Connections)

| Item | Current (Local) | Backend Needed |
|------|-----------------|----------------|
| Send link request | `storage.sendLinkRequest()` writes to Hive | Cloud function / API endpoint |
| Accept/decline | `storage.acceptLinkRequest()` with local side effects | Server-side transaction (atomicity) |
| Real-time notifications | Not implemented | FCM push notifications on new request |
| Request expiry | Not implemented | Auto-expire after 7 days |
| Block user | Not implemented | Block list + filtering |

---

## 4. Search & Discovery

| Item | Current (Local) | Backend Needed |
|------|-----------------|----------------|
| Broker/agency search | Local Hive scan | Algolia / Elasticsearch / Firestore composite queries |
| Candidate profile search | Local filtering | Full-text search with filters |
| Geo-based search | City string matching | Geolocation-based radius search |
| Pagination | All results loaded at once | Cursor-based pagination |
| Search analytics | Not tracked | Track popular searches, conversion rates |

---

## 5. Messaging / Chat

| Item | Current (Local) | Backend Needed |
|------|-----------------|----------------|
| Chat messages | Hive boxes `conversations` + `messages` | Firestore real-time streams / WebSocket |
| Real-time delivery | Not real-time (same-device only) | Firestore `onSnapshot` or WebSocket |
| Read receipts | Not implemented | Message status: sent / delivered / read |
| Media messages | Not implemented | Image/document upload + message type |
| Typing indicators | Not implemented | Firestore presence or WebSocket |
| Push notifications | Not implemented | FCM for new messages |

---

## 6. Profile Sharing

| Item | Current (Local) | Backend Needed |
|------|-----------------|----------------|
| Share profile with parent | `storage.shareProfile()` | API call + notification to parent |
| Forward to child | UI only (no persistence) | Server-side forwarding + notification |
| Response tracking | `SharedProfile.parentResponse` in Hive | Real-time response sync |
| Share analytics | Not tracked | Track views, responses, conversion |

---

## 7. Agency Management

| Item | Current (Local) | Backend Needed |
|------|-----------------|----------------|
| Invite broker | Link request via Hive | Email/SMS invitation + deep link |
| Assign broker to client | Not fully implemented | Server-side assignment + notification |
| Agency analytics | Basic stat counts | Detailed dashboards with date ranges |
| Broker performance | Not tracked | Rating system, response times, conversion rates |
| Agency verification | Not implemented | Document upload + admin review |

---

## 8. Premium Services (Vivaha Samskara / Anuyatra)

| Item | Current (Local) | Backend Needed |
|------|-----------------|----------------|
| Service listings | Hardcoded UI | CMS-managed service catalog |
| Service booking | Not implemented | Booking system + payment integration |
| Payment processing | Not implemented | Razorpay / Stripe integration |
| Trust verification | Mock scoring | Real background check API integration |
| Financial compatibility | Mock analysis | Secure financial data collection + analysis |

---

## 9. Data Integrity & Security

| Item | Current (Local) | Backend Needed |
|------|-----------------|----------------|
| Data validation | Client-side only | Server-side validation + sanitization |
| Rate limiting | None | API rate limiting |
| Data encryption | Hive stores plaintext | Encrypt sensitive fields at rest |
| Audit trail | None | Log all data changes |
| Backup & recovery | None | Automated backups |
| RBAC | Client-side role checks | Server-enforced role-based access control |

---

## 10. Notifications

| Item | Current (Local) | Backend Needed |
|------|-----------------|----------------|
| Push notifications | None | FCM (Firebase Cloud Messaging) |
| Email notifications | None | SendGrid / SES for email alerts |
| SMS notifications | None | Twilio / MSG91 for SMS |
| In-app notifications | None | Notification feed with read/unread |
| Notification preferences | None | User-configurable notification settings |

---

## 11. Analytics & Monitoring

| Item | Current (Local) | Backend Needed |
|------|-----------------|----------------|
| User analytics | None | Firebase Analytics / Mixpanel |
| Crash reporting | None | Firebase Crashlytics / Sentry |
| Performance monitoring | None | Firebase Performance / custom APM |
| A/B testing | None | Firebase Remote Config |

---

## 12. Deduplication

| Item | Current (Local) | Backend Needed |
|------|-----------------|----------------|
| Profile dedup key | `CandidateProfile.deduplicationKey` (name+age hash) | Server-side matching algorithm |
| Cross-broker dedup | `listedWithBrokersCount` field exists | Real-time dedup across all brokers |
| Merge profiles | Not implemented | Admin tool to merge duplicate profiles |

---

## Migration Strategy

1. **Phase 1: Firebase Setup**
   - Firebase Auth (phone + OTP)
   - Firestore for all data collections
   - Firebase Storage for photos
   - FCM for push notifications

2. **Phase 2: Replace LocalStorageService**
   - Create `FirebaseStorageService` implementing same interface
   - Swap provider: `localStorageServiceProvider` → `firebaseStorageServiceProvider`
   - All screens continue working unchanged

3. **Phase 3: Real-time Features**
   - Firestore streams for chat
   - Real-time link request notifications
   - Profile sharing notifications

4. **Phase 4: Premium Features**
   - Payment integration
   - Real verification APIs
   - Service booking system

---

## Key Architecture Decision

The `LocalStorageService` was designed with a **clean interface** so that swapping to a backend requires:
- Creating a new service class with the same method signatures
- Changing the Riverpod provider
- No screen-level code changes needed

All business logic (link request side effects, search filtering, stats computation) currently lives in `LocalStorageService` and should move to **cloud functions** or **server-side logic** in the backend.
