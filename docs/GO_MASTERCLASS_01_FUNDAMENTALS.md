# Go Masterclass — Part 1: Fundamentals

> **Audience**: Flutter/Dart developers who want to deeply understand Go.
> **Project**: All examples are drawn from the Anuyatra matrimonial platform backend.
> **Philosophy**: Every concept is explained with *why*, not just *what*.

---

## Table of Contents

1. [Go Philosophy & Mental Model](#1-go-philosophy--mental-model)
2. [Packages, Imports & Module System](#2-packages-imports--module-system)
3. [Types & Type System](#3-types--type-system)
4. [Structs — Go's Data Building Block](#4-structs--gos-data-building-block)
5. [Slices, Maps & the `make` Function](#5-slices-maps--the-make-function)
6. [Functions & Multiple Return Values](#6-functions--multiple-return-values)
7. [Error Handling — Go's Defining Feature](#7-error-handling--gos-defining-feature)
8. [Control Flow](#8-control-flow)
9. [The Blank Identifier `_`](#9-the-blank-identifier-_)

---

## 1. Go Philosophy & Mental Model

### 1.1 Why Go Exists

Go was created at Google in 2007 by Robert Griesemer, Rob Pike, and Ken Thompson. They were frustrated with the state of systems programming: C++ compilations took forever, Java was over-engineered with layers of abstraction, and Python was too slow for systems work. They wanted a language that was:

- **Fast to compile** (entire Google-scale codebases in seconds)
- **Fast to execute** (compiled to native machine code)
- **Fast to read** (one way to do things, minimal syntax)
- **Built for concurrency** (goroutines and channels as first-class citizens)
- **Practical over academic** (designed for working engineers, not language theorists)

### 1.2 The Mental Shift from Dart

If you're coming from Dart/Flutter, your brain is wired a certain way. Let's rewire it.

| Concept | Dart | Go |
|---------|------|-----|
| Execution model | JIT + AOT compiled, runs on Dart VM | Compiled to native binary, no runtime VM |
| Null safety | `String?` vs `String` | Pointer types: `*string` vs `string` |
| Error handling | Exceptions + try/catch | Return values + `if err != nil` |
| OOP | Classes, inheritance, mixins | Structs, interfaces, composition |
| Generics | Full generics since Dart 2.0 | Added in Go 1.18 (2022), used sparingly |
| Concurrency | `async/await`, Futures, Isolates | Goroutines, channels, `sync` package |
| Package manager | pub.dev | Go modules (go.sum for checksums) |
| Entry point | `void main()` | `func main()` in `package main` |
| Visibility | `_privateField` prefix | lowercase = private, Uppercase = public |

### 1.3 Compiled vs Interpreted: What This Means for You

In Dart, your code goes through multiple stages: parsing, compilation to kernel bytecode, JIT compilation in debug mode, or AOT compilation for release. There's always a runtime (the Dart VM) managing your code.

In Go, `go build` produces a **single static binary** with zero dependencies. No VM, no runtime framework, no shared libraries needed. You can compile on your Mac and produce a Linux binary that runs on a bare server with nothing else installed.

**Why this matters**: When you deploy the Anuyatra backend, you compile once and ship a single binary. No "install Go on the server." No dependency hell. The binary *is* the deployment artifact.

```go
// From cmd/server/main.go — this entire file compiles into one binary
package main

func main() {
    cfg := config.Load()
    container := inmem.NewContainer(cfg.JWTSecret, cfg.IsDev())
    // ... start server
}
```

After `go build ./cmd/server/`, you get a single file (`server`) that is your entire backend. Copy it to any Linux machine and run it. Done.

### 1.4 nil vs null: A Subtle but Critical Difference

In Dart, `null` means "no value" and the type system tracks nullability:

```dart
String name = "Alice";      // Cannot be null
String? nickname = null;    // Nullable
```

In Go, `nil` is the zero value for pointers, slices, maps, interfaces, channels, and functions. But **basic types cannot be nil**:

```go
var name string    // "" (empty string, NOT nil)
var age int        // 0 (NOT nil)
var active bool    // false (NOT nil)
var photo *string  // nil (pointer — CAN be nil)
```

**Why this matters**: In the Anuyatra `AppUser` model, notice that `PhotoURL` is `*string` (pointer to string) while `DisplayName` is `string` (plain string). This is Go's way of saying "a user MUST have a display name (even if empty), but a photo URL is truly optional (may not exist at all)."

### 1.5 "Less is More" — Go's Deliberate Omissions

Go intentionally lacks features that other languages consider essential:

| Feature | Go's Position | Why |
|---------|--------------|-----|
| Inheritance | Not supported | Composition is clearer and more flexible |
| Method overloading | Not supported | One function name = one behavior. Less confusion. |
| Generics | Added in 1.18, used conservatively | Most code doesn't need them. Concrete types are clearer. |
| Exceptions | Not supported | Error values make control flow explicit |
| Ternary operator | Not supported | `if/else` is always clear |
| Default arguments | Not supported | Use option structs or functional options |
| Enums | Not a language feature | Use typed constants (as we'll see) |

This isn't laziness — it's philosophy. Rob Pike said: "The key point here is our programmers are Googlers, they're not researchers. They're typically, fairly young, fresh out of school, probably learned Java, maybe learned C or C++... They need to get going quickly... and the language that we give them has to be easy for them to understand and easy to adopt."

**The result**: Any Go code you read looks like any other Go code. There's one way to iterate, one way to handle errors, one way to define types. You can read a stranger's Go code almost as easily as your own.

### 1.6 Composition over Inheritance

In Dart, you might write:

```dart
class Animal {
  void breathe() => print("breathing");
}
class Dog extends Animal {
  void bark() => print("woof");
}
```

In Go, there is no `extends`, no `implements` keyword, no class hierarchy. Instead, you compose types:

```go
type Breather struct{}
func (b Breather) Breathe() { fmt.Println("breathing") }

type Dog struct {
    Breather  // embedded — Dog now "has" Breathe()
}
func (d Dog) Bark() { fmt.Println("woof") }
```

**In this project**, look at `statusWriter` in `middleware.go`:

```go
type statusWriter struct {
    http.ResponseWriter  // embedded interface — statusWriter IS a ResponseWriter
    status int
}
```

`statusWriter` doesn't "extend" `http.ResponseWriter`. It **embeds** it. This means `statusWriter` automatically satisfies the `http.ResponseWriter` interface and can be used anywhere a `ResponseWriter` is expected, while adding its own `status` tracking field. This is composition in action.

---

## 2. Packages, Imports & Module System

### 2.1 Go Modules: The `go.mod` File

Every Go project starts with a `go.mod` file, analogous to `pubspec.yaml` in Flutter. Here's the Anuyatra backend's `go.mod`:

```go
module github.com/anuyatra/backend

go 1.23.6

require github.com/golang-jwt/jwt/v5 v5.3.1

require github.com/google/uuid v1.6.0 // indirect
```

Let's break this down:

**`module github.com/anuyatra/backend`**

This declares the module path — the unique identifier for this codebase. It's like the `name:` field in `pubspec.yaml`, but it uses a URL-like format. This is NOT a URL that must resolve (though it often does for open-source projects). It's an identifier that other Go code uses to import packages from this module.

All internal imports within this project will be prefixed with `github.com/anuyatra/backend/...`.

**`go 1.23.6`**

This specifies the minimum Go version required to compile this module. Unlike Dart's SDK constraints, this is a floor, not a range. Any Go 1.23.6 or later will work.

**`require` directives**

```go
require github.com/golang-jwt/jwt/v5 v5.3.1
require github.com/google/uuid v1.6.0 // indirect
```

These are your dependencies (like `dependencies:` in `pubspec.yaml`):
- `github.com/golang-jwt/jwt/v5 v5.3.1` — A JWT library for creating/validating tokens. The `/v5` suffix indicates major version 5 (Go uses semantic import versioning for major versions ≥ 2).
- `github.com/google/uuid v1.6.0 // indirect` — A UUID generation library. The `// indirect` comment means your code doesn't import it directly; it's pulled in by one of your direct dependencies (or used only in a sub-package).

**Why this matters**: Notice how minimal this is. The entire Anuyatra backend has only TWO dependencies. Go's standard library is so comprehensive (HTTP server, JSON encoding, cryptography, testing, etc.) that you rarely need external packages. In Flutter, your `pubspec.yaml` might have 30+ dependencies. In Go, 2-5 is typical for a production backend.

### 2.2 The `go.sum` File

Alongside `go.mod`, you'll find `go.sum`. This is analogous to `pubspec.lock` — it contains cryptographic checksums of every dependency to ensure reproducible builds and detect tampering. You never edit this file manually; `go mod tidy` manages it.

### 2.3 How Packages Work

In Go, a **package** is a directory of `.go` files that share the same `package` declaration. This is fundamentally different from Dart, where every file is independent and you `import` individual files.

Rules:
1. **One package per directory** — all `.go` files in a directory must have the same `package` declaration
2. **Package name ≠ directory name** (by convention they match, but it's not required)
3. **No circular imports** — if package A imports B, B cannot import A (the compiler enforces this)
4. **`package main`** is special — it's the entry point, must contain `func main()`

In the Anuyatra project:

```
backend/
├── cmd/server/main.go          → package main (entry point)
├── internal/
│   ├── config/config.go        → package config
│   ├── model/
│   │   ├── user.go             → package model
│   │   ├── errors.go           → package model
│   │   ├── candidate_profile.go → package model
│   │   └── ...                 → package model (all files share the same package)
│   ├── handler/
│   │   ├── handler.go          → package handler
│   │   ├── helpers.go          → package handler
│   │   ├── routes.go           → package handler
│   │   ├── auth_handlers.go    → package handler
│   │   └── ...                 → package handler
│   ├── inmem/
│   │   ├── module.go           → package inmem
│   │   ├── user_repo.go        → package inmem
│   │   └── ...                 → package inmem
│   ├── middleware/
│   │   ├── middleware.go       → package middleware
│   │   └── jwt.go             → package middleware
│   ├── repository/
│   │   └── interfaces.go       → package repository
│   └── service/
│       └── container.go        → package service
└── go.mod
```

**Key insight for Dart developers**: In Dart, you organize by file. In Go, you organize by package (directory). All files in `internal/model/` are one logical unit — they can access each other's unexported (lowercase) identifiers without importing anything. Think of a package as a single namespace spanning multiple files.

### 2.4 The `internal/` Convention

Notice that almost everything in this project lives under `internal/`. This is a Go-enforced convention (not just a naming convention — the compiler enforces it):

**Code inside `internal/` can only be imported by code in the parent directory tree.**

This means:
- `backend/cmd/server/main.go` CAN import `backend/internal/config` (it's in the same module, above `internal/`)
- An external project that depends on `github.com/anuyatra/backend` CANNOT import `backend/internal/config` — the compiler will reject it

**Why this matters**: This gives you a clean public API boundary. If you ever publish a Go library, anything in `internal/` is private implementation detail. The outside world can only use what you put outside `internal/`. It's like Dart's `src/` convention in packages, except the compiler enforces it.

### 2.5 The `cmd/` Convention

The `cmd/` directory is a convention (not enforced, but universally followed) for defining entry points. Each subdirectory under `cmd/` is a separate binary:

```
cmd/
├── server/main.go    → go build ./cmd/server → produces "server" binary
├── migrate/main.go   → go build ./cmd/migrate → produces "migrate" binary (if it existed)
└── seed/main.go      → go build ./cmd/seed → produces "seed" binary (if it existed)
```

Each must be `package main` with a `func main()`.

### 2.6 Import Grouping Convention

Go has a strict convention for organizing imports into groups separated by blank lines:

```go
import (
    // Group 1: Standard library packages
    "context"
    "fmt"
    "log"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    "time"

    // Group 2: External third-party packages
    // (none in main.go, but auth_handlers.go has: "github.com/google/uuid")

    // Group 3: Internal project packages
    "github.com/anuyatra/backend/internal/config"
    "github.com/anuyatra/backend/internal/handler"
    "github.com/anuyatra/backend/internal/inmem"
    "github.com/anuyatra/backend/internal/middleware"
)
```

The `gofmt` tool (Go's mandatory formatter — more on this later) enforces alphabetical ordering within groups. The `goimports` tool automatically manages your imports, adding missing ones and removing unused ones.

**Why this matters**: In Dart, imports can be messy and unordered. In Go, every file in every project follows this exact pattern. You can glance at any Go file's imports and immediately know what standard library features, external dependencies, and internal packages it uses.

### 2.7 Package-Level Variables and init()

Inside `handler.go`, notice:

```go
package handler

var svc *service.Container
```

This is a **package-level variable** — visible to all files in the `handler` package. It's set during route registration:

```go
func RegisterRoutes(mux *http.ServeMux, c *service.Container) {
    svc = c  // all handler functions can now access svc
    // ...
}
```

Go also supports `init()` functions that run automatically when a package is imported, but the Anuyatra project avoids them in favor of explicit initialization (a good practice).

### 2.8 Import Paths Are Not URLs

A common misconception: `"github.com/golang-jwt/jwt/v5"` looks like a URL, but Go doesn't download from that URL at runtime. During `go mod download` (similar to `flutter pub get`), Go fetches the source code from a module proxy (default: `proxy.golang.org`) which mirrors GitHub repos. After that, everything is local.

---

## 3. Types & Type System

### 3.1 Basic Types

Go has a small set of built-in types:

| Type | Zero Value | Description | Dart Equivalent |
|------|-----------|-------------|-----------------|
| `bool` | `false` | Boolean | `bool` |
| `string` | `""` | UTF-8 string (immutable) | `String` |
| `int` | `0` | Platform-sized integer (32 or 64 bit) | `int` |
| `int8`, `int16`, `int32`, `int64` | `0` | Fixed-size integers | No direct equivalent |
| `uint` | `0` | Unsigned integer | No direct equivalent |
| `float32`, `float64` | `0.0` | IEEE-754 floats | `double` |
| `byte` | `0` | Alias for `uint8` | No direct equivalent |
| `rune` | `0` | Alias for `int32` (Unicode code point) | Similar to a char code |
| `complex64`, `complex128` | `0+0i` | Complex numbers | No equivalent |

### 3.2 Zero Values — The Most Important Concept You'll Learn

**Every type in Go has a zero value.** When you declare a variable without initializing it, it gets the zero value automatically. There is no "uninitialized variable" in Go.

```go
var s string      // "" (empty string)
var n int         // 0
var f float64     // 0.0
var b bool        // false
var p *string     // nil (pointer to nothing)
var sl []int      // nil (nil slice)
var m map[string]int  // nil (nil map — careful! can read, cannot write)
```

**Why this matters**: In Dart, you might forget to initialize a variable and get a null reference error at runtime. In Go, zero values mean your code is always in a valid state from the start. A zero-value `bool` is `false`, not "undefined." A zero-value `string` is `""`, not `null`.

This has profound design implications. Look at `AppUser`:

```go
type AppUser struct {
    UID         string    `json:"uid"`
    PhoneNumber string    `json:"phoneNumber"`
    DisplayName string    `json:"displayName"`
    PhotoURL    *string   `json:"photoUrl"`
    Role        UserRole  `json:"role"`
    AgencyID    *string   `json:"agencyId"`
    CreatedAt   time.Time `json:"createdAt"`
    IsActive    bool      `json:"isActive"`
}
```

If you create `var user model.AppUser`, you get:
- `UID`: `""` (empty string — a user must have a UID, we'll assign one)
- `PhoneNumber`: `""` (empty string — a user must have a phone, we'll assign one)
- `DisplayName`: `""` (empty string — acceptable! "no display name yet")
- `PhotoURL`: `nil` (pointer — truly "no photo URL exists")
- `Role`: `""` (empty string — we must validate this!)
- `AgencyID`: `nil` (pointer — "not part of any agency")
- `CreatedAt`: `time.Time{}` (January 1, year 0 — we'll set this)
- `IsActive`: `false` (boolean — new user is inactive by default... or is this a bug?)

**Design lesson**: The choice between `string` and `*string` is a design decision about whether "empty" and "absent" are the same thing. For `DisplayName`, an empty string means "no name set yet." For `PhotoURL`, `nil` means "no photo has ever been uploaded" which is semantically different from an empty string.

### 3.3 Type Declarations and Custom Types

Go lets you create new types from existing ones. This isn't just a type alias — it creates a distinct type with its own method set.

From `internal/model/user.go`:

```go
type UserRole string

const (
    RoleParent      UserRole = "parent"
    RoleBroker      UserRole = "broker"
    RoleCandidate   UserRole = "candidate"
    RoleAgencyAdmin UserRole = "agencyAdmin"
)

func (r UserRole) IsValid() bool {
    switch r {
    case RoleParent, RoleBroker, RoleCandidate, RoleAgencyAdmin:
        return true
    }
    return false
}
```

Let's unpack this completely:

**`type UserRole string`** — This creates a NEW type called `UserRole`. Its underlying type is `string`, meaning it can hold string values, but it is NOT interchangeable with `string`. You cannot pass a `string` where a `UserRole` is expected without an explicit conversion.

```go
var role UserRole = "parent"       // OK — untyped string constant is compatible
var role UserRole = RoleParent     // OK — named constant of type UserRole
var s string = "parent"
var role UserRole = s              // COMPILE ERROR — cannot use string as UserRole
var role UserRole = UserRole(s)    // OK — explicit conversion
```

**Why this matters**: This gives you compile-time type safety. A function that takes `UserRole` cannot accidentally receive a random string. The compiler catches misuse.

**The constants block** — This is Go's "enum" pattern:

```go
const (
    RoleParent      UserRole = "parent"
    RoleBroker      UserRole = "broker"
    RoleCandidate   UserRole = "candidate"
    RoleAgencyAdmin UserRole = "agencyAdmin"
)
```

Go doesn't have a built-in `enum` keyword like Dart. Instead, you declare a custom type and define constants of that type. The convention is:
- Type name: singular noun (`UserRole`, `Gender`, `Diet`)
- Constants: prefixed with type name or meaningful prefix (`RoleParent`, `GenderBride`, `DietVegan`)

**The method**: `func (r UserRole) IsValid() bool` — This attaches a method to the `UserRole` type. We'll cover methods in detail later, but notice how this replaces what would be a static utility function in Dart:

```dart
// Dart approach
enum UserRole { parent, broker, candidate, agencyAdmin }
// isValid is implicit — if it's in the enum, it's valid

// Go approach — explicit validation
func (r UserRole) IsValid() bool { ... }
```

**In this project**, `IsValid()` is called during OTP verification to validate the role sent by the Flutter client:

```go
// From auth_handlers.go
if !body.Role.IsValid() {
    writeError(w, http.StatusBadRequest, model.ValidationError("invalid role"))
    return
}
```

### 3.4 More Custom Types from the Project

The `candidate_profile.go` file shows this pattern extensively:

```go
type Gender string
const (
    GenderBride Gender = "bride"
    GenderGroom Gender = "groom"
)

type ProfileVisibility string
const (
    VisibilityPublic        ProfileVisibility = "public"
    VisibilityConnectedOnly ProfileVisibility = "connectedOnly"
    VisibilityHidden        ProfileVisibility = "hidden"
)

type Diet string
const (
    DietVegetarian    Diet = "vegetarian"
    DietNonVegetarian Diet = "nonVegetarian"
    DietEggetarian    Diet = "eggetarian"
    DietVegan         Diet = "vegan"
    DietJain          Diet = "jain"
)

type FamilyType string
const (
    FamilyTypeJoint   FamilyType = "joint"
    FamilyTypeNuclear FamilyType = "nuclear"
)

type FamilyValues string
const (
    FamilyValuesOrthodox FamilyValues = "orthodox"
    FamilyValuesModerate FamilyValues = "moderate"
    FamilyValuesLiberal  FamilyValues = "liberal"
)
```

Each of these is a distinct type. You cannot accidentally assign a `Diet` to a `Gender` variable. The compiler protects you.

**Compare to Dart**:
```dart
enum Gender { bride, groom }
enum Diet { vegetarian, nonVegetarian, eggetarian, vegan, jain }
```

Dart enums are more structured (they have index, name, values list). Go's approach is simpler but requires you to write your own validation.

### 3.5 Pointer Types: When and Why

In Dart, everything (except primitives in some contexts) is a reference. You don't think about pointers. In Go, you must explicitly choose between values and pointers.

**The rule from this project**:
- Non-nullable field → use value type (`string`, `int`, `bool`)
- Nullable/optional field → use pointer type (`*string`, `*int`, `*bool`)

From `CandidateProfile`:

```go
type CandidateProfile struct {
    // Required fields — value types
    ID              string    `json:"id"`
    Name            string    `json:"name"`
    Age             int       `json:"age"`
    Gender          Gender    `json:"gender"`
    City            string    `json:"city"`

    // Optional fields — pointer types
    ParentUserID    *string   `json:"parentUserId"`
    DateOfBirth     *time.Time `json:"dateOfBirth,omitempty"`
    AnnualIncome    *string   `json:"annualIncome,omitempty"`
    Smokes          *bool     `json:"smokes,omitempty"`
    Drinks          *bool     `json:"drinks,omitempty"`
    NumberOfBrothers *int     `json:"numberOfBrothers,omitempty"`
    DietPref        *Diet     `json:"diet,omitempty"`
}
```

**Why pointers for optional fields?**

Consider `Smokes *bool`:
- `nil` → the user hasn't specified (no data)
- `&true` (pointer to true) → the user explicitly said "yes, they smoke"
- `&false` (pointer to false) → the user explicitly said "no, they don't smoke"

If this were just `bool`, you'd have:
- `false` → Does this mean "doesn't smoke" or "hasn't answered"? You can't tell!

The pointer gives you three states: yes, no, and unknown. This is critical for search filters and form fields in the Flutter app.

**Creating pointer values**:

```go
// You can't take the address of a literal directly
var s *string = &"hello"  // COMPILE ERROR

// Instead, use a variable or helper function
name := "Alice"
var s *string = &name     // OK

// Common helper pattern (not in this project, but useful)
func strPtr(s string) *string { return &s }
photo := strPtr("https://example.com/photo.jpg")
```

### 3.6 Type Conversions (Not Casting)

Go doesn't have "casting" — it has explicit type conversions. They always look like function calls:

```go
var i int = 42
var f float64 = float64(i)     // int → float64
var u uint = uint(f)           // float64 → uint

var role model.UserRole = model.UserRole("parent")  // string → UserRole
var s string = string(role)                          // UserRole → string
```

From `config.go`, see `strconv.Atoi` (string to integer):

```go
func envInt(key string, fallback int) int {
    if v := os.Getenv(key); v != "" {
        if n, err := strconv.Atoi(v); err == nil {
            return n
        }
    }
    return fallback
}
```

**Why this matters**: In Dart, implicit conversions can hide bugs. In Go, every conversion is visible and intentional in the source code. If you see `UserRole(someString)`, you know a conversion is happening. There's no silent coercion.

### 3.7 The `any` Type (formerly `interface{}`)

Go has a type called `any` (an alias for `interface{}`) that can hold any value — similar to Dart's `dynamic`:

```go
func paginatedResponse(data any, total int) map[string]any {
    return map[string]any{"data": data, "total": total}
}
```

Here, `data` can be a slice of users, a slice of profiles, or anything else. The `map[string]any` is a map from strings to any type — equivalent to `Map<String, dynamic>` in Dart.

**Use sparingly**: Reaching for `any` means you're losing type safety. It's appropriate for JSON-like structures and generic response envelopes (as shown above), but not for domain logic.

---

## 4. Structs — Go's Data Building Block

### 4.1 Structs Replace Classes

In Dart, you define classes with constructors, fields, methods, inheritance, and mixins. In Go, you have structs: plain data structures with fields. That's it. No constructors, no `this`, no inheritance.

From `internal/model/user.go`:

```go
type AppUser struct {
    UID         string    `json:"uid"`
    PhoneNumber string    `json:"phoneNumber"`
    DisplayName string    `json:"displayName"`
    PhotoURL    *string   `json:"photoUrl"`
    Role        UserRole  `json:"role"`
    AgencyID    *string   `json:"agencyId"`
    CreatedAt   time.Time `json:"createdAt"`
    IsActive    bool      `json:"isActive"`
}
```

This is the entire "User class." No constructor. No getters/setters. No `toString()`. Just fields.

**Creating instances**:

```go
// Named field initialization (most common, order doesn't matter)
user := &model.AppUser{
    UID:         uuid.NewString(),
    PhoneNumber: body.PhoneNumber,
    DisplayName: "",
    Role:        body.Role,
    CreatedAt:   time.Now(),
    IsActive:    true,
}

// Fields you don't list get their zero values:
// PhotoURL → nil, AgencyID → nil
```

**Compare to Dart**:
```dart
final user = AppUser(
  uid: Uuid().v4(),
  phoneNumber: body.phoneNumber,
  displayName: '',
  role: body.role,
  createdAt: DateTime.now(),
  isActive: true,
);
```

The key difference: In Dart, the constructor defines which fields are required. In Go, ALL fields are always "available" — it's up to your code to validate that required fields are set.

### 4.2 Struct Tags: Metadata for Serialization

Those backtick strings after each field are **struct tags** — metadata that doesn't affect the code's behavior but is read by libraries at runtime via reflection.

```go
type AppUser struct {
    UID         string    `json:"uid"`
    PhoneNumber string    `json:"phoneNumber"`
    DisplayName string    `json:"displayName"`
    PhotoURL    *string   `json:"photoUrl"`
    // ...
}
```

The `json:"uid"` tag tells the `encoding/json` package: "When marshaling this struct to JSON, use `uid` as the field name (not `UID`)."

**Common tag options**:

```go
type Example struct {
    Name     string  `json:"name"`             // field → "name" in JSON
    Age      int     `json:"age"`              // field → "age" in JSON
    Internal string  `json:"-"`                // SKIP this field entirely
    Address  string  `json:"address,omitempty"` // omit if zero value
    Score    *int    `json:"score,omitempty"`   // omit if nil
}
```

- `json:"fieldName"` — the JSON key name
- `json:"-"` — never include in JSON output
- `json:",omitempty"` — omit the field if it has its zero value

**In this project**, look at `CandidateProfile`:

```go
DateOfBirth   *time.Time `json:"dateOfBirth,omitempty"`
AnnualIncome  *string    `json:"annualIncome,omitempty"`
```

The `omitempty` combined with pointer types means: if the user hasn't provided a date of birth, the JSON response won't include a `"dateOfBirth": null` field at all — it will be completely absent. This is a common API design choice to keep responses clean.

**Why this matters**: In Dart with `json_serializable`, you use annotations like `@JsonKey(name: 'phoneNumber')`. In Go, struct tags serve the same purpose but are built into the language syntax. You'll also see tags for database ORMs (`db:"column_name"`), validation (`validate:"required,email"`), and more.

### 4.3 Exported vs Unexported: Go's Visibility Model

In Dart, you prefix private members with `_`:
```dart
class _PrivateClass {}
String _privateField = "hidden";
```

In Go, visibility is controlled by **capitalization**:
- **Uppercase first letter** = exported (public) — visible outside the package
- **Lowercase first letter** = unexported (private) — only visible within the same package

```go
// In package model:
type AppUser struct {     // AppUser — exported, visible to other packages
    UID string            // UID — exported field
    PhoneNumber string    // PhoneNumber — exported
}

// In package inmem:
type UserRepo struct {     // UserRepo — exported (handler package can use it)
    mu     sync.RWMutex   // mu — unexported (only inmem package can access)
    byID   map[string]*model.AppUser   // byID — unexported
    byPhone map[string]string           // byPhone — unexported
}
```

**Critical understanding**: Unexported doesn't mean "per-instance private" like in Dart/Java. It means "per-package private." ALL files in the `inmem` package can access `byID` and `byPhone`. The boundary is the package, not the struct.

From `inmem/auth_repo.go`:

```go
type otpSession struct {    // unexported struct — only used within inmem package
    phone     string        // unexported fields
    role      model.UserRole
    code      string
    expiresAt time.Time
    used      bool
}

type AuthRepo struct {      // exported struct — used by other packages
    mu       sync.RWMutex  // unexported fields — implementation detail
    sessions map[string]*otpSession
    isDev    bool
}
```

The `otpSession` type is lowercase, so code outside the `inmem` package cannot even reference it. It's a private implementation detail. The `AuthRepo` type is uppercase, so the `service` package can reference it, but the internal fields (`mu`, `sessions`, `isDev`) are lowercase so they're hidden.

### 4.4 Struct Embedding (Go's Composition)

Instead of inheritance, Go uses embedding to compose types:

From `middleware.go`:

```go
type statusWriter struct {
    http.ResponseWriter  // embedded interface
    status int
}

func (w *statusWriter) WriteHeader(status int) {
    w.status = status
    w.ResponseWriter.WriteHeader(status)
}
```

**What embedding does**:
1. `statusWriter` now has all methods of `http.ResponseWriter` automatically
2. You can call `wrapped.Header()`, `wrapped.Write()` etc. directly (they're promoted)
3. `statusWriter` satisfies the `http.ResponseWriter` interface without explicit declaration
4. You can override specific methods (like `WriteHeader`) while delegating others

**Why this is used here**: The `Logger` middleware needs to know what HTTP status code was written. But `http.ResponseWriter` doesn't expose the status after `WriteHeader()` is called. So we wrap it with `statusWriter` that intercepts `WriteHeader()`, saves the status, and forwards the call to the real writer.

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

**In Dart**, you'd probably use a decorator pattern or mixin. In Go, embedding achieves the same result with less boilerplate and no explicit interface declaration.

### 4.5 The Constructor Pattern: `New*` Functions

Go doesn't have constructors. Instead, the convention is to provide a `New*` function:

From `inmem/user_repo.go`:

```go
func NewUserRepo() *UserRepo {
    return &UserRepo{
        byID:    make(map[string]*model.AppUser),
        byPhone: make(map[string]string),
    }
}
```

From `inmem/auth_repo.go`:

```go
func NewAuthRepo(isDev bool) *AuthRepo {
    return &AuthRepo{
        sessions: make(map[string]*otpSession),
        isDev:    isDev,
    }
}
```

**Why `New*` functions exist**:
1. Maps and channels must be initialized with `make()` before use (a nil map panics on write)
2. You might want to validate parameters
3. You might want to set up goroutines, timers, or other side effects
4. It makes the API clearer — callers know they get a ready-to-use value

**When to skip `New*`**: If a struct's zero value is useful as-is, don't bother with a constructor. For example, `sync.Mutex` works with its zero value — no constructor needed.

**Why `New*` returns a pointer**: Returning `*UserRepo` (pointer) means all callers share the same instance. If you returned `UserRepo` (value), each caller would get a copy, and mutations would be isolated. Since a repository is a shared stateful object, a pointer is correct.

### 4.6 Value Receivers vs Pointer Receivers

Methods in Go have a "receiver" — the type the method is attached to:

```go
// Value receiver — works on a COPY of the UserRole
func (r UserRole) IsValid() bool {
    switch r {
    case RoleParent, RoleBroker, RoleCandidate, RoleAgencyAdmin:
        return true
    }
    return false
}

// Pointer receiver — works on the ACTUAL UserRepo instance
func (r *UserRepo) Create(_ context.Context, user *model.AppUser) error {
    r.mu.Lock()
    defer r.mu.Unlock()
    // ... modifies r.byID directly
}
```

**The rules**:

| Use pointer receiver `(r *Type)` when... | Use value receiver `(r Type)` when... |
|------------------------------------------|---------------------------------------|
| The method modifies the receiver | The method only reads, doesn't modify |
| The struct is large (avoid copying) | The struct is small (like UserRole — just a string) |
| The struct contains a `sync.Mutex` | The type is a basic type wrapper |
| Consistency — if any method needs a pointer receiver, use it for all | |

**In this project**:
- `UserRole.IsValid()` uses a value receiver — it just reads the role string, doesn't modify anything
- `UserRepo.Create()` uses a pointer receiver — it modifies the internal map
- `statusWriter.WriteHeader()` uses a pointer receiver — it modifies the status field
- `APIError.Error()` uses a pointer receiver — by convention, since `ErrNotFound` etc. are pointers

**Why this matters**: If you use a value receiver on a method that tries to modify the struct, the modification is lost (it modified a copy). This is a common beginner bug:

```go
// BUG: this modifies a copy, not the original
func (w statusWriter) WriteHeader(status int) {
    w.status = status  // lost! w is a copy
}

// CORRECT: pointer receiver modifies the original
func (w *statusWriter) WriteHeader(status int) {
    w.status = status  // modifies the actual statusWriter
}
```

### 4.7 Methods vs Functions

In Dart, methods belong to classes. In Go, methods belong to types — and any named type can have methods:

```go
// Method on a struct
func (r *UserRepo) GetByID(ctx context.Context, id string) (*model.AppUser, error) { ... }

// Method on a custom type (not a struct!)
func (r UserRole) IsValid() bool { ... }

// Regular function (no receiver)
func NewUserRepo() *UserRepo { ... }
```

You cannot add methods to types you don't own. You can't add a method to `string` or `int`. But you CAN create a new type and add methods to it:

```go
type contextKey string  // new type based on string

const userClaimsKey contextKey = "user_claims"
// Now contextKey has its own type identity, distinct from string
```

---

## 5. Slices, Maps & the `make` Function

### 5.1 Slices: Go's Dynamic Arrays

In Dart, you use `List<T>`. In Go, you use slices (`[]T`). A slice is a dynamically-sized view into an underlying array.

**Declaration and initialization**:

```go
// nil slice (length 0, capacity 0, equal to nil)
var names []string

// Empty slice (length 0, capacity 0, NOT nil)
names := []string{}

// Slice with initial values
names := []string{"Alice", "Bob", "Charlie"}

// make — pre-allocate capacity for performance
// make([]T, length, capacity)
all := make([]*model.AppUser, 0, len(r.byID))
```

From `inmem/user_repo.go`:

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

Let's break down `make([]*model.AppUser, 0, len(r.byID))`:
- `[]*model.AppUser` — a slice of pointers to AppUser structs
- `0` — initial length (the slice starts empty)
- `len(r.byID)` — initial capacity (pre-allocate enough memory for all users)

**Why pre-allocate capacity?**: If you just use `var all []*model.AppUser` and append in a loop, Go will reallocate the underlying array multiple times as it grows (doubling strategy). Pre-allocating avoids these expensive reallocations.

### 5.2 nil Slices vs Empty Slices

This subtlety trips up Go beginners:

```go
var s []int     // nil slice — s == nil is true
s := []int{}    // empty slice — s == nil is false
s := make([]int, 0)  // empty slice — s == nil is false
```

But functionally they're almost identical:
- Both have `len(s) == 0`
- Both work with `append(s, 1)`
- Both work with `for range s`

**When the difference matters**: JSON serialization.
- nil slice → `"field": null`
- empty slice → `"field": []`

In this project, when a profile has no photos:
```go
Photos: []string{}  // serializes as "photos": [] — better for the Flutter client
```

If it were `nil`, the JSON would have `"photos": null` and your Dart `List.from(json['photos'])` would throw.

### 5.3 The Append Pattern

`append` is how you add elements to a slice:

```go
all = append(all, &cp)
```

**Critical**: `append` may return a NEW slice (if the underlying array needed to grow). You MUST use the return value:

```go
// CORRECT
all = append(all, item)

// BUG — discards the potentially new slice
append(all, item)  // compiler will actually error on this (unused result)
```

From `profile_handlers.go`, notice the `BrokerIDs` initialization:

```go
if len(profile.BrokerIDs) == 0 {
    profile.BrokerIDs = []string{claims.UserID}
}
```

### 5.4 Maps: Go's Hash Tables

In Dart, you use `Map<K, V>`. In Go, you use `map[K]V`.

**Declaration and initialization**:

```go
// nil map (can read — returns zero values; CANNOT write — panics!)
var m map[string]*model.AppUser

// Initialized map (can read AND write)
m := make(map[string]*model.AppUser)

// Map with initial values
m := map[string]int{
    "alice": 1,
    "bob":   2,
}
```

From `inmem/user_repo.go`:

```go
type UserRepo struct {
    mu      sync.RWMutex
    byID    map[string]*model.AppUser    // UID → user
    byPhone map[string]string            // phone → UID (index for lookup)
}

func NewUserRepo() *UserRepo {
    return &UserRepo{
        byID:    make(map[string]*model.AppUser),
        byPhone: make(map[string]string),
    }
}
```

**Why `make` is required**: A nil map panics on write. This is one of the most common Go bugs:

```go
var m map[string]int
m["key"] = 1  // PANIC: assignment to entry in nil map
```

Always initialize maps with `make()` or a literal `{}` before writing.

### 5.5 The Comma-OK Idiom

Reading from a map returns two values: the value and a boolean indicating if the key existed:

```go
func (r *UserRepo) GetByID(_ context.Context, id string) (*model.AppUser, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    u, ok := r.byID[id]
    if !ok {
        return nil, model.NotFoundError("User", id)
    }
    cp := *u
    return &cp, nil
}
```

**`u, ok := r.byID[id]`** — This is the comma-ok idiom:
- `u` is the value (will be `nil` if key doesn't exist, since values are `*model.AppUser`)
- `ok` is `true` if the key exists, `false` otherwise

**Why you need the second value**: Without `ok`, you can't distinguish between "key exists with zero value" and "key doesn't exist":

```go
m := map[string]int{"zero": 0}

v := m["zero"]       // v = 0
v := m["missing"]    // v = 0 — same! Can't tell the difference!

v, ok := m["zero"]    // v = 0, ok = true — key exists
v, ok := m["missing"] // v = 0, ok = false — key doesn't exist
```

**In this project**, the comma-ok idiom is used extensively for checking existence:

```go
// Check if user already exists before creating
if _, ok := r.byID[user.UID]; ok {
    return model.ConflictError("user already exists")
}

// Check if phone is already registered to a different user
if uid, ok := r.byPhone[user.PhoneNumber]; ok && uid != user.UID {
    return model.ConflictError("phone number already registered")
}
```

### 5.6 Range Loops

The `range` keyword iterates over slices, maps, strings, and channels:

```go
// Iterating over a map (key-value pairs)
for _, u := range r.byID {
    cp := *u
    all = append(all, &cp)
}

// Iterating over a slice (index-value pairs)
for _, id := range p.BrokerIDs {
    if id == userID {
        return true
    }
}

// Iterating over allowedOrigins slice
for _, o := range allowedOrigins {
    if o == "*" || o == origin {
        allowed = true
        break
    }
}
```

**Map iteration order is random**: Unlike Dart's `LinkedHashMap`, Go maps have no guaranteed iteration order. Each time you range over a map, the order may be different. This is intentional — it prevents code from accidentally depending on insertion order.

### 5.7 Slicing: Sub-slices

From `inmem/helpers.go`:

```go
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

`items[p.Offset:end]` creates a sub-slice without copying. It's a window into the same underlying array. This is efficient but means modifications to the sub-slice affect the original.

Slice syntax:
- `s[low:high]` — elements from `low` to `high-1`
- `s[:high]` — from start to `high-1`
- `s[low:]` — from `low` to end
- `s[:]` — entire slice (useful for converting arrays to slices)

### 5.8 Copying: Why the Project Copies Values

Notice this pattern throughout the project:

```go
func (r *UserRepo) GetByID(_ context.Context, id string) (*model.AppUser, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    u, ok := r.byID[id]
    if !ok {
        return nil, model.NotFoundError("User", id)
    }
    cp := *u      // dereference pointer → copy the struct
    return &cp, nil  // return pointer to the copy
}
```

**Why `cp := *u` then `return &cp`?** This creates a defensive copy. Without it, the caller would receive a pointer directly into the repository's internal map. If the caller modifies the user (e.g., changes the display name), it would mutate the repository's data without going through the `Update()` method, bypassing validation and locking.

This is the Go equivalent of returning an immutable copy in Dart:
```dart
// Dart equivalent concept
AppUser getById(String id) {
  return _users[id]!.copyWith(); // return a copy
}
```

---

## 6. Functions & Multiple Return Values

### 6.1 The Error Pattern: Multiple Return Values

Go's most distinctive feature for Dart developers is that functions can return multiple values. This is used pervasively for error handling:

```go
func (r *UserRepo) GetByID(_ context.Context, id string) (*model.AppUser, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    u, ok := r.byID[id]
    if !ok {
        return nil, model.NotFoundError("User", id)
    }
    cp := *u
    return &cp, nil
}
```

The return type `(*model.AppUser, error)` means: this function returns either (user, nil) on success or (nil, error) on failure.

**Callers MUST check the error**:

```go
user, err := svc.Users.GetByPhone(r.Context(), body.PhoneNumber)
if err != nil {
    // handle error
    writeRepoError(w, err)
    return
}
// use user safely here
```

**Compare to Dart**:
```dart
// Dart — exception can fly from anywhere
try {
  final user = await userRepo.getByPhone(phone);
} catch (e) {
  // handle
}
```

In Go, the error is a value you handle in normal control flow. There's no hidden exception that can jump across function boundaries.

### 6.2 Three-Value Returns

Some functions return three values. From the repository interface:

```go
type UserRepository interface {
    List(ctx context.Context, p Pagination) ([]*model.AppUser, int, error)
}
```

This returns `(data, totalCount, error)`:

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

The caller unpacks all three:

```go
data, total, err := svc.ParentProfiles.List(r.Context(), parsePagination(r))
if err != nil {
    writeRepoError(w, err)
    return
}
writeJSON(w, http.StatusOK, paginatedResponse(data, total))
```

### 6.3 Named Return Values

Go allows naming return values, which pre-declares them as local variables:

```go
// From the AuthRepository interface
SendOTP(ctx context.Context, phone string, role model.UserRole) (sessionID string, err error)
```

Named returns serve as documentation — you can see at a glance that `SendOTP` returns a `sessionID` string and an `err`.

**Naked returns** (returning without specifying values) are possible with named returns but are generally avoided for clarity:

```go
// Avoid this in production code — hard to read
func divide(a, b float64) (result float64, err error) {
    if b == 0 {
        err = errors.New("division by zero")
        return  // returns result=0.0, err=<the error>
    }
    result = a / b
    return  // returns result=<answer>, err=nil
}
```

**In this project**, named returns are used in interfaces for documentation but not for naked returns in implementations.

### 6.4 Variadic Functions

A variadic function accepts a variable number of arguments of the same type:

From `middleware.go`:

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

`middlewares ...Middleware` means: accept zero or more `Middleware` values. Inside the function, `middlewares` is a slice (`[]Middleware`).

**Called like**:

```go
stack := middleware.Chain(
    middleware.Logger,
    middleware.CORS(cfg.AllowedOrigins),
    middleware.Recoverer,
)
```

**Dart equivalent**:
```dart
// Dart doesn't have true variadics, you'd use a List
Middleware chain(List<Middleware> middlewares) { ... }
```

### 6.5 First-Class Functions

Functions are values in Go. You can assign them to variables, pass them as arguments, and return them from other functions.

From `middleware.go`:

```go
type Middleware func(http.Handler) http.Handler
```

This declares a **function type**: `Middleware` is any function that takes an `http.Handler` and returns an `http.Handler`. This is the decorator pattern expressed as a type.

**Functions as values**:

```go
// Logger is a function value — no () means we're not calling it, just referencing it
middleware.Logger    // type: func(http.Handler) http.Handler

// CORS returns a function — it's a function that produces a function
middleware.CORS(cfg.AllowedOrigins)  // returns: func(http.Handler) http.Handler
```

From `handler/routes.go`:

```go
mux.HandleFunc("POST /api/v1/auth/send-otp", handleSendOTP)
```

`handleSendOTP` is passed as a value (note: no parentheses — we're not calling it, we're passing it). The mux will call it later when a matching request arrives.

**In Dart**, this is similar to passing functions around:
```dart
// Dart
void registerRoute(String path, Function(Request) handler) { ... }
registerRoute('/api/auth', handleAuth);  // passing function reference
```

### 6.6 Closures

A closure is a function that captures variables from its enclosing scope. This is exactly like Dart closures.

From `middleware.go` — the CORS middleware:

```go
func CORS(allowedOrigins []string) Middleware {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            origin := r.Header.Get("Origin")
            allowed := false
            for _, o := range allowedOrigins {  // ← captures allowedOrigins from outer scope
                if o == "*" || o == origin {
                    allowed = true
                    break
                }
            }
            if allowed {
                w.Header().Set("Access-Control-Allow-Origin", origin)
            }
            // ...
            next.ServeHTTP(w, r)
        })
    }
}
```

**The structure**:
1. `CORS` is called once at startup with `cfg.AllowedOrigins`
2. It returns a `Middleware` function (the outer closure)
3. That middleware wraps a handler with another function (the inner closure)
4. The inner function captures `allowedOrigins` — it "remembers" the origins even though `CORS()` has long since returned

**This is three levels of nesting**:
```
CORS(allowedOrigins) → returns Middleware
  └─ Middleware(next) → returns http.Handler
       └─ http.HandlerFunc(w, r) → handles the actual request
```

**Why this pattern**: It separates configuration (what origins are allowed) from execution (checking each request). The `CORS` function is called once during setup. The inner function is called for every HTTP request but already "knows" which origins are allowed.

From `middleware.go` — the Auth middleware shows the same pattern:

```go
func Auth(jwtSecret string) Middleware {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            // jwtSecret is captured from the outer scope
            claims, err := ValidateJWT(token, jwtSecret)
            // ...
        })
    }
}
```

### 6.7 Anonymous Structs in Function Bodies

Go allows declaring structs inline without a name. This is used for one-off JSON parsing:

From `auth_handlers.go`:

```go
func handleSendOTP(w http.ResponseWriter, r *http.Request) {
    var body struct {
        PhoneNumber string         `json:"phoneNumber"`
        Role        model.UserRole `json:"role"`
    }
    if err := decodeJSON(r, &body); err != nil {
        writeError(w, http.StatusBadRequest, model.ValidationError("invalid JSON body"))
        return
    }
    // use body.PhoneNumber, body.Role
}
```

**Why anonymous structs**: This request body structure is only used in this one handler. Creating a named type in the model package would pollute the namespace for something used exactly once. The anonymous struct is defined, used, and forgotten.

**Dart equivalent**:
```dart
// In Dart, you'd probably just use a Map
final body = jsonDecode(request.body) as Map<String, dynamic>;
final phone = body['phoneNumber'] as String;
```

Go's approach is more type-safe — the struct ensures you get the exact fields you expect with the right types.

### 6.8 Defer: Guaranteed Cleanup

`defer` schedules a function call to run when the enclosing function returns:

```go
func (r *UserRepo) Create(_ context.Context, user *model.AppUser) error {
    r.mu.Lock()
    defer r.mu.Unlock()   // guaranteed to run when Create returns
    // ... even if panic occurs
}
```

**Key properties of defer**:
1. **Guaranteed execution** — runs even if the function panics
2. **LIFO order** — if you have multiple defers, they run in reverse order (last deferred = first executed)
3. **Arguments evaluated immediately** — `defer fmt.Println(x)` captures the current value of `x`

From `handler/helpers.go`:

```go
func decodeJSON(r *http.Request, v any) error {
    defer r.Body.Close()  // always close the body, regardless of decode success/failure
    return json.NewDecoder(r.Body).Decode(v)
}
```

From `middleware.go` — the Recoverer middleware uses defer for panic recovery:

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

**Why defer is important**: In Dart, you use `try/finally`:
```dart
try {
  mutex.lock();
  // do work
} finally {
  mutex.unlock();
}
```

In Go, `defer` is cleaner because the unlock is declared right next to the lock — you can see at a glance that the lock will be released:
```go
r.mu.Lock()
defer r.mu.Unlock()
// ... any amount of code, any number of return paths ...
// mu.Unlock() WILL be called no matter what
```

### 6.9 `http.HandlerFunc` — A Function Type That Implements an Interface

This pattern is uniquely Go and worth understanding deeply:

```go
// In the standard library:
type Handler interface {
    ServeHTTP(ResponseWriter, *Request)
}

type HandlerFunc func(ResponseWriter, *Request)

func (f HandlerFunc) ServeHTTP(w ResponseWriter, r *Request) {
    f(w, r)
}
```

`HandlerFunc` is a function type that implements the `Handler` interface. This means any plain function with the right signature can be used as an `http.Handler`:

```go
// This is a function:
func handleSendOTP(w http.ResponseWriter, r *http.Request) { ... }

// Wrapping it makes it implement the Handler interface:
http.HandlerFunc(handleSendOTP)

// Now it can be passed to anything expecting Handler:
mux.Handle("POST /api/v1/auth/send-otp", auth(http.HandlerFunc(handleSendOTP)))
```

This adapter pattern is extremely common in Go — it lets you use simple functions where interfaces are expected.

---

## 7. Error Handling — Go's Defining Feature

### 7.1 No Exceptions. No try/catch. Errors Are Values.

This is the single biggest mental shift from Dart to Go. Let it sink in:

**In Dart**, errors are exceptional events that interrupt normal control flow:
```dart
try {
  final user = await repo.getUser(id);
  print(user.name);
} on NotFoundException catch (e) {
  print('Not found: $e');
} catch (e) {
  print('Unknown error: $e');
}
```

**In Go**, errors are ordinary values returned from functions:
```go
user, err := repo.GetByID(ctx, id)
if err != nil {
    // handle the error — it's just a value
    return
}
// use user
```

**Why Go chose this approach**:
1. **Explicitness**: You can see every error path by reading the code linearly
2. **No hidden control flow**: In Dart/Java, an exception can jump up the call stack to a catch block 10 frames up. In Go, errors flow upward explicitly.
3. **Compiler enforcement**: If a function returns `error`, you MUST handle it (or explicitly ignore it with `_`)
4. **Composability**: Errors are values, so you can store them in slices, pass them to functions, combine them, wrap them — all with normal Go code

### 7.2 The `error` Interface

The `error` type is Go's simplest interface:

```go
type error interface {
    Error() string
}
```

Any type that has an `Error() string` method satisfies this interface. That's it. No base class, no exception hierarchy, no stack traces by default.

### 7.3 Custom Error Types: `APIError`

From `internal/model/errors.go`:

```go
type APIError struct {
    Code    string `json:"code"`
    Message string `json:"message"`
}

func (e *APIError) Error() string {
    return fmt.Sprintf("%s: %s", e.Code, e.Message)
}
```

`APIError` implements the `error` interface (it has `Error() string`), but it carries extra information: a machine-readable `Code` and a human-readable `Message`. The struct tags mean it serializes cleanly to JSON for the Flutter client.

**Why a custom error type?** The standard `errors.New("not found")` gives you a plain string error. But your HTTP handler needs to know:
1. What HTTP status code to send (404, 400, 403, etc.)
2. What machine-readable code the client can match on
3. What message to show the user

The `APIError` carries all this context.

### 7.4 Sentinel Errors: Pre-Defined Error Values

From `errors.go`:

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

These are **sentinel errors** — package-level variables that represent specific error conditions. They're like Dart's `StateError`, `ArgumentError`, etc. but as values, not classes.

**Usage**:

```go
// Returning a sentinel error
if s.used {
    return false, model.ErrInvalidOTP
}

// Using in handlers
writeError(w, http.StatusForbidden, model.ErrForbidden)
```

### 7.5 Error Factory Functions

Sometimes you need dynamic error messages. The project uses factory functions:

```go
func NotFoundError(entityType, id string) *APIError {
    return &APIError{
        Code:    "NOT_FOUND",
        Message: fmt.Sprintf("%s %s not found", entityType, id),
    }
}

func ConflictError(msg string) *APIError {
    return &APIError{
        Code:    "CONFLICT",
        Message: msg,
    }
}

func ValidationError(msg string) *APIError {
    return &APIError{
        Code:    "VALIDATION_ERROR",
        Message: msg,
    }
}
```

**Usage in repositories**:

```go
if _, ok := r.byID[user.UID]; ok {
    return model.ConflictError("user already exists")
}

if uid, ok := r.byPhone[user.PhoneNumber]; ok && uid != user.UID {
    return model.ConflictError("phone number already registered")
}
```

**Why factory functions?** Sentinel errors have fixed messages. Factory functions let you create errors with contextual details while keeping the same error code. The handler can still match on the code to determine the HTTP status.

### 7.6 Error Unwrapping with `errors.As`

From `handler.go`:

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

**`errors.As(err, &apiErr)`** does two things:
1. Checks if `err` (or any error it wraps) is of type `*model.APIError`
2. If yes, sets `apiErr` to that value and returns `true`

This is Go's equivalent of Dart's `catch (e) { if (e is APIError) ... }`.

**Why `errors.As` instead of type assertion?** Because errors can be wrapped. If you wrap an error with `fmt.Errorf("context: %w", err)`, the outer error is a different type but contains the original. `errors.As` unwraps through the chain to find the target type.

### 7.7 The `if err != nil` Pattern

You'll write this hundreds of times:

```go
user, err := svc.Users.GetByPhone(r.Context(), body.PhoneNumber)
if err != nil {
    var apiErr *model.APIError
    if !errors.As(err, &apiErr) || apiErr.Code != "NOT_FOUND" {
        writeRepoError(w, err)
        return
    }
    // user not found — create new user
    user = &model.AppUser{
        UID:         uuid.NewString(),
        PhoneNumber: body.PhoneNumber,
        // ...
    }
    if err := svc.Users.Create(r.Context(), user); err != nil {
        writeRepoError(w, err)
        return
    }
}
```

**Why `if err != nil` is good**:

1. **Visible error paths**: You can scan a function and instantly see every place it can fail
2. **Early returns**: Each error check immediately returns, keeping the "happy path" at the left margin
3. **No surprise exceptions**: You'll never have a function blow up on line 50 because of an unhandled exception from line 10
4. **Forces you to think**: Every function call that can fail forces you to decide: handle it, wrap it and pass it up, or explicitly ignore it

**The counterargument** (and why some people dislike Go): It's verbose. The same function in Dart might be 10 lines instead of 30. Go chose explicitness over brevity.

### 7.8 Error Handling Patterns in the Handler Layer

The Anuyatra project shows a clean pattern for HTTP handlers:

```go
func handleGetMyParentProfile(w http.ResponseWriter, r *http.Request) {
    // Step 1: Authenticate
    claims, ok := requireClaims(w, r)
    if !ok {
        return  // requireClaims already wrote the error response
    }

    // Step 2: Business logic (repository call)
    p, err := svc.ParentProfiles.GetByUserID(r.Context(), claims.UserID)
    if err != nil {
        writeRepoError(w, err)  // maps error to HTTP status
        return
    }

    // Step 3: Success response
    writeJSON(w, http.StatusOK, p)
}
```

Every handler follows this structure:
1. Validate auth/input
2. Call repository/service
3. Handle error or return success

The `writeRepoError` helper centralizes error-to-HTTP-status mapping so every handler doesn't need a switch statement.

### 7.9 Panic and Recover

Go does have a mechanism for truly exceptional situations: `panic` and `recover`. But these are NOT for normal error handling — they're for programmer bugs (like accessing a nil pointer, index out of bounds) or irrecoverable situations.

From `middleware.go`:

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

**The rule**: Use `panic` only for programming errors. Use `error` returns for expected failure cases (user not found, validation failed, etc.). The `Recoverer` middleware is a safety net — it catches panics so one bad request doesn't crash the entire server.

---

## 8. Control Flow

### 8.1 If/Else with Initialization

Go's `if` has a unique feature: you can declare a variable in the condition that's scoped to the if/else block:

From `config.go`:

```go
func envStr(key, fallback string) string {
    if v := os.Getenv(key); v != "" {
        return v
    }
    return fallback
}
```

`if v := os.Getenv(key); v != "" {` declares `v`, assigns the result of `os.Getenv(key)`, then checks if `v != ""`. The variable `v` only exists within this if/else block.

**Compare to Dart**:
```dart
String envStr(String key, String fallback) {
  final v = Platform.environment[key];
  if (v != null && v.isNotEmpty) return v;
  return fallback;
}
```

In Go, the scoping is tighter — `v` doesn't leak into the rest of the function.

**This pattern is everywhere in the project**:

```go
// From helpers.go — parse query parameter
if v := r.URL.Query().Get("limit"); v != "" {
    if n, err := strconv.Atoi(v); err == nil && n > 0 && n <= 100 {
        p.Limit = n
    }
}

// From config.go — parse integer environment variable
if v := os.Getenv(key); v != "" {
    if n, err := strconv.Atoi(v); err == nil {
        return n
    }
}
```

### 8.2 Switch Without Break

In Dart/Java/C, switch cases fall through by default (you need `break`). In Go, it's the opposite: **cases do NOT fall through by default**.

From `handler.go`:

```go
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
```

Notice:
- No `break` statements — each case is independent
- Multiple values in one case: `"INVALID_OTP", "SESSION_NOT_FOUND"` (instead of fall-through)
- If you DO want fall-through (rare), use the `fallthrough` keyword explicitly

From `model/user.go` — switch with no expression (acts like if/else chain):

```go
func (r UserRole) IsValid() bool {
    switch r {
    case RoleParent, RoleBroker, RoleCandidate, RoleAgencyAdmin:
        return true
    }
    return false
}
```

### 8.3 Switch with No Expression (Boolean Switch)

You can use `switch` without an expression — each case is evaluated as a boolean:

```go
switch {
case age < 18:
    category = "minor"
case age < 65:
    category = "adult"
default:
    category = "senior"
}
```

This is equivalent to an if/else if/else chain but is more readable when there are many conditions.

### 8.4 Type Switch

Go can switch on the dynamic type of an interface value:

```go
func describe(i interface{}) string {
    switch v := i.(type) {
    case string:
        return "string: " + v
    case int:
        return fmt.Sprintf("int: %d", v)
    case *model.APIError:
        return "API error: " + v.Code
    default:
        return "unknown"
    }
}
```

**In this project**, this pattern appears implicitly in how `errors.As` works — it performs type matching on the error chain. The JWT validation also uses it:

```go
// From jwt.go
claims, ok := token.Claims.(jwt.MapClaims)
```

This is a **type assertion**: "I believe `token.Claims` is actually a `jwt.MapClaims` — give it to me as that type." The `ok` will be `false` if it's not.

### 8.5 For: The Only Loop

Go has only one loop keyword: `for`. But it covers every looping need:

**Infinite loop** (like Dart's `while(true)`):
```go
for {
    // runs forever until break or return
}
```

**Condition loop** (like Dart's `while`):
```go
for i < n {
    i++
}
```

**Classic three-part loop** (like Dart's `for`):
```go
for i := 0; i < n; i++ {
    fmt.Println(i)
}
```

**Range loop over slice**:
```go
for i, user := range users {
    fmt.Printf("User %d: %s\n", i, user.Name)
}
```

**Range loop over map**:
```go
for key, value := range myMap {
    fmt.Printf("%s: %v\n", key, value)
}
```

**Range loop over string** (iterates over Unicode runes, not bytes):
```go
for i, ch := range "Hello, 世界" {
    fmt.Printf("index %d: %c\n", i, ch)
}
```

**Range loop over channel** (blocks until channel closes):
```go
for msg := range messageChan {
    process(msg)
}
```

**In this project**, you'll see range loops constantly:

```go
// Iterating over all users in the map
for _, u := range r.byID {
    cp := *u
    all = append(all, &cp)
}

// Iterating backwards through middleware stack
for i := len(middlewares) - 1; i >= 0; i-- {
    next = middlewares[i](next)
}

// Iterating over allowed origins
for _, o := range allowedOrigins {
    if o == "*" || o == origin {
        allowed = true
        break
    }
}

// Iterating over broker IDs
for _, id := range p.BrokerIDs {
    if id == userID {
        return true
    }
}
```

### 8.6 Break, Continue, and Labels

`break` exits the innermost loop. `continue` skips to the next iteration:

```go
for _, o := range allowedOrigins {
    if o == "*" || o == origin {
        allowed = true
        break  // found a match, stop looking
    }
}
```

For nested loops, you can use labels:

```go
outer:
for _, user := range users {
    for _, tag := range user.SearchTags {
        if tag == searchTerm {
            results = append(results, user)
            continue outer  // found match, move to next user
        }
    }
}
```

### 8.7 No While, No Do-While

If you miss Dart's `while`:
```dart
while (condition) { ... }      // Dart
```

In Go:
```go
for condition { ... }           // Go — same semantics
```

If you miss `do-while`:
```dart
do { ... } while (condition);   // Dart
```

In Go:
```go
for {
    // ... do work ...
    if !condition {
        break
    }
}
```

---

## 9. The Blank Identifier `_`

### 9.1 What Is `_`?

The blank identifier `_` is Go's way of explicitly discarding a value. Go's compiler requires that every declared variable be used. If a function returns a value you don't need, you MUST assign it to `_`.

**In Dart**, you can just ignore return values:
```dart
myList.remove(item);  // returns bool, you ignore it — no error
```

**In Go**, unused variables are compile errors:
```go
value, err := someFunc()
// If you don't use `value`, the compiler refuses to compile!
```

### 9.2 Discarding Values in Range Loops

From throughout the project:

```go
// Don't need the map key, just the value
for _, u := range r.byID {
    cp := *u
    all = append(all, &cp)
}

// Don't need the index, just the value
for _, o := range allowedOrigins {
    if o == "*" || o == origin {
        allowed = true
        break
    }
}

// Don't need the value, just the key (checking existence)
for _, id := range p.BrokerIDs {
    if id == userID {
        return true
    }
}
```

**Why `_` exists**: Go's philosophy is "if you declare it, you must use it." This catches bugs where you declare a variable intending to use it but forget. The `_` is your way of telling the compiler "I acknowledge this value exists but intentionally don't need it."

### 9.3 Discarding Context Parameters

From `inmem/user_repo.go`:

```go
func (r *UserRepo) Create(_ context.Context, user *model.AppUser) error {
    r.mu.Lock()
    defer r.mu.Unlock()
    // ...
}

func (r *UserRepo) GetByID(_ context.Context, id string) (*model.AppUser, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    // ...
}
```

The `context.Context` parameter is named `_` because the in-memory implementation doesn't need it (there's nothing to cancel or timeout on). But the interface requires it:

```go
type UserRepository interface {
    Create(ctx context.Context, user *model.AppUser) error
    GetByID(ctx context.Context, id string) (*model.AppUser, error)
    // ...
}
```

**Why the interface requires context**: When you swap to a real database (PostgreSQL), the context will be used for query timeouts and cancellation. The in-memory implementation satisfies the same interface but discards the context since all operations are instant.

```go
// Future PostgreSQL implementation would use ctx:
func (r *PostgresUserRepo) GetByID(ctx context.Context, id string) (*model.AppUser, error) {
    row := r.db.QueryRowContext(ctx, "SELECT * FROM users WHERE id = $1", id)
    // ctx enables timeout/cancellation of the database query
}
```

### 9.4 Compile-Time Interface Checks

This is an advanced but important pattern:

```go
var _ repository.UserRepository = (*UserRepo)(nil)
```

This line declares a package-level variable (assigned to `_` so it's unused), attempting to assign a nil `*UserRepo` to the `repository.UserRepository` interface type. If `UserRepo` doesn't implement all methods of `UserRepository`, this line fails to compile.

**Breaking it down**:
- `var _` — declare a variable we'll never use (blank identifier)
- `repository.UserRepository` — the variable's type (the interface)
- `= (*UserRepo)(nil)` — assign a nil pointer of type `*UserRepo`

**Why this exists**: Go interfaces are satisfied implicitly (no `implements` keyword). You might accidentally forget to implement a method, and you'd only discover it when you try to use the type as the interface somewhere else in code. This line is a compile-time assertion: "Make sure UserRepo satisfies UserRepository NOW, at this exact location."

**In Dart**, this is explicit:
```dart
class UserRepoImpl implements UserRepository {
  // compiler forces you to implement all methods
}
```

In Go, without the compile-time check:
```go
type UserRepo struct { ... }
// Did I implement all 5 methods of UserRepository? Who knows until I try to use it!
```

With the check:
```go
var _ repository.UserRepository = (*UserRepo)(nil)
// COMPILE ERROR if any method is missing — caught immediately
```

### 9.5 Discarding Error Returns (Use With Caution)

Sometimes you intentionally ignore an error:

```go
_, _ = rand.Read(b)  // from auth_repo.go — crypto/rand.Read rarely fails
```

Or a return value:

```go
w.Write([]byte(`{"status":"ok"}`))  // ignoring the (int, error) return
```

In the second case, the linter might warn you. The `w.Write` call returns `(int, error)` but the Anuyatra project ignores it because: if writing to the response fails, the connection is already broken and there's nothing useful to do.

**Rule of thumb**: Only ignore errors when you've consciously decided that failure at that point is either impossible or inconsequential. When in doubt, check the error.

### 9.6 Import for Side Effects

One more use of `_` you'll encounter:

```go
import _ "net/http/pprof"
```

This imports a package purely for its `init()` side effects (in this case, registering profiling HTTP endpoints). The package is imported, its `init()` runs, but we don't use any of its exported names.

**The Anuyatra project doesn't use this pattern**, but you'll see it in projects that use database drivers:

```go
import _ "github.com/lib/pq"  // registers PostgreSQL driver with database/sql
```

---

## Summary: The Go Mental Model

After reading this chapter, here's the mental model to carry forward:

| Concept | Go Way |
|---------|--------|
| **Data** | Structs (not classes). No inheritance. Composition via embedding. |
| **Behavior** | Methods on types. Interfaces are implicit. |
| **Errors** | Return values. Check `if err != nil`. No exceptions. |
| **Visibility** | Uppercase = public, lowercase = private. Package is the boundary. |
| **Nullability** | Pointers for optional fields. Zero values for everything else. |
| **Collections** | Slices (dynamic arrays), maps (hash tables). `make` to initialize. |
| **Functions** | First-class values. Closures. Multiple returns. Defer for cleanup. |
| **Packages** | One per directory. `internal/` for private code. Import by path. |
| **Philosophy** | Simple, explicit, boring. One way to do things. Fast to read. |

---

## What's Next

In **Part 2: Interfaces, Concurrency & Patterns**, we'll cover:
- Interfaces in depth (the `repository.UserRepository` pattern)
- How Go's interface satisfaction works (structural typing vs nominal typing)
- Goroutines and channels (the graceful shutdown in `main.go`)
- The `sync` package (`sync.Mutex`, `sync.RWMutex`, `sync.WaitGroup`)
- Context propagation and cancellation
- Dependency injection without a framework (the `Container` pattern)
- Testing patterns in Go

---

## Quick Reference: Go vs Dart Cheat Sheet

```
┌─────────────────────────────────────────────────────────────────────┐
│  Dart                              │  Go                            │
├─────────────────────────────────────────────────────────────────────┤
│  class User { ... }                │  type User struct { ... }      │
│  String name;                      │  Name string                   │
│  String? photo;                    │  Photo *string                 │
│  final user = User(name: "Al");    │  user := User{Name: "Al"}     │
│  user.name                         │  user.Name                     │
│  void doThing() { ... }           │  func doThing() { ... }        │
│  Future<User> getUser()           │  func GetUser() (*User, error) │
│  try { } catch (e) { }            │  if err != nil { }             │
│  List<String>                      │  []string                      │
│  Map<String, int>                  │  map[string]int                │
│  enum Role { admin, user }         │  type Role string              │
│                                    │  const RoleAdmin Role = "admin"│
│  import 'package:foo/foo.dart';    │  import "github.com/foo/bar"   │
│  _privateField                     │  privateField (lowercase)      │
│  for (var x in list) { }          │  for _, x := range list { }    │
│  list.add(item)                    │  list = append(list, item)     │
│  map[key] ?? defaultValue          │  val, ok := map[key]           │
│  async/await                       │  goroutines + channels         │
│  print('hello')                    │  fmt.Println("hello")          │
│  null                              │  nil (pointers/interfaces only)│
└─────────────────────────────────────────────────────────────────────┘
```

---

## Exercises

Try these on the Anuyatra codebase to solidify your understanding:

1. **Read `internal/model/candidate_profile.go`** — identify all the custom types, explain why each optional field uses a pointer, and explain what `omitempty` does for the JSON output.

2. **Read `internal/inmem/user_repo.go`** — trace through the `Create` method and explain: Why does it copy the user (`cp := *user`)? What would happen without the copy? Why does it use `sync.RWMutex` instead of `sync.Mutex`?

3. **Read `internal/handler/auth_handlers.go`** — follow the `handleVerifyOTP` function and list every place an error can occur. For each, explain what happens next.

4. **Read `internal/middleware/middleware.go`** — explain the closure nesting in `CORS`. Why is `allowedOrigins` a parameter to `CORS()` rather than a package-level variable?

5. **Read `internal/config/config.go`** — explain the `envStr` function. Why does `if v := os.Getenv(key); v != ""` use the initialization form? What's the scope of `v`?
