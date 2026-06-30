# Go Masterclass — Part 3: HTTP Servers & Middleware

> **Prerequisites:** You've completed Parts 1 (types, interfaces, concurrency) and 2 (project structure, DI, repository pattern). Now we build the HTTP layer that exposes everything to the outside world.

---

## Table of Contents

1. [net/http — Go's Built-in Web Server](#1-nethttp--gos-built-in-web-server)
2. [The Middleware Pattern](#2-the-middleware-pattern)
3. [Each Middleware Explained In Depth](#3-each-middleware-explained-in-depth)
4. [JWT Authentication Deep Dive](#4-jwt-authentication-deep-dive)
5. [Handler Architecture](#5-handler-architecture)
6. [Request Handling Patterns](#6-request-handling-patterns)
7. [Full Handler Walkthroughs](#7-full-handler-walkthroughs)
8. [Graceful Shutdown](#8-graceful-shutdown)
9. [Configuration Pattern](#9-configuration-pattern)

---

## 1. net/http — Go's Built-in Web Server

Most languages require third-party frameworks for HTTP servers. Go ships one in the standard library that's production-ready. No Express, no Flask, no Spring Boot. Just `net/http`.

### 1.1 The `http.Handler` Interface

Everything in Go's HTTP world revolves around a single interface:

```go
type Handler interface {
    ServeHTTP(ResponseWriter, *Request)
}
```

That's it. Any type that implements `ServeHTTP` can handle HTTP requests. This is the foundation of the entire ecosystem — routers, middleware, and your application handlers all satisfy this one interface.

Think about what this means:
- A router is a `Handler` that dispatches to other handlers
- A middleware is a function that takes a `Handler` and returns a new `Handler`
- Your entire application, from the perspective of `http.Server`, is just one `Handler`

### 1.2 The `http.HandlerFunc` Adapter

Writing a struct for every handler would be tedious. Go provides an adapter type:

```go
type HandlerFunc func(ResponseWriter, *Request)

func (f HandlerFunc) ServeHTTP(w ResponseWriter, r *Request) {
    f(w, r)
}
```

This is the **adapter pattern** — it converts any function with the right signature into a `Handler`. You'll see this everywhere in the codebase:

```go
mux.Handle("GET /api/v1/users/me", auth(http.HandlerFunc(handleGetMe)))
```

Here `handleGetMe` is just a function `func(http.ResponseWriter, *http.Request)`. Wrapping it with `http.HandlerFunc(...)` makes it satisfy the `Handler` interface so we can pass it to middleware.

### 1.3 `http.ServeMux` — Go's Built-in Router

`ServeMux` is Go's request multiplexer (router). Before Go 1.22, it was limited — no method matching, no path parameters. You needed third-party routers like `chi` or `gorilla/mux`.

**Go 1.22 changed everything.** The enhanced `ServeMux` now supports:
- HTTP method matching: `"GET /api/v1/health"`
- Path parameters: `"GET /api/v1/users/{id}"`
- Method + pattern combined: `"POST /api/v1/auth/send-otp"`

From our `main.go`:

```go
mux := http.NewServeMux()

mux.HandleFunc("GET /api/v1/health", func(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")
    w.Write([]byte(`{"status":"ok"}`))
})

handler.RegisterRoutes(mux, container)
```

### 1.4 The Go 1.22 Routing Syntax

The pattern string encodes both the HTTP method and the URL structure:

```
"METHOD /path/to/resource"
"METHOD /path/with/{parameter}"
```

Real examples from our codebase:

```go
// Fixed paths — exact match
mux.HandleFunc("POST /api/v1/auth/send-otp", handleSendOTP)
mux.HandleFunc("POST /api/v1/auth/verify-otp", handleVerifyOTP)

// Path parameters — variable segments
mux.Handle("GET /api/v1/users/{id}", auth(http.HandlerFunc(handleGetUser)))
mux.Handle("PUT /api/v1/candidate-profiles/{id}", auth(http.HandlerFunc(handleUpdateCandidateProfile)))
mux.Handle("DELETE /api/v1/candidate-profiles/{id}", auth(http.HandlerFunc(handleDeleteCandidateProfile)))

// Nested path parameters
mux.Handle("GET /api/v1/agencies/{id}/brokers", auth(http.HandlerFunc(handleListAgencyBrokers)))
mux.Handle("GET /api/v1/candidate-profiles/{id}/activity", auth(http.HandlerFunc(handleGetProfileActivity)))

// Multi-segment paths
mux.Handle("GET /api/v1/link-requests/connected-brokers", auth(http.HandlerFunc(handleGetConnectedBrokers)))
mux.Handle("POST /api/v1/shared-profiles/{id}/forward", auth(http.HandlerFunc(handleForwardProfile)))
```

### 1.5 Extracting Path Parameters

With Go 1.22+, path parameters are extracted with `r.PathValue()`:

```go
func handleGetUser(w http.ResponseWriter, r *http.Request) {
    id := r.PathValue("id")
    user, err := svc.Users.GetByID(r.Context(), id)
    // ...
}
```

The parameter name in the route (`{id}`) matches the argument to `PathValue("id")`. Simple, type-safe (it's always a string — you parse it yourself if you need an int), and zero allocations.

### 1.6 `http.Server` Configuration

Never use `http.ListenAndServe(addr, handler)` in production. It creates a server with zero timeouts — a recipe for resource exhaustion. Instead, configure every field explicitly:

```go
srv := &http.Server{
    Addr:         fmt.Sprintf(":%d", cfg.Port),
    Handler:      stack(mux),
    ReadTimeout:  15 * time.Second,
    WriteTimeout: 15 * time.Second,
    IdleTimeout:  60 * time.Second,
}
```

Let's break down every field:

| Field | Purpose | Why It Matters |
|-------|---------|----------------|
| `Addr` | `":8080"` — listen on all interfaces, port 8080 | The `:` prefix means "all interfaces" (0.0.0.0) |
| `Handler` | The root handler (our middleware-wrapped mux) | Everything flows through this single entry point |
| `ReadTimeout` | Max time to read the entire request (headers + body) | Protects against slow clients holding connections open |
| `WriteTimeout` | Max time from request read to response written | Prevents handlers from hanging forever |
| `IdleTimeout` | Max time a keep-alive connection stays idle | Frees connections that clients abandoned without closing |

#### Why Timeouts Matter in Production

Without timeouts, a malicious or broken client can:
1. **Slowloris attack**: Send headers one byte at a time, holding a connection forever → `ReadTimeout` stops this
2. **Hung handler**: A database query hangs indefinitely → `WriteTimeout` kills the connection
3. **Connection exhaustion**: Thousands of idle keep-alive connections eat file descriptors → `IdleTimeout` reclaims them

In our project, 15s read/write and 60s idle is a reasonable default for a mobile API backend. Adjust based on your largest expected request (file uploads might need longer `ReadTimeout`) and expected response time.

#### The `Handler` field — Why `stack(mux)` instead of `mux`

Notice we don't pass `mux` directly. We pass `stack(mux)` — the mux wrapped in our middleware chain. This is the key insight: **the server only sees one Handler; middleware wraps the router before it reaches the server.**

```go
stack := middleware.Chain(
    middleware.Logger,
    middleware.CORS(cfg.AllowedOrigins),
    middleware.Recoverer,
)

srv := &http.Server{
    Handler: stack(mux),  // mux wrapped in Logger → CORS → Recoverer
}
```

---

## 2. The Middleware Pattern

### 2.1 What Is a Middleware?

A middleware is a function that takes a handler and returns a new handler that wraps the original:

```go
func(http.Handler) http.Handler
```

It can:
- Run code **before** calling the next handler (logging the start time, checking auth)
- Run code **after** calling the next handler (logging the response status)
- Short-circuit (return early without calling next — e.g., auth failure)
- Modify the request (add context values)
- Modify the response (add headers)

### 2.2 The Project's Type Alias

From `middleware/middleware.go`:

```go
type Middleware func(http.Handler) http.Handler
```

This type alias makes function signatures cleaner. Instead of writing:

```go
func Chain(middlewares ...func(http.Handler) http.Handler) func(http.Handler) http.Handler
```

We write:

```go
func Chain(middlewares ...Middleware) Middleware
```

Same behavior, dramatically better readability.

### 2.3 The Chain Function — Middleware Composition

```go
func Chain(middlewares ...Middleware) Middleware {
    return func(next http.Handler) http.Handler {
        for i := len(middlewares) - 1; i >= 0; i-- {
            next = middlewares[i](next)
        }
        return next
    }
}
```

This is the most important function in the middleware package. Let's trace it step by step.

#### Why Reverse Iteration?

Given: `Chain(Logger, CORS, Recoverer)`

The loop runs from the **last** middleware to the **first**:

```
i=2: next = Recoverer(mux)           → call it R(mux)
i=1: next = CORS(R(mux))             → call it C(R(mux))
i=0: next = Logger(C(R(mux)))        → final result
```

So the request flows:

```
Request → Logger → CORS → Recoverer → mux (your handlers)
```

The **first** middleware in the list is the **outermost** wrapper. This is intuitive — you list them in the order you want them to execute.

If we iterated forward instead:

```
i=0: next = Logger(mux)
i=1: next = CORS(Logger(mux))
i=2: next = Recoverer(CORS(Logger(mux)))
```

Request would flow: `Recoverer → CORS → Logger → mux` — the opposite of what you'd expect from reading `Chain(Logger, CORS, Recoverer)`.

#### Usage in main.go

```go
stack := middleware.Chain(
    middleware.Logger,       // 1st: logs every request
    middleware.CORS(cfg.AllowedOrigins),  // 2nd: handles CORS
    middleware.Recoverer,    // 3rd: catches panics
)

srv := &http.Server{
    Handler: stack(mux),  // Apply the chain to our router
}
```

The execution order for each request:
1. Logger starts timer
2. CORS checks origin, sets headers
3. Recoverer sets up panic recovery
4. Mux dispatches to the correct handler
5. Handler executes and writes response
6. Recoverer's deferred function runs (no-op if no panic)
7. Logger logs method, path, status, duration

### 2.4 The Onion Model

Visualize middleware as concentric layers (like an onion):

```
┌─────────────────────────────────────────┐
│  Logger (outermost)                      │
│  ┌─────────────────────────────────────┐ │
│  │  CORS                               │ │
│  │  ┌─────────────────────────────────┐ │ │
│  │  │  Recoverer                      │ │ │
│  │  │  ┌─────────────────────────────┐ │ │ │
│  │  │  │  Your Handler (innermost)   │ │ │ │
│  │  │  └─────────────────────────────┘ │ │ │
│  │  └─────────────────────────────────┘ │ │
│  └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

Request travels inward (Logger → CORS → Recoverer → Handler).
Response travels outward (Handler → Recoverer → CORS → Logger).

---

## 3. Each Middleware Explained In Depth

### 3.1 Logger Middleware

```go
func Logger(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        start := time.Now()
        wrapped := &statusWriter{ResponseWriter: w, status: 200}
        next.ServeHTTP(wrapped, r)
        log.Printf("%s %s %d %s", r.Method, r.URL.Path, wrapped.status, time.Since(start))
    })
}
```

#### The `statusWriter` Trick

Here's the problem: Go's `http.ResponseWriter` doesn't expose the status code after you call `WriteHeader`. Once the handler writes `w.WriteHeader(404)`, there's no `w.Status()` method to read it back.

Solution: wrap `ResponseWriter` with a type that captures the status:

```go
type statusWriter struct {
    http.ResponseWriter
    status int
}

func (w *statusWriter) WriteHeader(status int) {
    w.status = status
    w.ResponseWriter.WriteHeader(status)
}
```

Key Go concepts at play:

1. **Struct embedding**: `statusWriter` embeds `http.ResponseWriter`. This means it "inherits" all methods of `ResponseWriter` (Write, Header, Flush, etc.) without implementing them. Only `WriteHeader` is overridden.

2. **Method promotion**: When you call `wrapped.Write(data)`, Go sees that `statusWriter` doesn't have a `Write` method, so it promotes the call to the embedded `ResponseWriter.Write(data)`. The handler doesn't even know it's writing to a wrapper.

3. **Default status**: We initialize `status: 200` because if a handler just calls `w.Write(data)` without explicitly calling `WriteHeader`, Go implicitly sends 200. Our wrapper must match that behavior.

#### The Decorator Pattern

```
before → call next → after
```

This is the classic decorator (or "around advice" in AOP terms):
- **Before**: `start := time.Now()` captures when the request began
- **Call next**: `next.ServeHTTP(wrapped, r)` — runs the entire downstream chain
- **After**: `log.Printf(...)` — logs the result after everything completes

The log output looks like:
```
POST /api/v1/auth/verify-otp 200 3.42ms
GET /api/v1/candidate-profiles 200 1.87ms
DELETE /api/v1/saved-profiles/abc123 204 0.52ms
GET /api/v1/users/nonexistent 404 0.31ms
```

### 3.2 CORS Middleware

```go
func CORS(allowedOrigins []string) Middleware {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            origin := r.Header.Get("Origin")
            allowed := false
            for _, o := range allowedOrigins {
                if o == "*" || o == origin {
                    allowed = true
                    break
                }
            }

            if allowed {
                w.Header().Set("Access-Control-Allow-Origin", origin)
            }
            w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
            w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
            w.Header().Set("Access-Control-Max-Age", "86400")

            if r.Method == http.MethodOptions {
                w.WriteHeader(http.StatusNoContent)
                return
            }
            next.ServeHTTP(w, r)
        })
    }
}
```

#### Factory Function Pattern

Unlike `Logger` and `Recoverer` which are just `func(http.Handler) http.Handler`, CORS needs configuration. So it's a **factory function** — a function that returns a middleware:

```go
func CORS(allowedOrigins []string) Middleware
```

The outer function captures `allowedOrigins` in a **closure**. Every time the middleware handles a request, it has access to the configured origins without needing global state or a struct.

This pattern is used when middleware needs configuration:
- `CORS(allowedOrigins)` → configured CORS middleware
- `Auth(jwtSecret)` → configured auth middleware
- `RateLimit(maxPerSecond)` → configured rate limiter (hypothetical)

#### CORS Deep Dive

**Why CORS exists**: Browsers enforce the Same-Origin Policy. A Flutter web app at `http://localhost:3000` can't call an API at `http://localhost:8080` without the server explicitly allowing it via CORS headers.

**The flow:**

1. **Origin check**: Extract `Origin` header from request, compare against allowlist
2. **Set Allow-Origin**: Only if origin is in the list (or `*` allows all)
3. **Set other headers**: Methods, allowed headers, cache duration
4. **Preflight handling**: Browsers send an `OPTIONS` request before certain cross-origin requests. We respond `204 No Content` immediately — no need to hit the handler

**Header breakdown:**

| Header | Value | Purpose |
|--------|-------|---------|
| `Access-Control-Allow-Origin` | The matched origin | Tells browser "this origin is allowed" |
| `Access-Control-Allow-Methods` | `GET, POST, PUT, DELETE, OPTIONS` | Which HTTP methods are permitted |
| `Access-Control-Allow-Headers` | `Content-Type, Authorization` | Which request headers the client can send |
| `Access-Control-Max-Age` | `86400` (24 hours) | Browser caches preflight response for this long |

**Why `origin` not `*` in Allow-Origin**: Setting `Access-Control-Allow-Origin: *` doesn't work with credentials (cookies, Authorization header). By echoing back the specific allowed origin, we support credentialed requests.

#### Preflight Short-Circuit

```go
if r.Method == http.MethodOptions {
    w.WriteHeader(http.StatusNoContent)
    return  // ← Don't call next.ServeHTTP — stop here
}
```

For `OPTIONS` preflight requests, we don't invoke the handler at all. The browser just needs the CORS headers (already set above) and a success status. This is a **short-circuit** — the middleware terminates the request without calling `next`.

### 3.3 Recoverer Middleware

```go
func Recoverer(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        defer func() {
            if err := recover(); err != nil {
                log.Printf("PANIC: %v\n%s", err, debug.Stack())
                http.Error(w, `{"error":{"code":"INTERNAL_ERROR","message":"internal server error"}}`, http.StatusInternalServerError)
            }
        }()
        next.ServeHTTP(w, r)
    })
}
```

#### `defer` + `recover()` — Go's Panic Recovery

In Go, `panic` is for truly unrecoverable situations — nil pointer dereference, index out of bounds, logic errors that should never happen. Unlike exceptions in other languages, panics are **not** for normal error handling.

But in an HTTP server, you don't want one handler's panic to crash the entire process. `Recoverer` catches panics and converts them to 500 responses:

```go
defer func() {
    if err := recover(); err != nil {
        // panic was caught — err is whatever was passed to panic()
    }
}()
```

Key rules about `recover()`:
1. Must be called directly inside a deferred function
2. Returns `nil` if no panic is in progress
3. Returns the panic value otherwise (could be any type — string, error, int, anything)
4. Stops the panic from propagating up the call stack

#### `debug.Stack()` for Stack Traces

```go
log.Printf("PANIC: %v\n%s", err, debug.Stack())
```

`debug.Stack()` returns a `[]byte` containing the goroutine's stack trace at the point of recovery. In logs, this gives you the exact line that panicked:

```
PANIC: runtime error: invalid memory address or nil pointer dereference
goroutine 42 [running]:
runtime/debug.Stack()
    /usr/local/go/src/runtime/debug/stack.go:24
github.com/anuyatra/backend/internal/handler.handleGetUser(...)
    /app/internal/handler/user_handlers.go:147
```

#### Why Recoverer Is Critical

Without it:
```
$ curl http://localhost:8080/api/v1/users/nil-pointer
Connection reset by peer
(server process exits with: "panic: runtime error: nil pointer dereference")
```

With it:
```
$ curl http://localhost:8080/api/v1/users/nil-pointer
{"error":{"code":"INTERNAL_ERROR","message":"internal server error"}}
(server keeps running, panic logged for debugging)
```

One panicking handler doesn't bring down the entire server. Other goroutines handling other requests are completely unaffected.

#### Panics vs Errors in Go

| Aspect | Error | Panic |
|--------|-------|-------|
| Usage | Expected failures (file not found, invalid input) | Programming bugs (nil deref, impossible state) |
| Return type | `error` as second return value | N/A — unwinds the stack |
| Handling | Check `if err != nil` | `defer/recover` or let it crash |
| In HTTP context | Return 4xx/5xx to client | Caught by Recoverer, becomes 500 |
| Example | `svc.Users.GetByID() → (nil, ErrNotFound)` | `slice[99]` when len is 10 |

### 3.4 Auth Middleware

```go
func Auth(jwtSecret string) Middleware {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            header := r.Header.Get("Authorization")
            if header == "" || !strings.HasPrefix(header, "Bearer ") {
                http.Error(w, `{"error":{"code":"UNAUTHORIZED","message":"missing or invalid token"}}`, http.StatusUnauthorized)
                return
            }

            token := strings.TrimPrefix(header, "Bearer ")
            claims, err := ValidateJWT(token, jwtSecret)
            if err != nil {
                http.Error(w, `{"error":{"code":"UNAUTHORIZED","message":"invalid token"}}`, http.StatusUnauthorized)
                return
            }

            ctx := WithUserClaims(r.Context(), claims)
            next.ServeHTTP(w, r.WithContext(ctx))
        })
    }
}
```

#### Step-by-Step Flow

1. **Extract header**: `Authorization: Bearer eyJhbG...`
2. **Validate format**: Must start with `"Bearer "`
3. **Parse and validate JWT**: Signature check, expiry check, extract claims
4. **Store in context**: Inject `UserClaims` into the request context
5. **Create new request**: `r.WithContext(ctx)` returns a new `*Request` with the enriched context
6. **Call next**: Downstream handlers can extract claims from context

#### Context Enrichment

The key innovation is storing authenticated user data in the request context:

```go
ctx := WithUserClaims(r.Context(), claims)
next.ServeHTTP(w, r.WithContext(ctx))
```

This means handlers don't need to re-parse the JWT. They just call:

```go
claims, ok := middleware.GetUserClaims(r.Context())
```

This is the standard Go pattern for passing request-scoped data through middleware chains.

#### Per-Route Application

Unlike Logger/CORS/Recoverer (applied globally to all routes), Auth is applied per-route:

```go
// Public routes — no auth
mux.HandleFunc("POST /api/v1/auth/send-otp", handleSendOTP)
mux.HandleFunc("POST /api/v1/auth/verify-otp", handleVerifyOTP)

// Protected routes — wrapped with auth()
mux.Handle("GET /api/v1/users/me", auth(http.HandlerFunc(handleGetMe)))
mux.Handle("PUT /api/v1/users/me", auth(http.HandlerFunc(handleUpdateMe)))
```

Notice the difference:
- `mux.HandleFunc(pattern, func)` — registers a function directly (for public routes)
- `mux.Handle(pattern, auth(http.HandlerFunc(func)))` — registers a Handler (middleware returns a Handler)

---

## 4. JWT Authentication Deep Dive

### 4.1 The UserClaims Type and Context Helpers

```go
type UserClaims struct {
    UserID string `json:"uid"`
    Role   string `json:"role"`
}

type contextKey string

const userClaimsKey contextKey = "user_claims"

func WithUserClaims(ctx context.Context, claims *UserClaims) context.Context {
    return context.WithValue(ctx, userClaimsKey, claims)
}

func GetUserClaims(ctx context.Context) (*UserClaims, bool) {
    claims, ok := ctx.Value(userClaimsKey).(*UserClaims)
    return claims, ok
}
```

#### Why a Custom contextKey Type?

`context.WithValue` uses the key's **type** for uniqueness, not just its value. If you used a plain `string` key:

```go
ctx = context.WithValue(ctx, "user_claims", claims)  // Bad!
```

Any package could accidentally overwrite it with the same string key. By declaring an unexported type (`type contextKey string`), only this package can create keys of that type. It's impossible for other packages to collide.

#### The Comma-Ok Pattern

```go
claims, ok := ctx.Value(userClaimsKey).(*UserClaims)
```

This is a type assertion with the comma-ok idiom:
- If the value exists and is `*UserClaims`: `claims` = the value, `ok` = true
- If the value is nil or a different type: `claims` = nil, `ok` = false
- Without the `, ok`: a failed assertion would **panic**

### 4.2 Generating JWTs

```go
func GenerateJWT(userID, role, secret string, expiry time.Duration) (string, error) {
    claims := jwt.MapClaims{
        "uid":  userID,
        "role": role,
        "exp":  time.Now().Add(expiry).Unix(),
        "iat":  time.Now().Unix(),
    }
    token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
    return token.SignedString([]byte(secret))
}
```

#### JWT Structure: header.payload.signature

A JWT is three Base64-encoded JSON segments separated by dots:

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1aWQiOiJhYmMxMjMiLCJyb2xlIjoicGFyZW50IiwiZXhwIjoxNzE5OTk5MDAwfQ.KjN8XpJfL9Gm3R...
|___________________________________|.|___________________________________________________________________|.|__________________|
         Header (algorithm)                              Payload (claims)                                      Signature
```

**Header**: `{"alg": "HS256", "typ": "JWT"}` — tells the verifier which algorithm was used.

**Payload** (claims): The actual data:
```json
{
    "uid": "abc123",
    "role": "parent",
    "exp": 1719999000,
    "iat": 1719998100
}
```

**Signature**: `HMAC-SHA256(base64(header) + "." + base64(payload), secret)` — proves the token hasn't been tampered with.

#### HS256 (HMAC-SHA256) — Symmetric Signing

"Symmetric" means the same secret signs AND verifies. Both the issuer (our server generating tokens) and the verifier (our server checking tokens) use `cfg.JWTSecret`.

This works perfectly for monolithic servers (one process does both). For microservices where multiple services verify tokens but don't issue them, you'd use RS256 (asymmetric: private key signs, public key verifies).

#### Standard vs Custom Claims

| Claim | Type | Purpose |
|-------|------|---------|
| `exp` | Standard | Expiration time (Unix timestamp). Token rejected after this. |
| `iat` | Standard | Issued-at time. For auditing when the token was created. |
| `uid` | Custom | Our app's user ID. Used to identify who's making the request. |
| `role` | Custom | User's role (parent/broker/agency_admin/candidate). Used for authorization. |

#### Token Expiry Durations

From `service/container.go`:

```go
const (
    DefaultAccessExpiry  = 15 * time.Minute
    DefaultRefreshExpiry = 7 * 24 * time.Hour
)
```

- **Access token**: 15 minutes. Short-lived. Included in every API request.
- **Refresh token**: 7 days. Used only to get a new access token when the old one expires.

### 4.3 Validating JWTs

```go
func ValidateJWT(tokenStr, secret string) (*UserClaims, error) {
    token, err := jwt.Parse(tokenStr, func(token *jwt.Token) (interface{}, error) {
        if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
            return nil, errors.New("unexpected signing method")
        }
        return []byte(secret), nil
    })
    if err != nil {
        return nil, err
    }

    claims, ok := token.Claims.(jwt.MapClaims)
    if !ok || !token.Valid {
        return nil, errors.New("invalid token claims")
    }

    uid, _ := claims["uid"].(string)
    role, _ := claims["role"].(string)
    if uid == "" {
        return nil, errors.New("missing uid in token")
    }

    return &UserClaims{UserID: uid, Role: role}, nil
}
```

#### The Key Function Callback

```go
jwt.Parse(tokenStr, func(token *jwt.Token) (interface{}, error) {
    // This callback is called AFTER the header is parsed but BEFORE verification
    if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
        return nil, errors.New("unexpected signing method")
    }
    return []byte(secret), nil
})
```

The callback serves two purposes:
1. **Algorithm verification**: Check that the token uses the algorithm we expect (HMAC). A common attack is to send a token signed with `"alg": "none"` — checking the method prevents this.
2. **Return the signing key**: The library uses this key to verify the signature.

#### Validation Steps

1. Parse the Base64 segments
2. Call key function — verify algorithm, get secret
3. Compute HMAC-SHA256 over header+payload with the secret
4. Compare computed signature to token's signature
5. Check `exp` claim — reject expired tokens (the library does this automatically)
6. Extract our custom claims (`uid`, `role`)
7. Validate that `uid` is present (a token without a user ID is useless)

### 4.4 Refresh Token Flow

```go
func handleRefreshToken(w http.ResponseWriter, r *http.Request) {
    var body struct {
        RefreshToken string `json:"refreshToken"`
    }
    if err := decodeJSON(r, &body); err != nil || body.RefreshToken == "" {
        writeError(w, http.StatusBadRequest, model.ValidationError("refreshToken is required"))
        return
    }

    claims, err := middleware.ValidateJWT(body.RefreshToken, svc.JWTSecret)
    if err != nil {
        writeError(w, http.StatusUnauthorized, model.ErrUnauthorized)
        return
    }

    access, err := middleware.GenerateJWT(claims.UserID, claims.Role, svc.JWTSecret, svc.JWTAccessExpiry)
    if err != nil {
        writeError(w, http.StatusInternalServerError, model.ErrInternal)
        return
    }
    writeJSON(w, http.StatusOK, map[string]any{"accessToken": access})
}
```

The flow:
1. Client's access token expires (15 min)
2. Client sends refresh token (7 day expiry) to `/auth/refresh`
3. Server validates refresh token, generates new access token
4. Client uses new access token for subsequent requests

Why two tokens? If someone steals an access token, it's only valid for 15 minutes. The refresh token is stored more securely (secure storage on device) and only sent to one endpoint.

---

## 5. Handler Architecture

### 5.1 The Global `svc` Variable

From `handler/handler.go`:

```go
var svc *service.Container
```

And from `handler/routes.go`:

```go
func RegisterRoutes(mux *http.ServeMux, c *service.Container) {
    svc = c
    // ... register all routes
}
```

All handlers access dependencies through this package-level variable. When a handler needs the user repository, it calls `svc.Users.GetByID(...)`. When it needs to generate a JWT, it uses `svc.JWTSecret`.

#### Why This Pattern Works for Go

**Simplicity**: Handlers are plain functions `func(w, r)`. No constructor injection, no handler structs, no method receivers. Just call `svc.Whatever`.

**Thread safety**: `svc` is set once during initialization (before any requests arrive) and never modified after. Read-only access from concurrent goroutines is safe without locks.

**Testability**: In tests, you create a `service.Container` with mock repositories and call `RegisterRoutes` with it.

#### Alternatives You'll See in Other Go Projects

**Handler structs** (more common in large projects):
```go
type UserHandler struct {
    users repository.UserRepository
    jwt   string
}

func (h *UserHandler) GetMe(w http.ResponseWriter, r *http.Request) {
    // use h.users, h.jwt
}
```

**Closures** (functional style):
```go
func makeGetMe(users repository.UserRepository) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        // use users from closure
    }
}
```

Our approach (package-level `svc`) is simpler and works well for medium-sized applications where a single Container holds all dependencies.

### 5.2 The RegisterRoutes Function

`RegisterRoutes` is the single place where all HTTP routes are defined. It takes the `ServeMux` and the dependency container, then wires everything up:

```go
func RegisterRoutes(mux *http.ServeMux, c *service.Container) {
    svc = c
    auth := middleware.Auth(c.JWTSecret)

    // Auth (public) — 4 routes
    mux.HandleFunc("POST /api/v1/auth/send-otp", handleSendOTP)
    mux.HandleFunc("POST /api/v1/auth/verify-otp", handleVerifyOTP)
    mux.HandleFunc("POST /api/v1/auth/refresh", handleRefreshToken)
    mux.HandleFunc("POST /api/v1/auth/logout", handleLogout)

    // Users — 5 routes
    mux.Handle("GET /api/v1/users/me", auth(http.HandlerFunc(handleGetMe)))
    mux.Handle("PUT /api/v1/users/me", auth(http.HandlerFunc(handleUpdateMe)))
    mux.Handle("POST /api/v1/users/setup-profile", auth(http.HandlerFunc(handleSetupProfile)))
    mux.Handle("GET /api/v1/users", auth(http.HandlerFunc(handleListUsers)))
    mux.Handle("GET /api/v1/users/{id}", auth(http.HandlerFunc(handleGetUser)))

    // Parent profiles — 4 routes
    // Broker profiles — 5 routes
    // Candidate profiles — 6 routes
    // Agencies — 6 routes
    // Link requests — 10 routes
    // Shared profiles — 6 routes
    // Conversations & messaging — 5 routes
    // Saved profiles — 4 routes
    // Viewed profiles — 3 routes
    // Notes — 6 routes
    // Meetings — 4 routes
    // File uploads — 1 route
    // Total: 69 routes
}
```

#### Organization by Domain

Routes are grouped by business domain, making it easy to find related endpoints. Each group has its own handler file:
- `auth_handlers.go` — authentication
- `user_handlers.go` — user management
- `profile_handlers.go` — parent, broker, and candidate profiles
- `agency_handlers.go` — agency CRUD
- `link_handlers.go` — connection requests
- `shared_profile_handlers.go` — profile sharing
- `messaging_handlers.go` — conversations and messages
- `misc_handlers.go` — saved, viewed, notes, meetings, uploads

### 5.3 `mux.Handle` vs `mux.HandleFunc`

| Method | Parameter Type | Use Case |
|--------|---------------|----------|
| `mux.HandleFunc(pattern, func)` | `func(ResponseWriter, *Request)` | Public routes (no middleware wrapping) |
| `mux.Handle(pattern, handler)` | `http.Handler` | Protected routes (middleware returns a Handler) |

```go
// HandleFunc — takes a raw function. Simple, direct.
mux.HandleFunc("POST /api/v1/auth/send-otp", handleSendOTP)

// Handle — takes a Handler interface. Needed because auth() returns a Handler.
mux.Handle("GET /api/v1/users/me", auth(http.HandlerFunc(handleGetMe)))
```

The type conversion chain for protected routes:
1. `handleGetMe` is `func(http.ResponseWriter, *http.Request)` — a plain function
2. `http.HandlerFunc(handleGetMe)` converts it to the `HandlerFunc` type (which implements `Handler`)
3. `auth(...)` wraps it with auth middleware, returning a new `Handler`
4. `mux.Handle(...)` registers the wrapped `Handler`

---

## 6. Request Handling Patterns

### 6.1 JSON Encoding/Decoding

From `handler/helpers.go`:

```go
func writeJSON(w http.ResponseWriter, status int, v any) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    json.NewEncoder(w).Encode(v)
}

