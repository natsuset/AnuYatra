# Go Masterclass — Part 4: Concurrency, Testing & Production Patterns

> **Series**: Part 4 of 4 — The final installment.
> **Prerequisites**: Parts 1-3 (syntax, types, interfaces, structs, error handling, HTTP handlers).
> **What you'll learn**: Goroutines, channels, sync primitives, race conditions, testing, project
> structure best practices, production readiness, and advanced Go patterns — all grounded in the
> Anuyatra codebase you've been building.

---

## Table of Contents

1. [Goroutines — Lightweight Threads](#1-goroutines--lightweight-threads)
2. [Channels — Communication Between Goroutines](#2-channels--communication-between-goroutines)
3. [sync Package — Mutual Exclusion](#3-sync-package--mutual-exclusion)
4. [Race Conditions & Data Races](#4-race-conditions--data-races)
5. [Thread Safety Patterns in This Project](#5-thread-safety-patterns-in-this-project)
6. [Testing in Go](#6-testing-in-go)
7. [Project Structure Best Practices](#7-project-structure-best-practices)
8. [Production Readiness Checklist](#8-production-readiness-checklist)
9. [Common Go Gotchas](#9-common-go-gotchas-things-that-trip-everyone-up)
10. [Go vs Dart/Flutter — Side-by-Side Comparison](#10-go-vs-dartflutter--side-by-side-comparison)
11. [Go Standard Library Power Tools](#11-go-standard-library-power-tools)

---

## 1. Goroutines — Lightweight Threads

Concurrency is Go's defining superpower. While most languages bolt concurrency on as a library
feature, Go builds it into the language itself.

### What Is a Goroutine?

A goroutine is a function executing concurrently with other goroutines in the same address space.
You create one by putting the `go` keyword before a function call:

```go
go myFunction()           // named function
go func() { /* ... */ }() // anonymous function (note the trailing () to invoke it)
```

That's it. No thread pools to configure. No executor services. No async/await coloring. Just `go`.

### Goroutines Are NOT OS Threads

This is the most important thing to understand. Go's runtime includes a sophisticated scheduler
that multiplexes potentially thousands of goroutines onto a small number of OS threads (typically
equal to the number of CPU cores).

| Property | OS Thread | Goroutine |
|---|---|---|
| Stack size | ~1-8 MB (fixed) | ~2-8 KB (grows as needed) |
| Creation cost | Expensive (syscall) | Cheap (function call) |
| Context switch | Slow (kernel mode) | Fast (user space) |
| Typical count | Hundreds | Hundreds of thousands |
| Managed by | OS kernel | Go runtime scheduler |

The Go scheduler uses an M:N model:

- **G** = goroutine (the lightweight thread)
- **M** = machine (OS thread)
- **P** = processor (logical CPU, scheduling context)

The scheduler maps G's onto M's through P's. When a goroutine blocks (e.g., on I/O or a channel
operation), the scheduler moves other goroutines onto the available OS thread. No goroutine hogs
a thread.

### Goroutines in Our Codebase: The Server Startup

Look at `main.go` — the very first goroutine you encounter:

```go
go func() {
    log.Printf("Anuyatra API server starting on :%d (storage=in-memory)", cfg.Port)
    if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
        log.Fatalf("server error: %v", err)
    }
}()
```

**Why is the server launched in a goroutine?** Because `ListenAndServe()` blocks forever — it
sits in a loop accepting connections. If we called it directly in `main()`, the subsequent
signal-handling code would never execute. By launching it in a goroutine, `main()` continues
to the signal channel and waits there instead.

### The Invisible Goroutines: HTTP Request Handling

Here's something that isn't obvious from reading the code: **every incoming HTTP request is
handled in its own goroutine**. The standard library's `net/http` server does this automatically:

```go
// Inside net/http (simplified):
for {
    conn, err := listener.Accept()
    if err != nil { ... }
    go srv.serve(conn) // <-- each connection gets its own goroutine
}
```

This means that when your Anuyatra server has 100 concurrent users browsing profiles, there are
roughly 100 goroutines running simultaneously — each executing handler code, reading from
repositories, and writing JSON responses. This is exactly why thread safety matters for the
in-memory repositories.

### Goroutine Lifecycle

A goroutine runs until its function returns. There is **no way to forcibly kill a goroutine
from outside** — you must design it to exit on its own. This is a deliberate design choice
that prevents resource leaks from interrupted operations.

```go
// BAD: this goroutine runs forever — goroutine leak!
go func() {
    for {
        doWork()
    }
}()

// GOOD: this goroutine can be stopped via a done channel
go func() {
    for {
        select {
        case <-done:
            return // clean exit
        default:
            doWork()
        }
    }
}()
```

### The Main Goroutine

`main()` is itself a goroutine — the very first one. When `main()` returns, the entire program
exits, regardless of whether other goroutines are still running. There is no "wait for all
goroutines" built into the language (you use `sync.WaitGroup` for that — covered in section 3).

```go
func main() {
    go func() {
        time.Sleep(5 * time.Second)
        fmt.Println("This will never print")
    }()
    // main returns immediately, program exits, goroutine is killed
}
```

### Goroutine Scheduling: Cooperative vs Preemptive

Go's scheduler is **cooperatively preemptive** (since Go 1.14). Goroutines yield control at:

1. **Channel operations** (send, receive)
2. **Function calls** (the compiler inserts preemption points)
3. **Blocking syscalls** (I/O, sleep)
4. **Garbage collection** safe points
5. **Explicit runtime calls** (`runtime.Gosched()`)

Before Go 1.14, a tight CPU-bound loop with no function calls could starve other goroutines.
Now the runtime can asynchronously preempt even tight loops using signals.

### How Many Goroutines Can You Run?

The practical limit depends on what each goroutine does:

```go
// This is totally fine — creates 1 million goroutines
// Each just sleeps, using ~2KB stack = ~2GB total memory
for i := 0; i < 1_000_000; i++ {
    go func(n int) {
        time.Sleep(10 * time.Second)
        fmt.Println(n)
    }(i)
}
```

Rules of thumb:
- **I/O-bound goroutines** (waiting on network, disk): millions are fine
- **CPU-bound goroutines** (computing): limited by CPU cores (use `runtime.GOMAXPROCS`)
- **Memory-bound goroutines** (large stacks): limited by available RAM

### GOMAXPROCS: Controlling Parallelism

```go
import "runtime"

// Defaults to the number of CPU cores
runtime.GOMAXPROCS(4) // use 4 OS threads for goroutine execution

n := runtime.NumGoroutine() // how many goroutines are currently alive?
```

`GOMAXPROCS` controls how many goroutines can execute **simultaneously** (parallelism), not how
many can exist (concurrency). You rarely need to change this.

---

## 2. Channels — Communication Between Goroutines

Go's concurrency philosophy is captured in a single sentence:

> **Do not communicate by sharing memory; instead, share memory by communicating.**

Channels are the mechanism for this communication. They are typed conduits through which you can
send and receive values between goroutines.

### Creating Channels

```go
// Unbuffered channel — sender blocks until receiver is ready
ch := make(chan int)

// Buffered channel — sender blocks only when buffer is full
ch := make(chan int, 10)    // buffer of 10

// Channel of structs (common for signals)
done := make(chan struct{})

// Channel of os.Signal (used in our main.go)
quit := make(chan os.Signal, 1)
```

### Sending and Receiving

```go
ch <- 42        // send the value 42 into the channel
value := <-ch   // receive a value from the channel
<-ch            // receive and discard (just block until something arrives)
```

### Unbuffered vs Buffered Channels

This distinction is critical and trips up many newcomers.

**Unbuffered channel** (`make(chan int)`):
- Send blocks until another goroutine receives
- Receive blocks until another goroutine sends
- Provides a **synchronization point** — both goroutines meet at the channel
- Think of it as a hand-off: the sender waits with the value held out until someone takes it

```go
ch := make(chan int) // unbuffered

go func() {
    ch <- 42 // blocks here until main goroutine receives
    fmt.Println("sent!")
}()

value := <-ch // blocks here until goroutine sends
fmt.Println(value) // 42
```

**Buffered channel** (`make(chan int, N)`):
- Send blocks only when the buffer is full
- Receive blocks only when the buffer is empty
- Think of it as a mailbox with N slots

```go
ch := make(chan int, 3) // buffer of 3

ch <- 1 // doesn't block (buffer: [1])
ch <- 2 // doesn't block (buffer: [1, 2])
ch <- 3 // doesn't block (buffer: [1, 2, 3])
ch <- 4 // BLOCKS — buffer is full, waits for a receiver
```

### Channels in Our Codebase: Signal Handling

The most important channel usage in the Anuyatra backend is the graceful shutdown mechanism
in `main.go`:

```go
quit := make(chan os.Signal, 1)
signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
<-quit // blocks until signal received
```

Let's break this down:

1. `make(chan os.Signal, 1)` — creates a buffered channel that can hold one OS signal.
   The buffer of 1 is important: if the signal arrives before anyone is receiving,
   it won't be lost.

2. `signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)` — tells the Go runtime to
   deliver SIGINT (Ctrl+C) and SIGTERM (kill command) into the `quit` channel instead
   of the default behavior (crash).

3. `<-quit` — blocks the main goroutine here. The server goroutine is running in the
   background handling requests. The main goroutine just... waits. When the user presses
   Ctrl+C, a signal is sent into the channel, `<-quit` unblocks, and the shutdown
   sequence begins.

This is the **done channel pattern** — one of the most fundamental channel patterns in Go.

### Closing Channels

A sender can close a channel to signal that no more values will be sent:

```go
close(ch) // only the sender should close a channel

// After closing:
value, ok := <-ch // ok is false if channel is closed and empty
// Receiving from a closed, empty channel returns the zero value immediately
```

You can range over a channel — the loop exits when the channel is closed:

```go
go func() {
    for i := 0; i < 5; i++ {
        ch <- i
    }
    close(ch) // signal that we're done
}()

for value := range ch {
    fmt.Println(value) // prints 0, 1, 2, 3, 4 then loop exits
}
```

### Channel Direction Annotations

Go lets you restrict a channel to send-only or receive-only in function signatures. This
is a powerful safety mechanism:

```go
// Can only send into this channel
func producer(out chan<- int) {
    out <- 42
    // <-out  // compile error: cannot receive from send-only channel
}

// Can only receive from this channel
func consumer(in <-chan int) {
    value := <-in
    // in <- 42  // compile error: cannot send to receive-only channel
}

func main() {
    ch := make(chan int) // bidirectional
    go producer(ch)      // implicitly converts to chan<-
    consumer(ch)         // implicitly converts to <-chan
}
```

The `signal.Notify` function signature demonstrates this:
```go
func Notify(c chan<- os.Signal, sig ...os.Signal)
//               ^^^^^ signal.Notify can only send into the channel
```

### The Select Statement: Multiplexing Channels

`select` lets a goroutine wait on multiple channel operations simultaneously. It's like a
`switch` statement for channels:

```go
select {
case msg := <-messageCh:
    fmt.Println("received message:", msg)
case sig := <-signalCh:
    fmt.Println("received signal:", sig)
case outCh <- result:
    fmt.Println("sent result")
case <-time.After(5 * time.Second):
    fmt.Println("timeout — nothing happened in 5 seconds")
}
```

**Key behaviors of select:**
- If multiple cases are ready, one is chosen **at random** (prevents starvation)
- If no case is ready, `select` blocks until one becomes ready
- A `default` case makes `select` non-blocking

```go
// Non-blocking receive
select {
case msg := <-ch:
    fmt.Println("got:", msg)
default:
    fmt.Println("no message available, moving on")
}

// Non-blocking send
select {
case ch <- msg:
    fmt.Println("sent")
default:
    fmt.Println("channel full, dropping message")
}
```

### Channel Patterns

These patterns appear everywhere in production Go code.

#### Pattern 1: Done Channel (used in main.go)

Signal completion or cancellation:

```go
done := make(chan struct{}) // empty struct uses zero memory

go func() {
    defer close(done) // signal completion when function exits
    doExpensiveWork()
}()

<-done // wait for completion
```

#### Pattern 2: Fan-Out

Distribute work across multiple goroutines:

```go
func fanOut(jobs <-chan int, numWorkers int) {
    for i := 0; i < numWorkers; i++ {
        go func(workerID int) {
            for job := range jobs {
                process(workerID, job)
            }
        }(i)
    }
}
```

#### Pattern 3: Fan-In

Merge multiple channels into one:

```go
func fanIn(channels ...<-chan string) <-chan string {
    merged := make(chan string)
    var wg sync.WaitGroup

    for _, ch := range channels {
        wg.Add(1)
        go func(c <-chan string) {
            defer wg.Done()
            for msg := range c {
                merged <- msg
            }
        }(ch)
    }

    go func() {
        wg.Wait()
        close(merged)
    }()

    return merged
}
```

#### Pattern 4: Pipeline

Chain stages where each stage is a goroutine:

```go
func generate(nums ...int) <-chan int {
    out := make(chan int)
    go func() {
        for _, n := range nums {
            out <- n
        }
        close(out)
    }()
    return out
}

func square(in <-chan int) <-chan int {
    out := make(chan int)
    go func() {
        for n := range in {
            out <- n * n
        }
        close(out)
    }()
    return out
}

func main() {
    // Pipeline: generate → square → print
    for val := range square(generate(2, 3, 4)) {
        fmt.Println(val) // 4, 9, 16
    }
}
```

#### Pattern 5: Timeout

```go
func fetchWithTimeout(url string, timeout time.Duration) (string, error) {
    resultCh := make(chan string, 1)
    errCh := make(chan error, 1)

    go func() {
        result, err := httpGet(url)
        if err != nil {
            errCh <- err
            return
        }
        resultCh <- result
    }()

    select {
    case result := <-resultCh:
        return result, nil
    case err := <-errCh:
        return "", err
    case <-time.After(timeout):
        return "", fmt.Errorf("request timed out after %v", timeout)
    }
}
```

#### Pattern 6: Semaphore (limiting concurrency)

```go
// Process at most 10 items concurrently
sem := make(chan struct{}, 10)

for _, item := range items {
    sem <- struct{}{} // acquire slot (blocks when 10 are in-flight)
    go func(it Item) {
        defer func() { <-sem }() // release slot
        process(it)
    }(item)
}
```

#### Pattern 7: Context-Based Cancellation

The `context` package integrates with channels for cancellation:

```go
ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
defer cancel()

// This is exactly what our graceful shutdown does:
if err := srv.Shutdown(ctx); err != nil {
    log.Fatalf("forced shutdown: %v", err)
}
```

Under the hood, `context.WithTimeout` creates a channel that closes after the timeout.
`srv.Shutdown` checks `ctx.Done()` (a `<-chan struct{}`) to know when to give up waiting
for in-flight requests.

### Nil Channel Trick

A nil channel blocks forever on both send and receive. This is useful for disabling a
`select` case:

```go
var ch chan int // nil

// This select case is effectively disabled
select {
case v := <-ch:       // never fires (nil channel blocks forever)
    fmt.Println(v)
case <-time.After(1 * time.Second):
    fmt.Println("timeout")
}
```

---

## 3. sync Package — Mutual Exclusion

While channels are Go's preferred synchronization mechanism for communicating between goroutines,
sometimes you need traditional locking. The `sync` package provides mutex-based synchronization
primitives. Our Anuyatra backend uses these extensively.

### sync.Mutex — Exclusive Lock

A `Mutex` (mutual exclusion lock) ensures that only one goroutine can access a critical
section at a time:

```go
var mu sync.Mutex
var count int

func increment() {
    mu.Lock()         // acquire the lock — blocks if another goroutine holds it
    count++           // critical section: only one goroutine executes this at a time
    mu.Unlock()       // release the lock — another goroutine can now enter
}
```

### sync.RWMutex — Reader-Writer Lock

This is the star of the show in the Anuyatra backend. **Every single in-memory repository**
uses `sync.RWMutex`.

A `RWMutex` allows either:
- **Multiple concurrent readers** (`RLock` / `RUnlock`), OR
- **One exclusive writer** (`Lock` / `Unlock`)
- Never both at the same time

```go
type SavedProfileRepo struct {
    mu   sync.RWMutex
    data map[string]*model.SavedProfile
}
```

Why `RWMutex` over plain `Mutex`? In a web API, **reads vastly outnumber writes**. Users
browse profiles, search, view conversations far more often than they create or update records.
With a plain `Mutex`, every read would block every other read. With `RWMutex`, 100 concurrent
profile-browsing goroutines can all read simultaneously — they only wait when someone is writing.

### The Locking Pattern in Every Repository

Every public method in every in-memory repo follows the same disciplined pattern.

**Read operations** — use `RLock`:

```go
func (r *UserRepo) GetByID(_ context.Context, id string) (*model.AppUser, error) {
    r.mu.RLock()         // acquire read lock — multiple readers allowed simultaneously
    defer r.mu.RUnlock() // guaranteed unlock even if panic occurs

    u, ok := r.byID[id]
    if !ok {
        return nil, model.NotFoundError("User", id)
    }
    cp := *u             // CRITICAL: copy before returning (explained below)
    return &cp, nil
}
```

**Write operations** — use `Lock`:

```go
func (r *UserRepo) Create(_ context.Context, user *model.AppUser) error {
    r.mu.Lock()          // acquire exclusive write lock — no other readers or writers
    defer r.mu.Unlock()  // guaranteed unlock

    if _, ok := r.byID[user.UID]; ok {
        return model.ConflictError("user already exists")
    }
    if uid, ok := r.byPhone[user.PhoneNumber]; ok && uid != user.UID {
        return model.ConflictError("phone number already registered")
    }
    cp := *user          // copy the input before storing
    r.byID[user.UID] = &cp
    r.byPhone[user.PhoneNumber] = user.UID
    return nil
}
```

### The Copy-on-Read Pattern

You'll notice `cp := *u; return &cp, nil` appearing in every read method. This is the
**copy-on-read** (or defensive copy) pattern, and it's essential for thread safety.

**Without copying (DANGEROUS):**

```go
func (r *UserRepo) GetByID(_ context.Context, id string) (*model.AppUser, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    u, ok := r.byID[id]
    if !ok {
        return nil, model.NotFoundError("User", id)
    }
    return u, nil // DANGER: returning a pointer to internal data
}
```

What goes wrong without the copy:

1. Goroutine A calls `GetByID("user1")` and receives a pointer to the internal map's value
2. Goroutine A releases the read lock (via defer)
3. Goroutine B calls `Update` on user1, acquires write lock, modifies the data
4. Goroutine A is now reading from memory that Goroutine B is writing to — **DATA RACE**

Or even worse:

1. Goroutine A calls `GetByID("user1")`, gets pointer `p`
2. Goroutine A modifies `p.DisplayName = "hacked"` (without any lock!)
3. Now the internal map's data is corrupted — all future readers see "hacked"

**With copying (SAFE):**

```go
cp := *u          // dereference the pointer, creating a full struct copy
return &cp, nil   // return a pointer to the NEW copy
```

The caller gets their own independent copy. They can read it, modify it, pass it around —
none of that affects the repository's internal state. The internal map remains consistent.

### The `defer` Idiom for Unlocking

Every lock in the project is paired with a `defer` unlock:

```go
r.mu.RLock()
defer r.mu.RUnlock()
```

Why `defer` instead of calling `Unlock()` at the end?

1. **Early returns**: If the function has multiple return paths, you'd need an `Unlock()` before
   each one. Miss one, and you have a deadlock.

2. **Panic safety**: If the code inside the critical section panics, `defer` still runs. Without
   it, the mutex stays locked forever, and every other goroutine trying to access it will deadlock.

3. **Code clarity**: The lock and unlock are always adjacent in the source code, making it
   impossible to forget the unlock.

```go
// WITHOUT defer — fragile, error-prone:
func (r *UserRepo) GetByID(_ context.Context, id string) (*model.AppUser, error) {
    r.mu.RLock()

    u, ok := r.byID[id]
    if !ok {
        r.mu.RUnlock() // must remember to unlock on this path!
        return nil, model.NotFoundError("User", id)
    }

    cp := *u
    r.mu.RUnlock() // and this path!
    return &cp, nil
}

// WITH defer — bulletproof:
func (r *UserRepo) GetByID(_ context.Context, id string) (*model.AppUser, error) {
    r.mu.RLock()
    defer r.mu.RUnlock() // runs no matter how the function exits

    u, ok := r.byID[id]
    if !ok {
        return nil, model.NotFoundError("User", id) // safe — defer handles unlock
    }
    cp := *u
    return &cp, nil // safe — defer handles unlock
}
```

### Lock Granularity: Struct-Level Locking

Notice that each repository has its own mutex. We don't use a single global lock for the
entire application:

```go
type UserRepo struct {
    mu      sync.RWMutex  // only protects THIS repo's maps
    byID    map[string]*model.AppUser
    byPhone map[string]string
}

type AgencyRepo struct {
    mu   sync.RWMutex     // only protects THIS repo's map
    data map[string]*model.Agency
}
```

This is **fine-grained locking**. A user update doesn't block agency reads. A profile search
doesn't block message sends. Each resource type is independently protected.

The alternative — a single global `sync.RWMutex` for all data — would create a massive
bottleneck where any write to any entity blocks all reads across the entire application.

### sync.Once — Exactly Once Initialization

`sync.Once` ensures a function runs exactly once, even if called from multiple goroutines:

```go
var (
    instance *Database
    once     sync.Once
)

func GetDB() *Database {
    once.Do(func() {
        instance = connectToDatabase() // runs exactly once, no matter how many goroutines call GetDB
    })
    return instance
}
```

Common uses:
- Lazy singleton initialization
- One-time configuration loading
- Expensive resource setup (connection pools, caches)

### sync.WaitGroup — Waiting for Goroutines

`WaitGroup` lets you wait for a collection of goroutines to finish:

```go
var wg sync.WaitGroup

for i := 0; i < 10; i++ {
    wg.Add(1)           // increment counter BEFORE launching goroutine
    go func(n int) {
        defer wg.Done() // decrement counter when goroutine exits
        processItem(n)
    }(i)
}

wg.Wait() // blocks until counter reaches zero
fmt.Println("all 10 goroutines completed")
```

**Critical rule**: Call `wg.Add(1)` in the **parent** goroutine, not inside the child goroutine.
If you call it inside the child, there's a race: the parent might reach `wg.Wait()` before the
child calls `wg.Add(1)`, causing the Wait to return too early.

```go
// WRONG:
for i := 0; i < 10; i++ {
    go func(n int) {
        wg.Add(1)        // race! main might call Wait() before this runs
        defer wg.Done()
        processItem(n)
    }(i)
}
wg.Wait()

// RIGHT:
for i := 0; i < 10; i++ {
    wg.Add(1)            // called in parent, before go statement
    go func(n int) {
        defer wg.Done()
        processItem(n)
    }(i)
}
wg.Wait()
```

### sync.Map — Concurrent Map (Use Sparingly)

`sync.Map` is a concurrent-safe map built into the `sync` package. It's optimized for two
specific use cases:

1. When a key is written once but read many times (like a cache)
2. When multiple goroutines read/write disjoint sets of keys

```go
var cache sync.Map

cache.Store("key1", "value1")                  // set
value, ok := cache.Load("key1")                // get
cache.Delete("key1")                           // delete
actual, loaded := cache.LoadOrStore("key1", "default") // get-or-set atomically
cache.Range(func(key, value any) bool {        // iterate
    fmt.Println(key, value)
    return true // return false to stop iteration
})
```

**Why don't we use sync.Map in the Anuyatra repos?** Because `sync.Map` has significant
downsides for our use case:

- **No type safety**: Keys and values are `any` — you lose compile-time type checking
- **No generics support**: Can't express `sync.Map[string, *model.AppUser]`
- **Slower for mixed read/write workloads**: Our repos do both reads and writes
- **No multi-key transactions**: We often need to update multiple maps atomically
  (e.g., `byID` AND `byPhone` in `UserRepo`)

The explicit `map + RWMutex` pattern gives us type safety, multi-map atomicity, and better
performance for our access patterns.

### sync.Pool — Object Reuse

`sync.Pool` is a concurrent-safe pool of temporary objects to reduce garbage collection pressure:

```go
var bufferPool = sync.Pool{
    New: func() any {
        return new(bytes.Buffer)
    },
}

func processRequest() {
    buf := bufferPool.Get().(*bytes.Buffer)
    defer func() {
        buf.Reset()
        bufferPool.Put(buf)
    }()

    buf.WriteString("response data")
    // use buf...
}
```

Commonly used for:
- Buffer reuse in high-throughput servers
- Reducing allocations in hot paths
- JSON encoder/decoder reuse

### sync.Cond — Condition Variables

`sync.Cond` allows goroutines to wait for or announce an event:

```go
var (
    mu    sync.Mutex
    cond  = sync.NewCond(&mu)
    ready bool
)

// Waiter
go func() {
    mu.Lock()
    for !ready {
        cond.Wait() // atomically unlocks mu, waits, re-locks mu when woken
    }
    fmt.Println("condition met!")
    mu.Unlock()
}()

// Signaler
mu.Lock()
ready = true
cond.Signal() // wake one waiter (or cond.Broadcast() to wake all)
mu.Unlock()
```

`sync.Cond` is relatively rare in Go code — channels usually provide a cleaner solution.

### Atomic Operations: sync/atomic

For simple counters and flags, atomic operations avoid the need for a full mutex:

```go
import "sync/atomic"

var requestCount atomic.Int64

func handleRequest() {
    requestCount.Add(1)           // thread-safe increment
    current := requestCount.Load() // thread-safe read
    fmt.Println("request #", current)
}
```

Available atomic types (Go 1.19+): `atomic.Bool`, `atomic.Int32`, `atomic.Int64`,
`atomic.Uint32`, `atomic.Uint64`, `atomic.Pointer[T]`.

When to use atomics vs mutexes:
- **Atomics**: Single scalar value, no invariants across multiple fields
- **Mutexes**: Multiple related fields that must be updated together (our repos)

---

## 4. Race Conditions & Data Races

### What Is a Data Race?

A data race occurs when:
1. Two or more goroutines access the same memory location
2. At least one of them writes
3. There is no synchronization between them

Data races are **undefined behavior** in Go. Your program might work correctly 99% of the time
and then corrupt data, crash, or produce impossible results the other 1%.

### Go Maps Are NOT Thread-Safe

This is the single most important thing to understand about our in-memory repos. Go's built-in
`map` type is not safe for concurrent access:

```go
m := make(map[string]int)

// Two goroutines accessing the same map concurrently:
go func() { m["a"] = 1 }()
go func() { m["b"] = 2 }()

// This can:
// 1. Corrupt the map's internal hash table → garbage data
// 2. Trigger a runtime panic: "concurrent map writes"
// 3. Cause a segfault (extremely rare, but possible)
```

Go actually **detects** concurrent map writes at runtime and panics with a clear message:

```
fatal error: concurrent map writes
```

This is a safety feature — the runtime crashes rather than silently corrupting your data.

### What Would Happen Without Mutexes in UserRepo?

Imagine we removed the `sync.RWMutex` from `UserRepo`:

```go
// UNSAFE VERSION — DO NOT DO THIS
type UserRepo struct {
    byID    map[string]*model.AppUser
    byPhone map[string]string
}

func (r *UserRepo) Create(_ context.Context, user *model.AppUser) error {
    // No lock!
    r.byID[user.UID] = user
    r.byPhone[user.PhoneNumber] = user.UID
    return nil
}
```

With 100 concurrent HTTP requests:
1. **Corrupted maps**: The internal hash table of `byID` gets corrupted because two goroutines
   are resizing it simultaneously
2. **Lost writes**: Goroutine A writes user "alice", Goroutine B writes user "bob" — one
   of them disappears because they both tried to place their entry in the same bucket
3. **Torn reads**: Goroutine A reads `byID["alice"]` while Goroutine B is updating it —
   the pointer might be half-updated, pointing to partially initialized memory
4. **Panic**: Go's runtime detects the concurrent write and crashes the server
5. **Index inconsistency**: `byID` has user "alice" but `byPhone` doesn't have her phone
   number because the crash happened between the two map writes

### Go's Race Detector

Go ships with a built-in race detector — one of the best in any language:

```bash
# Run your program with race detection
go run -race ./cmd/server/main.go

# Run tests with race detection
go test -race ./...

# Build with race detection
go build -race -o server ./cmd/server
```

When a race is detected, you get a detailed report:

```
==================
WARNING: DATA RACE
Write at 0x00c000126000 by goroutine 7:
  github.com/anuyatra/backend/internal/inmem.(*UserRepo).Create()
      /backend/internal/inmem/user_repo.go:27 +0x104

Previous read at 0x00c000126000 by goroutine 6:
  github.com/anuyatra/backend/internal/inmem.(*UserRepo).GetByID()
      /backend/internal/inmem/user_repo.go:42 +0x80

Goroutine 7 (running) created at:
  net/http.(*Server).Serve()
      /usr/local/go/src/net/http/server.go:3086 +0x5dd

Goroutine 6 (running) created at:
  net/http.(*Server).Serve()
      /usr/local/go/src/net/http/server.go:3086 +0x5dd
==================
```

The race detector tells you:
- **What**: A write and a read accessing the same memory
- **Where**: Exact file and line number for both accesses
- **Who**: Which goroutines, and where they were created

**Important**: The race detector uses ~2-10x more memory and runs ~2-10x slower. It's intended
for development and CI, not production. But you should **always** run `go test -race` in CI.

### How This Project Is Race-Free

Every public method in every in-memory repository wraps all map access with proper locking:

| Repository | Mutex | Protected Data |
|---|---|---|
| `UserRepo` | `sync.RWMutex` | `byID`, `byPhone` |
| `AgencyRepo` | `sync.RWMutex` | `data` |
| `ParentProfileRepo` | `sync.RWMutex` | `data` |
| `BrokerProfileRepo` | `sync.RWMutex` | `data` |
| `CandidateProfileRepo` | `sync.RWMutex` | `data` |
| `AuthRepo` | `sync.RWMutex` | `sessions` |
| `MessagingRepo` | `sync.RWMutex` | `conversations`, `messages`, `byUser` |
| `SavedProfileRepo` | `sync.RWMutex` | `data` |
| `ViewedProfileRepo` | `sync.RWMutex` | `byUser` |
| `ActivityRepo` | `sync.RWMutex` | `data` |
| `NoteRepo` | `sync.RWMutex` | `parentNotes`, `brokerNotes` |
| `MeetingRepo` | `sync.RWMutex` | `data` |

Additionally, every method returns **copies** of internal data, so callers can't accidentally
create a race by modifying returned pointers.

### Common Race Condition Patterns

#### Race: Check-Then-Act

```go
// UNSAFE:
if _, ok := r.byID[user.UID]; !ok {
    r.byID[user.UID] = user // another goroutine might have inserted between check and act
}

// SAFE: wrap the entire check-then-act in a single lock
r.mu.Lock()
defer r.mu.Unlock()
if _, ok := r.byID[user.UID]; !ok {
    r.byID[user.UID] = user
}
```

#### Race: Read-Modify-Write

```go
// UNSAFE:
count := r.data[key]  // read
count++               // modify
r.data[key] = count   // write — another goroutine might have modified between read and write

// SAFE:
r.mu.Lock()
defer r.mu.Unlock()
r.data[key]++
```

#### Race: Multiple Map Updates

```go
// UNSAFE — even with individual map operations being atomic:
r.byID[user.UID] = user           // step 1
r.byPhone[user.PhoneNumber] = uid  // step 2
// If a reader runs between step 1 and step 2, they see inconsistent state

// SAFE — our UserRepo.Create does this correctly:
r.mu.Lock()
defer r.mu.Unlock()
cp := *user
r.byID[user.UID] = &cp
r.byPhone[user.PhoneNumber] = user.UID
// Both maps are updated atomically from readers' perspective
```

---

## 5. Thread Safety Patterns in This Project

Let's catalog every thread-safety pattern used in the Anuyatra backend. These patterns are
reusable in any Go project.

### Pattern 1: Map + RWMutex (Basic CRUD)

**Used by**: `UserRepo`, `AgencyRepo`, `ParentProfileRepo`, `BrokerProfileRepo`,
`CandidateProfileRepo`, `MeetingRepo`

```go
type AgencyRepo struct {
    mu   sync.RWMutex
    data map[string]*model.Agency
}

func (r *AgencyRepo) GetByID(_ context.Context, id string) (*model.Agency, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    a, ok := r.data[id]
    if !ok {
        return nil, model.NotFoundError("Agency", id)
    }
    cp := *a
    return &cp, nil
}

func (r *AgencyRepo) Create(_ context.Context, agency *model.Agency) error {
    r.mu.Lock()
    defer r.mu.Unlock()
    cp := *agency
    r.data[agency.ID] = &cp
    return nil
}
```

**Best for**: Key-value CRUD where the primary key is a single field (ID).

**Characteristics**:
- Single map keyed by entity ID
- Reads use `RLock`, writes use `Lock`
- Every value is copied in and copied out
- O(1) lookups by ID

### Pattern 2: Primary + Secondary Indexes

**Used by**: `UserRepo` (byID + byPhone)

```go
type UserRepo struct {
    mu      sync.RWMutex
    byID    map[string]*model.AppUser   // primary index
    byPhone map[string]string           // secondary index: phone → user ID
}
```

This is like having two indexes on a database table. The secondary index (`byPhone`) maps
phone numbers to user IDs, enabling O(1) lookup by phone number:

```go
func (r *UserRepo) GetByPhone(_ context.Context, phone string) (*model.AppUser, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    uid, ok := r.byPhone[phone]  // O(1) phone lookup
    if !ok {
        return nil, model.NotFoundError("User", phone)
    }
    cp := *r.byID[uid]           // O(1) ID lookup
    return &cp, nil
}
```

**Critical**: Both maps must be updated atomically. The `Create` method updates both under
a single `Lock()`:

```go
func (r *UserRepo) Create(_ context.Context, user *model.AppUser) error {
    r.mu.Lock()
    defer r.mu.Unlock()
    // ... validation ...
    cp := *user
    r.byID[user.UID] = &cp           // update primary index
    r.byPhone[user.PhoneNumber] = user.UID  // update secondary index
    return nil
}
```

If these updates weren't atomic, a concurrent reader might find the user by ID but not
by phone number, or vice versa.

### Pattern 3: Composite Keys

**Used by**: `SavedProfileRepo`, `NoteRepo`

When you need a unique constraint on a combination of fields, concatenate them into a
composite key:

```go
func savedKey(userID, profileID string) string { return userID + ":" + profileID }

type SavedProfileRepo struct {
    mu   sync.RWMutex
    data map[string]*model.SavedProfile  // key = "userID:profileID"
}

func (r *SavedProfileRepo) Save(_ context.Context, sp *model.SavedProfile) error {
    r.mu.Lock()
    defer r.mu.Unlock()
    cp := *sp
    r.data[savedKey(sp.UserID, sp.ProfileID)] = &cp
    return nil
}

func (r *SavedProfileRepo) IsSaved(_ context.Context, userID, profileID string) (bool, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    _, ok := r.data[savedKey(userID, profileID)]
    return ok, nil
}
```

The `NoteRepo` uses the same pattern with more complex composite keys:

```go
func parentNoteKey(parentUserID, profileID string) string {
    return parentUserID + ":" + profileID
}

func brokerNoteKey(brokerUserID, profileID, forParentID string) string {
    return brokerUserID + ":" + profileID + ":" + forParentID  // three-part key!
}
```

**Best for**: Many-to-many relationships where you need to check "does user X have a
relationship with entity Y?"

**Caveat**: Composite keys using string concatenation can collide if field values contain
the separator character. In our case, UUIDs never contain `:`, so this is safe.

### Pattern 4: Per-Entity Append Lists

**Used by**: `ViewedProfileRepo`, `ActivityRepo`

When you need to record a time-ordered list of events per entity:

```go
type ViewedProfileRepo struct {
    mu     sync.RWMutex
    byUser map[string][]*model.ViewedProfile  // user → sorted list of views
}

func (r *ViewedProfileRepo) RecordView(_ context.Context, vp *model.ViewedProfile) error {
    r.mu.Lock()
    defer r.mu.Unlock()
    cp := *vp
    r.byUser[vp.UserID] = append(r.byUser[vp.UserID], &cp)
    return nil
}

func (r *ViewedProfileRepo) ListByUser(_ context.Context, userID string, limit int) ([]*model.ViewedProfile, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    src := r.byUser[userID]
    all := make([]*model.ViewedProfile, len(src))
    copy(all, src)  // copy the slice to avoid returning internal data
    sort.Slice(all, func(i, j int) bool {
        return all[i].ViewedAt.After(all[j].ViewedAt)  // newest first
    })
    if limit > 0 && len(all) > limit {
        all = all[:limit]
    }
    return all, nil
}
```

**Key insight**: The `ListByUser` method copies the entire slice before sorting. If it
sorted `r.byUser[userID]` directly, it would mutate internal state while holding only
a read lock — other concurrent readers would see a partially-sorted slice.

**Best for**: Event logs, activity feeds, view history — append-only data with per-entity
grouping.

### Pattern 5: Triple Index

**Used by**: `MessagingRepo`

When a single entity has multiple access patterns, you need multiple indexes:

```go
type MessagingRepo struct {
    mu            sync.RWMutex
    conversations map[string]*model.Conversation    // by conversation ID
    messages      map[string][]*model.ChatMessage    // by conversation ID → messages
    byUser        map[string][]string                // user ID → conversation IDs
}
```

Three maps, one mutex. Each map serves a different access pattern:

- `conversations`: "Get conversation by ID" — used when loading a specific chat
- `messages`: "Get messages for a conversation" — used when displaying chat history
- `byUser`: "List all conversations for a user" — used on the messages inbox screen

The `findBetween` helper does an O(n) scan of a user's conversations to find an existing
conversation between two specific users:

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

Note that `findBetween` is a **private** method (lowercase). It doesn't acquire a lock because
it's only called from `GetOrCreateConversation`, which already holds the lock. This is the
"hold-the-lock-in-the-caller" pattern — it avoids recursive locking (which would deadlock
with `sync.Mutex`).

**Best for**: Complex domain objects with multiple access patterns (messaging, social graphs,
order management).

### Pattern 6: Dual-Collection with Shared Lock

**Used by**: `NoteRepo`

When two related but distinct collections share the same lifecycle:

```go
type NoteRepo struct {
    mu          sync.RWMutex
    parentNotes map[string]*model.ParentNote   // parent's private notes on profiles
    brokerNotes map[string]*model.BrokerNote   // broker's notes for specific parents
}
```

Both maps are protected by the same mutex. This is simpler than having two separate
repos with two separate mutexes, and it reflects the domain reality that parent notes
and broker notes are closely related features.

### Pattern 7: Generic Pagination Helper

The `paginate` function demonstrates Go generics with the concurrent data:

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

This function works on any pointer-to-struct type. It's called after the data has been
filtered and copied under the lock, so it operates on the caller's private copy.

### Summary: Thread Safety Invariants

The invariants maintained across ALL repositories:

1. **All public methods acquire the appropriate lock** (RLock for reads, Lock for writes)
2. **All locks are released via defer** (panic-safe)
3. **All returned data is a copy** (no shared pointers)
4. **All stored data is a copy** (input pointers don't alias internal state)
5. **Multi-map updates are atomic** (all maps updated under the same Lock)
6. **Private helpers don't lock** (callers hold the lock)

---

## 6. Testing in Go

Go has testing built into the language and toolchain. No external test runner needed. No
configuration files. Just follow the conventions and run `go test`.

### The Basics

**Test file naming**: Any file ending in `_test.go` is a test file. It's compiled and
executed only during `go test` — it's excluded from normal builds.

**Test file location**: Test files live in the same directory and package as the code they
test. This gives them access to unexported (lowercase) functions.

```
backend/internal/model/
├── user.go          # production code
├── user_test.go     # tests for user.go
├── errors.go        # production code
└── errors_test.go   # tests for errors.go
```

**Test function signature**: Functions must start with `Test` and take a `*testing.T`:

```go
func TestSomething(t *testing.T) {
    // test code
}
```

**Running tests**:

```bash
go test ./...                    # run all tests in all packages
go test ./internal/model/...     # run tests in a specific package
go test -v ./...                 # verbose output (show each test name)
go test -run TestUserRoleIsValid # run tests matching a regex
go test -count=1 ./...           # disable test caching
go test -race ./...              # enable race detector
go test -cover ./...             # show coverage percentage
go test -coverprofile=cover.out  # generate coverage file
go tool cover -html=cover.out    # view coverage in browser
```

### Table-Driven Tests — The Go Way

The idiomatic way to test in Go is **table-driven tests**. Instead of writing separate
test functions for each case, you define a slice of test cases and loop over them:

```go
func TestUserRoleIsValid(t *testing.T) {
    tests := []struct {
        name string
        role model.UserRole
        want bool
    }{
        {"valid parent", model.RoleParent, true},
        {"valid broker", model.RoleBroker, true},
        {"valid candidate", model.RoleCandidate, true},
        {"valid agency admin", model.RoleAgencyAdmin, true},
        {"invalid empty", model.UserRole(""), false},
        {"invalid superadmin", model.UserRole("superadmin"), false},
        {"invalid uppercase", model.UserRole("Parent"), false},
        {"invalid spaces", model.UserRole(" parent "), false},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            if got := tt.role.IsValid(); got != tt.want {
                t.Errorf("UserRole(%q).IsValid() = %v, want %v", tt.role, got, tt.want)
            }
        })
    }
}
```

Why table-driven tests are the Go standard:

1. **Easy to add cases**: Just add another struct literal to the slice
2. **DRY**: The assertion logic is written once
3. **Clear names**: Each case has a descriptive name shown in output
4. **Independent**: `t.Run` creates subtests that can be run individually
5. **Parallel-ready**: Subtests can run in parallel with `t.Parallel()`

Output when a test fails:

```
--- FAIL: TestUserRoleIsValid (0.00s)
    --- FAIL: TestUserRoleIsValid/invalid_uppercase (0.00s)
        user_test.go:25: UserRole("Parent").IsValid() = true, want false
FAIL
```

### Testing Repository Implementations

Here's how you'd write comprehensive tests for the `UserRepo`:

```go
package inmem_test

import (
    "context"
    "testing"

    "github.com/anuyatra/backend/internal/inmem"
    "github.com/anuyatra/backend/internal/model"
    "github.com/anuyatra/backend/internal/repository"
)

func newTestUser(uid, phone, name string) *model.AppUser {
    return &model.AppUser{
        UID:         uid,
        PhoneNumber: phone,
        DisplayName: name,
        Role:        model.RoleParent,
        IsActive:    true,
    }
}

func TestUserRepo_CreateAndGet(t *testing.T) {
    repo := inmem.NewUserRepo()
    ctx := context.Background()
    user := newTestUser("test-1", "9876543210", "Test User")

    if err := repo.Create(ctx, user); err != nil {
        t.Fatalf("Create: %v", err)
    }

    got, err := repo.GetByID(ctx, "test-1")
    if err != nil {
        t.Fatalf("GetByID: %v", err)
    }
    if got.DisplayName != "Test User" {
        t.Errorf("DisplayName = %q, want %q", got.DisplayName, "Test User")
    }
    if got.PhoneNumber != "9876543210" {
        t.Errorf("PhoneNumber = %q, want %q", got.PhoneNumber, "9876543210")
    }
}

func TestUserRepo_CreateDuplicate(t *testing.T) {
    repo := inmem.NewUserRepo()
    ctx := context.Background()
    user := newTestUser("test-1", "9876543210", "Test User")

    if err := repo.Create(ctx, user); err != nil {
        t.Fatalf("first Create: %v", err)
    }

    err := repo.Create(ctx, user)
    if err == nil {
        t.Fatal("expected error on duplicate Create, got nil")
    }

    apiErr, ok := err.(*model.APIError)
    if !ok {
        t.Fatalf("expected *model.APIError, got %T", err)
    }
    if apiErr.Code != "CONFLICT" {
        t.Errorf("error code = %q, want %q", apiErr.Code, "CONFLICT")
    }
}

func TestUserRepo_GetByPhone(t *testing.T) {
    repo := inmem.NewUserRepo()
    ctx := context.Background()
    user := newTestUser("test-1", "9876543210", "Test User")

    if err := repo.Create(ctx, user); err != nil {
        t.Fatalf("Create: %v", err)
    }

    got, err := repo.GetByPhone(ctx, "9876543210")
    if err != nil {
        t.Fatalf("GetByPhone: %v", err)
    }
    if got.UID != "test-1" {
        t.Errorf("UID = %q, want %q", got.UID, "test-1")
    }
}

func TestUserRepo_GetNotFound(t *testing.T) {
    repo := inmem.NewUserRepo()

    _, err := repo.GetByID(context.Background(), "nonexistent")
    if err == nil {
        t.Fatal("expected error for nonexistent user, got nil")
    }

    apiErr, ok := err.(*model.APIError)
    if !ok {
        t.Fatalf("expected *model.APIError, got %T", err)
    }
    if apiErr.Code != "NOT_FOUND" {
        t.Errorf("error code = %q, want %q", apiErr.Code, "NOT_FOUND")
    }
}

func TestUserRepo_Update(t *testing.T) {
    repo := inmem.NewUserRepo()
    ctx := context.Background()
    user := newTestUser("test-1", "9876543210", "Original Name")

    if err := repo.Create(ctx, user); err != nil {
        t.Fatalf("Create: %v", err)
    }

    user.DisplayName = "Updated Name"
    if err := repo.Update(ctx, user); err != nil {
        t.Fatalf("Update: %v", err)
    }

    got, err := repo.GetByID(ctx, "test-1")
    if err != nil {
        t.Fatalf("GetByID after update: %v", err)
    }
    if got.DisplayName != "Updated Name" {
        t.Errorf("DisplayName = %q, want %q", got.DisplayName, "Updated Name")
    }
}

func TestUserRepo_List(t *testing.T) {
    repo := inmem.NewUserRepo()
    ctx := context.Background()

    for i := 0; i < 5; i++ {
        user := newTestUser(
            fmt.Sprintf("user-%d", i),
            fmt.Sprintf("98765432%02d", i),
            fmt.Sprintf("User %d", i),
        )
        if err := repo.Create(ctx, user); err != nil {
            t.Fatalf("Create user %d: %v", i, err)
        }
    }

    page, total, err := repo.List(ctx, repository.Pagination{Limit: 3, Offset: 0})
    if err != nil {
        t.Fatalf("List: %v", err)
    }
    if total != 5 {
        t.Errorf("total = %d, want 5", total)
    }
    if len(page) != 3 {
        t.Errorf("page size = %d, want 3", len(page))
    }
}
```

### Testing for Concurrency Safety

You can test that your repos are thread-safe by running concurrent operations under
the race detector:

```go
func TestUserRepo_ConcurrentAccess(t *testing.T) {
    repo := inmem.NewUserRepo()
    ctx := context.Background()
    var wg sync.WaitGroup

    // Spawn 100 goroutines doing concurrent reads and writes
    for i := 0; i < 100; i++ {
        wg.Add(1)
        go func(n int) {
            defer wg.Done()
            uid := fmt.Sprintf("user-%d", n)
            phone := fmt.Sprintf("98%08d", n)

            user := newTestUser(uid, phone, fmt.Sprintf("User %d", n))
            _ = repo.Create(ctx, user)
            _, _ = repo.GetByID(ctx, uid)
            _, _ = repo.GetByPhone(ctx, phone)
            _, _, _ = repo.List(ctx, repository.DefaultPagination())

            user.DisplayName = fmt.Sprintf("Updated %d", n)
            _ = repo.Update(ctx, user)
        }(i)
    }

    wg.Wait()
}
```

Run this test with `-race`:

```bash
go test -race -run TestUserRepo_ConcurrentAccess ./internal/inmem/
```

If there's a data race, the race detector will catch it and fail the test.

### Subtests with t.Run

`t.Run` creates named subtests that appear in hierarchical output:

```go
func TestAPIErrors(t *testing.T) {
    t.Run("NotFoundError", func(t *testing.T) {
        err := model.NotFoundError("User", "abc")
        if err.Code != "NOT_FOUND" {
            t.Errorf("Code = %q, want NOT_FOUND", err.Code)
        }
        if !strings.Contains(err.Message, "User") {
            t.Errorf("Message should contain 'User', got %q", err.Message)
        }
    })

    t.Run("ConflictError", func(t *testing.T) {
        err := model.ConflictError("already exists")
        if err.Code != "CONFLICT" {
            t.Errorf("Code = %q, want CONFLICT", err.Code)
        }
    })

    t.Run("ValidationError", func(t *testing.T) {
        err := model.ValidationError("bad input")
        if err.Code != "VALIDATION_ERROR" {
            t.Errorf("Code = %q, want VALIDATION_ERROR", err.Code)
        }
    })
}
```

You can run a specific subtest:

```bash
go test -run TestAPIErrors/NotFoundError ./internal/model/
```

### t.Fatal vs t.Error

- `t.Error` / `t.Errorf`: Records a failure but continues the test
- `t.Fatal` / `t.Fatalf`: Records a failure and stops the test immediately

Use `t.Fatal` when continuing would make no sense (e.g., if setup fails):

```go
// If Create fails, there's no point testing GetByID
if err := repo.Create(ctx, user); err != nil {
    t.Fatalf("Create: %v", err) // stop here
}

// But for the actual assertion, use Error — let other checks run
if got.DisplayName != "Test" {
    t.Errorf("DisplayName = %q, want %q", got.DisplayName, "Test") // continue
}
if got.Role != model.RoleParent {
    t.Errorf("Role = %q, want %q", got.Role, model.RoleParent) // also check this
}
```

### Parallel Tests

Mark tests as safe for parallel execution:

```go
func TestParallel(t *testing.T) {
    tests := []struct {
        name  string
        input int
        want  int
    }{
        {"double 1", 1, 2},
        {"double 2", 2, 4},
        {"double 3", 3, 6},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel() // this subtest can run concurrently with other Parallel subtests
            got := double(tt.input)
            if got != tt.want {
                t.Errorf("double(%d) = %d, want %d", tt.input, got, tt.want)
            }
        })
    }
}
```

### Benchmarks

Benchmark functions measure performance:

```go
func BenchmarkUserRepoGetByID(b *testing.B) {
    repo := inmem.NewUserRepo()
    ctx := context.Background()
    user := newTestUser("bench-1", "9876543210", "Bench User")
    _ = repo.Create(ctx, user)

    b.ResetTimer() // don't count setup time

    for i := 0; i < b.N; i++ {
        _, _ = repo.GetByID(ctx, "bench-1")
    }
}

func BenchmarkUserRepoCreate(b *testing.B) {
    repo := inmem.NewUserRepo()
    ctx := context.Background()

    b.ResetTimer()

    for i := 0; i < b.N; i++ {
        user := newTestUser(
            fmt.Sprintf("user-%d", i),
            fmt.Sprintf("98%08d", i),
            "Bench User",
        )
        _ = repo.Create(ctx, user)
    }
}
```

Running benchmarks:

```bash
go test -bench=. -benchmem ./internal/inmem/
```

Output:

```
BenchmarkUserRepoGetByID-8    5000000    312 ns/op    96 B/op    2 allocs/op
BenchmarkUserRepoCreate-8    1000000    1504 ns/op    320 B/op    5 allocs/op
```

Reading the output:
- `5000000` — the benchmark ran 5 million iterations
- `312 ns/op` — each GetByID took 312 nanoseconds
- `96 B/op` — each operation allocated 96 bytes
- `2 allocs/op` — each operation made 2 heap allocations

### Test Helpers

Create helper functions to reduce boilerplate. Use `t.Helper()` so that error messages
point to the calling test, not the helper:

```go
func assertNoError(t *testing.T, err error) {
    t.Helper() // mark this function as a helper
    if err != nil {
        t.Fatalf("unexpected error: %v", err)
    }
}

func assertEqual[T comparable](t *testing.T, got, want T) {
    t.Helper()
    if got != want {
        t.Errorf("got %v, want %v", got, want)
    }
}

// Usage:
func TestWithHelpers(t *testing.T) {
    repo := inmem.NewUserRepo()
    err := repo.Create(context.Background(), newTestUser("1", "999", "Test"))
    assertNoError(t, err) // if this fails, error points here, not inside assertNoError

    user, err := repo.GetByID(context.Background(), "1")
    assertNoError(t, err)
    assertEqual(t, user.DisplayName, "Test")
}
```

### TestMain — Global Setup/Teardown

```go
func TestMain(m *testing.M) {
    // Global setup (runs once before all tests)
    setupTestDatabase()

    code := m.Run() // run all tests

    // Global teardown (runs once after all tests)
    teardownTestDatabase()

    os.Exit(code)
}
```

### HTTP Handler Testing

Test HTTP handlers using `net/http/httptest`:

```go
func TestHealthEndpoint(t *testing.T) {
    req := httptest.NewRequest("GET", "/api/v1/health", nil)
    w := httptest.NewRecorder()

    handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Content-Type", "application/json")
        w.Write([]byte(`{"status":"ok"}`))
    })
    handler.ServeHTTP(w, req)

    if w.Code != http.StatusOK {
        t.Errorf("status = %d, want %d", w.Code, http.StatusOK)
    }

    var resp map[string]string
    if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
        t.Fatalf("failed to parse response: %v", err)
    }
    if resp["status"] != "ok" {
        t.Errorf("status = %q, want %q", resp["status"], "ok")
    }
}
```

### Testing Middleware

```go
func TestAuthMiddleware_MissingToken(t *testing.T) {
    handler := middleware.Auth("test-secret")(
        http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            t.Error("handler should not be called without auth")
        }),
    )

    req := httptest.NewRequest("GET", "/protected", nil)
    w := httptest.NewRecorder()
    handler.ServeHTTP(w, req)

    if w.Code != http.StatusUnauthorized {
        t.Errorf("status = %d, want %d", w.Code, http.StatusUnauthorized)
    }
}

func TestAuthMiddleware_ValidToken(t *testing.T) {
    secret := "test-secret"
    token, _ := middleware.GenerateJWT("user-1", "parent", secret, time.Hour)

    var gotClaims *middleware.UserClaims
    handler := middleware.Auth(secret)(
        http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            gotClaims, _ = middleware.GetUserClaims(r.Context())
            w.WriteHeader(http.StatusOK)
        }),
    )

    req := httptest.NewRequest("GET", "/protected", nil)
    req.Header.Set("Authorization", "Bearer "+token)
    w := httptest.NewRecorder()
    handler.ServeHTTP(w, req)

    if w.Code != http.StatusOK {
        t.Errorf("status = %d, want %d", w.Code, http.StatusOK)
    }
    if gotClaims == nil {
        t.Fatal("claims should not be nil")
    }
    if gotClaims.UserID != "user-1" {
        t.Errorf("UserID = %q, want %q", gotClaims.UserID, "user-1")
    }
}
```

### Test Caching

Go caches test results. If you haven't changed the code, `go test` reuses cached results
(indicated by `(cached)` in the output). To force a re-run:

```bash
go test -count=1 ./...  # disable caching
go clean -testcache     # clear the test cache
```

---

## 7. Project Structure Best Practices

### The Anuyatra Backend Layout

```
backend/
├── cmd/server/main.go              # Entry point — thin, wiring only
├── internal/                        # Cannot be imported by external code
│   ├── config/config.go             # Environment-based configuration
│   ├── model/                       # Domain types (no business logic)
│   │   ├── user.go                  # AppUser, UserRole
│   │   ├── errors.go                # APIError, error constructors
│   │   ├── broker_profile.go
│   │   ├── candidate_profile.go
│   │   ├── parent_profile.go
│   │   ├── agency.go
│   │   ├── link_request.go
│   │   ├── shared_profile.go
│   │   ├── messaging.go
│   │   └── extras.go
│   ├── repository/interfaces.go     # All repository interfaces in one file
│   ├── service/container.go         # DI container
│   ├── inmem/                       # In-memory implementations
│   │   ├── module.go                # Factory: NewContainer()
│   │   ├── helpers.go               # Shared utilities (paginate, containsFold)
│   │   ├── user_repo.go
│   │   ├── auth_repo.go
│   │   ├── agency_repo.go
│   │   ├── profile_repos.go
│   │   ├── link_repo.go
│   │   ├── shared_profile_repo.go
│   │   ├── messaging_repo.go
│   │   └── extras_repo.go
│   ├── handler/                     # HTTP handlers
│   │   ├── handler.go               # Shared handler setup
│   │   ├── helpers.go               # JSON/pagination helpers
│   │   ├── routes.go                # Route registration
│   │   ├── auth_handlers.go
│   │   ├── user_handlers.go
│   │   ├── profile_handlers.go
│   │   ├── agency_handlers.go
│   │   ├── link_handlers.go
│   │   ├── shared_profile_handlers.go
│   │   ├── messaging_handlers.go
│   │   └── misc_handlers.go
│   └── middleware/                   # HTTP middleware
│       ├── middleware.go             # Logger, CORS, Recoverer, Auth
│       └── jwt.go                   # JWT generation/validation
├── go.mod                           # Module definition and dependencies
└── go.sum                           # Dependency checksums
```

### Why `internal/`

The `internal` directory is special in Go. Code inside `internal/` can only be imported by code
within the parent of `internal/`. External packages **cannot** import it — the Go compiler
enforces this.

```
github.com/anuyatra/backend/internal/model    ← can be imported by anything under backend/
github.com/someother/project                  ← CANNOT import internal/model (compiler error)
```

This is the access control mechanism in Go. You use it to mark packages as private to your
module.

### Why `cmd/`

The `cmd/` directory is a convention (not compiler-enforced) for executable entry points. Each
subdirectory contains a `main` package:

```
cmd/
├── server/main.go     # the API server
├── migrate/main.go    # database migration tool (future)
└── seed/main.go       # data seeding tool (future)
```

Each is built separately: `go build ./cmd/server`, `go build ./cmd/migrate`.

### Dependency Direction

The import graph is carefully designed to prevent circular imports (which are compile errors
in Go):

```
main.go
  └── imports: config, handler, inmem, middleware

handler/
  └── imports: model, repository (Pagination), service (Container), middleware (claims)

inmem/
  └── imports: model, repository (implements interfaces)

middleware/
  └── imports: (no internal packages — self-contained)

service/
  └── imports: repository (holds interface types)

repository/
  └── imports: model (uses domain types in interface signatures)

model/
  └── imports: (NOTHING internal — only stdlib)
```

**The golden rule**: Model imports nothing. Repository imports model. Everything else imports
model and repository. This prevents circular dependencies.

If `model` imported `handler`, and `handler` imported `model`, you'd get:

```
import cycle not allowed:
    handler → model → handler
```

### Why One `interfaces.go` File

All 14 repository interfaces live in a single file (`repository/interfaces.go`). Why?

1. **Discoverability**: Open one file to see every data access contract
2. **Consistency**: Easy to ensure all interfaces follow the same patterns
3. **Implementation checklist**: When building a new storage backend (e.g., PostgreSQL),
   you see every interface you need to implement in one place
4. **Minimal package**: The `repository` package has no implementation code — just types
   and interfaces. This keeps the dependency graph clean.

### The Container Pattern

`service.Container` is a simple DI (dependency injection) container — a struct that holds all
the application's dependencies:

```go
type Container struct {
    Users             repository.UserRepository
    Auth              repository.AuthRepository
    ParentProfiles    repository.ParentProfileRepository
    // ... 11 more interfaces ...
    JWTSecret        string
    JWTAccessExpiry  time.Duration
    JWTRefreshExpiry time.Duration
    IsDev            bool
}
```

This pattern enables swapping implementations:

```go
// Development: in-memory storage
container := inmem.NewContainer(cfg.JWTSecret, cfg.IsDev())

// Production: PostgreSQL storage (future)
container := postgres.NewContainer(db, cfg.JWTSecret, cfg.IsDev())

// Testing: mock storage
container := mock.NewContainer()
```

The handler layer depends on `*service.Container` which holds **interfaces**. It doesn't know
or care whether the data is in memory, PostgreSQL, or MongoDB.

---

## 8. Production Readiness Checklist

The Anuyatra backend is production-ready in **structure** but uses in-memory storage. Here's
what needs to happen for a real production deployment.

### 1. Real Database

Implement a `postgres/` (or `mongo/`) package with the same repository interfaces:

```go
package postgres

type UserRepo struct {
    db *sql.DB
}

func (r *UserRepo) GetByID(ctx context.Context, id string) (*model.AppUser, error) {
    var user model.AppUser
    err := r.db.QueryRowContext(ctx,
        `SELECT uid, phone_number, display_name, photo_url, role, agency_id, created_at, is_active
         FROM users WHERE uid = $1`, id,
    ).Scan(&user.UID, &user.PhoneNumber, &user.DisplayName, &user.PhotoURL,
        &user.Role, &user.AgencyID, &user.CreatedAt, &user.IsActive)
    if err == sql.ErrNoRows {
        return nil, model.NotFoundError("User", id)
    }
    return &user, err
}
```

No mutex needed — the database handles concurrent access. No copy-on-read needed — each
query returns fresh data.

### 2. Connection Pooling

```go
db, err := sql.Open("postgres", cfg.DatabaseURL)
if err != nil {
    log.Fatal(err)
}
db.SetMaxOpenConns(25)             // max simultaneous connections
db.SetMaxIdleConns(10)             // keep 10 idle connections warm
db.SetConnMaxLifetime(5 * time.Minute)  // recycle connections every 5 minutes
db.SetConnMaxIdleTime(1 * time.Minute)  // close idle connections after 1 minute
```

### 3. Database Migrations

Use a migration tool like `golang-migrate` or `goose`:

```bash
# Install
go install github.com/pressly/goose/v3/cmd/goose@latest

# Create a migration
goose -dir migrations create add_users_table sql
```

```sql
-- migrations/001_add_users_table.sql

-- +goose Up
CREATE TABLE users (
    uid TEXT PRIMARY KEY,
    phone_number TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL,
    photo_url TEXT,
    role TEXT NOT NULL CHECK (role IN ('parent', 'broker', 'candidate', 'agencyAdmin')),
    agency_id TEXT REFERENCES agencies(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX idx_users_phone ON users(phone_number);

-- +goose Down
DROP TABLE users;
```

### 4. Structured Logging

Replace `log.Printf` with `slog` (Go 1.21+):

```go
import "log/slog"

logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
    Level: slog.LevelInfo,
}))

logger.Info("server starting",
    slog.Int("port", cfg.Port),
    slog.String("env", cfg.Env),
    slog.String("storage", "in-memory"),
)

logger.Error("request failed",
    slog.String("method", r.Method),
    slog.String("path", r.URL.Path),
    slog.Int("status", 500),
    slog.Any("error", err),
    slog.Duration("duration", time.Since(start)),
)
```

Output (JSON, machine-parseable):
```json
{"time":"2024-01-15T10:30:00Z","level":"INFO","msg":"server starting","port":8080,"env":"development","storage":"in-memory"}
```

### 5. Metrics with Prometheus

```go
import "github.com/prometheus/client_golang/prometheus"

var (
    requestsTotal = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "http_requests_total",
            Help: "Total number of HTTP requests",
        },
        []string{"method", "path", "status"},
    )

    requestDuration = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "http_request_duration_seconds",
            Help:    "HTTP request duration in seconds",
            Buckets: prometheus.DefBuckets,
        },
        []string{"method", "path"},
    )
)

func init() {
    prometheus.MustRegister(requestsTotal, requestDuration)
}
```

### 6. Health Checks

```go
// Liveness: "is the process alive?"
mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
    w.Write([]byte(`{"status":"alive"}`))
})

// Readiness: "is the process ready to serve traffic?"
mux.HandleFunc("GET /readyz", func(w http.ResponseWriter, r *http.Request) {
    if err := db.PingContext(r.Context()); err != nil {
        w.WriteHeader(http.StatusServiceUnavailable)
        json.NewEncoder(w).Encode(map[string]string{"status": "not ready", "error": err.Error()})
        return
    }
    w.WriteHeader(http.StatusOK)
    w.Write([]byte(`{"status":"ready"}`))
})
```

### 7. Rate Limiting

```go
import "golang.org/x/time/rate"

type IPRateLimiter struct {
    mu       sync.Mutex
    limiters map[string]*rate.Limiter
}

func (rl *IPRateLimiter) GetLimiter(ip string) *rate.Limiter {
    rl.mu.Lock()
    defer rl.mu.Unlock()
    limiter, exists := rl.limiters[ip]
    if !exists {
        limiter = rate.NewLimiter(rate.Every(time.Second), 10) // 10 requests/second
        rl.limiters[ip] = limiter
    }
    return limiter
}

func RateLimit(rl *IPRateLimiter) Middleware {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            limiter := rl.GetLimiter(r.RemoteAddr)
            if !limiter.Allow() {
                writeError(w, http.StatusTooManyRequests, model.ErrRateLimited)
                return
            }
            next.ServeHTTP(w, r)
        })
    }
}
```

### 8. Input Validation

```go
func validateCreateUser(user *model.AppUser) error {
    if user.UID == "" {
        return model.ValidationError("uid is required")
    }
    if len(user.PhoneNumber) < 10 {
        return model.ValidationError("phone number must be at least 10 digits")
    }
    if !user.Role.IsValid() {
        return model.ValidationError("invalid role: " + string(user.Role))
    }
    return nil
}
```

### 9. Graceful Shutdown (Already Implemented!)

Our `main.go` already implements graceful shutdown correctly:

```go
quit := make(chan os.Signal, 1)
signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
<-quit

log.Println("Shutting down server...")
ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
defer cancel()

if err := srv.Shutdown(ctx); err != nil {
    log.Fatalf("forced shutdown: %v", err)
}
```

`srv.Shutdown` waits for in-flight requests to complete (up to the 10-second timeout), then
closes all listeners. New connections are refused immediately.

### 10. Docker Multi-Stage Build

```dockerfile
# Build stage
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /server ./cmd/server

# Run stage
FROM alpine:3.19
RUN apk --no-cache add ca-certificates
COPY --from=builder /server /server
EXPOSE 8080
ENTRYPOINT ["/server"]
```

Final image size: ~15MB (vs ~1GB for a naive `golang:latest` image).

### 11. CI/CD Pipeline

```bash
# Linting and static analysis
go vet ./...                    # built-in linter
staticcheck ./...               # advanced static analysis
golangci-lint run               # meta-linter (runs many linters)

# Testing
go test -race -cover ./...      # tests with race detection and coverage

# Security
govulncheck ./...               # check for known vulnerabilities in dependencies

# Build
go build -o server ./cmd/server # verify it compiles
```

### 12. Security Hardening

```go
srv := &http.Server{
    Addr:         ":8080",
    Handler:      stack(mux),
    ReadTimeout:  15 * time.Second,   // ← already set
    WriteTimeout: 15 * time.Second,   // ← already set
    IdleTimeout:  60 * time.Second,   // ← already set
    ReadHeaderTimeout: 5 * time.Second, // prevent slowloris
    MaxHeaderBytes: 1 << 20,            // 1MB max header size
}
```

Additional headers to add:

```go
func SecurityHeaders(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("X-Content-Type-Options", "nosniff")
        w.Header().Set("X-Frame-Options", "DENY")
        w.Header().Set("X-XSS-Protection", "1; mode=block")
        w.Header().Set("Strict-Transport-Security", "max-age=63072000; includeSubDomains")
        w.Header().Set("Content-Security-Policy", "default-src 'self'")
        next.ServeHTTP(w, r)
    })
}
```

---

## 9. Common Go Gotchas (Things That Trip Everyone Up)

### 1. nil Interface != Interface Containing nil

This is the most confusing thing in Go:

```go
type MyError struct{ msg string }
func (e *MyError) Error() string { return e.msg }

func mayFail() error {
    var err *MyError = nil   // typed nil pointer
    return err               // wraps nil pointer in error interface
}

func main() {
    err := mayFail()
    fmt.Println(err == nil) // false! 🤯
}
```

Why? An interface value consists of two parts: (type, value). When you return `err` (a
`*MyError`), the interface becomes `(*MyError, nil)`. The type is not nil, so the interface
is not nil.

**The fix**: Always return `nil` directly for interface types:

```go
func mayFail() error {
    var err *MyError = nil
    if err != nil {
        return err
    }
    return nil // return bare nil, not a typed nil
}
```

### 2. Map Iteration Order Is Random

```go
m := map[string]int{"a": 1, "b": 2, "c": 3}
for k, v := range m {
    fmt.Println(k, v)
}
// Output order is DIFFERENT each time you run this!
// This is intentional — Go randomizes map iteration to prevent
// code from accidentally depending on insertion order.
```

This is why our `List` methods that need ordering always sort after collecting:

```go
sort.Slice(all, func(i, j int) bool {
    return all[i].ViewedAt.After(all[j].ViewedAt)
})
```

### 3. Goroutine Leaks

A goroutine that can never exit is a memory leak:

```go
// LEAK: if nobody ever sends on ch, this goroutine lives forever
go func() {
    val := <-ch
    process(val)
}()

// FIX: use context for cancellation
go func() {
    select {
    case val := <-ch:
        process(val)
    case <-ctx.Done():
        return // clean exit when context is cancelled
    }
}()
```

### 4. Shadowed Variables

`:=` can accidentally shadow an outer variable:

```go
x := 1
if true {
    x := 2        // this creates a NEW x, shadows the outer one
    fmt.Println(x) // 2
}
fmt.Println(x)     // 1 — outer x was never modified!

// Fix: use = instead of := to assign to the existing variable
x := 1
if true {
    x = 2          // modifies the outer x
    fmt.Println(x) // 2
}
fmt.Println(x)     // 2
```

This is especially dangerous with error variables:

```go
var err error
if condition {
    result, err := someFunction() // shadows outer err!
    // err is a new variable scoped to this if block
    _ = result
}
// outer err is still nil, even if someFunction returned an error
```

Use `go vet -shadow` or `golangci-lint` to detect shadowed variables.

### 5. Slice Gotcha: Append Can Mutate the Original

```go
original := []int{1, 2, 3, 4, 5}
sub := original[:3]        // [1, 2, 3] — shares underlying array!

sub = append(sub, 99)      // modifies original's 4th element!
fmt.Println(original)       // [1, 2, 3, 99, 5] 😱

// Fix: use full slice expression to limit capacity
sub := original[:3:3]      // length=3, capacity=3
sub = append(sub, 99)      // allocates new array, original untouched
fmt.Println(original)       // [1, 2, 3, 4, 5] ✓
```

This is why our repos copy slices before returning them:

```go
all := make([]*model.ViewedProfile, len(src))
copy(all, src)  // independent copy — modifications don't affect internal state
```

### 6. defer in Loops

`defer` is function-scoped, not block-scoped:

```go
// BAD: opens 1000 files, none are closed until the function returns
func processFiles(paths []string) {
    for _, path := range paths {
        f, _ := os.Open(path)
        defer f.Close() // deferred until processFiles returns, not loop iteration!
    }
    // at this point, all 1000 files are still open
}

// FIX 1: extract to a function
func processFiles(paths []string) {
    for _, path := range paths {
        processOne(path) // defer runs when processOne returns
    }
}

func processOne(path string) {
    f, _ := os.Open(path)
    defer f.Close() // runs when processOne returns — each iteration
    // ...
}

// FIX 2: use an immediately-invoked function
func processFiles(paths []string) {
    for _, path := range paths {
        func() {
            f, _ := os.Open(path)
            defer f.Close()
            // ...
        }()
    }
}
```

### 7. String Concatenation Performance

```go
// BAD: O(n²) — each + creates a new string
result := ""
for i := 0; i < 10000; i++ {
    result += fmt.Sprintf("item %d, ", i)
}

// GOOD: O(n) — strings.Builder uses a growing byte buffer
var b strings.Builder
for i := 0; i < 10000; i++ {
    fmt.Fprintf(&b, "item %d, ", i)
}
result := b.String()
```

### 8. Time Formatting Uses a Reference Time

Go doesn't use `yyyy-mm-dd`. Instead, it uses a specific reference time that you rearrange:

```
Mon Jan 2 15:04:05 MST 2006
```

Why these specific values? **1 2 3 4 5 6 7**:
- Month = 1 (January)
- Day = 2
- Hour = 3 (15 for 24h)
- Minute = 4 (04)
- Second = 5 (05)
- Year = 6 (2006)
- Timezone offset = -7 (MST = -0700)

```go
t := time.Now()
fmt.Println(t.Format("2006-01-02"))           // "2024-01-15"
fmt.Println(t.Format("02/01/2006 15:04"))     // "15/01/2024 14:30"
fmt.Println(t.Format(time.RFC3339))           // "2024-01-15T14:30:00+05:30"
fmt.Println(t.Format("Monday, January 2"))    // "Monday, January 15"
```

### 9. Loop Variable Capture (Fixed in Go 1.22+)

Before Go 1.22, this was a common bug:

```go
// Before Go 1.22 — BUG: all goroutines print the same value
for _, val := range values {
    go func() {
        fmt.Println(val) // captures the loop variable by reference
    }()
}

// Fix (pre-1.22): shadow the variable
for _, val := range values {
    val := val // create a new variable in each iteration
    go func() {
        fmt.Println(val) // captures the new variable
    }()
}
```

**Go 1.22+ fixed this** — each loop iteration now creates a new variable. But you'll still
see the `val := val` pattern in older code.

### 10. Unkeyed Struct Literals Are Fragile

```go
// BAD: if someone adds a field to AppUser, this breaks
user := model.AppUser{"uid-1", "9876543210", "Name", nil, "parent", nil, time.Now(), true}

// GOOD: unaffected by new fields, self-documenting
user := model.AppUser{
    UID:         "uid-1",
    PhoneNumber: "9876543210",
    DisplayName: "Name",
    Role:        model.RoleParent,
    IsActive:    true,
}
```

`go vet` warns about unkeyed struct literals for exported types.

---

## 10. Go vs Dart/Flutter — Side-by-Side Comparison

Since the Anuyatra project has both a Flutter frontend and a Go backend, here's how the
two languages compare across every major dimension.

### Error Handling

| Go | Dart |
|---|---|
| Errors are values: `error` interface | Exceptions: `throw` / `try-catch` |
| `result, err := doThing()` | `try { result = doThing(); } catch (e) { }` |
| Multiple return values | Single return + exceptions |
| Must handle every error explicitly | Can ignore exceptions (bad practice) |
| No stack traces by default | Stack traces included |
| `errors.Is()`, `errors.As()` for matching | `on TypeError catch (e)` for type matching |
| No `try/catch` (by design) | `try/catch/finally` |

```go
// Go
user, err := repo.GetByID(ctx, id)
if err != nil {
    return nil, fmt.Errorf("get user: %w", err)
}
```

```dart
// Dart
try {
  final user = await repo.getUserById(id);
} on NotFoundException catch (e) {
  // handle not found
} catch (e) {
  // handle any other error
}
```

### Null Safety

| Go | Dart |
|---|---|
| Pointers can be nil | Sound null safety |
| `*string` = nullable string | `String?` = nullable String |
| `string` = always has a value (zero value: `""`) | `String` = never null |
| No compiler enforcement for nil checks | Compiler enforces null checks |
| `if ptr != nil { *ptr }` | `value?.method()` or `value!.method()` |

```go
// Go
type AppUser struct {
    PhotoURL *string  `json:"photoUrl"` // nil = no photo
    AgencyID *string  `json:"agencyId"` // nil = no agency
}

if user.PhotoURL != nil {
    fmt.Println(*user.PhotoURL)
}
```

```dart
// Dart
class AppUser {
  final String? photoUrl;  // null = no photo
  final String? agencyId;  // null = no agency
}

if (user.photoUrl != null) {
  print(user.photoUrl!);
}
// or: print(user.photoUrl ?? 'default.png');
```

### Concurrency

| Go | Dart |
|---|---|
| Goroutines (true parallelism) | Isolates (true parallelism) + async/await (single-thread) |
| `go func() { ... }()` | `Isolate.spawn(function, message)` or `compute()` |
| Channels for communication | Ports for isolate communication |
| Shared memory + mutexes | Isolates don't share memory |
| `sync.RWMutex` for safety | No mutexes needed (no shared memory) |
| ~2KB per goroutine | ~2MB per isolate |
| Millions of goroutines | Handful of isolates |
| `select` for multiplexing | `Future.wait()`, `Stream` |
| No async/await (by design) | `async` / `await` everywhere |

```go
// Go — true parallelism, shared memory
var mu sync.Mutex
var results []string

for _, url := range urls {
    go func(u string) {
        resp := fetch(u)
        mu.Lock()
        results = append(results, resp)
        mu.Unlock()
    }(url)
}
```

```dart
// Dart — async/await on single thread
final results = await Future.wait(
  urls.map((url) => http.get(Uri.parse(url))),
);
```

### Object-Oriented Programming

| Go | Dart |
|---|---|
| No classes — structs + methods | Classes with inheritance |
| Composition over inheritance | Both composition and inheritance |
| Interfaces are implicit (duck typing) | Interfaces are explicit (`implements`) |
| No constructors — factory functions | Constructors (named, factory, const) |
| No method overriding | Method overriding with `@override` |
| Embedding for code reuse | `extends` / `with` (mixins) for code reuse |

```go
// Go — composition via embedding
type Animal struct {
    Name string
}
func (a Animal) Speak() string { return "..." }

type Dog struct {
    Animal          // embedded — Dog "has-a" Animal
    Breed string
}
// Dog automatically has Speak() method from Animal
```

```dart
// Dart — inheritance
class Animal {
  final String name;
  Animal(this.name);
  String speak() => '...';
}

class Dog extends Animal {
  final String breed;
  Dog(super.name, this.breed);

  @override
  String speak() => 'Woof!';
}
```

### Generics

| Go | Dart |
|---|---|
| Added in Go 1.18 (2022) | Always had generics |
| `func paginate[T any](items []*T, ...)` | `List<T> paginate<T>(List<T> items, ...)` |
| Type constraints: `[T comparable]` | No type constraints (uses `extends`) |
| No generic methods on types (only functions and types) | Generic methods on classes |

```go
// Go
func paginate[T any](items []*T, p Pagination) ([]*T, int) { ... }
// used: paginate(users, p)   — T inferred as model.AppUser
// used: paginate(agencies, p) — T inferred as model.Agency
```

```dart
// Dart
List<T> paginate<T>(List<T> items, int limit, int offset) { ... }
// used: paginate(users, 20, 0)
```

### Package Management

| Go | Dart |
|---|---|
| Go Modules (`go.mod`) | Pub (`pubspec.yaml`) |
| `go get github.com/pkg@v1.2.3` | `flutter pub add package_name` |
| Semantic import versioning | Semantic version constraints |
| `go.sum` for checksums | `pubspec.lock` for checksums |
| Minimal version selection (MVS) | Version solving (like npm) |
| No central registry (any Git URL) | Central registry (pub.dev) |

### Testing

| Go | Dart |
|---|---|
| Built-in: `go test` | `flutter test` / `dart test` |
| `*_test.go` files | `*_test.dart` files |
| `func TestXxx(t *testing.T)` | `void main() { test('xxx', () { }); }` |
| `t.Error`, `t.Fatal` | `expect(actual, matcher)` |
| Table-driven tests (convention) | Parameterized tests (plugin) |
| `t.Run("subtest", ...)` | `group('description', () { ... })` |
| Benchmarks built-in: `BenchmarkXxx` | Benchmarks need external package |
| Race detector: `-race` flag | No equivalent |

### JSON Serialization

| Go | Dart |
|---|---|
| Struct tags: `` `json:"fieldName"` `` | Manual or code-generated `fromJson`/`toJson` |
| `encoding/json` stdlib | `dart:convert` + `json_serializable` |
| Reflection-based (runtime) | Code generation (build-time) or manual |
| `json.Marshal(v)` / `json.Unmarshal(data, &v)` | `jsonEncode(v)` / `jsonDecode(data)` |

```go
// Go — struct tags drive serialization
type AppUser struct {
    UID         string   `json:"uid"`
    PhoneNumber string   `json:"phoneNumber"`
    PhotoURL    *string  `json:"photoUrl"`    // omitted if nil? Only with omitempty
    Role        UserRole `json:"role"`
}

data, _ := json.Marshal(user)
// {"uid":"abc","phoneNumber":"999","photoUrl":null,"role":"parent"}
```

```dart
// Dart — manual or generated
class AppUser {
  final String uid;
  final String phoneNumber;
  final String? photoUrl;
  final String role;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    uid: json['uid'],
    phoneNumber: json['phoneNumber'],
    photoUrl: json['photoUrl'],
    role: json['role'],
  );

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'phoneNumber': phoneNumber,
    'photoUrl': photoUrl,
    'role': role,
  };
}
```

### Type System

| Go | Dart |
|---|---|
| Statically typed | Statically typed |
| Structural typing (interfaces) | Nominal typing |
| No union types | Sealed classes (Dart 3) |
| `any` (alias for `interface{}`) | `dynamic` / `Object?` |
| Type assertions: `v.(Type)` | Type checks: `v is Type` |
| Type switch: `switch v.(type)` | Pattern matching: `switch (v) { case Type(): }` |
| No enums (use `const` + `iota`) | First-class enums |

### Summary Table

| Feature | Go | Dart |
|---|---|---|
| Primary paradigm | Procedural + concurrent | OOP + functional |
| Memory model | Shared memory | Isolates (no sharing) |
| Error handling | Explicit values | Exceptions |
| Null safety | Pointers (runtime) | Sound (compile-time) |
| Compilation | Native binary | AOT (mobile) / JIT (dev) |
| Binary size | ~10-15 MB | ~15-30 MB (Flutter) |
| Startup time | Instant (~1ms) | ~100-500ms (Flutter) |
| GC | Concurrent, low-latency | Generational |
| Learning curve | Simple, small spec | Larger spec, more features |

---

## 11. Go Standard Library Power Tools

Go's standard library is famously comprehensive. Here's a tour of the packages used in
the Anuyatra backend, with practical examples.

### encoding/json — JSON Marshaling

Used everywhere for request/response serialization:

```go
import "encoding/json"

// Struct → JSON bytes
data, err := json.Marshal(user)
// {"uid":"abc","phoneNumber":"999","role":"parent"}

// JSON bytes → struct
var user model.AppUser
err := json.Unmarshal(data, &user)

// Stream encoding (used in our handlers):
json.NewEncoder(w).Encode(response)  // writes JSON directly to http.ResponseWriter

// Stream decoding (used in our handlers):
json.NewDecoder(r.Body).Decode(&request)  // reads JSON directly from request body

// Pretty printing
data, _ := json.MarshalIndent(user, "", "  ")
```

**Struct tags** control serialization behavior:

```go
type Example struct {
    Name     string  `json:"name"`                // rename field
    Age      int     `json:"age,omitempty"`        // omit if zero value
    Internal string  `json:"-"`                    // never serialize
    Score    float64 `json:"score,string"`         // serialize as string "3.14"
}
```

### net/http — The Web Server

The foundation of our API:

```go
import "net/http"

// Creating a server
mux := http.NewServeMux()

// Go 1.22+ pattern-based routing (used in our project):
mux.HandleFunc("GET /api/v1/users/{id}", handleGetUser)
mux.HandleFunc("POST /api/v1/users", handleCreateUser)

// Path parameters (Go 1.22+):
func handleGetUser(w http.ResponseWriter, r *http.Request) {
    id := r.PathValue("id")  // extract {id} from the URL pattern
    // ...
}

// Query parameters:
limit := r.URL.Query().Get("limit")    // returns "" if not present

// Request headers:
token := r.Header.Get("Authorization")

// Response:
w.Header().Set("Content-Type", "application/json")
w.WriteHeader(http.StatusOK)     // 200
w.Write([]byte(`{"status":"ok"}`))

// Server configuration:
srv := &http.Server{
    Addr:         ":8080",
    Handler:      mux,
    ReadTimeout:  15 * time.Second,
    WriteTimeout: 15 * time.Second,
    IdleTimeout:  60 * time.Second,
}
```

### context — Request-Scoped Values and Cancellation

The `context` package carries request-scoped data, cancellation signals, and deadlines:

```go
import "context"

// Every repository method takes a context as the first argument:
func (r *UserRepo) GetByID(ctx context.Context, id string) (*model.AppUser, error)

// Creating contexts:
ctx := context.Background()                              // root context
ctx, cancel := context.WithTimeout(ctx, 10*time.Second)  // with deadline
defer cancel()                                            // always cancel!
ctx, cancel := context.WithCancel(ctx)                    // manual cancellation

// Checking for cancellation:
select {
case <-ctx.Done():
    return ctx.Err() // context.Canceled or context.DeadlineExceeded
default:
    // continue working
}

// Storing values (used for auth claims):
ctx = context.WithValue(ctx, userClaimsKey, claims)
claims := ctx.Value(userClaimsKey).(*UserClaims)
```

Our middleware stores user claims in the context:

```go
func WithUserClaims(ctx context.Context, claims *UserClaims) context.Context {
    return context.WithValue(ctx, userClaimsKey, claims)
}

func GetUserClaims(ctx context.Context) (*UserClaims, bool) {
    claims, ok := ctx.Value(userClaimsKey).(*UserClaims)
    return claims, ok
}
```

### sync — Synchronization Primitives

Covered extensively in section 3. Summary of what's available:

```go
import "sync"

var mu sync.Mutex        // exclusive lock
var rw sync.RWMutex      // reader-writer lock
var once sync.Once       // run-once guard
var wg sync.WaitGroup    // goroutine counter
var pool sync.Pool       // object pool
var cond sync.Cond       // condition variable
var m sync.Map           // concurrent-safe map
```

### time — Durations, Timers, Formatting

```go
import "time"

// Durations (used throughout our server config):
15 * time.Second         // 15s
5 * time.Minute          // 5m
7 * 24 * time.Hour       // 7 days (used for refresh token expiry)

// Measuring elapsed time:
start := time.Now()
doWork()
elapsed := time.Since(start) // time.Duration

// Formatting (see section 9 for the reference time):
t.Format("2006-01-02 15:04:05")  // "2024-01-15 14:30:00"
t.Format(time.RFC3339)           // "2024-01-15T14:30:00+05:30"

// Parsing:
t, err := time.Parse(time.RFC3339, "2024-01-15T14:30:00+05:30")

// Timers for timeouts:
timer := time.NewTimer(5 * time.Second)
<-timer.C // blocks for 5 seconds

// Tickers for periodic work:
ticker := time.NewTicker(1 * time.Minute)
defer ticker.Stop()
for range ticker.C {
    doPeriodicWork()
}
```

### fmt — Formatted I/O

```go
import "fmt"

// Printing:
fmt.Println("hello")              // with newline
fmt.Printf("port: %d\n", 8080)   // formatted
fmt.Fprintf(w, "error: %s", msg)  // to any io.Writer

// String formatting:
s := fmt.Sprintf(":%d", cfg.Port) // returns a string

// Format verbs:
%s    // string
%d    // integer
%f    // float
%v    // default format (works for any type)
%+v   // struct with field names
%#v   // Go syntax representation
%T    // type name
%p    // pointer address
%w    // error wrapping (fmt.Errorf only)
%q    // quoted string
%x    // hexadecimal
%b    // binary
```

### strconv — String/Number Conversion

Used in our `parsePagination` helper:

```go
import "strconv"

// String → int (used in query parameter parsing):
n, err := strconv.Atoi("42")           // 42, nil
n, err := strconv.Atoi("abc")          // 0, error

// Int → string:
s := strconv.Itoa(42)                  // "42"

// More precise conversions:
f, err := strconv.ParseFloat("3.14", 64)  // 3.14
b, err := strconv.ParseBool("true")       // true
n, err := strconv.ParseInt("FF", 16, 64)  // 255 (hex)

s := strconv.FormatFloat(3.14, 'f', 2, 64)  // "3.14"
s := strconv.FormatBool(true)                 // "true"
```

### strings — String Manipulation

Used in our helper functions:

```go
import "strings"

strings.Contains("hello world", "world")     // true
strings.HasPrefix("hello", "hel")            // true
strings.HasSuffix("hello", "llo")            // true
strings.ToLower("HELLO")                     // "hello"
strings.ToUpper("hello")                     // "HELLO"
strings.TrimSpace("  hello  ")               // "hello"
strings.Split("a,b,c", ",")                  // ["a", "b", "c"]
strings.Join([]string{"a", "b"}, ", ")       // "a, b"
strings.ReplaceAll("aaa", "a", "b")          // "bbb"
strings.TrimPrefix("Bearer token", "Bearer ") // "token"

// Used in our CORS middleware:
origin := strings.Split(envStr("ALLOWED_ORIGINS", "*"), ",")

// Used in our auth middleware:
token := strings.TrimPrefix(header, "Bearer ")

// Efficient string building:
var b strings.Builder
b.WriteString("hello")
b.WriteString(" world")
s := b.String() // "hello world"
```

### crypto/rand — Secure Random Bytes

Used in our OTP generation:

```go
import "crypto/rand"

// Generate cryptographically secure random bytes:
b := make([]byte, 3)
_, _ = rand.Read(b)

// Our OTP generation in auth_repo.go:
func randomOTP() string {
    b := make([]byte, 3)
    _, _ = rand.Read(b)
    n := int(b[0])<<16 | int(b[1])<<8 | int(b[2])
    return fmt.Sprintf("%06d", n%1000000) // 6-digit OTP
}
```

**Never use `math/rand` for security-sensitive operations** — it's not cryptographically
secure. Use `crypto/rand` for tokens, OTPs, session IDs, and anything security-related.

### os, os/signal, syscall — Process Management

Used in our graceful shutdown:

```go
import (
    "os"
    "os/signal"
    "syscall"
)

// Environment variables:
v := os.Getenv("PORT")                    // read env var
os.Setenv("KEY", "value")                 // set env var

// Signal handling:
quit := make(chan os.Signal, 1)
signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
<-quit  // block until signal

// Common signals:
syscall.SIGINT   // Ctrl+C (interrupt)
syscall.SIGTERM  // kill command (terminate gracefully)
syscall.SIGHUP   // terminal closed (hangup)
syscall.SIGUSR1  // user-defined signal 1 (often: reload config)

// Process exit:
os.Exit(0)  // success
os.Exit(1)  // failure
```

### log — Simple Logging

Used throughout our codebase:

```go
import "log"

log.Println("server started")                        // 2024/01/15 14:30:00 server started
log.Printf("listening on :%d", 8080)                 // 2024/01/15 14:30:00 listening on :8080
log.Fatal("cannot start")                             // logs + os.Exit(1)
log.Fatalf("server error: %v", err)                   // formatted + os.Exit(1)
log.Panic("something terrible")                       // logs + panic()

// Custom logger:
logger := log.New(os.Stderr, "API: ", log.LstdFlags|log.Lshortfile)
logger.Println("request received")
// API: 2024/01/15 14:30:00 handler.go:42: request received
```

For production, prefer `log/slog` (Go 1.21+) for structured, leveled logging.

### errors — Error Wrapping and Unwrapping

```go
import "errors"

// Wrapping errors (adds context while preserving the original):
err := fmt.Errorf("get user %s: %w", id, originalErr)

// Unwrapping:
inner := errors.Unwrap(err)

// Checking error identity:
if errors.Is(err, model.ErrNotFound) {
    // handle not found
}

// Checking error type:
var apiErr *model.APIError
if errors.As(err, &apiErr) {
    fmt.Println(apiErr.Code) // use the typed error
}

// Creating sentinel errors:
var ErrNotFound = errors.New("not found")
```

### runtime/debug — Stack Traces for Panic Recovery

Used in our `Recoverer` middleware:

```go
import "runtime/debug"

func Recoverer(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        defer func() {
            if err := recover(); err != nil {
                log.Printf("PANIC: %v\n%s", err, debug.Stack())
                http.Error(w, `{"error":"internal server error"}`, 500)
            }
        }()
        next.ServeHTTP(w, r)
    })
}
```

`debug.Stack()` returns a formatted stack trace as a byte slice — invaluable for debugging
panics in production.

### sort — Sorting Slices

Used in our repos for ordering results:

```go
import "sort"

// Sort a slice with a custom comparator:
sort.Slice(all, func(i, j int) bool {
    return all[i].ViewedAt.After(all[j].ViewedAt) // newest first
})

// Sort strings:
sort.Strings([]string{"banana", "apple", "cherry"})

// Sort ints:
sort.Ints([]int{3, 1, 4, 1, 5})

// Check if sorted:
sort.IsSorted(sort.IntSlice(nums))

// Binary search (slice must be sorted):
i := sort.SearchStrings(sorted, "target")

// Stable sort (preserves order of equal elements):
sort.SliceStable(all, func(i, j int) bool { ... })
```

### Quick Reference: Other Useful stdlib Packages

| Package | Purpose | Example Use |
|---|---|---|
| `bytes` | Byte slice manipulation | `bytes.Buffer` for building byte output |
| `io` | I/O interfaces | `io.Reader`, `io.Writer`, `io.Copy` |
| `path/filepath` | File path manipulation | `filepath.Join("a", "b", "c.txt")` |
| `regexp` | Regular expressions | Input validation |
| `math` | Math functions | `math.Max`, `math.Floor` |
| `net/url` | URL parsing | `url.Parse("https://example.com/path?q=1")` |
| `html/template` | Safe HTML templating | Server-rendered HTML (if needed) |
| `database/sql` | Database interface | PostgreSQL, MySQL, SQLite drivers |
| `embed` | Embed files in binary | Static assets, SQL migrations |
| `testing` | Test framework | Everything in section 6 |
| `net/http/httptest` | HTTP testing utilities | `httptest.NewRecorder()` |

---

## Wrapping Up: The Complete Picture

Let's zoom out and see how everything in this 4-part series connects.

### What We Built

A full-featured REST API with:

- **14 repository interfaces** covering users, auth, profiles, agencies, links, shares,
  messaging, bookmarks, views, activity, notes, and meetings
- **12 in-memory repository implementations** with proper thread safety
- **40+ HTTP endpoints** organized by domain
- **JWT authentication** with access and refresh tokens
- **Middleware chain**: logging, CORS, panic recovery, auth
- **Graceful shutdown** with OS signal handling
- **Dependency injection** via a Container struct

### What We Learned

| Part | Topics |
|---|---|
| Part 1 | Syntax, variables, functions, control flow, data types |
| Part 2 | Structs, methods, interfaces, packages, imports |
| Part 3 | Error handling, HTTP handlers, middleware, JSON, routing |
| Part 4 | Goroutines, channels, sync, testing, production patterns |

### The Go Philosophy

Go is deliberately simple. It doesn't have:
- Classes or inheritance
- Generics method receivers
- Exceptions
- Decorators or annotations
- Operator overloading
- Default parameter values
- Optional parameters

Each omission is intentional. Go trades expressiveness for readability, clever features for
explicit code, and syntactic sugar for maintainability at scale.

As Rob Pike (co-creator of Go) said:

> **Simplicity is complicated.** The art of programming is the art of organizing complexity;
> of mastering multitude and avoiding its bastard chaos as effectively as possible.

The Anuyatra backend demonstrates this philosophy: every file is readable, every pattern is
consistent, every interface is minimal, and every concurrent operation is safe.

---

**End of Part 4 — Congratulations on completing the Go Masterclass!**

You now have the conceptual foundation to:
1. Read and understand any Go codebase
2. Write thread-safe concurrent code
3. Build production-ready HTTP APIs
4. Write comprehensive tests
5. Structure Go projects for long-term maintainability

The next step: pick a feature, open the code, and start building.
