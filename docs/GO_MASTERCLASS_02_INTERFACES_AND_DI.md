# Go Masterclass — Part 2: Interfaces, the Repository Pattern & Dependency Injection

> **Prerequisites**: You've read Part 1 (types, structs, functions, errors).
> You know what a struct is, how methods attach to receivers, and how Go
> handles errors via multiple return values. This part builds on all of that.

---

## Table of Contents

1. [Interfaces — The Most Important Go Concept](#1-interfaces--the-most-important-go-concept)
2. [The Repository Pattern in This Project](#2-the-repository-pattern-in-this-project)
3. [Implementing Interfaces — The In-Memory Layer](#3-implementing-interfaces--the-in-memory-layer)
4. [Dependency Injection Without a Framework](#4-dependency-injection-without-a-framework)
5. [Generics (Go 1.18+)](#5-generics-go-118)
6. [Context — Go's Request-Scoped Value Carrier](#6-context--gos-request-scoped-value-carrier)

---

## 1. Interfaces — The Most Important Go Concept

If you learn one thing about Go that separates it from every other language
you've used, let it be interfaces. Go interfaces are the reason the standard
library is so composable, the reason dependency injection works without a
framework, and the reason you can swap an in-memory database for Postgres
with a one-line change.

### 1.1 Implicit Satisfaction (Duck Typing)

In Java or Dart, you explicitly declare that a class implements an interface:

```java
// Java — explicit
class MyService implements UserRepository { ... }
```

```dart
// Dart — explicit
class MyService implements UserRepository { ... }
```

Go does **none of this**. There is no `implements` keyword. A type satisfies
an interface simply by having the right methods with the right signatures.
If it walks like a duck and quacks like a duck, it's a duck:

```go
// The interface
type Speaker interface {
    Speak() string
}

// Dog has a Speak() string method — it satisfies Speaker automatically.
type Dog struct{ Name string }
func (d Dog) Speak() string { return d.Name + " says woof!" }

// Cat also satisfies Speaker. No "implements" declaration needed.
type Cat struct{ Name string }
func (c Cat) Speak() string { return c.Name + " says meow!" }

// This function accepts anything that satisfies Speaker.
func Greet(s Speaker) {
    fmt.Println(s.Speak())
}

func main() {
    Greet(Dog{Name: "Rex"})    // "Rex says woof!"
    Greet(Cat{Name: "Whiskers"})  // "Whiskers says meow!"
}
```

**Why this matters**: You can define an interface in package A, and a struct
in package B can satisfy it without even importing package A. The two packages
are completely decoupled. This is the foundation of Go's composition model.

### 1.2 Small Interfaces — The Go Way

Go's standard library is full of tiny interfaces. The most famous:

```go
// io.Reader — one method, used everywhere
type Reader interface {
    Read(p []byte) (n int, err error)
}

// io.Writer — one method, used everywhere
type Writer interface {
    Write(p []byte) (n int, err error)
}

// error — one method, the most used interface in Go
type error interface {
    Error() string
}

// fmt.Stringer — one method
type Stringer interface {
    String() string
}
```

The `error` interface is so fundamental that it's a built-in type. Any struct
that has an `Error() string` method is an error. That's it. No base class,
no inheritance, no registration — just the method.

The Go proverb: **"The bigger the interface, the weaker the abstraction."**
A one-method interface can be satisfied by thousands of types. A ten-method
interface will only be satisfied by the one type you wrote it for.

### 1.3 How `*APIError` Satisfies `error`

In our project, look at `internal/model/errors.go`:

```go
type APIError struct {
    Code    string `json:"code"`
    Message string `json:"message"`
}

func (e *APIError) Error() string {
    return fmt.Sprintf("%s: %s", e.Code, e.Message)
}
```

That's it. By implementing the single method `Error() string`, the pointer
type `*APIError` now satisfies Go's built-in `error` interface. You can
return an `*APIError` anywhere an `error` is expected:

```go
func GetByID(ctx context.Context, id string) (*model.AppUser, error) {
    // ...
    if !ok {
        return nil, model.NotFoundError("User", id)
        //         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        //         This returns an *APIError, which IS an error.
    }
    // ...
}
```

The `NotFoundError` function returns `*APIError`, but the function signature
says `error`. This works because `*APIError` satisfies the `error` interface.

```go
func NotFoundError(entityType, id string) *APIError {
    return &APIError{
        Code:    "NOT_FOUND",
        Message: fmt.Sprintf("%s %s not found", entityType, id),
    }
}
```

The project also defines pre-built error singletons for common cases:

```go
var (
    ErrNotFound        = &APIError{Code: "NOT_FOUND", Message: "resource not found"}
    ErrUnauthorized    = &APIError{Code: "UNAUTHORIZED", Message: "authentication required"}
    ErrForbidden       = &APIError{Code: "FORBIDDEN", Message: "insufficient permissions"}
    ErrConflict        = &APIError{Code: "CONFLICT", Message: "resource already exists"}
    ErrValidation      = &APIError{Code: "VALIDATION_ERROR", Message: "invalid request"}
    ErrRateLimited     = &APIError{Code: "RATE_LIMITED", Message: "too many requests"}
    ErrInternal        = &APIError{Code: "INTERNAL_ERROR", Message: "internal server error"}
    ErrInvalidOTP      = &APIError{Code: "INVALID_OTP", Message: "invalid or expired OTP"}
    ErrSessionNotFound = &APIError{Code: "SESSION_NOT_FOUND", Message: "session not found"}
)
```

These are `var` not `const` because Go constants can only be primitive types.
Struct pointers must be variables.

### 1.4 The Empty Interface: `any` (alias for `interface{}`)

Before Go 1.18, the empty interface `interface{}` was the way to say "any
type". Since Go 1.18, `any` is a built-in alias:

```go
// These are identical:
var x interface{}
var y any

// The empty interface is satisfied by EVERY type.
x = 42
x = "hello"
x = Dog{Name: "Rex"}
x = []int{1, 2, 3}
```

You'll see `any` used in our project for generic metadata:

```go
type ProfileActivity struct {
    ID          string              `json:"id"`
    ProfileID   string              `json:"profileId"`
    Kind        ProfileActivityKind `json:"kind"`
    At          time.Time           `json:"at"`
    Meta        map[string]any      `json:"meta"`  // ← any value type
}
```

The `Meta` field is `map[string]any` — a JSON-like map where values can be
strings, numbers, booleans, nested maps, whatever. This is useful when you
need a flexible schema, but you lose type safety. Use `any` sparingly.

### 1.5 Interface Values: The (type, value) Pair

This is the most subtle and important concept about Go interfaces, and the
source of the most common Go bug.

An interface value in Go is internally a pair: **(concrete type, concrete
value)**. An interface is `nil` only when BOTH components are nil.

```go
var err error       // err is nil — both type and value are nil
fmt.Println(err == nil)  // true

var apiErr *APIError     // apiErr is nil (a nil pointer of type *APIError)
err = apiErr             // err now holds (type=*APIError, value=nil)
fmt.Println(err == nil)  // FALSE! The interface is NOT nil.
```

**This is the famous Go gotcha.** Even though the underlying `*APIError`
pointer is nil, the interface itself is not nil because it has a type
component. The interface knows it's holding an `*APIError` — it just happens
to be a nil one.

**The rule**: Never assign a typed nil pointer to an interface if you want
the interface to remain nil. Return `nil` directly:

```go
// WRONG — returns a non-nil error even when there's no error
func doSomething() error {
    var err *APIError  // nil
    // ... no error occurred ...
    return err  // returns (type=*APIError, value=nil) — NOT nil!
}

// RIGHT — return nil directly
func doSomething() error {
    // ... no error occurred ...
    return nil  // returns a truly nil interface
}
```

This matters in practice. If you write `if err != nil { handleError(err) }`,
the wrong version above will always enter the error-handling branch.

### 1.6 The Go Proverb: Accept Interfaces, Return Structs

This is one of the most important design principles in Go:

- **Function parameters** should be interfaces (accept the most general type)
- **Function return values** should be concrete types (give the caller the
  most specific type)

```go
// GOOD: accepts the interface, returns the concrete type
func NewUserRepo() *UserRepo {
    return &UserRepo{
        byID:    make(map[string]*model.AppUser),
        byPhone: make(map[string]string),
    }
}

// The caller can assign this concrete *UserRepo to the interface field:
container.Users = NewUserRepo()  // *UserRepo → UserRepository
```

**Why return structs?** Because the caller might need methods that aren't
on the interface. Returning the concrete type gives them full access. They
can still assign it to an interface variable when they want polymorphism.

**Why accept interfaces?** Because it makes your function work with any type
that has the right methods. A function that takes `io.Reader` can read from
a file, a network connection, a string, a gzip stream, or a test mock — all
without knowing or caring which one.

---

## 2. The Repository Pattern in This Project

The repository pattern is the bridge between your domain logic (handlers)
and your data storage. Every piece of data access goes through an interface.
The handler never knows (or cares) whether data lives in memory, Postgres,
MongoDB, or a CSV file.

### 2.1 File: `internal/repository/interfaces.go`

This single file defines ALL 14 repository interfaces plus supporting types.
It is the contract that the entire backend builds on.

### 2.2 The Pagination Type

Before looking at any interface, notice the shared pagination type:

```go
type Pagination struct {
    Limit  int
    Offset int
}

func DefaultPagination() Pagination {
    return Pagination{Limit: 20, Offset: 0}
}
```

Every `List*` method in every repository takes a `Pagination` parameter.
This is a deliberate design choice: you never return unbounded result sets.
Even in the in-memory implementation, you paginate. When you move to Postgres,
this maps directly to `LIMIT` and `OFFSET` in SQL.

`DefaultPagination()` returns a sensible default (first 20 items). Handlers
call this when the client doesn't specify pagination parameters.

### 2.3 Why Every Method Takes `context.Context`

Look at any method signature:

```go
Create(ctx context.Context, user *model.AppUser) error
GetByID(ctx context.Context, id string) (*model.AppUser, error)
```

The first parameter is always `context.Context`. This is a Go convention so
strong it's nearly a law. The `context` carries:

- **Cancellation signals**: If the HTTP client disconnects, the context is
  cancelled, and database queries can abort early.
- **Deadlines/timeouts**: "You have 5 seconds to complete this query."
- **Request-scoped values**: User ID, trace ID, request ID — values that
  follow the request through the entire call chain.

In our in-memory implementation, we ignore the context (using `_` for the
parameter name). But the interface requires it because a Postgres
implementation would need it for query cancellation and timeouts.

### 2.4 Interface 1: `UserRepository`

```go
type UserRepository interface {
    Create(ctx context.Context, user *model.AppUser) error
    GetByID(ctx context.Context, id string) (*model.AppUser, error)
    GetByPhone(ctx context.Context, phone string) (*model.AppUser, error)
    Update(ctx context.Context, user *model.AppUser) error
    List(ctx context.Context, p Pagination) ([]*model.AppUser, int, error)
}
```

The basic CRUD interface. Five methods. Notice:

- `Create` returns only `error` — the user's ID is already set before calling
  Create (the handler generates it).
- `GetByPhone` is a secondary lookup — users can be found by phone number,
  not just by ID. This is critical for authentication (login by phone + OTP).
- `List` returns `([]*model.AppUser, int, error)` — the slice of results,
  the total count (for "Page 1 of 5"), and an error.

### 2.5 Interface 2: `AuthRepository`

```go
type AuthRepository interface {
    SendOTP(ctx context.Context, phone string, role model.UserRole) (sessionID string, err error)
    VerifyOTP(ctx context.Context, sessionID, phone, code string) (bool, error)
}
```

Only two methods. This is the authentication contract. The implementation
can send real SMS messages (production) or use a hardcoded `123456` (dev
mode). The handler doesn't know or care.

- `SendOTP` returns a `sessionID` — a UUID that the client must send back
  when verifying. This prevents replay attacks.
- `VerifyOTP` returns `(bool, error)` — `true` if the code matches, `false`
  if it doesn't, or an error if the session is expired/not found.

Named return values (`sessionID string, err error`) serve as documentation
here — they tell the reader what each return value means.

### 2.6 Interface 3: `ParentProfileRepository`

```go
type ParentProfileRepository interface {
    Save(ctx context.Context, profile *model.ParentProfile) error
    GetByUserID(ctx context.Context, userID string) (*model.ParentProfile, error)
    List(ctx context.Context, p Pagination) ([]*model.ParentProfile, int, error)
}
```

Three methods. Notice it uses `Save` (upsert) instead of separate `Create`
and `Update`. This is because there's exactly one parent profile per user —
saving it either creates it or overwrites it.

The key is `UserID`, not a separate profile ID. A parent profile IS the
user's profile; there's a 1:1 relationship.

### 2.7 Interface 4: `BrokerProfileRepository`

```go
type BrokerProfileRepository interface {
    Save(ctx context.Context, profile *model.BrokerProfile) error
    GetByUserID(ctx context.Context, userID string) (*model.BrokerProfile, error)
    List(ctx context.Context, p Pagination) ([]*model.BrokerProfile, int, error)
    ListByAgency(ctx context.Context, agencyID string, p Pagination) ([]*model.BrokerProfile, int, error)
    Search(ctx context.Context, query, city *string, minRating *float64, p Pagination) ([]*model.BrokerProfile, int, error)
    GetStats(ctx context.Context, brokerUserID string) (*model.BrokerStats, error)
    GetAgencyStats(ctx context.Context, agencyID string) (*model.AgencyStats, error)
}
```

Seven methods. This is the largest profile interface because brokers have
more complex querying needs:

- `ListByAgency` — filter brokers belonging to a specific agency.
- `Search` — multi-field search with optional `query` (name), `city`, and
  `minRating`. All three are `*string` / `*float64` (pointers), meaning they
  are optional. A nil pointer means "don't filter on this field."
- `GetStats` / `GetAgencyStats` — aggregation queries that return summary
  structs, not lists.

**The pointer-as-optional pattern**: In Go, there's no built-in `Optional<T>`
type. The idiomatic way to represent "this parameter might not be provided"
is a pointer. `nil` means "not provided", `&value` means "filter on this."

### 2.8 Interface 5: `CandidateProfileRepository`

```go
type CandidateProfileRepository interface {
    Create(ctx context.Context, profile *model.CandidateProfile) error
    GetByID(ctx context.Context, id string) (*model.CandidateProfile, error)
    Update(ctx context.Context, profile *model.CandidateProfile) error
    Delete(ctx context.Context, id string) error
    List(ctx context.Context, p Pagination) ([]*model.CandidateProfile, int, error)
    ListByBroker(ctx context.Context, brokerUserID string, p Pagination) ([]*model.CandidateProfile, int, error)
    Search(ctx context.Context, filters CandidateSearchFilters, p Pagination) ([]*model.CandidateProfile, int, error)
}
```

Seven methods. This is the most feature-rich interface:

- Full CRUD (`Create`, `GetByID`, `Update`, `Delete`)
- `ListByBroker` — brokers manage many candidate profiles; this returns
  all profiles managed by a specific broker.
- `Search` — takes a dedicated filters struct instead of individual parameters.

The `CandidateSearchFilters` struct shows when to graduate from individual
parameters to a struct:

```go
type CandidateSearchFilters struct {
    Query     *string
    BrokerID  *string
    Gender    *model.Gender
    City      *string
    Religion  *string
    MinAge    *int
    MaxAge    *int
}
```

Seven optional filter fields. Passing these as individual function parameters
would be unwieldy: `Search(ctx, query, brokerID, gender, city, religion,
minAge, maxAge, pagination)` — nine parameters! The struct makes it readable
and extensible (add a field without changing the function signature).

Every field is a pointer, following the pointer-as-optional pattern. A nil
field means "don't filter on this." You can search by just city:

```go
filters := repository.CandidateSearchFilters{
    City: &city,  // only filter by city
}
results, total, err := repo.Search(ctx, filters, pagination)
```

### 2.9 Interface 6: `AgencyRepository`

```go
type AgencyRepository interface {
    Create(ctx context.Context, agency *model.Agency) error
    GetByID(ctx context.Context, id string) (*model.Agency, error)
    Update(ctx context.Context, agency *model.Agency) error
    List(ctx context.Context, p Pagination) ([]*model.Agency, int, error)
    Search(ctx context.Context, query, city *string, minRating *float64, p Pagination) ([]*model.Agency, int, error)
}
```

Five methods. Notice that `Search` has the exact same parameter signature as
`BrokerProfileRepository.Search` — `query, city *string, minRating *float64`.
Both agencies and brokers can be searched by name, city, and rating. This
isn't enforced by a shared interface (Go doesn't have interface inheritance in
that sense), but it's a design consistency.

No `Delete` method. Agencies are never deleted — they can be deactivated
via `Update` (setting `IsActive: false`).

### 2.10 Interface 7: `LinkRequestRepository`

```go
type LinkRequestRepository interface {
    Create(ctx context.Context, req *model.LinkRequest) error
    GetByID(ctx context.Context, id string) (*model.LinkRequest, error)
    Update(ctx context.Context, req *model.LinkRequest) error
    ListReceived(ctx context.Context, userID string, status *model.LinkRequestStatus, reqType *model.LinkRequestType, p Pagination) ([]*model.LinkRequest, int, error)
    ListSent(ctx context.Context, userID string, status *model.LinkRequestStatus, reqType *model.LinkRequestType, p Pagination) ([]*model.LinkRequest, int, error)
    ListConnections(ctx context.Context, userID string) ([]*model.LinkRequest, error)
    FindDuplicate(ctx context.Context, fromID, toID string, reqType model.LinkRequestType) (*model.LinkRequest, error)
    GetConnectedBrokerIDs(ctx context.Context, parentUserID string) ([]string, error)
    GetConnectedParentIDs(ctx context.Context, brokerUserID string) ([]string, error)
    GetLinkedChildIDs(ctx context.Context, parentUserID string) ([]string, error)
    GetLinkedParentID(ctx context.Context, childUserID string) (*string, error)
}
```

Eleven methods — the largest interface. Links are the social graph of the
app: parent↔broker, parent↔agency, child↔parent. This interface handles
the full lifecycle:

- `ListReceived` / `ListSent` — both take optional `status` and `reqType`
  filters. You can ask "show me all pending broker requests I've sent" by
  setting both filters.
- `ListConnections` — returns only accepted links. This is the "my network"
  query.
- `FindDuplicate` — prevents sending the same link request twice. Returns
  `(*model.LinkRequest, error)` where the result can be `nil, nil` (no
  duplicate found — not an error, just empty).
- `GetConnectedBrokerIDs` / `GetConnectedParentIDs` — return just the IDs,
  not full objects. These are graph traversal queries: "who is this parent
  connected to?"
- `GetLinkedChildIDs` / `GetLinkedParentID` — parent-child links. A child
  has at most one parent (`*string` return — nil if no parent linked).

### 2.11 Interface 8: `SharedProfileRepository`

```go
type SharedProfileRepository interface {
    Create(ctx context.Context, sp *model.SharedProfile) error
    GetByID(ctx context.Context, id string) (*model.SharedProfile, error)
    Update(ctx context.Context, sp *model.SharedProfile) error
    ListForUser(ctx context.Context, userID string, response *model.SharedProfileResponse, p Pagination) ([]*model.SharedProfile, int, error)
    ListByBroker(ctx context.Context, brokerUserID string, profileID *string, response *model.SharedProfileResponse, p Pagination) ([]*model.SharedProfile, int, error)
    ListForwarded(ctx context.Context, parentUserID string, p Pagination) ([]*model.SharedProfile, int, error)
    FindDuplicate(ctx context.Context, profileID, sharedWithUserID string) (*model.SharedProfile, error)
}
```

Seven methods. This handles the core workflow: a broker shares a candidate
profile with a parent.

- `ListForUser` — "show me all profiles shared with me." Optional `response`
  filter: show only profiles I haven't responded to yet (`ResponsePending`).
- `ListByBroker` — "show me everything I've shared." Optional `profileID`
  filter: "show me everyone I've shared this specific profile with."
- `ListForwarded` — profiles the parent has forwarded to their child.
- `FindDuplicate` — prevents sharing the same profile twice with the same
  user. Same pattern as `LinkRequestRepository.FindDuplicate`: returns
  `(*model.SharedProfile, error)` where `nil, nil` means "no duplicate."

### 2.12 Interface 9: `MessagingRepository`

```go
type MessagingRepository interface {
    GetOrCreateConversation(ctx context.Context, userID1, userID2 string) (*model.Conversation, error)
    GetConversation(ctx context.Context, id string) (*model.Conversation, error)
    ListConversations(ctx context.Context, userID string, p Pagination) ([]*model.Conversation, int, error)
    UpdateConversation(ctx context.Context, conv *model.Conversation) error
    CreateMessage(ctx context.Context, msg *model.ChatMessage) error
    ListMessages(ctx context.Context, conversationID string, p Pagination) ([]*model.ChatMessage, int, error)
    MarkAsRead(ctx context.Context, conversationID, userID string) error
}
```

Seven methods. The messaging system has two entities: conversations and
messages.

- `GetOrCreateConversation` — this is the key method. When user A messages
  user B for the first time, it creates the conversation. If they've already
  talked, it returns the existing one. This is an **idempotent** operation —
  calling it twice with the same users produces the same result.
- `ListConversations` — "show me my inbox." Returns conversations sorted by
  most recent activity.
- `ListMessages` — messages within a conversation, paginated and sorted
  chronologically.
- `MarkAsRead` — mark all messages from the other person as read.

### 2.13 Interface 10: `SavedProfileRepository`

```go
type SavedProfileRepository interface {
    Save(ctx context.Context, sp *model.SavedProfile) error
    Delete(ctx context.Context, userID, profileID string) error
    IsSaved(ctx context.Context, userID, profileID string) (bool, error)
    ListByUser(ctx context.Context, userID string, p Pagination) ([]*model.SavedProfile, int, error)
}
```

Four methods. Bookmarks/favorites. Simple toggle behavior:

- `Save` — bookmark a profile
- `Delete` — unbookmark (takes user + profile, not a bookmark ID)
- `IsSaved` — quick check: "has this user bookmarked this profile?"
- `ListByUser` — "show me all my bookmarks"

### 2.14 Interface 11: `ViewedProfileRepository`

```go
type ViewedProfileRepository interface {
    RecordView(ctx context.Context, vp *model.ViewedProfile) error
    ListByUser(ctx context.Context, userID string, limit int) ([]*model.ViewedProfile, error)
    ClearHistory(ctx context.Context, userID string) error
}
```

Three methods. An append-only log of profile views. Unlike other interfaces,
`ListByUser` takes a simple `limit int` instead of `Pagination` — there's no
offset-based pagination for view history; you just get the most recent N.

`ClearHistory` is a bulk delete — wipe all viewing history for a user. This
is a privacy feature.

### 2.15 Interface 12: `ActivityRepository`

```go
type ActivityRepository interface {
    Record(ctx context.Context, event *model.ProfileActivity) error
    ListByProfile(ctx context.Context, profileID string, limit int) ([]*model.ProfileActivity, error)
}
```

Two methods. The simplest interface. An activity feed for a candidate profile:
"Broker Ravi shared this profile," "Parent Lakshmi marked interested,"
"Meeting scheduled." It's an event log — you write events and read the most
recent ones.

Like `ViewedProfileRepository`, it uses `limit int` instead of `Pagination`
because activity feeds are typically "show me the last 20 events."

### 2.16 Interface 13: `NoteRepository`

```go
type NoteRepository interface {
    GetParentNote(ctx context.Context, parentUserID, profileID string) (*model.ParentNote, error)
    UpsertParentNote(ctx context.Context, note *model.ParentNote) error
    ListParentNotes(ctx context.Context, parentUserID string) ([]*model.ParentNote, error)
    DeleteParentNote(ctx context.Context, noteID string) error
    GetBrokerNote(ctx context.Context, brokerUserID, profileID, forParentID string) (*model.BrokerNote, error)
    UpsertBrokerNote(ctx context.Context, note *model.BrokerNote) error
}
```

Six methods. This handles two separate note types in a single interface:

- **Parent notes**: A parent's private notes on a candidate profile.
  Indexed by `(parentUserID, profileID)` — one note per parent per profile.
- **Broker notes**: A broker's notes on a candidate for a specific parent.
  Indexed by `(brokerUserID, profileID, forParentID)` — a three-part key.
  The broker might write different notes about the same candidate for
  different parents.

Both use `Upsert` — create if new, update if exists. This is the right
pattern for notes: the user either creates a note or edits an existing one;
the API doesn't need to distinguish.

### 2.17 Interface 14: `MeetingRepository`

```go
type MeetingRepository interface {
    Save(ctx context.Context, meeting *model.Meeting) error
    GetByID(ctx context.Context, id string) (*model.Meeting, error)
    ListForPair(ctx context.Context, parentUserID, profileID, viewerUserID string, p Pagination) ([]*model.Meeting, int, error)
    GetNext(ctx context.Context, parentUserID, profileID, viewerUserID string) (*model.Meeting, error)
    Cancel(ctx context.Context, id string) error
}
```

Five methods. Meetings are between a parent (and their child/candidate) and
a broker-recommended candidate. The interesting design:

- `ListForPair` takes `viewerUserID` — the same meeting list is filtered
  differently depending on who's viewing it. Brokers see meetings marked
  `BrokerVisible`, parents see meetings marked `ParentPartyVisible`. A
  meeting can be visible to one party but not the other.
- `GetNext` — "what's the next upcoming meeting for this parent+profile
  pair?" Filters by `MeetingScheduled` status and future dates.
- `Cancel` — a status change, not a delete. Cancelled meetings remain in
  the history.

---

## 3. Implementing Interfaces — The In-Memory Layer

Every interface from Section 2 has a concrete implementation in the
`internal/inmem/` package. These implementations use Go maps as the storage
engine, protected by mutexes for thread safety.

### 3.1 The Anatomy of an In-Memory Repository

Every in-memory repo follows the same structural pattern:

```go
type SomeRepo struct {
    mu   sync.RWMutex          // 1. Mutex for thread safety
    data map[string]*model.X   // 2. Map as the "database table"
}

func NewSomeRepo() *SomeRepo {
    return &SomeRepo{
        data: make(map[string]*model.X),  // 3. Initialized with make()
    }
}
```

Three invariants:

1. **`sync.RWMutex`** — a read-write mutex. Multiple goroutines can read
   simultaneously (`RLock`), but only one can write (`Lock`). This is critical
   because Go's HTTP server handles each request in its own goroutine.

2. **Maps as storage** — Go maps are hash maps. O(1) lookup by key. The key
   is always a string (usually an ID).

3. **`make()` initialization** — Go maps are reference types that default to
   `nil`. A nil map can be read from (returns zero values) but PANICS on
   write. `make(map[string]*model.X)` creates an initialized, empty map.

### 3.2 The Copy-on-Read Pattern

This pattern appears in EVERY read method:

```go
func (r *UserRepo) GetByID(_ context.Context, id string) (*model.AppUser, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    u, ok := r.byID[id]
    if !ok {
        return nil, model.NotFoundError("User", id)
    }
    cp := *u       // Copy the struct
    return &cp, nil // Return a pointer to the COPY
}
```

The critical lines are:

```go
cp := *u       // Dereference u to get the struct value, assign to cp
return &cp, nil // Take the address of the copy, return it
```

**Why copy?** Without the copy, callers get a pointer directly into the
repo's internal map. If they modify the struct, they modify the repo's data
without going through the mutex, and without the repo knowing. This would:

1. Break thread safety (modifications without holding the lock)
2. Bypass validation logic (the `Update` method might enforce constraints)
3. Make bugs nearly impossible to reproduce (race conditions)

The copy ensures the caller gets their own independent copy. They can modify
it freely; if they want to persist changes, they must call `Update`.

This pattern also appears on writes:

```go
func (r *UserRepo) Create(_ context.Context, user *model.AppUser) error {
    r.mu.Lock()
    defer r.mu.Unlock()
    // ...validation...
    cp := *user           // Copy the incoming struct
    r.byID[user.UID] = &cp  // Store the COPY
    return nil
}
```

We copy on write too. If we stored the caller's pointer directly, the caller
could modify the struct after Create returns, corrupting the stored data.

**Analogy for Dart developers**: This is like doing
`Map[id] = Model.fromJson(model.toJson())` to deep-clone before storing.
Go's `cp := *value` is a shallow copy of all struct fields.

### 3.3 `UserRepo` — Full Dissection

```go
type UserRepo struct {
    mu      sync.RWMutex
    byID    map[string]*model.AppUser  // primary index: UID → user
    byPhone map[string]string           // secondary index: phone → UID
}
```

Two maps. `byID` is the primary storage. `byPhone` is a secondary index
that maps phone numbers to user IDs. This secondary index enables O(1)
phone-number lookups (needed for login).

**Constructor:**

```go
func NewUserRepo() *UserRepo {
    return &UserRepo{
        byID:    make(map[string]*model.AppUser),
        byPhone: make(map[string]string),
    }
}
```

Both maps are initialized with `make()`. The constructor returns `*UserRepo`
(a concrete type), not `repository.UserRepository` (the interface). This
follows the "return structs" proverb — the caller can assign it to an
interface variable when they need to.

**Create — dual uniqueness validation:**

```go
func (r *UserRepo) Create(_ context.Context, user *model.AppUser) error {
    r.mu.Lock()
    defer r.mu.Unlock()
    if _, ok := r.byID[user.UID]; ok {
        return model.ConflictError("user already exists")
    }
    if uid, ok := r.byPhone[user.PhoneNumber]; ok && uid != user.UID {
        return model.ConflictError("phone number already registered")
    }
    cp := *user
    r.byID[user.UID] = &cp
    r.byPhone[user.PhoneNumber] = user.UID
    return nil
}
```

Two uniqueness checks:
1. Is the UID already taken? (Shouldn't be if we generate UUIDs, but defense
   in depth.)
2. Is the phone number already registered to a DIFFERENT user? (The `&& uid
   != user.UID` check allows re-registration of the same user.)

Both maps are updated atomically (within the same Lock/Unlock).

**GetByPhone — secondary index lookup:**

```go
func (r *UserRepo) GetByPhone(_ context.Context, phone string) (*model.AppUser, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    uid, ok := r.byPhone[phone]
    if !ok {
        return nil, model.NotFoundError("User", phone)
    }
    cp := *r.byID[uid]  // Look up by UID, then copy
    return &cp, nil
}
```

Two-step lookup: phone → UID → user. The secondary index avoids a full
table scan (iterating all users to find one by phone).

**List — materializing a map into a paginated slice:**

```go
func (r *UserRepo) List(_ context.Context, p repository.Pagination) ([]*model.AppUser, int, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    all := make([]*model.AppUser, 0, len(r.byID))
    for _, u := range r.byID {
        cp := *u
        all = append(all, &cp)
    }
    page, total := paginate(all, p)
    return page, total, nil
}
```

Three steps:
1. Pre-allocate a slice with `make([]*model.AppUser, 0, len(r.byID))`.
   The `0` is the length (empty), `len(r.byID)` is the capacity (we know
   how many items we'll have). This avoids reallocations during append.
2. Copy every user (copy-on-read pattern).
3. Run the generic `paginate` function (covered in Section 5).

**Note**: Map iteration order in Go is intentionally randomized. The list
order is non-deterministic. In production (Postgres), you'd add `ORDER BY`.

### 3.4 `AuthRepo` — OTP Sessions with Expiry

```go
type otpSession struct {
    phone     string
    role      model.UserRole
    code      string
    expiresAt time.Time
    used      bool
}

type AuthRepo struct {
    mu       sync.RWMutex
    sessions map[string]*otpSession
    isDev    bool
}
```

The `otpSession` struct is a private type (lowercase). It's an implementation
detail that doesn't escape the package.

**Constructor with configuration:**

```go
func NewAuthRepo(isDev bool) *AuthRepo {
    return &AuthRepo{
        sessions: make(map[string]*otpSession),
        isDev:    isDev,
    }
}
```

`isDev` is a runtime configuration flag. In dev mode, OTP is always `123456`.

**SendOTP — session creation:**

```go
func (r *AuthRepo) SendOTP(_ context.Context, phone string, role model.UserRole) (string, error) {
    code := "123456"
    if !r.isDev {
        code = randomOTP()
    }
    sessionID := uuid.NewString()
    r.mu.Lock()
    defer r.mu.Unlock()
    r.sessions[sessionID] = &otpSession{
        phone:     phone,
        role:      role,
        code:      code,
        expiresAt: time.Now().Add(5 * time.Minute),
    }
    return sessionID, nil
}
```

- Dev mode: hardcoded `123456` for easy testing
- Production: `randomOTP()` generates a cryptographically random 6-digit code
  using `crypto/rand`
- Session expires in 5 minutes
- Returns the session ID (a UUID) to the caller

**VerifyOTP — one-time-use with triple validation:**

```go
func (r *AuthRepo) VerifyOTP(_ context.Context, sessionID, phone, code string) (bool, error) {
    r.mu.Lock()
    defer r.mu.Unlock()
    s, ok := r.sessions[sessionID]
    if !ok {
        return false, model.ErrSessionNotFound
    }
    if s.used {
        return false, model.ErrInvalidOTP
    }
    if time.Now().After(s.expiresAt) {
        return false, model.ErrInvalidOTP
    }
    if s.phone != phone || s.code != code {
        return false, nil
    }
    s.used = true
    return true, nil
}
```

Four checks in order:
1. Session exists? (ErrSessionNotFound)
2. Already used? (ErrInvalidOTP — prevents replay attacks)
3. Expired? (ErrInvalidOTP — 5-minute window)
4. Phone + code match? If not, return `false, nil` — wrong code isn't an
   error, it's a failed verification.

Note: `s.used = true` modifies the session in place. This is safe because
we hold the write lock. After this, the same session can never be used again.

**Random OTP generation:**

```go
func randomOTP() string {
    b := make([]byte, 3)
    _, _ = rand.Read(b)
    n := int(b[0])<<16 | int(b[1])<<8 | int(b[2])
    return fmt.Sprintf("%06d", n%1000000)
}
```

Uses `crypto/rand` (not `math/rand`) for security. Reads 3 random bytes
(24 bits of entropy), combines them into a number, mods by 1000000 to get
a 6-digit number, and zero-pads with `%06d`.

### 3.5 `ParentProfileRepo` — One Profile Per User

```go
type ParentProfileRepo struct {
    mu   sync.RWMutex
    data map[string]*model.ParentProfile  // keyed by UserID
}
```

The simplest profile repo. Keyed by `UserID` because there's a 1:1
relationship. `Save` is an upsert:

```go
func (r *ParentProfileRepo) Save(_ context.Context, profile *model.ParentProfile) error {
    r.mu.Lock()
    defer r.mu.Unlock()
    cp := *profile
    r.data[profile.UserID] = &cp  // overwrites if exists
    return nil
}
```

No existence check, no conflict error. If a profile with this UserID already
exists, it's replaced. This is intentional — a parent can update their profile
at any time.

### 3.6 `BrokerProfileRepo` — Multi-Field Search

Same 1:1 keying as `ParentProfileRepo`, but with search capabilities:

```go
func (r *BrokerProfileRepo) ListByAgency(_ context.Context, agencyID string, p repository.Pagination) ([]*model.BrokerProfile, int, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    all := make([]*model.BrokerProfile, 0)
    for _, v := range r.data {
        if v.AgencyID != nil && *v.AgencyID == agencyID {
            cp := *v
            all = append(all, &cp)
        }
    }
    page, total := paginate(all, p)
    return page, total, nil
}
```

`AgencyID` is a `*string` (optional — independent brokers have no agency).
The check `v.AgencyID != nil && *v.AgencyID == agencyID` safely handles nil
pointers. You must check for nil BEFORE dereferencing.

**Search with the filter-chain pattern:**

```go
func (r *BrokerProfileRepo) Search(_ context.Context, query, city *string, minRating *float64, p repository.Pagination) ([]*model.BrokerProfile, int, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    all := make([]*model.BrokerProfile, 0)
    for _, v := range r.data {
        if query != nil && *query != "" && !containsFold(v.Name, *query) {
            continue
        }
        if city != nil && *city != "" {
            matched := false
            for _, a := range v.AreasServed {
                if containsFold(a, *city) {
                    matched = true
                    break
                }
            }
            if !matched {
                continue
            }
        }
        if minRating != nil && v.Rating < *minRating {
            continue
        }
        cp := *v
        all = append(all, &cp)
    }
    page, total := paginate(all, p)
    return page, total, nil
}
```

The filter-chain pattern: iterate all items, apply each filter as a
`continue` (skip this item if it doesn't match). Items that survive all
filters are collected. This is O(n) where n is total brokers — fine for
in-memory, but a Postgres implementation would use indexed WHERE clauses.

**City matching** is interesting: it checks `AreasServed` (a slice of
strings), not a single city field. A broker who serves `["Hyderabad",
"Bangalore"]` should match a search for "Hyderabad". The inner loop handles
this.

**`GetStats` and `GetAgencyStats`** return empty stubs:

```go
func (r *BrokerProfileRepo) GetStats(_ context.Context, _ string) (*model.BrokerStats, error) {
    return &model.BrokerStats{}, nil
}
```

These would be computed from actual data in a real database (COUNT queries,
JOINs). In the in-memory implementation, they return zero values. The `_`
parameter name signals "this parameter is deliberately unused."

### 3.7 `CandidateProfileRepo` — Full CRUD with Search

```go
type CandidateProfileRepo struct {
    mu   sync.RWMutex
    data map[string]*model.CandidateProfile  // keyed by profile ID
}
```

Unlike parent/broker profiles (keyed by UserID), candidate profiles are
keyed by their own ID. One broker can create many candidate profiles.

**Delete:**

```go
func (r *CandidateProfileRepo) Delete(_ context.Context, id string) error {
    r.mu.Lock()
    defer r.mu.Unlock()
    if _, ok := r.data[id]; !ok {
        return model.NotFoundError("CandidateProfile", id)
    }
    delete(r.data, id)
    return nil
}
```

Go's built-in `delete(map, key)` function removes a key from a map. If the
key doesn't exist, `delete` is a no-op (no panic). But we check existence
first to return a proper error.

**ListByBroker — the `containsStr` helper:**

```go
func (r *CandidateProfileRepo) ListByBroker(_ context.Context, brokerUserID string, p repository.Pagination) ([]*model.CandidateProfile, int, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    all := make([]*model.CandidateProfile, 0)
    for _, v := range r.data {
        if containsStr(v.BrokerIDs, brokerUserID) || v.CreatedByUserID == brokerUserID {
            cp := *v
            all = append(all, &cp)
        }
    }
    page, total := paginate(all, p)
    return page, total, nil
}
```

A profile belongs to a broker if:
- The broker is in the profile's `BrokerIDs` slice, OR
- The broker created the profile

`containsStr` is a helper (from `helpers.go`):

```go
func containsStr(list []string, val string) bool {
    for _, s := range list {
        if s == val {
            return true
        }
    }
    return false
}
```

Go has no built-in `slice.contains()` (unlike Dart's `list.contains()`).
You write a loop. (Go 1.21 added `slices.Contains`, but this project uses
a custom helper.)

**Search with the filters struct:**

```go
func (r *CandidateProfileRepo) Search(_ context.Context, filters repository.CandidateSearchFilters, p repository.Pagination) ([]*model.CandidateProfile, int, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    all := make([]*model.CandidateProfile, 0)
    for _, v := range r.data {
        if filters.Query != nil && *filters.Query != "" && !containsFold(v.Name, *filters.Query) {
            continue
        }
        if filters.BrokerID != nil && !containsStr(v.BrokerIDs, *filters.BrokerID) && v.CreatedByUserID != *filters.BrokerID {
            continue
        }
        if filters.Gender != nil && v.Gender != *filters.Gender {
            continue
        }
        if filters.City != nil && *filters.City != "" && !containsFold(v.City, *filters.City) {
            continue
        }
        if filters.Religion != nil && *filters.Religion != "" && !containsFold(v.Religion, *filters.Religion) {
            continue
        }
        if filters.MinAge != nil && v.Age < *filters.MinAge {
            continue
        }
        if filters.MaxAge != nil && v.Age > *filters.MaxAge {
            continue
        }
        cp := *v
        all = append(all, &cp)
    }
    page, total := paginate(all, p)
    return page, total, nil
}
```

Seven filter checks, each guarded by a nil check. This is the standard
in-memory search pattern. Every nil filter is a no-op (passes all items).
Non-nil filters act as AND conditions — an item must pass ALL non-nil
filters to be included.

`containsFold` does case-insensitive substring matching:

```go
func containsFold(haystack, needle string) bool {
    return strings.Contains(strings.ToLower(haystack), strings.ToLower(needle))
}
```

### 3.8 `AgencyRepo` — Search with Name/City/Rating

```go
type AgencyRepo struct {
    mu   sync.RWMutex
    data map[string]*model.Agency
}
```

Structurally identical to `BrokerProfileRepo`'s search but on `Agency`
fields. The search method:

```go
func (r *AgencyRepo) Search(_ context.Context, query, city *string, minRating *float64, p repository.Pagination) ([]*model.Agency, int, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    all := make([]*model.Agency, 0)
    for _, v := range r.data {
        if query != nil && *query != "" && !containsFold(v.Name, *query) {
            continue
        }
        if city != nil && *city != "" && !containsFold(v.City, *city) {
            continue
        }
        if minRating != nil && v.Rating < *minRating {
            continue
        }
        cp := *v
        all = append(all, &cp)
    }
    page, total := paginate(all, p)
    return page, total, nil
}
```

Notice the difference from broker search: agencies have a single `City`
field, so the city filter is a simple `containsFold(v.City, *city)`. Brokers
have `AreasServed []string`, requiring the inner loop.

### 3.9 `LinkRequestRepo` — Bidirectional Filtering

```go
type LinkRequestRepo struct {
    mu   sync.RWMutex
    data map[string]*model.LinkRequest
}
```

The most complex repository in terms of query patterns. The key insight is
the private `filter` helper:

```go
func (r *LinkRequestRepo) filter(userID string, received bool, status *model.LinkRequestStatus, reqType *model.LinkRequestType) []*model.LinkRequest {
    all := make([]*model.LinkRequest, 0)
    for _, v := range r.data {
        if received {
            if v.ToUserID != userID {
                continue
            }
        } else {
            if v.FromUserID != userID {
                continue
            }
        }
        if status != nil && v.Status != *status {
            continue
        }
        if reqType != nil && v.Type != *reqType {
            continue
        }
        cp := *v
        all = append(all, &cp)
    }
    return all
}
```

This private method is shared between `ListReceived` and `ListSent`. The
`received` boolean controls the direction:
- `received = true`: filter by `ToUserID` (I received this request)
- `received = false`: filter by `FromUserID` (I sent this request)

Both public methods delegate to `filter`:

```go
func (r *LinkRequestRepo) ListReceived(_ context.Context, userID string, status *model.LinkRequestStatus, reqType *model.LinkRequestType, p repository.Pagination) ([]*model.LinkRequest, int, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    all := r.filter(userID, true, status, reqType)
    page, total := paginate(all, p)
    return page, total, nil
}

func (r *LinkRequestRepo) ListSent(_ context.Context, userID string, status *model.LinkRequestStatus, reqType *model.LinkRequestType, p repository.Pagination) ([]*model.LinkRequest, int, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    all := r.filter(userID, false, status, reqType)
    page, total := paginate(all, p)
    return page, total, nil
}
```

**ListConnections — accepted links in both directions:**

```go
func (r *LinkRequestRepo) ListConnections(_ context.Context, userID string) ([]*model.LinkRequest, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    all := make([]*model.LinkRequest, 0)
    for _, v := range r.data {
        if v.Status != model.LinkStatusAccepted {
            continue
        }
        if v.FromUserID == userID || v.ToUserID == userID {
            cp := *v
            all = append(all, &cp)
        }
    }
    return all, nil
}
```

This checks BOTH directions (`FromUserID == userID || ToUserID == userID`).
If I sent a request and it was accepted, that's my connection. If I received
a request and accepted it, that's also my connection.

**FindDuplicate — preventing double-sends:**

```go
func (r *LinkRequestRepo) FindDuplicate(_ context.Context, fromID, toID string, reqType model.LinkRequestType) (*model.LinkRequest, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    for _, v := range r.data {
        if v.FromUserID == fromID && v.ToUserID == toID && v.Type == reqType && v.Status == model.LinkStatusPending {
            cp := *v
            return &cp, nil
        }
    }
    return nil, nil  // No duplicate found — not an error
}
```

`return nil, nil` is a valid Go pattern meaning "no result, no error."
The handler checks: if result is non-nil, a duplicate pending request
exists; reject the new one.

**Graph traversal queries:**

```go
func (r *LinkRequestRepo) GetConnectedBrokerIDs(_ context.Context, parentUserID string) ([]string, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    ids := make([]string, 0)
    for _, v := range r.data {
        if v.Status == model.LinkStatusAccepted && v.Type == model.LinkParentToBroker && v.FromUserID == parentUserID {
            ids = append(ids, v.ToUserID)
        }
    }
    return ids, nil
}
```

This finds all brokers connected to a parent by filtering on three conditions:
status is accepted, type is parent-to-broker, and the parent is the sender.
Returns just IDs, not full objects — the caller can look up full profiles if
needed.

`GetConnectedParentIDs` mirrors this in reverse (brokers are the receiver).
`GetLinkedChildIDs` and `GetLinkedParentID` do the same for child-parent
links.

**`GetLinkedParentID` — returning an optional single result:**

```go
func (r *LinkRequestRepo) GetLinkedParentID(_ context.Context, childUserID string) (*string, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    for _, v := range r.data {
        if v.Status == model.LinkStatusAccepted && v.Type == model.LinkChildToParent && v.FromUserID == childUserID {
            id := v.ToUserID
            return &id, nil
        }
    }
    return nil, nil  // No parent linked — valid state, not an error
}
```

Returns `*string` — a pointer to a string. `nil` means "no parent linked."
This is distinct from an error; a child without a linked parent is a valid
state. The `id := v.ToUserID` + `return &id` pattern creates a local copy
before returning a pointer to it.

### 3.10 `SharedProfileRepo` — Multi-Field Filtering

```go
type SharedProfileRepo struct {
    mu   sync.RWMutex
    data map[string]*model.SharedProfile
}
```

**ListForUser — incoming shares with optional response filter:**

```go
func (r *SharedProfileRepo) ListForUser(_ context.Context, userID string, response *model.SharedProfileResponse, p repository.Pagination) ([]*model.SharedProfile, int, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    all := make([]*model.SharedProfile, 0)
    for _, v := range r.data {
        if v.SharedWithUserID != userID {
            continue
        }
        if response != nil && v.ParentResponse != *response {
            continue
        }
        cp := *v
        all = append(all, &cp)
    }
    page, total := paginate(all, p)
    return page, total, nil
}
```

**ListByBroker — outgoing shares with optional profile and response filters:**

```go
func (r *SharedProfileRepo) ListByBroker(_ context.Context, brokerUserID string, profileID *string, response *model.SharedProfileResponse, p repository.Pagination) ([]*model.SharedProfile, int, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    all := make([]*model.SharedProfile, 0)
    for _, v := range r.data {
        if v.SharedByUserID != brokerUserID {
            continue
        }
        if profileID != nil && v.ProfileID != *profileID {
            continue
        }
        if response != nil && v.ParentResponse != *response {
            continue
        }
        cp := *v
        all = append(all, &cp)
    }
    page, total := paginate(all, p)
    return page, total, nil
}
```

Two optional filters composed with the filter-chain pattern. The broker can
ask: "show me all shares of profile X that parents haven't responded to yet."

**ListForwarded — compound boolean filter:**

```go
func (r *SharedProfileRepo) ListForwarded(_ context.Context, parentUserID string, p repository.Pagination) ([]*model.SharedProfile, int, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    all := make([]*model.SharedProfile, 0)
    for _, v := range r.data {
        if v.SharedWithUserID == parentUserID && v.ForwardedToChild {
            cp := *v
            all = append(all, &cp)
        }
    }
    page, total := paginate(all, p)
    return page, total, nil
}
```

Two conditions ANDed: shared with this parent AND forwarded to child.

**FindDuplicate:**

```go
func (r *SharedProfileRepo) FindDuplicate(_ context.Context, profileID, sharedWithUserID string) (*model.SharedProfile, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    for _, v := range r.data {
        if v.ProfileID == profileID && v.SharedWithUserID == sharedWithUserID {
            cp := *v
            return &cp, nil
        }
    }
    return nil, nil  // No duplicate found
}
```

Same `nil, nil` pattern as `LinkRequestRepo.FindDuplicate`.

### 3.11 `MessagingRepo` — Triple Index

```go
type MessagingRepo struct {
    mu            sync.RWMutex
    conversations map[string]*model.Conversation     // convID → conversation
    messages      map[string][]*model.ChatMessage     // convID → messages
    byUser        map[string][]string                  // userID → convIDs
}
```

Three maps, each serving a different access pattern:

1. `conversations` — primary storage: look up a conversation by ID
2. `messages` — messages grouped by conversation (like a foreign key)
3. `byUser` — which conversations does this user participate in? (like a
   join index)

**`findBetween` — looking up a conversation by participants:**

```go
func (r *MessagingRepo) findBetween(userID1, userID2 string) *model.Conversation {
    for _, cid := range r.byUser[userID1] {
        c := r.conversations[cid]
        if c != nil && len(c.ParticipantIDs) == 2 {
            if (c.ParticipantIDs[0] == userID1 && c.ParticipantIDs[1] == userID2) ||
                (c.ParticipantIDs[0] == userID2 && c.ParticipantIDs[1] == userID1) {
                cp := *c
                return &cp
            }
        }
    }
    return nil
}
```

Private method (lowercase). Uses the `byUser` index to narrow the search
to only conversations that user1 is in, then checks if user2 is also a
participant. Handles both orderings of participants.

**`GetOrCreateConversation` — the idempotent pattern:**

```go
func (r *MessagingRepo) GetOrCreateConversation(_ context.Context, userID1, userID2 string) (*model.Conversation, error) {
    r.mu.Lock()
    defer r.mu.Unlock()
    if existing := r.findBetween(userID1, userID2); existing != nil {
        return existing, nil
    }
    id := uuid.NewString()
    c := &model.Conversation{
        ID:             id,
        ParticipantIDs: []string{userID1, userID2},
        UnreadCount:    0,
    }
    r.conversations[id] = c
    r.byUser[userID1] = append(r.byUser[userID1], id)
    r.byUser[userID2] = append(r.byUser[userID2], id)
    cp := *c
    return &cp, nil
}
```

Check first, create if not found. Uses a full Lock (not RLock) because it
might write. Updates the `byUser` index for BOTH users.

**`CreateMessage` — updating the conversation preview:**

```go
func (r *MessagingRepo) CreateMessage(_ context.Context, msg *model.ChatMessage) error {
    r.mu.Lock()
    defer r.mu.Unlock()
    cp := *msg
    r.messages[msg.ConversationID] = append(r.messages[msg.ConversationID], &cp)
    if c := r.conversations[msg.ConversationID]; c != nil {
        preview := msg.Content
        if len(preview) > 100 {
            preview = preview[:100]
        }
        now := msg.Timestamp
        c.LastMessagePreview = &preview
        c.LastMessageAt = &now
    }
    return nil
}
```

Two things happen atomically:
1. Message is appended to the conversation's message list
2. The conversation's preview is updated (truncated to 100 chars)

**`ListConversations` — sorted by most recent:**

```go
func (r *MessagingRepo) ListConversations(_ context.Context, userID string, p repository.Pagination) ([]*model.Conversation, int, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    all := make([]*model.Conversation, 0)
    for _, cid := range r.byUser[userID] {
        if c := r.conversations[cid]; c != nil {
            cp := *c
            all = append(all, &cp)
        }
    }
    sort.Slice(all, func(i, j int) bool {
        ti, tj := all[i].LastMessageAt, all[j].LastMessageAt
        if ti == nil {
            return false
        }
        if tj == nil {
            return true
        }
        return ti.After(*tj)
    })
    page, total := paginate(all, p)
    return page, total, nil
}
```

The sort handles nil `LastMessageAt` (conversations with no messages yet).
Nil timestamps sort to the bottom.

**`MarkAsRead` — bulk update:**

```go
func (r *MessagingRepo) MarkAsRead(_ context.Context, conversationID, userID string) error {
    r.mu.Lock()
    defer r.mu.Unlock()
    for _, m := range r.messages[conversationID] {
        if m.SenderID != userID {
            m.IsRead = true
        }
    }
    if c := r.conversations[conversationID]; c != nil {
        c.UnreadCount = 0
    }
    return nil
}
```

Marks all messages FROM THE OTHER PERSON as read (`SenderID != userID`).
You don't mark your own messages as read — they're already read by you.
Also resets the conversation's unread count.

### 3.12 `SavedProfileRepo` — Composite Key Pattern

```go
type SavedProfileRepo struct {
    mu   sync.RWMutex
    data map[string]*model.SavedProfile
}

func savedKey(userID, profileID string) string { return userID + ":" + profileID }
```

The `savedKey` function creates a composite map key by concatenating two IDs
with a colon separator. This is a common Go pattern when you need a compound
key for a map. The key `"user123:profile456"` uniquely identifies a bookmark.

**IsSaved — existence check:**

```go
func (r *SavedProfileRepo) IsSaved(_ context.Context, userID, profileID string) (bool, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    _, ok := r.data[savedKey(userID, profileID)]
    return ok, nil
}
```

O(1) lookup using the composite key. No iteration needed.

**Delete — by composite key, not by ID:**

```go
func (r *SavedProfileRepo) Delete(_ context.Context, userID, profileID string) error {
    r.mu.Lock()
    defer r.mu.Unlock()
    delete(r.data, savedKey(userID, profileID))
    return nil
}
```

No existence check — `delete` on a missing key is a no-op in Go. The API
is idempotent: calling "unsave" on a profile you haven't saved is fine.

### 3.13 `ViewedProfileRepo` — Per-User Append List

```go
type ViewedProfileRepo struct {
    mu      sync.RWMutex
    byUser  map[string][]*model.ViewedProfile  // userID → list of views
}
```

Instead of a flat map of views, this uses a **map of slices**. Each user
has their own list of viewed profiles. This makes "list my views" O(1) for
the lookup plus O(k) for sorting, where k is the number of views for that
user (not all users combined).

**RecordView — append:**

```go
func (r *ViewedProfileRepo) RecordView(_ context.Context, vp *model.ViewedProfile) error {
    r.mu.Lock()
    defer r.mu.Unlock()
    cp := *vp
    r.byUser[vp.UserID] = append(r.byUser[vp.UserID], &cp)
    return nil
}
```

Go maps return the zero value for missing keys. `r.byUser[vp.UserID]` for a
new user returns `nil` (the zero value for a slice). `append(nil, &cp)` works
fine in Go — it creates a new slice. No special "first write" handling needed.

**ListByUser — sorted by recency, capped:**

```go
func (r *ViewedProfileRepo) ListByUser(_ context.Context, userID string, limit int) ([]*model.ViewedProfile, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    src := r.byUser[userID]
    all := make([]*model.ViewedProfile, len(src))
    copy(all, src)
    sort.Slice(all, func(i, j int) bool { return all[i].ViewedAt.After(all[j].ViewedAt) })
    if limit > 0 && len(all) > limit {
        all = all[:limit]
    }
    return all, nil
}
```

Notice: it uses `copy(all, src)` instead of the `cp := *v` pattern. This
copies the slice of pointers, not the structs themselves. A subtle difference:
the caller gets their own slice, but the pointers point to the same structs.
This is acceptable here because ViewedProfile records are append-only (never
modified after creation).

**ClearHistory — bulk delete:**

```go
func (r *ViewedProfileRepo) ClearHistory(_ context.Context, userID string) error {
    r.mu.Lock()
    defer r.mu.Unlock()
    delete(r.byUser, userID)
    return nil
}
```

Removes the entire slice for this user. Clean and simple.

### 3.14 `ActivityRepo` — Per-Profile Append, Capped Retrieval

```go
type ActivityRepo struct {
    mu   sync.RWMutex
    data map[string][]*model.ProfileActivity  // profileID → events
}
```

Nearly identical to `ViewedProfileRepo` but keyed by `profileID` instead of
`userID`. Activities are about a profile, not about a user.

```go
func (r *ActivityRepo) ListByProfile(_ context.Context, profileID string, limit int) ([]*model.ProfileActivity, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    src := r.data[profileID]
    all := make([]*model.ProfileActivity, len(src))
    copy(all, src)
    sort.Slice(all, func(i, j int) bool { return all[i].At.After(all[j].At) })
    if limit > 0 && len(all) > limit {
        all = all[:limit]
    }
    return all, nil
}
```

Sorted by `At` (timestamp) in descending order (most recent first), then
truncated to `limit`.

### 3.15 `NoteRepo` — Dual Composite Keys

```go
type NoteRepo struct {
    mu          sync.RWMutex
    parentNotes map[string]*model.ParentNote   // composite key: parentUserID:profileID
    brokerNotes map[string]*model.BrokerNote   // composite key: brokerUserID:profileID:forParentID
}
```

Two separate maps for two note types. Two composite key functions:

```go
func parentNoteKey(parentUserID, profileID string) string {
    return parentUserID + ":" + profileID
}

func brokerNoteKey(brokerUserID, profileID, forParentID string) string {
    return brokerUserID + ":" + profileID + ":" + forParentID
}
```

Parent notes have a 2-part key (one note per parent per profile). Broker
notes have a 3-part key (one note per broker per profile per parent) — the
broker might write different notes about the same candidate for different
parents.

**UpsertParentNote — create or replace:**

```go
func (r *NoteRepo) UpsertParentNote(_ context.Context, note *model.ParentNote) error {
    r.mu.Lock()
    defer r.mu.Unlock()
    cp := *note
    r.parentNotes[parentNoteKey(note.ParentUserID, note.CandidateProfileID)] = &cp
    return nil
}
```

Simple map assignment — if the key exists, the value is overwritten.
This is the upsert semantic.

**DeleteParentNote — delete by note ID, not by composite key:**

```go
func (r *NoteRepo) DeleteParentNote(_ context.Context, noteID string) error {
    r.mu.Lock()
    defer r.mu.Unlock()
    for k, n := range r.parentNotes {
        if n.ID == noteID {
            delete(r.parentNotes, k)
            return nil
        }
    }
    return model.NotFoundError("ParentNote", noteID)
}
```

This is an O(n) scan because we're deleting by the note's own ID, not by
the composite key. The map is keyed by `parentUserID:profileID`, but the
delete API takes `noteID`. A secondary index by noteID would make this O(1),
but that's an optimization for the Postgres layer.

**ListParentNotes — sorted by UpdatedAt:**

```go
func (r *NoteRepo) ListParentNotes(_ context.Context, parentUserID string) ([]*model.ParentNote, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    var result []*model.ParentNote
    for _, n := range r.parentNotes {
        if n.ParentUserID == parentUserID {
            cp := *n
            result = append(result, &cp)
        }
    }
    sort.Slice(result, func(i, j int) bool { return result[i].UpdatedAt.After(result[j].UpdatedAt) })
    return result, nil
}
```

Notice: `var result []*model.ParentNote` — declares a nil slice without
`make`. This is fine because `append(nil, ...)` works in Go. Using `var`
instead of `make` is idiomatic when you don't know the capacity in advance
and the list might be empty.

### 3.16 `MeetingRepo` — Visibility Filtering and Next-Meeting Query

```go
type MeetingRepo struct {
    mu   sync.RWMutex
    data map[string]*model.Meeting
}
```

**ListForPair — visibility-aware listing:**

```go
func (r *MeetingRepo) ListForPair(_ context.Context, parentUserID, profileID, viewerUserID string, p repository.Pagination) ([]*model.Meeting, int, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    all := make([]*model.Meeting, 0)
    for _, m := range r.data {
        if m.ParentUserID != parentUserID || m.CandidateProfileID != profileID {
            continue
        }
        if viewerUserID == m.BrokerUserID && !m.BrokerVisible {
            continue
        }
        if viewerUserID == m.ParentUserID && !m.ParentPartyVisible {
            continue
        }
        cp := *m
        all = append(all, &cp)
    }
    sort.Slice(all, func(i, j int) bool { return all[i].When.Before(all[j].When) })
    page, total := paginate(all, p)
    return page, total, nil
}
```

First, filter by the parent+profile pair. Then apply visibility rules:
- If the viewer is the broker, skip meetings not visible to brokers
- If the viewer is the parent, skip meetings not visible to the parent party

Sorted chronologically (earliest first) so upcoming meetings appear at top.

**GetNext — finding the next upcoming meeting:**

```go
func (r *MeetingRepo) GetNext(_ context.Context, parentUserID, profileID, viewerUserID string) (*model.Meeting, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    var next *model.Meeting
    now := time.Now()
    for _, m := range r.data {
        if m.ParentUserID != parentUserID || m.CandidateProfileID != profileID {
            continue
        }
        if m.Status != model.MeetingScheduled || m.When.Before(now) {
            continue
        }
        if viewerUserID == m.BrokerUserID && !m.BrokerVisible {
            continue
        }
        if viewerUserID == m.ParentUserID && !m.ParentPartyVisible {
            continue
        }
        if next == nil || m.When.Before(next.When) {
            cp := *m
            next = &cp
        }
    }
    if next == nil {
        return nil, model.NotFoundError("Meeting", "next")
    }
    return next, nil
}
```

Finds the meeting closest to now that:
1. Matches the parent+profile pair
2. Is still scheduled (not completed or cancelled)
3. Is in the future (`!m.When.Before(now)`)
4. Is visible to the viewer

The `next == nil || m.When.Before(next.When)` check keeps track of the
earliest qualifying meeting.

**Cancel — status change, not delete:**

```go
func (r *MeetingRepo) Cancel(_ context.Context, id string) error {
    r.mu.Lock()
    defer r.mu.Unlock()
    m, ok := r.data[id]
    if !ok {
        return model.NotFoundError("Meeting", id)
    }
    m.Status = model.MeetingCancelled
    return nil
}
```

Modifies the meeting in place (within the lock). The meeting remains in the
map with `MeetingCancelled` status. This is a soft delete — the meeting
history is preserved.

---

## 4. Dependency Injection Without a Framework

Go doesn't have Spring, Dagger, or Riverpod. It doesn't need them. DI in Go
is just... structs with interface fields.

### 4.1 The Container Struct

```go
// internal/service/container.go
package service

import (
    "time"
    "github.com/anuyatra/backend/internal/repository"
)

const (
    DefaultAccessExpiry  = 15 * time.Minute
    DefaultRefreshExpiry = 7 * 24 * time.Hour
)

type Container struct {
    Users             repository.UserRepository
    Auth              repository.AuthRepository
    ParentProfiles    repository.ParentProfileRepository
    BrokerProfiles    repository.BrokerProfileRepository
    CandidateProfiles repository.CandidateProfileRepository
    Agencies          repository.AgencyRepository
    LinkRequests      repository.LinkRequestRepository
    SharedProfiles    repository.SharedProfileRepository
    Messaging         repository.MessagingRepository
    SavedProfiles     repository.SavedProfileRepository
    ViewedProfiles    repository.ViewedProfileRepository
    Activity          repository.ActivityRepository
    Notes             repository.NoteRepository
    Meetings          repository.MeetingRepository

    JWTSecret        string
    JWTAccessExpiry  time.Duration
    JWTRefreshExpiry time.Duration
    IsDev            bool
}
```

**Why this works**: Every field type is an INTERFACE, not a concrete type.
The Container doesn't know about `inmem.UserRepo` or a hypothetical
`postgres.UserRepo`. It only knows about `repository.UserRepository`. This
is the inversion of control principle.

The Container also holds configuration values (`JWTSecret`, expiry durations,
`IsDev`). These are plain values, not interfaces — they don't need to be
swappable.

**The constants**:

```go
const (
    DefaultAccessExpiry  = 15 * time.Minute
    DefaultRefreshExpiry = 7 * 24 * time.Hour
)
```

`time.Duration` constants use Go's duration arithmetic. `15 * time.Minute`
is 15 minutes. `7 * 24 * time.Hour` is 7 days. These are type-safe — you
can't accidentally pass a raw integer where a `time.Duration` is expected.

### 4.2 The In-Memory Factory

```go
// internal/inmem/module.go
package inmem

import "github.com/anuyatra/backend/internal/service"

func NewContainer(jwtSecret string, isDev bool) *service.Container {
    return &service.Container{
        Users:             NewUserRepo(),
        Auth:              NewAuthRepo(isDev),
        ParentProfiles:    NewParentProfileRepo(),
        BrokerProfiles:    NewBrokerProfileRepo(),
        CandidateProfiles: NewCandidateProfileRepo(),
        Agencies:          NewAgencyRepo(),
        LinkRequests:      NewLinkRequestRepo(),
        SharedProfiles:    NewSharedProfileRepo(),
        Messaging:         NewMessagingRepo(),
        SavedProfiles:     NewSavedProfileRepo(),
        ViewedProfiles:    NewViewedProfileRepo(),
        Activity:          NewActivityRepo(),
        Notes:             NewNoteRepo(),
        Meetings:          NewMeetingRepo(),
        JWTSecret:         jwtSecret,
        JWTAccessExpiry:   service.DefaultAccessExpiry,
        JWTRefreshExpiry:  service.DefaultRefreshExpiry,
        IsDev:             isDev,
    }
}
```

This is the wiring point. Each `New*Repo()` function returns a concrete type
(like `*UserRepo`), but the Container fields are interfaces (like
`repository.UserRepository`). Go's implicit interface satisfaction means this
just works — `*UserRepo` satisfies `UserRepository` because it has all the
required methods.

**The DI pattern in three lines:**

```
1. Interface definition:     repository.UserRepository (the contract)
2. Concrete implementation:  inmem.UserRepo             (one way to fulfill it)
3. Wiring:                   container.Users = NewUserRepo() (connect them)
```

### 4.3 How to Swap to Postgres

When you're ready for a real database, you create a new package:

```go
// postgres/module.go  (hypothetical)
package postgres

import (
    "database/sql"
    "github.com/anuyatra/backend/internal/service"
)

func NewContainer(db *sql.DB, jwtSecret string, isDev bool) *service.Container {
    return &service.Container{
        Users:             NewUserRepo(db),      // postgres.UserRepo
        Auth:              NewAuthRepo(db, isDev),
        ParentProfiles:    NewParentProfileRepo(db),
        // ... same pattern for all 14 repos
        JWTSecret:         jwtSecret,
        JWTAccessExpiry:   service.DefaultAccessExpiry,
        JWTRefreshExpiry:  service.DefaultRefreshExpiry,
        IsDev:             isDev,
    }
}
```

The handlers don't change at all. They only interact with the Container's
interface fields. The only change is in `main.go` — which factory you call.

### 4.4 Comparison to Dart's Riverpod

In the Flutter app, you might write:

```dart
// Dart/Riverpod
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return HiveUserRepository();  // or ApiUserRepository()
});

// Consumer widget
final repo = ref.watch(userRepositoryProvider);
await repo.getUser(id);
```

The Go equivalent:

```go
// Go
container := inmem.NewContainer(cfg.JWTSecret, cfg.IsDev())
// or: container := postgres.NewContainer(db, cfg.JWTSecret, cfg.IsDev())

// Handler
user, err := container.Users.GetByID(ctx, id)
```

Same pattern:
- Riverpod `Provider<UserRepository>` → Go `repository.UserRepository` field
- Riverpod `HiveUserRepository()` → Go `inmem.NewUserRepo()`
- `ref.watch(provider)` → `container.Users`

The difference: Riverpod is a framework with runtime provider resolution.
Go uses plain struct fields resolved at compile time. If you misspell a
field name, the Go compiler catches it. If you forget to wire a repository,
the compiler catches it (nil interface panic on first use, but also easily
caught with a simple nil check).

### 4.5 The Wiring in `main.go`

```go
// cmd/server/main.go
func main() {
    cfg := config.Load()

    // ONE LINE changes the entire data layer
    container := inmem.NewContainer(cfg.JWTSecret, cfg.IsDev())

    mux := http.NewServeMux()
    handler.RegisterRoutes(mux, container)

    // ... server setup, middleware, graceful shutdown ...
}
```

`handler.RegisterRoutes(mux, container)` passes the Container to all route
handlers. Every handler receives the same Container, and through it, access
to all 14 repositories.

The comment in the source code says it all:

```go
// DI: swap inmem.NewContainer for a postgres/mongo module when ready.
container := inmem.NewContainer(cfg.JWTSecret, cfg.IsDev())
```

### 4.6 How Handlers Use the Container

Handlers receive the Container and access repositories through it:

```go
func (h *Handler) getUser(w http.ResponseWriter, r *http.Request) {
    userID := r.PathValue("id")
    user, err := h.container.Users.GetByID(r.Context(), userID)
    if err != nil {
        writeError(w, err)
        return
    }
    writeJSON(w, http.StatusOK, user)
}
```

The handler never knows whether `h.container.Users` is an `*inmem.UserRepo`
or a `*postgres.UserRepo`. It only sees the `UserRepository` interface.

---

## 5. Generics (Go 1.18+)

Go got generics in version 1.18 (released March 2022). Before that, you'd
write the same function once for each type. Generics let you write it once.

### 5.1 The `paginate` Function

```go
// internal/inmem/helpers.go

func paginate[T any](items []*T, p repository.Pagination) ([]*T, int) {
    total := len(items)
    if p.Offset >= total {
        return nil, total
    }
    end := p.Offset + p.Limit
    if end > total {
        end = total
    }
    return items[p.Offset:end], total
}
```

Let's break down the generic syntax:

**`paginate[T any]`** — this is the type parameter list:
- `T` is the type parameter name (a placeholder for a concrete type)
- `any` is the constraint (T can be any type)
- The brackets `[T any]` come right after the function name

**`items []*T`** — a slice of pointers to T. When called with
`paginate[model.AppUser](...)`, this becomes `[]*model.AppUser`.

**`([]*T, int)`** — return type uses the same type parameter. Returns a
slice of pointers to T (the page) and an int (total count).

**What it does:**

1. Calculates the total count from the full list
2. If offset is past the end, returns nil (no results) with the total
3. Calculates the end index (`offset + limit`), clamped to the list length
4. Returns a slice of the original slice — Go slices are reference types,
   so this is O(1), not O(n)

### 5.2 How It's Called

The compiler infers the type parameter:

```go
// In UserRepo.List:
page, total := paginate(all, p)
// Compiler infers: paginate[model.AppUser](all, p)

// In CandidateProfileRepo.List:
page, total := paginate(all, p)
// Compiler infers: paginate[model.CandidateProfile](all, p)

// In SharedProfileRepo.ListForUser:
page, total := paginate(all, p)
// Compiler infers: paginate[model.SharedProfile](all, p)
```

One function, used by all 14 repositories. Without generics, you'd write:

```go
func paginateUsers(items []*model.AppUser, p repository.Pagination) ([]*model.AppUser, int) { ... }
func paginateProfiles(items []*model.CandidateProfile, p repository.Pagination) ([]*model.CandidateProfile, int) { ... }
func paginateAgencies(items []*model.Agency, p repository.Pagination) ([]*model.Agency, int) { ... }
// ... 11 more identical functions
```

### 5.3 Type Constraints

`any` is the most permissive constraint. Go offers more restrictive ones:

```go
// comparable: types that support == and !=
func contains[T comparable](slice []T, target T) bool {
    for _, v := range slice {
        if v == target {
            return true
        }
    }
    return false
}

// This works:
contains([]int{1, 2, 3}, 2)        // true
contains([]string{"a", "b"}, "c")  // false

// This would NOT compile:
// contains([][]int{{1}, {2}}, []int{1})  // slices are not comparable
```

**Custom constraints** let you define your own type sets:

```go
// A constraint that allows any numeric type
type Number interface {
    ~int | ~int8 | ~int16 | ~int32 | ~int64 |
    ~uint | ~uint8 | ~uint16 | ~uint32 | ~uint64 |
    ~float32 | ~float64
}

func Sum[T Number](numbers []T) T {
    var total T
    for _, n := range numbers {
        total += n
    }
    return total
}

Sum([]int{1, 2, 3})        // 6
Sum([]float64{1.5, 2.5})   // 4.0
```

The `~int` syntax means "int or any type whose underlying type is int."
This allows user-defined types like `type Age int` to also match.

### 5.4 When NOT to Use Generics

The Go community's guidance: **don't use generics just because you can.**

Use generics when:
- You're writing the same function body for multiple types (like `paginate`)
- The function is in a utility/helper package
- Type safety matters (don't fall back to `any` and type assertions)

Don't use generics when:
- A concrete type works fine
- You'd only use it with one or two types
- The generic version is harder to read than two concrete functions
- You're tempted to build generic frameworks (Go philosophy: simple > clever)

In this project, only `paginate` uses generics. Everything else uses
concrete types. That's typical for Go — generics are a precision tool,
not the default.

### 5.5 The Helper Functions

The `helpers.go` file also contains two non-generic helpers:

```go
func containsFold(haystack, needle string) bool {
    return strings.Contains(strings.ToLower(haystack), strings.ToLower(needle))
}

func containsStr(list []string, val string) bool {
    for _, s := range list {
        if s == val {
            return true
        }
    }
    return false
}
```

These could be generic (especially `containsStr`), but they're not. Why?
`containsFold` is string-specific (case folding only makes sense for strings).
`containsStr` could be `contains[T comparable]`, but it's only used for
`[]string` — adding generics would be overengineering. Since Go 1.21, the
standard library provides `slices.Contains` which makes both obsolete, but
the project uses its own helpers for simplicity and zero-dependency within
the package.

---

## 6. Context — Go's Request-Scoped Value Carrier

Every repository method takes `context.Context` as its first parameter.
The context is the invisible thread that ties an entire request lifecycle
together.

### 6.1 What Context Carries

A `context.Context` can carry three things:

1. **Deadlines**: "This operation must complete by 3:00:05 PM"
2. **Cancellation signals**: "The client disconnected; stop working"
3. **Request-scoped values**: "The authenticated user is user123"

```
HTTP Request arrives
    ↓
Middleware creates context with user claims
    ↓
Handler receives context, passes to repository
    ↓
Repository receives context, passes to database driver
    ↓
Database query checks context for cancellation
```

The context flows down through the entire call chain, carrying information
and control signals.

### 6.2 Context in the JWT Middleware

This is the most important use of context in our project. The JWT middleware
extracts user identity from the Authorization header and stores it in the
context:

```go
// internal/middleware/jwt.go

type contextKey string
const userClaimsKey contextKey = "user_claims"
```

**Why `contextKey` is a custom type**: Context values are stored in a
key-value map. If we used a plain `string` as the key, any package could
accidentally use the same key and overwrite our value:

```go
// DANGEROUS: both packages use the string "user" as the key
ctx = context.WithValue(ctx, "user", myUser)        // package A
ctx = context.WithValue(ctx, "user", differentUser) // package B — overwrites!
```

By defining a custom type `contextKey`, only code with access to that type
can read or write the value. The type is unexported (lowercase), so only the
`middleware` package can use it:

```go
// SAFE: different types, even with the same underlying value, are different keys
type contextKey string                    // middleware package
type otherKey string                      // other package

const userClaimsKey contextKey = "user_claims"
const otherUserKey otherKey = "user_claims"
// These are DIFFERENT keys because their types differ.
```

**Setting the context value:**

```go
func WithUserClaims(ctx context.Context, claims *UserClaims) context.Context {
    return context.WithValue(ctx, userClaimsKey, claims)
}
```

`context.WithValue` creates a NEW context that wraps the parent context.
Contexts are immutable — you never modify one, you create a new one that
carries additional information. The original context is unchanged.

**Reading the context value:**

```go
func GetUserClaims(ctx context.Context) (*UserClaims, bool) {
    claims, ok := ctx.Value(userClaimsKey).(*UserClaims)
    return claims, ok
}
```

`ctx.Value(key)` returns `any` (the empty interface). The `.(*UserClaims)`
is a **type assertion** — it asserts that the value is of type `*UserClaims`.
The two-value form `claims, ok := ...` returns `(value, true)` if the
assertion succeeds, or `(nil, false)` if it fails.

### 6.3 How the Middleware Uses It

```go
func Auth(jwtSecret string) Middleware {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            header := r.Header.Get("Authorization")
            if header == "" || !strings.HasPrefix(header, "Bearer ") {
                http.Error(w, `{"error":{"code":"UNAUTHORIZED",...}}`, http.StatusUnauthorized)
                return
            }

            token := strings.TrimPrefix(header, "Bearer ")
            claims, err := ValidateJWT(token, jwtSecret)
            if err != nil {
                http.Error(w, `{"error":{"code":"UNAUTHORIZED",...}}`, http.StatusUnauthorized)
                return
            }

            ctx := WithUserClaims(r.Context(), claims)
            next.ServeHTTP(w, r.WithContext(ctx))
        })
    }
}
```

The flow:

1. Extract the `Authorization: Bearer <token>` header
2. Validate the JWT token (check signature, expiry)
3. Extract user claims (UserID, Role) from the token
4. Create a new context with the claims: `WithUserClaims(r.Context(), claims)`
5. Create a new request with the enriched context: `r.WithContext(ctx)`
6. Pass the enriched request to the next handler: `next.ServeHTTP(w, r...)`

After this middleware, any handler can extract the user identity:

```go
func (h *Handler) someProtectedEndpoint(w http.ResponseWriter, r *http.Request) {
    claims, ok := middleware.GetUserClaims(r.Context())
    if !ok {
        // This shouldn't happen if the Auth middleware ran
        writeError(w, model.ErrUnauthorized)
        return
    }
    userID := claims.UserID
    role := claims.Role
    // ... use userID and role ...
}
```

### 6.4 `context.Background()` — The Root Context

```go
ctx := context.Background()
```

This creates an empty, non-cancellable context. It's the root of all
context trees. You use it at the top of your program (not inside request
handlers — those already have a context from the HTTP server).

### 6.5 `context.WithTimeout()` — Graceful Shutdown

In `main.go`, the graceful shutdown uses context timeout:

```go
func main() {
    // ... server setup ...

    // Wait for interrupt signal (Ctrl+C, SIGTERM)
    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit  // Block until a signal is received

    log.Println("Shutting down server...")
    ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
    defer cancel()

    if err := srv.Shutdown(ctx); err != nil {
        log.Fatalf("forced shutdown: %v", err)
    }
    log.Println("Server stopped")
}
```

Breaking this down:

**Signal handling:**

```go
quit := make(chan os.Signal, 1)           // Create a buffered channel
signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)  // Subscribe to signals
<-quit                                     // Block until signal received
```

Channels are Go's concurrency primitive for communication between goroutines.
`<-quit` blocks the main goroutine until an OS signal arrives.

**Timeout context:**

```go
ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
defer cancel()
```

`context.WithTimeout` creates a context that automatically cancels after 10
seconds. It returns two values:
- `ctx` — the context (passed to `srv.Shutdown`)
- `cancel` — a function that cancels the context immediately

`defer cancel()` ensures the cancel function is called when `main` returns,
even if the shutdown completes before the timeout. This prevents a context
leak (the timer goroutine would keep running otherwise).

**`srv.Shutdown(ctx)`:**

```go
if err := srv.Shutdown(ctx); err != nil {
    log.Fatalf("forced shutdown: %v", err)
}
```

`Shutdown` gracefully stops the server:
1. Stops accepting new connections
2. Waits for in-flight requests to complete
3. If the context expires (10 seconds), forces shutdown

If all requests finish within 10 seconds, `Shutdown` returns `nil`.
If the timeout fires first, `Shutdown` returns the context's error, and
`log.Fatalf` kills the process.

### 6.6 Why In-Memory Repos Ignore Context

You've noticed every in-memory method uses `_` for the context parameter:

```go
func (r *UserRepo) GetByID(_ context.Context, id string) (*model.AppUser, error) {
```

The `_` means "I receive this parameter but don't use it." In-memory
operations are instantaneous — there's nothing to cancel, no timeout to
respect, no remote call to abort.

But the interface REQUIRES the parameter:

```go
type UserRepository interface {
    GetByID(ctx context.Context, id string) (*model.AppUser, error)
}
```

This is forward-thinking design. When you implement a Postgres repository,
you'll pass the context to the database driver, which will respect
cancellation and timeouts:

```go
// postgres/user_repo.go (hypothetical)
func (r *UserRepo) GetByID(ctx context.Context, id string) (*model.AppUser, error) {
    row := r.db.QueryRowContext(ctx, "SELECT * FROM users WHERE uid = $1", id)
    //                          ^^^
    //     Context is passed to the database driver.
    //     If the context is cancelled, the query is aborted.
    // ...
}
```

### 6.7 The Full Context Flow

Putting it all together, here's the context's journey through a single
request:

```
1. HTTP server creates context from the incoming request
   ctx := r.Context()

2. Logger middleware passes it through unchanged
   next.ServeHTTP(w, r)

3. CORS middleware passes it through unchanged
   next.ServeHTTP(w, r)

4. Auth middleware enriches it with user claims
   ctx := WithUserClaims(r.Context(), claims)
   r = r.WithContext(ctx)

5. Handler reads user claims from context
   claims, ok := GetUserClaims(r.Context())

6. Handler passes context to repository
   user, err := container.Users.GetByID(r.Context(), id)

7. Repository (in-memory) ignores it
   func (r *UserRepo) GetByID(_ context.Context, id string) ...

   Repository (postgres, hypothetical) uses it
   r.db.QueryRowContext(ctx, query, args...)
```

The context is the backbone that carries identity, cancellation, and
deadlines from the network layer all the way down to the data layer.

---

## Summary: The Architecture in One Page

```
┌─────────────────────────────────────────────────────┐
│                    main.go                          │
│                                                     │
│  container := inmem.NewContainer(secret, isDev)     │
│                    │                                │
│                    ▼                                │
│  handler.RegisterRoutes(mux, container)             │
└─────────────────────┬───────────────────────────────┘
                      │
         ┌────────────▼────────────┐
         │   service.Container     │
         │                         │
         │  Users: UserRepository ─────────────► inmem.UserRepo
         │  Auth:  AuthRepository ─────────────► inmem.AuthRepo
         │  ParentProfiles: ... ───────────────► inmem.ParentProfileRepo
         │  BrokerProfiles: ... ───────────────► inmem.BrokerProfileRepo
         │  CandidateProfiles: ... ────────────► inmem.CandidateProfileRepo
         │  Agencies: ... ─────────────────────► inmem.AgencyRepo
         │  LinkRequests: ... ─────────────────► inmem.LinkRequestRepo
         │  SharedProfiles: ... ───────────────► inmem.SharedProfileRepo
         │  Messaging: ... ────────────────────► inmem.MessagingRepo
         │  SavedProfiles: ... ────────────────► inmem.SavedProfileRepo
         │  ViewedProfiles: ... ───────────────► inmem.ViewedProfileRepo
         │  Activity: ... ─────────────────────► inmem.ActivityRepo
         │  Notes: ... ────────────────────────► inmem.NoteRepo
         │  Meetings: ... ─────────────────────► inmem.MeetingRepo
         │                         │
         │  (All fields are        │
         │   INTERFACES, not       │
         │   concrete types)       │
         └─────────────────────────┘
```

To swap from in-memory to Postgres:

```
 BEFORE: container := inmem.NewContainer(secret, isDev)
 AFTER:  container := postgres.NewContainer(db, secret, isDev)
```

**One line changes. Zero handler changes.**

### Key Patterns to Remember

| Pattern | Where | Why |
|---------|-------|-----|
| Implicit interface satisfaction | Everywhere | No `implements`, just methods |
| Accept interfaces, return structs | All constructors | Maximum flexibility + specificity |
| `context.Context` as first param | All repo methods | Cancellation, timeouts, values |
| Pointer as optional (`*string`) | Search filters | nil = "not provided" |
| Copy-on-read/write (`cp := *v`) | All in-memory repos | Prevent external mutation |
| `make()` for maps | All constructors | Maps must be initialized |
| `sync.RWMutex` | All in-memory repos | Thread-safe concurrent access |
| Composite map keys (`a + ":" + b`) | Notes, Saved | Multi-field lookup without nested maps |
| Filter chain (`if ...; continue`) | All search methods | Composable filter logic |
| `nil, nil` return | FindDuplicate methods | "Not found" is not an error |
| Generic pagination | `paginate[T any]` | One function for 14 types |
| Custom context key type | JWT middleware | Prevent key collisions |

---

## Exercises

1. **Add a `CountByRole` method to `UserRepository`**: Write the interface
   method signature and implement it in `inmem.UserRepo`. It should count
   users by role.

2. **Write a `postgres.UserRepo`**: Implement `UserRepository` using
   `database/sql`. Focus on `GetByID` and `Create`. Use `ctx` for
   `QueryRowContext`.

3. **Find the nil interface bug**: Given this code, explain why
   `err != nil` is `true` even though there's no error:

   ```go
   func validate(user *model.AppUser) error {
       var apiErr *model.APIError
       if user.DisplayName == "" {
           apiErr = model.ValidationError("name required")
       }
       return apiErr  // BUG: returns non-nil interface when apiErr is nil!
   }
   ```

4. **Add a filter**: Add `MinExperience *int` to `CandidateSearchFilters`
   and implement it in `CandidateProfileRepo.Search`.

5. **Generic contains**: Replace `containsStr` with a generic
   `contains[T comparable]` function and update all callers.

---

> **Next up — Part 3**: HTTP Handlers, routing, middleware chains, JSON
> serialization, and the complete request lifecycle from HTTP to data and
> back.