func decodeJSON(r *http.Request, v any) error {
    defer r.Body.Close()
    return json.NewDecoder(r.Body).Decode(v)
}
```

#### Why `json.NewEncoder(w)` Instead of `json.Marshal`?

Two approaches to JSON encoding:

```go
// Approach 1: Marshal to bytes, then write
data, err := json.Marshal(v)
w.Write(data)

// Approach 2: Stream directly to writer
json.NewEncoder(w).Encode(v)
```

`NewEncoder` is better for HTTP because:
1. **No intermediate buffer**: Marshal allocates a `[]byte`, then `w.Write` copies it to the connection. Encoder writes directly to the connection.
2. **Less memory pressure**: For large responses (list of 100 profiles), avoiding the intermediate buffer matters.
3. **Streaming**: Encoder can start writing before the entire struct is marshaled.

#### The `any` Type Parameter

```go
func writeJSON(w http.ResponseWriter, status int, v any) {
```

`any` is Go 1.18's alias for `interface{}`. It means "accept any type." The JSON encoder uses reflection to inspect the actual type at runtime and serialize its fields.

You'll see it called with:
- Single objects: `writeJSON(w, http.StatusOK, user)`
- Maps: `writeJSON(w, http.StatusOK, map[string]any{"data": items, "total": count})`
- Slices: `writeJSON(w, http.StatusOK, profiles)`

#### Body Decoding Pattern

```go
func decodeJSON(r *http.Request, v any) error {
    defer r.Body.Close()
    return json.NewDecoder(r.Body).Decode(v)
}
```

- `defer r.Body.Close()` — ensures the body is fully read and the connection can be reused (HTTP keep-alive requires reading the full body)
- `json.NewDecoder(r.Body)` — creates a streaming decoder from the request body reader
- `.Decode(v)` — populates `v` (which must be a pointer) with the JSON data

The caller always passes a pointer to a struct:

```go
var body struct {
    PhoneNumber string         `json:"phoneNumber"`
    Role        model.UserRole `json:"role"`
}
if err := decodeJSON(r, &body); err != nil {
    writeError(w, http.StatusBadRequest, model.ValidationError("invalid JSON body"))
    return
}
```

### 6.2 Error Responses

```go
func writeError(w http.ResponseWriter, status int, err *model.APIError) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    json.NewEncoder(w).Encode(map[string]any{"error": err})
}
```

Every error response follows the same envelope:

```json
{
    "error": {
        "code": "NOT_FOUND",
        "message": "user abc123 not found"
    }
}
```

This consistency is critical for the Flutter client — it can always check for the `error` key and extract `code` + `message` regardless of which endpoint failed.

#### The `writeRepoError` Helper — Mapping Domain Errors to HTTP Status

```go
func writeRepoError(w http.ResponseWriter, err error) {
    if err == nil {
        return
    }
    var apiErr *model.APIError
    if errors.As(err, &apiErr) {
        status := http.StatusInternalServerError
        switch apiErr.Code {
        case "NOT_FOUND":
            status = http.StatusNotFound
        case "UNAUTHORIZED":
            status = http.StatusUnauthorized
        case "FORBIDDEN":
            status = http.StatusForbidden
        case "CONFLICT":
            status = http.StatusConflict
        case "VALIDATION_ERROR":
            status = http.StatusBadRequest
        case "INVALID_OTP", "SESSION_NOT_FOUND":
            status = http.StatusUnauthorized
        }
        writeError(w, status, apiErr)
        return
    }
    writeError(w, http.StatusInternalServerError, model.ErrInternal)
}
```

This function bridges between the **domain layer** (which returns `*model.APIError`) and the **HTTP layer** (which needs status codes). The repository and service layers never think about HTTP — they return domain errors. This helper translates them.

Key technique: `errors.As(err, &apiErr)` — Go's error unwrapping. It checks if `err` (or any error it wraps) is of type `*model.APIError`. If so, it populates `apiErr` and returns `true`.

#### Pre-defined Error Sentinels

```go
var (
    ErrNotFound     = &APIError{Code: "NOT_FOUND", Message: "resource not found"}
    ErrUnauthorized = &APIError{Code: "UNAUTHORIZED", Message: "authentication required"}
    ErrForbidden    = &APIError{Code: "FORBIDDEN", Message: "insufficient permissions"}
    ErrConflict     = &APIError{Code: "CONFLICT", Message: "resource already exists"}
    ErrInternal     = &APIError{Code: "INTERNAL_ERROR", Message: "internal server error"}
    ErrInvalidOTP   = &APIError{Code: "INVALID_OTP", Message: "invalid or expired OTP"}
)
```

And factory functions for context-specific messages:

```go
func NotFoundError(entityType, id string) *APIError {
    return &APIError{Code: "NOT_FOUND", Message: fmt.Sprintf("%s %s not found", entityType, id)}
}

