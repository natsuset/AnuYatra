# Go Masterclass — From Zero to Production

A comprehensive Go learning series built around the Anuyatra backend codebase. Every concept is taught using real code from this project, not toy examples.

## Who This Is For

You're a Flutter/Dart developer who wants to deeply understand Go — not just the syntax, but the **why** behind every design decision. By the end, you'll understand every line of code in this backend and be able to write production-grade Go yourself.

## The Documents

Read in order. Each builds on the previous.

| # | Document | What You'll Learn | Time |
|---|----------|-------------------|------|
| 1 | [**Fundamentals**](GO_MASTERCLASS_01_FUNDAMENTALS.md) | Types, structs, functions, error handling, packages, the Go mental model | ~60 min |
| 2 | [**Interfaces & Dependency Injection**](GO_MASTERCLASS_02_INTERFACES_AND_DI.md) | Interfaces (Go's most important feature), the repository pattern, DI without frameworks, generics, context | ~60 min |
| 3 | [**HTTP & Middleware**](GO_MASTERCLASS_03_HTTP_AND_MIDDLEWARE.md) | Building REST APIs with `net/http`, middleware chain, JWT auth, handler patterns, graceful shutdown | ~60 min |
| 4 | [**Concurrency & Advanced Topics**](GO_MASTERCLASS_04_CONCURRENCY_AND_ADVANCED.md) | Goroutines, channels, `sync.RWMutex`, race conditions, testing, project structure, production readiness | ~60 min |

## Project Architecture at a Glance

```
backend/
├── cmd/server/main.go              ← Entry point: config, DI wiring, server start
├── internal/                       ← Private to this module (Go enforced)
│   ├── config/config.go            ← Environment-based configuration
│   ├── model/                      ← Domain types — structs, enums, errors
│   │   ├── user.go                 ← AppUser, UserRole
│   │   ├── candidate_profile.go    ← CandidateProfile (60+ fields)
│   │   ├── parent_profile.go       ← ParentProfile
│   │   ├── broker_profile.go       ← BrokerProfile, BrokerStats, AgencyStats
│   │   ├── agency.go               ← Agency
│   │   ├── link_request.go         ← LinkRequest, LinkRequestType, LinkRequestStatus
│   │   ├── shared_profile.go       ← SharedProfile, SharedProfileResponse
│   │   ├── messaging.go            ← ChatMessage, Conversation
│   │   ├── extras.go               ← SavedProfile, ViewedProfile, Activity, Notes, Meetings
│   │   └── errors.go               ← APIError (implements error interface)
│   ├── repository/interfaces.go    ← 14 repository interfaces — THE contracts
│   ├── service/container.go        ← DI container: holds all interfaces + config
│   ├── inmem/                      ← In-memory implementations (swap for postgres/)
│   │   ├── module.go               ← NewContainer() factory
│   │   ├── helpers.go              ← paginate[T], containsFold
│   │   ├── user_repo.go            ← UserRepo (primary + secondary index)
│   │   ├── auth_repo.go            ← OTP sessions with expiry
│   │   ├── profile_repos.go        ← Parent, Broker, Candidate repos
│   │   ├── agency_repo.go          ← Agency CRUD + search
│   │   ├── link_repo.go            ← Link requests + connection queries
│   │   ├── shared_profile_repo.go  ← Profile sharing + dedup
│   │   ├── messaging_repo.go       ← Conversations + messages (triple index)
│   │   └── extras_repo.go          ← Saved, Viewed, Activity, Notes, Meetings
│   ├── handler/                    ← HTTP handlers (65+ endpoints)
│   │   ├── handler.go              ← svc container, requireClaims, writeRepoError
│   │   ├── helpers.go              ← writeJSON, decodeJSON, parsePagination
│   │   ├── routes.go               ← RegisterRoutes (all 65+ routes)
│   │   ├── auth_handlers.go        ← OTP send/verify, JWT issue/refresh, logout
│   │   ├── user_handlers.go        ← CRUD, profile setup, phone lookup
│   │   ├── profile_handlers.go     ← Parent, broker, candidate CRUD + search
│   │   ├── agency_handlers.go      ← Agency CRUD + stats
│   │   ├── link_handlers.go        ← Send/accept/decline/revoke + connection queries
│   │   ├── shared_profile_handlers.go ← Share/respond/forward
│   │   ├── messaging_handlers.go   ← Conversations + messages
│   │   └── misc_handlers.go        ← Saved, Viewed, Notes, Meetings, Uploads
│   └── middleware/                  ← HTTP middleware
│       ├── middleware.go            ← Logger, CORS, Recoverer, Auth, Chain
│       └── jwt.go                  ← JWT generate/validate, context claims
├── go.mod                          ← Module definition + dependencies
└── go.sum                          ← Dependency checksums
```

## Key Architectural Decisions

1. **Standard library only for HTTP** — no Gin, Echo, Chi. Go 1.22's `http.ServeMux` with method+pattern matching is sufficient.
2. **Repository pattern with interfaces** — every data operation goes through an interface. Swap `inmem/` for `postgres/` by changing one line in `main.go`.
3. **DI via struct, not framework** — `service.Container` holds all dependencies. No reflect, no wire, no dig.
4. **In-memory storage** — maps + `sync.RWMutex`. Production-ready patterns without database complexity. Swap later.
5. **Copy-on-read** — all repo reads return copies (`cp := *v; return &cp`). Prevents data races without holding locks during handler execution.
6. **Flat error model** — `*model.APIError` implements `error`. Handlers use `errors.As` to convert to HTTP status codes.

## How to Read the Code

Start here → follow the arrows:

```
main.go                         ← Read FIRST. 67 lines. The whole app wiring.
    ↓
config.Load()                   ← Where settings come from
    ↓
inmem.NewContainer()            ← How DI is wired
    ↓
handler.RegisterRoutes()        ← How HTTP routes map to handlers
    ↓
middleware.Chain(Logger, CORS, Recoverer) ← Request pipeline
    ↓
Pick any handler (e.g., handleVerifyOTP) ← Follow the request flow
    ↓
Repository interface method     ← Abstract data operation
    ↓
In-memory implementation        ← Concrete logic
```

## Dependencies

This entire backend uses only **2 external packages**:

| Package | Purpose | Why Not Stdlib |
|---------|---------|----------------|
| `github.com/golang-jwt/jwt/v5` | JWT token signing and validation | JWT is a complex standard — stdlib doesn't have it |
| `github.com/google/uuid` | UUID v4 generation | Stdlib `crypto/rand` could do it, but uuid package is cleaner |

Everything else — HTTP server, routing, middleware, JSON encoding, configuration — is standard library.