func ValidationError(msg string) *APIError {
    return &APIError{Code: "VALIDATION_ERROR", Message: msg}
}

func ConflictError(msg string) *APIError {
    return &APIError{Code: "CONFLICT", Message: msg}
}
```

### 6.3 Pagination Helper

```go
func parsePagination(r *http.Request) repository.Pagination {
    p := repository.DefaultPagination()
    if v := r.URL.Query().Get("limit"); v != "" {
        if n, err := strconv.Atoi(v); err == nil && n > 0 && n <= 100 {
            p.Limit = n
        }
    }
    if v := r.URL.Query().Get("offset"); v != "" {
        if n, err := strconv.Atoi(v); err == nil && n >= 0 {
            p.Offset = n
        }
    }
    return p
}
```

#### Input Validation in Helpers

Notice the validation chain:
1. `v != ""` — parameter is present
2. `strconv.Atoi(v)` — it's a valid integer
3. `n > 0 && n <= 100` — it's in an acceptable range

The **max limit of 100** is a server-side guard against clients requesting enormous pages (imagine `?limit=999999` loading all records into memory). If the client sends an invalid value, we silently fall back to defaults (limit=20, offset=0) rather than returning an error.

#### Query Parameter Extraction

```go
r.URL.Query().Get("limit")
```

Breaking this down:
- `r.URL` — the parsed URL from the request
- `.Query()` — parses the query string into `url.Values` (a `map[string][]string`)
- `.Get("limit")` — returns the first value for "limit", or "" if absent

### 6.4 Optional Query Parameter Helper

```go
func queryStringPtr(r *http.Request, key string) *string {
    v := r.URL.Query().Get(key)
    if v == "" {
        return nil
    }
    return &v
}
```

This returns a `*string` — a pointer. This is the Go idiom for "optional" values:
- `nil` → parameter was not provided → don't filter
- `&"value"` → parameter was provided → use it as a filter

Used extensively in search/filter handlers:

```go
filters := repository.CandidateSearchFilters{
    Query:    queryStringPtr(r, "q"),       // nil or &"search term"
    BrokerID: queryStringPtr(r, "brokerId"), // nil or &"broker-uuid"
    City:     queryStringPtr(r, "city"),     // nil or &"Hyderabad"
    Religion: queryStringPtr(r, "religion"), // nil or &"Hindu"
}
```

The repository layer then checks: `if filters.City != nil { /* apply city filter */ }`.

### 6.5 Auth Extraction

```go
func requireClaims(w http.ResponseWriter, r *http.Request) (*middleware.UserClaims, bool) {
    claims, ok := middleware.GetUserClaims(r.Context())
    if !ok {
        writeError(w, http.StatusUnauthorized, model.ErrUnauthorized)
        return nil, false
    }
    return claims, true
}
```

This is a guard function. Every authenticated handler starts with:

```go
claims, ok := requireClaims(w, r)
if !ok {
    return
}
// Use claims.UserID, claims.Role
```

The comma-ok pattern means the caller can bail early if auth fails. The function handles writing the error response itself — the handler just needs to `return`.

**Why this exists alongside Auth middleware**: The Auth middleware ensures a valid token exists, but the handler still needs to extract the claims for business logic (checking permissions, getting the current user's data). `requireClaims` is a convenience wrapper.

### 6.6 Paginated Response Helper

```go
func paginatedResponse(data any, total int) map[string]any {
    return map[string]any{"data": data, "total": total}
}
```

Every list endpoint returns:
```json
{
    "data": [...],
    "total": 47
}
```

The client uses `total` to know how many pages exist (total / limit = pages). `data` is the current page of results.

### 6.7 Typed Filter Pointer Helpers

```go
func linkStatusPtr(r *http.Request) *model.LinkRequestStatus {
    v := r.URL.Query().Get("status")
    if v == "" {
        return nil
    }
    s := model.LinkRequestStatus(v)
    return &s
}

func linkTypePtr(r *http.Request) *model.LinkRequestType {
    v := r.URL.Query().Get("type")
    if v == "" {
        return nil
    }
    t := model.LinkRequestType(v)
    return &t
}

func sharedResponsePtr(r *http.Request) *model.SharedProfileResponse {
    v := r.URL.Query().Get("response")
    if v == "" {
        return nil
    }
    resp := model.SharedProfileResponse(v)
    return &resp
}
```

These follow the same pattern as `queryStringPtr` but convert the string to a domain type. In Go, named types like `model.LinkRequestStatus` are just type aliases over `string`, so the conversion `model.LinkRequestStatus(v)` is a zero-cost type assertion that adds semantic meaning.

### 6.8 The `strField` Helper

```go
func strField(m map[string]any, key, fallback string) string {
    if m == nil {
        return fallback
    }
    if v, ok := m[key].(string); ok && v != "" {
        return v
    }
    return fallback
}
```

Used when handlers receive untyped JSON maps (like `roleData` in profile setup):

```go
agency := &model.Agency{
    Name:        strField(body.RoleData, "agencyName", user.DisplayName+"'s Agency"),
    City:        strField(body.RoleData, "city", ""),
    State:       strField(body.RoleData, "state", ""),
    Description: strField(body.RoleData, "description", ""),
}
```

This safely extracts string values from a `map[string]any` with fallback defaults. The type assertion `m[key].(string)` uses comma-ok to avoid panics on nil or wrong-type values.

---

## 7. Full Handler Walkthroughs

### 7.1 handleVerifyOTP — The Most Complex Handler

This handler does 5 things: verify OTP, find-or-create user, generate tokens, and return everything:

```go
func handleVerifyOTP(w http.ResponseWriter, r *http.Request) {
    var body struct {
        SessionID   string         `json:"sessionId"`
        PhoneNumber string         `json:"phoneNumber"`
        OTP         string         `json:"otp"`
        Role        model.UserRole `json:"role"`
    }
    if err := decodeJSON(r, &body); err != nil {
        writeError(w, http.StatusBadRequest, model.ValidationError("invalid JSON body"))
        return
    }

    ok, err := svc.Auth.VerifyOTP(r.Context(), body.SessionID, body.PhoneNumber, body.OTP)
    if err != nil {
        writeRepoError(w, err)
        return
    }
    if !ok {
        writeError(w, http.StatusUnauthorized, model.ErrInvalidOTP)
        return
    }

    user, err := svc.Users.GetByPhone(r.Context(), body.PhoneNumber)
    needsProfile := false
    if err != nil {
        var apiErr *model.APIError
        if !errors.As(err, &apiErr) || apiErr.Code != "NOT_FOUND" {
            writeRepoError(w, err)
            return
        }
        user = &model.AppUser{
            UID:         uuid.NewString(),
            PhoneNumber: body.PhoneNumber,
            DisplayName: "",
            Role:        body.Role,
            CreatedAt:   time.Now(),
            IsActive:    true,
        }
        if err := svc.Users.Create(r.Context(), user); err != nil {
            writeRepoError(w, err)
            return
        }
        needsProfile = true
    }

    access, err := middleware.GenerateJWT(user.UID, string(user.Role), svc.JWTSecret, svc.JWTAccessExpiry)
    if err != nil {
        writeError(w, http.StatusInternalServerError, model.ErrInternal)
        return
    }
    refresh, err := middleware.GenerateJWT(user.UID, string(user.Role), svc.JWTSecret, svc.JWTRefreshExpiry)
    if err != nil {
        writeError(w, http.StatusInternalServerError, model.ErrInternal)
        return
    }

    writeJSON(w, http.StatusOK, map[string]any{
        "accessToken":       access,
        "refreshToken":      refresh,
        "user":              user,
        "needsProfileSetup": needsProfile,
    })
}
```

#### Line-by-Line Breakdown

**Step 1: Decode and validate request body**
```go
var body struct {
    SessionID   string         `json:"sessionId"`
    PhoneNumber string         `json:"phoneNumber"`
    OTP         string         `json:"otp"`
    Role        model.UserRole `json:"role"`
}
if err := decodeJSON(r, &body); err != nil {
    writeError(w, http.StatusBadRequest, model.ValidationError("invalid JSON body"))
    return
}
```

Anonymous struct — declared inline, used once. The `json:"..."` tags tell the decoder which JSON keys to map to which fields.

**Step 2: Verify the OTP**
```go
ok, err := svc.Auth.VerifyOTP(r.Context(), body.SessionID, body.PhoneNumber, body.OTP)
if err != nil {
    writeRepoError(w, err)
    return
}
if !ok {
    writeError(w, http.StatusUnauthorized, model.ErrInvalidOTP)
    return
}
```

Two-level error handling:
- `err != nil` → something went wrong (session not found, database error)
- `!ok` → OTP didn't match (wrong code, expired)

**Step 3: Find or create user**
```go
user, err := svc.Users.GetByPhone(r.Context(), body.PhoneNumber)
needsProfile := false
if err != nil {
    var apiErr *model.APIError
    if !errors.As(err, &apiErr) || apiErr.Code != "NOT_FOUND" {
        writeRepoError(w, err)
        return
    }
    // NOT_FOUND means first login — create the user
    user = &model.AppUser{
        UID:         uuid.NewString(),
        PhoneNumber: body.PhoneNumber,
        DisplayName: "",
        Role:        body.Role,
        CreatedAt:   time.Now(),
        IsActive:    true,
    }
    if err := svc.Users.Create(r.Context(), user); err != nil {
        writeRepoError(w, err)
        return
    }
    needsProfile = true
}
```

The interesting pattern here: we distinguish between "not found" (expected — new user) and other errors (unexpected — database crash). `errors.As` unwraps the error to check if it's specifically a NOT_FOUND.

`needsProfile = true` signals to the Flutter client that it should navigate to the profile setup screen.

**Step 4: Generate both tokens**
```go
access, err := middleware.GenerateJWT(user.UID, string(user.Role), svc.JWTSecret, svc.JWTAccessExpiry)
refresh, err := middleware.GenerateJWT(user.UID, string(user.Role), svc.JWTSecret, svc.JWTRefreshExpiry)
```

Same function, different expiry durations. The refresh token has identical claims but lasts 7 days instead of 15 minutes.

**Step 5: Return combined response**
```go
writeJSON(w, http.StatusOK, map[string]any{
    "accessToken":       access,
    "refreshToken":      refresh,
    "user":              user,
    "needsProfileSetup": needsProfile,
})
```

The client gets everything it needs in one response: tokens for auth, user object for the UI, and a flag for routing logic.

### 7.2 handleSetupProfile — The Role-Based Switch

```go
func handleSetupProfile(w http.ResponseWriter, r *http.Request) {
    claims, ok := requireClaims(w, r)
    if !ok {
        return
    }
    user, err := svc.Users.GetByID(r.Context(), claims.UserID)
    if err != nil {
        writeRepoError(w, err)
        return
    }

    var body struct {
        DisplayName string         `json:"displayName"`
        RoleData    map[string]any `json:"roleData"`
    }
    if err := decodeJSON(r, &body); err != nil {
        writeError(w, http.StatusBadRequest, model.ValidationError("invalid JSON body"))
        return
    }
    if body.DisplayName != "" {
        user.DisplayName = body.DisplayName
    }

    now := time.Now()
    switch user.Role {
    case model.RoleAgencyAdmin:
        agency := &model.Agency{
            ID:          uuid.NewString(),
            AdminUserID: user.UID,
            Name:        strField(body.RoleData, "agencyName", user.DisplayName+"'s Agency"),
            City:        strField(body.RoleData, "city", ""),
            State:       strField(body.RoleData, "state", ""),
            Description: strField(body.RoleData, "description", ""),
            IsActive:    true,
            CreatedAt:   now,
        }
        if err := svc.Agencies.Create(r.Context(), agency); err != nil {
            writeRepoError(w, err)
            return
        }
        user.AgencyID = &agency.ID

    case model.RoleBroker:
        bp := &model.BrokerProfile{
            UserID:      user.UID,
            Name:        user.DisplayName,
            PhoneNumber: user.PhoneNumber,
            Bio:         strField(body.RoleData, "bio", ""),
            LastSeen:    now,
            CreatedAt:   now,
        }
        if err := svc.BrokerProfiles.Save(r.Context(), bp); err != nil {
            writeRepoError(w, err)
            return
        }

    case model.RoleParent:
        looking := model.LookingForGroom
        if strField(body.RoleData, "lookingFor", "groom") == "bride" {
            looking = model.LookingForBride
        }
        pp := &model.ParentProfile{
            UserID:     user.UID,
            Name:       user.DisplayName,
            LookingFor: looking,
            City:       strField(body.RoleData, "city", ""),
            State:      strField(body.RoleData, "state", ""),
            CreatedAt:  now,
        }
        if err := svc.ParentProfiles.Save(r.Context(), pp); err != nil {
            writeRepoError(w, err)
            return
        }

    case model.RoleCandidate:
        // No additional profile creation needed
    }

    if err := svc.Users.Update(r.Context(), user); err != nil {
        writeRepoError(w, err)
        return
    }
    writeJSON(w, http.StatusOK, user)
}
```

#### Key Patterns

**The `RoleData` approach**: Instead of separate endpoints for each role, we use one endpoint with a flexible `map[string]any` payload. The `switch` on `user.Role` determines how to interpret the data. This keeps the Flutter client simple — one setup screen, one API call.

**`strField` with fallbacks**: Every field extraction has a default value. If the client omits `agencyName`, we generate one from the user's display name. This makes the API forgiving — partial data is fine.

**Cross-entity creation**: When an agency admin sets up their profile, we create both the `Agency` entity AND update the user's `AgencyID` pointer. This handler touches multiple repositories in a single request.

**The empty `case model.RoleCandidate:`**: Candidates don't need an additional profile during setup — their candidate profile is created later by a broker. The explicit empty case documents this intention.

### 7.3 handleListCandidateProfiles — Search with Filters

```go
func handleListCandidateProfiles(w http.ResponseWriter, r *http.Request) {
    claims, ok := requireClaims(w, r)
    if !ok {
        return
    }
    p := parsePagination(r)
    brokerID := queryStringPtr(r, "brokerId")
    if brokerID != nil && *brokerID == claims.UserID {
        data, total, err := svc.CandidateProfiles.ListByBroker(r.Context(), claims.UserID, p)
        if err != nil {
            writeRepoError(w, err)
            return
        }
        writeJSON(w, http.StatusOK, paginatedResponse(data, total))
        return
    }

    filters := repository.CandidateSearchFilters{
        Query:    queryStringPtr(r, "q"),
        BrokerID: brokerID,
        City:     queryStringPtr(r, "city"),
        Religion: queryStringPtr(r, "religion"),
    }
    if g := r.URL.Query().Get("gender"); g != "" {
        gender := model.Gender(g)
        filters.Gender = &gender
    }
    if v := r.URL.Query().Get("minAge"); v != "" {
        if n, err := strconv.Atoi(v); err == nil {
            filters.MinAge = &n
        }
    }
    if v := r.URL.Query().Get("maxAge"); v != "" {
        if n, err := strconv.Atoi(v); err == nil {
            filters.MaxAge = &n
        }
    }
    data, total, err := svc.CandidateProfiles.Search(r.Context(), filters, p)
    if err != nil {
        writeRepoError(w, err)
        return
    }
    writeJSON(w, http.StatusOK, paginatedResponse(data, total))
}
```

#### Key Patterns

**Self-filter shortcut**: If a broker asks for `?brokerId=<their own ID>`, we use the more efficient `ListByBroker` method instead of the full search. This is an optimization — listing your own profiles is faster than searching all profiles with a broker filter.

**Building filter structs from query params**: Each filter field is independently extracted. `nil` fields are ignored by the repository's search implementation. This means `GET /candidate-profiles` returns all, `GET /candidate-profiles?city=Hyderabad` filters by city, and `GET /candidate-profiles?city=Hyderabad&gender=female&minAge=25` combines multiple filters.

**Type-specific parsing**: Different fields need different parsing:
- Strings: `queryStringPtr(r, "city")` → `*string`
- Enums: `model.Gender(g)` → type conversion from string
- Numbers: `strconv.Atoi(v)` → parse, validate, store as `*int`

### 7.4 handleShareProfile — Business Logic in Handlers

```go
func handleShareProfile(w http.ResponseWriter, r *http.Request) {
    claims, ok := requireClaims(w, r)
    if !ok {
        return
    }
    var body struct {
        ProfileID        string  `json:"profileId"`
        SharedWithUserID string  `json:"sharedWithUserId"`
        ParentNote       *string `json:"parentNote"`
    }
    if err := decodeJSON(r, &body); err != nil {
        writeError(w, http.StatusBadRequest, model.ValidationError("invalid JSON body"))
        return
    }
    if _, err := svc.CandidateProfiles.GetByID(r.Context(), body.ProfileID); err != nil {
        writeRepoError(w, err)
        return
    }
    dup, err := svc.SharedProfiles.FindDuplicate(r.Context(), body.ProfileID, body.SharedWithUserID)
    if err != nil {
        writeRepoError(w, err)
        return
    }
    if dup != nil {
        writeError(w, http.StatusConflict, model.ConflictError("profile already shared with this user"))
        return
    }

    sp := &model.SharedProfile{
        ID:               uuid.NewString(),
        ProfileID:        body.ProfileID,
        SharedByUserID:   claims.UserID,
        SharedWithUserID: body.SharedWithUserID,
        SharedAt:         time.Now(),
        ParentResponse:   model.ResponsePending,
        ParentNote:       body.ParentNote,
    }
    if err := svc.SharedProfiles.Create(r.Context(), sp); err != nil {
        writeRepoError(w, err)
        return
    }
    recordActivity(r, body.ProfileID, claims.UserID, model.ActivityBrokerShared, nil)
    writeJSON(w, http.StatusCreated, sp)
}
```

#### Key Patterns

**Existence validation**: Before sharing a profile, verify it exists:
```go
if _, err := svc.CandidateProfiles.GetByID(r.Context(), body.ProfileID); err != nil {
    writeRepoError(w, err)
    return
}
```
The `_` discards the profile data — we just need to know it exists.

**Duplicate prevention**:
```go
dup, err := svc.SharedProfiles.FindDuplicate(r.Context(), body.ProfileID, body.SharedWithUserID)
if dup != nil {
    writeError(w, http.StatusConflict, model.ConflictError("profile already shared with this user"))
    return
}
```
Business rule: you can't share the same profile with the same parent twice. The handler checks before creating, returning 409 Conflict if duplicate exists.

**Cross-repository interaction**:
```go
svc.SharedProfiles.Create(r.Context(), sp)
recordActivity(r, body.ProfileID, claims.UserID, model.ActivityBrokerShared, nil)
```
After creating the shared profile, we also record an activity event. This is an audit trail — the profile's activity feed will show "Shared by Broker X on Date Y".

**The `recordActivity` helper**:
```go
func recordActivity(r *http.Request, profileID string, actorID string, kind model.ProfileActivityKind, meta map[string]any) {
    actorName := ""
    if user, err := svc.Users.GetByID(r.Context(), actorID); err == nil {
        actorName = user.DisplayName
    }
    _ = svc.Activity.Record(r.Context(), &model.ProfileActivity{
        ID:          uuid.NewString(),
        ProfileID:   profileID,
        ActorUserID: &actorID,
        ActorName:   &actorName,
        Kind:        kind,
        At:          time.Now(),
        Meta:        meta,
    })
}
```
Notice `_ = svc.Activity.Record(...)` — we intentionally discard the error. Activity recording is a best-effort side effect. If it fails, the main operation (sharing the profile) already succeeded and we don't want to confuse the client with an error about a secondary concern.

### 7.5 handleCreateLinkRequest — Complex Validation

```go
func handleCreateLinkRequest(w http.ResponseWriter, r *http.Request) {
    claims, ok := requireClaims(w, r)
    if !ok {
        return
    }
    var body struct {
        ToUserID string                `json:"toUserId"`
        Type     model.LinkRequestType `json:"type"`
        Note     *string               `json:"note"`
    }
    if err := decodeJSON(r, &body); err != nil {
        writeError(w, http.StatusBadRequest, model.ValidationError("invalid JSON body"))
        return
    }
    if body.ToUserID == "" {
        writeError(w, http.StatusBadRequest, model.ValidationError("toUserId is required"))
        return
    }
    if body.ToUserID == claims.UserID {
        writeError(w, http.StatusBadRequest, model.ValidationError("cannot link to yourself"))
        return
    }

    dup, err := svc.LinkRequests.FindDuplicate(r.Context(), claims.UserID, body.ToUserID, body.Type)
    if err != nil {
        writeRepoError(w, err)
        return
    }
    if dup != nil {
        writeError(w, http.StatusConflict, model.ConflictError("link request already pending"))
        return
    }

    fromUser, err := svc.Users.GetByID(r.Context(), claims.UserID)
    if err != nil {
        writeRepoError(w, err)
        return
    }
    toUser, err := svc.Users.GetByID(r.Context(), body.ToUserID)
    if err != nil {
        writeRepoError(w, err)
        return
    }

    req := &model.LinkRequest{
        ID:           uuid.NewString(),
        FromUserID:   claims.UserID,
        ToUserID:     body.ToUserID,
        FromUserName: fromUser.DisplayName,
        ToUserName:   toUser.DisplayName,
        Type:         body.Type,
        Status:       model.LinkStatusPending,
        CreatedAt:    time.Now(),
        Note:         body.Note,
    }
    if err := svc.LinkRequests.Create(r.Context(), req); err != nil {
        writeRepoError(w, err)
        return
    }
    writeJSON(w, http.StatusCreated, req)
}
```

#### Key Patterns

**Multi-level validation**:
1. JSON decode validation (is it valid JSON?)
2. Required field validation (`toUserId == ""`)
3. Business rule validation (can't link to yourself)
4. Duplicate check (is there already a pending request?)
5. Existence validation (do both users exist?)

Each validation returns early with an appropriate error. This "guard clause" pattern keeps the happy path readable — the actual creation logic is at the bottom.

**Denormalization for read performance**: The `LinkRequest` stores `FromUserName` and `ToUserName`. This is deliberate denormalization — when listing link requests, we don't need to join with the users table to display names. The trade-off: if a user changes their name, existing link requests show the old name. For our use case, this is acceptable.

### 7.6 handleAcceptLinkRequest — State Machine Transition

```go
func handleAcceptLinkRequest(w http.ResponseWriter, r *http.Request) {
    claims, ok := requireClaims(w, r)
    if !ok {
        return
    }
    req, err := svc.LinkRequests.GetByID(r.Context(), r.PathValue("id"))
    if err != nil {
        writeRepoError(w, err)
        return
    }
    if req.ToUserID != claims.UserID {
        writeError(w, http.StatusForbidden, model.ErrForbidden)
        return
    }
    if req.Status != model.LinkStatusPending {
        writeError(w, http.StatusBadRequest, model.ValidationError("request is not pending"))
        return
    }
    now := time.Now()
    req.Status = model.LinkStatusAccepted
    req.RespondedAt = &now
    if err := svc.LinkRequests.Update(r.Context(), req); err != nil {
        writeRepoError(w, err)
        return
    }
    if req.Type == model.LinkParentToBroker {
        _, _ = svc.Messaging.GetOrCreateConversation(r.Context(), req.FromUserID, req.ToUserID)
    }
    writeJSON(w, http.StatusOK, req)
}
```

#### Key Patterns

**Authorization check**: `req.ToUserID != claims.UserID` — only the recipient can accept a link request. The sender can revoke, but not accept.

**State guard**: `req.Status != model.LinkStatusPending` — you can't accept an already-accepted, declined, or revoked request. This is a state machine: `Pending → Accepted | Declined | Revoked`.

**Side effects on state transition**: When a parent-broker link is accepted, we automatically create a conversation between them:
```go
if req.Type == model.LinkParentToBroker {
    _, _ = svc.Messaging.GetOrCreateConversation(r.Context(), req.FromUserID, req.ToUserID)
}
```

This is business logic: "when two users connect, they should be able to message each other immediately." The `GetOrCreate` pattern is idempotent — if called twice, it just returns the existing conversation.

### 7.7 handleSendMessage — Complex Object Construction

```go
func handleSendMessage(w http.ResponseWriter, r *http.Request) {
    claims, ok := requireClaims(w, r)
    if !ok {
        return
    }
    convID := r.PathValue("id")
    conv, err := svc.Messaging.GetConversation(r.Context(), convID)
    if err != nil {
        writeRepoError(w, err)
        return
    }
    var body struct {
        Content       string               `json:"content"`
        Type          model.ChatMessageType `json:"type"`
        RecipientID   string               `json:"recipientId"`
        ProfileID     *string              `json:"profileId"`
        AttachmentURL *string              `json:"attachmentUrl"`
    }
    if err := decodeJSON(r, &body); err != nil {
        writeError(w, http.StatusBadRequest, model.ValidationError("invalid JSON body"))
        return
    }
    if body.Type == "" {
        body.Type = model.MessageText
    }
    msg := &model.ChatMessage{
        ID:             uuid.NewString(),
        ConversationID: convID,
        SenderID:       claims.UserID,
        RecipientID:    body.RecipientID,
        Content:        body.Content,
        Type:           body.Type,
        Timestamp:      time.Now(),
        ProfileID:      body.ProfileID,
        AttachmentURL:  body.AttachmentURL,
    }
    if msg.RecipientID == "" {
        for _, pid := range conv.ParticipantIDs {
            if pid != claims.UserID {
                msg.RecipientID = pid
                break
            }
        }
    }
    if err := svc.Messaging.CreateMessage(r.Context(), msg); err != nil {
        writeRepoError(w, err)
        return
    }
    writeJSON(w, http.StatusCreated, msg)
}
```

#### Key Patterns

**Default values**: `if body.Type == "" { body.Type = model.MessageText }` — if the client doesn't specify a message type, assume plain text.

**Smart defaults from context**: If `RecipientID` is omitted, we infer it from the conversation participants:
```go
if msg.RecipientID == "" {
    for _, pid := range conv.ParticipantIDs {
        if pid != claims.UserID {
            msg.RecipientID = pid
            break
        }
    }
}
```
In a two-person conversation, the recipient is always "the other person." This saves the client from tracking and sending it every time.

**Server-generated fields**: `ID`, `SenderID`, `Timestamp` are always set server-side regardless of what the client sends. This prevents clients from spoofing message metadata.

### 7.8 handleUpdateCandidateProfile — Permission Checking

```go
func handleUpdateCandidateProfile(w http.ResponseWriter, r *http.Request) {
    claims, ok := requireClaims(w, r)
    if !ok {
        return
    }
    id := r.PathValue("id")
    existing, err := svc.CandidateProfiles.GetByID(r.Context(), id)
    if err != nil {
        writeRepoError(w, err)
        return
    }
    if !canManageProfile(claims.UserID, existing) {
        writeError(w, http.StatusForbidden, model.ErrForbidden)
        return
    }
    var updated model.CandidateProfile
    if err := decodeJSON(r, &updated); err != nil {
        writeError(w, http.StatusBadRequest, model.ValidationError("invalid JSON body"))
        return
    }
    updated.ID = existing.ID
    updated.CreatedByUserID = existing.CreatedByUserID
    updated.CreatedAt = existing.CreatedAt
    updated.UpdatedAt = time.Now()
    if err := svc.CandidateProfiles.Update(r.Context(), &updated); err != nil {
        writeRepoError(w, err)
        return
    }
    writeJSON(w, http.StatusOK, &updated)
}
```

#### Key Patterns

**Permission function**:
```go
func canManageProfile(userID string, p *model.CandidateProfile) bool {
    if p.CreatedByUserID == userID {
        return true
    }
    for _, id := range p.BrokerIDs {
        if id == userID {
            return true
        }
    }
    return false
}
```
A profile can be managed by its creator OR any broker listed on it. This models the real-world scenario where multiple brokers might co-manage a candidate.

**Immutable fields preservation**: After decoding the new data:
```go
updated.ID = existing.ID
updated.CreatedByUserID = existing.CreatedByUserID
updated.CreatedAt = existing.CreatedAt
updated.UpdatedAt = time.Now()
```
We override certain fields with the original values. Even if a malicious client sends `"id": "different-id"` in the body, we ignore it and keep the original. `UpdatedAt` is always set server-side.

**Full replacement semantics**: This handler uses full replacement — the client sends the complete updated profile. This is simpler than PATCH semantics (partial updates) but means the client must send all fields, even unchanged ones. The trade-off is simplicity vs bandwidth.

### 7.9 handleCreateMeeting — Simple Entity Creation

```go
func handleCreateMeeting(w http.ResponseWriter, r *http.Request) {
    claims, ok := requireClaims(w, r)
    if !ok {
        return
    }
    var meeting model.Meeting
    if err := decodeJSON(r, &meeting); err != nil {
        writeError(w, http.StatusBadRequest, model.ValidationError("invalid JSON body"))
        return
    }
    meeting.ID = uuid.NewString()
    meeting.ScheduledByUserID = claims.UserID
    meeting.Status = model.MeetingScheduled
    meeting.CreatedAt = time.Now()
    if err := svc.Meetings.Save(r.Context(), &meeting); err != nil {
        writeRepoError(w, err)
        return
    }
    writeJSON(w, http.StatusCreated, &meeting)
}
```

The simplest CRUD pattern:
1. Authenticate
2. Decode body into the domain model
3. Override server-controlled fields (ID, creator, status, timestamp)
4. Save
5. Return the created entity

### 7.10 handleGetPresignedURL — Dev vs Production Branching

```go
func handleGetPresignedURL(w http.ResponseWriter, r *http.Request) {
    if _, ok := requireClaims(w, r); !ok {
        return
    }
    var body struct {
        Filename    string `json:"filename"`
        ContentType string `json:"contentType"`
    }
    if err := decodeJSON(r, &body); err != nil {
        writeError(w, http.StatusBadRequest, model.ValidationError("invalid JSON body"))
        return
    }
    if body.Filename == "" {
        writeError(w, http.StatusBadRequest, model.ValidationError("filename is required"))
        return
    }
    key := uuid.NewString() + "_" + body.Filename
    baseURL := "http://localhost:8080"
    if svc.IsDev {
        writeJSON(w, http.StatusOK, map[string]string{
            "uploadUrl": baseURL + "/api/v1/uploads/" + key,
            "publicUrl": baseURL + "/api/v1/uploads/" + key,
            "key":       key,
        })
        return
    }
    writeJSON(w, http.StatusOK, map[string]string{
        "uploadUrl": "https://storage.example.com/upload/" + key,
        "publicUrl": "https://storage.example.com/files/" + key,
        "key":       key,
    })
}
```

#### Key Patterns

**Environment-aware behavior**: `if svc.IsDev` switches between local mock URLs and production cloud storage URLs. The handler's API contract is identical in both environments — clients always get `uploadUrl`, `publicUrl`, and `key`.

**UUID-prefixed keys**: `uuid.NewString() + "_" + body.Filename` ensures uniqueness even if two users upload files with the same name. The original filename is preserved for readability.

**Claims used only for gating**: `if _, ok := requireClaims(w, r); !ok { return }` — we check auth but don't use the claims. The underscore `_` discards the value. This endpoint requires authentication but doesn't need the user's identity.

---

## 8. Graceful Shutdown

From `main.go`:

```go
go func() {
    log.Printf("Anuyatra API server starting on :%d (storage=in-memory)", cfg.Port)
    if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
        log.Fatalf("server error: %v", err)
    }
}()

quit := make(chan os.Signal, 1)
signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
<-quit

log.Println("Shutting down server...")
ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
defer cancel()

if err := srv.Shutdown(ctx); err != nil {
    log.Fatalf("forced shutdown: %v", err)
}
log.Println("Server stopped")
```

### 8.1 Server Runs in a Goroutine

```go
go func() {
    if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
        log.Fatalf("server error: %v", err)
    }
}()
```

`ListenAndServe` blocks forever (listening for connections). We run it in a goroutine so that `main()` can continue to the signal-waiting code below.

The error check `err != http.ErrServerClosed` is important: when we call `srv.Shutdown()` later, `ListenAndServe` returns `http.ErrServerClosed` — that's expected, not an error worth crashing over.

### 8.2 Signal Handling

```go
quit := make(chan os.Signal, 1)
signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
<-quit
```

Breaking this down:

1. `make(chan os.Signal, 1)` — create a buffered channel for signals. Buffer of 1 ensures the signal isn't lost if we're not actively receiving.

2. `signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)` — tell the OS to send these signals to our channel instead of the default behavior (killing the process):
   - `SIGINT` (Ctrl+C in terminal)
   - `SIGTERM` (what `docker stop`, Kubernetes, and `kill` send)

3. `<-quit` — block the main goroutine until a signal arrives. The program sits here indefinitely while the server goroutine handles requests.

### 8.3 Graceful Drain

```go
ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
defer cancel()

if err := srv.Shutdown(ctx); err != nil {
    log.Fatalf("forced shutdown: %v", err)
}
```

`srv.Shutdown(ctx)` does the following:
1. Immediately stops accepting new connections
2. Waits for all in-flight requests to complete
3. If the context expires (10 seconds), forces remaining connections closed

#### Why This Matters

**Without graceful shutdown** (`log.Fatal` on signal):
- Client mid-request gets `connection reset`
- Database transaction left uncommitted
- File upload partially written
- Load balancer still sending traffic to a dead process

**With graceful shutdown**:
- All in-flight requests complete normally
- New connections are refused (load balancer detects this and routes elsewhere)
- Server stops cleanly after all work is done
- If requests take longer than 10s, we force-kill (prevent hanging forever)

### 8.4 The Complete main() Flow

```
1. Load config
2. Create DI container (repositories + services)
3. Create router (ServeMux)
4. Register routes
5. Build middleware stack
6. Create http.Server with timeouts
7. Start server in goroutine
8. Block main goroutine on signal channel
9. Signal received → shutdown with 10s timeout
10. Exit cleanly
```

---

## 9. Configuration Pattern

### 9.1 The Config Struct

```go
type Config struct {
    Port           int
    DatabaseURL    string
    JWTSecret      string
    AllowedOrigins []string
    OTPProvider    string
    StorageProvider string
    StorageBucket   string
    Env            string
}
```

Every configuration value has a concrete type. No `map[string]string` for config — that's a Go anti-pattern. Typed structs give you:
- Compile-time typo detection (`cfg.Potr` won't compile, `cfg["potr"]` silently returns "")
- Autocomplete in IDEs
- Documentation through field names

### 9.2 The Load Function

```go
func Load() *Config {
    return &Config{
        Port:           envInt("PORT", 8080),
        DatabaseURL:    envStr("DATABASE_URL", "postgres://localhost:5432/anuyatra?sslmode=disable"),
        JWTSecret:      envStr("JWT_SECRET", "dev-secret-change-in-production"),
        AllowedOrigins: strings.Split(envStr("ALLOWED_ORIGINS", "*"), ","),
        OTPProvider:    envStr("OTP_PROVIDER", "mock"),
        StorageProvider: envStr("STORAGE_PROVIDER", "local"),
        StorageBucket:   envStr("STORAGE_BUCKET", "anuyatra-uploads"),
        Env:            envStr("ENV", "development"),
    }
}
```

### 9.3 The 12-Factor App Principle

Our config follows the [12-Factor App](https://12factor.net/config) methodology:

> **Store config in environment variables.**

Why environment variables instead of config files?
1. **No secrets in source control**: `JWT_SECRET` never appears in code
2. **Environment-specific**: Same binary, different config per deploy (dev, staging, prod)
3. **Container-friendly**: `docker run -e PORT=9090 ...` overrides without rebuilding
4. **Platform-agnostic**: Every OS and orchestrator supports env vars

### 9.4 Helper Functions with Fallbacks

```go
func envStr(key, fallback string) string {
    if v := os.Getenv(key); v != "" {
        return v
    }
    return fallback
}

func envInt(key string, fallback int) int {
    if v := os.Getenv(key); v != "" {
        if n, err := strconv.Atoi(v); err == nil {
            return n
        }
    }
    return fallback
}
```

Pattern:
1. Check if the environment variable is set and non-empty
2. Parse it to the expected type (for `envInt`, validate it's a valid integer)
3. Return the fallback if unset, empty, or unparseable

**Fallbacks are development defaults**: When you `go run cmd/server/main.go` without setting any env vars, you get a working server on port 8080 with mock OTP, local storage, and a dev JWT secret. Zero configuration needed for development.

**Production ignores fallbacks**: In production, every env var is set explicitly. The fallbacks exist only so new developers don't need to configure anything to start coding.

### 9.5 The IsDev() Method

```go
func (c *Config) IsDev() bool {
    return c.Env == "development"
}
```

Used throughout the codebase to enable development-only features:

```go
// In handleSendOTP: return the OTP in the response (so devs don't need SMS)
if svc.IsDev {
    resp["otp"] = "123456"
}

// In handleGetPresignedURL: use local URLs instead of cloud storage
if svc.IsDev {
    writeJSON(w, http.StatusOK, map[string]string{
        "uploadUrl": baseURL + "/api/v1/uploads/" + key,
        // ...
    })
}
```

The `IsDev` flag flows through the DI container (`svc.IsDev`) so every handler can check it without importing the config package directly.

### 9.6 AllowedOrigins Parsing

```go
AllowedOrigins: strings.Split(envStr("ALLOWED_ORIGINS", "*"), ","),
```

The environment variable `ALLOWED_ORIGINS` is a comma-separated list:
```bash
# Development: allow all
ALLOWED_ORIGINS=*

# Production: specific origins only
ALLOWED_ORIGINS=https://app.anuyatra.com,https://admin.anuyatra.com
```

`strings.Split("*", ",")` returns `["*"]` — a slice with one element that the CORS middleware interprets as "allow all origins."

---

## Summary: Patterns Catalog

### Handler Patterns Used in This Project

| Pattern | Example | When to Use |
|---------|---------|-------------|
| Simple GET by ID | `handleGetUser` | Fetch one entity by path param |
| GET "me" | `handleGetMe` | Current user's own data |
| List with pagination | `handleListUsers` | Paginated collection endpoints |
| Search with filters | `handleListCandidateProfiles` | Optional filter parameters |
| Create with server IDs | `handleCreateMeeting` | Server generates ID + timestamps |
| Full replacement update | `handleUpdateCandidateProfile` | Client sends complete object |
| Partial update | `handleUpdateMe` | Client sends only changed fields |
| State machine transition | `handleAcceptLinkRequest` | Status changes with validation |
| Role-based branching | `handleSetupProfile` | Different logic per user role |
| Duplicate prevention | `handleShareProfile` | Check-then-create with conflict |
| Cross-entity side effects | `handleAcceptLinkRequest` | Create conversation on accept |
| Authorization by ownership | `handleUpdateAgency` | Only owner can modify |
| Authorization by role | `canManageProfile` | Creator or listed broker |
| Environment branching | `handleGetPresignedURL` | Dev mock vs production service |
| Fire-and-forget side effects | `recordActivity` | Best-effort audit logging |
| Guard clause | `requireClaims` | Early return on auth failure |
| Smart defaults | `handleSendMessage` | Infer recipient from context |

### Middleware Patterns

| Pattern | Example | Key Concept |
|---------|---------|-------------|
| Simple wrapper | `Logger` | before → next → after |
| Factory with config | `CORS(origins)` | Closure captures config |
| Short-circuit | `Auth` (invalid token) | Return without calling next |
| Context enrichment | `Auth` (valid token) | Add data via `r.WithContext` |
| Panic recovery | `Recoverer` | defer + recover |
| Response wrapping | `statusWriter` in Logger | Embed ResponseWriter |
| Chain composition | `Chain(...)` | Combine N middlewares into one |

### Error Handling Patterns

| Pattern | Example | When to Use |
|---------|---------|-------------|
| Typed error matching | `errors.As(err, &apiErr)` | Map domain errors to HTTP |
| Pre-defined sentinels | `model.ErrNotFound` | Common, reusable errors |
| Factory functions | `model.ValidationError(msg)` | Context-specific messages |
| Consistent envelope | `{"error": {"code", "message"}}` | Every error response |
| Status code mapping | `writeRepoError` switch | Domain code → HTTP status |

---

## What's Next

In **Part 4**, we'll dive into the **Repository Pattern and In-Memory Storage** — how the `inmem` package implements all those interfaces, concurrency with `sync.RWMutex`, and how to swap in PostgreSQL without changing a single handler.
