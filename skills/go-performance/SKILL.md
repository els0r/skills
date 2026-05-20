---
name: go-performance
tags: [golang, performance]
description: >
  Go performance analysis: memory allocation, CPU bottlenecks, concurrency
  contention, struct alignment, escape analysis, and benchmarking patterns.
  Use this skill whenever writing performance-sensitive Go code, reviewing Go
  code for efficiency, discussing allocations or GC pressure, benchmarking,
  profiling with pprof, or optimizing hot paths. Also trigger when the user
  mentions sync.Pool, atomic operations, pre-allocation, or escape analysis —
  even without saying "performance."
---

# Go Performance

Performance is cost in cloud, experience on user-facing paths. Never optimize without measurement.

## Workflow

1. Establish a benchmark baseline (see `go-testing` for benchmark patterns).
2. Implement fixes.
3. Compare with `benchstat baseline.txt optimized.txt`.
4. Always ask the user to validate results — if they look too good, they probably are.

Prioritize: hot paths > allocation-heavy code > concurrency contention > stylistic.

---

## Rules

### 1. Expose pprof

Every service must expose pprof. Import `_ "net/http/pprof"` and run `go http.ListenAndServe(":6060", nil)` alongside the app.

| Endpoint | Shows |
|---|---|
| `/debug/pprof/profile` | CPU profile |
| `/debug/pprof/heap` | Live heap allocations |
| `/debug/pprof/allocs` | Cumulative allocation counts |
| `/debug/pprof/goroutine` | Goroutine stacks |
| `/debug/pprof/mutex` | Mutex contention |
| `/debug/pprof/block` | Blocking operations |

```bash
go tool pprof http://localhost:6060/debug/pprof/profile?seconds=30
go tool pprof http://localhost:6060/debug/pprof/heap
```

### 2. `sync.Pool` — Reuse Temporary Buffers

Reuse buffers on high-frequency paths to relieve GC.

```go
var bufPool = sync.Pool{New: func() any { return new(bytes.Buffer) }}

func handleRequest(w http.ResponseWriter, r *http.Request) {
    buf := bufPool.Get().(*bytes.Buffer)
    defer func() { buf.Reset(); bufPool.Put(buf) }()
    buf.ReadFrom(r.Body)
    process(buf.Bytes())
}
```

**NEVER pool `strings.Builder` when returning `b.String()`** — `String()` shares the builder's internal buffer (no copy). Resetting the builder corrupts the string the previous caller still holds. Use `bytes.Buffer` and consume `buf.Bytes()` before reset.

Use `bytes.Clone(buf.Bytes())` when you need to retain data after the buffer is returned to the pool.

### 3. Pre-allocate Slices and Maps

Known size → pre-allocate. Avoids runtime reallocation and memory copying.

```go
// ❌
var result []int
for _, v := range input {
    result = append(result, v*2)
}

// ✅
result := make([]int, 0, len(input))
```

### 4. `strings.Builder` for Concatenation

Strings are immutable. `+` in a loop creates a new string per iteration.

```go
var b strings.Builder
b.Grow(expectedTotalLength)
for _, word := range words {
    b.WriteString(word)
}
```

### 5. `strconv` over `fmt`

`fmt` uses reflection. For basic type conversions, use `strconv`.

```go
s := strconv.Itoa(42)       // not fmt.Sprintf("%d", 42)
s := strconv.FormatFloat(f, 'f', 2, 64) // not fmt.Sprintf("%.2f", f)
```

### 6. Struct Field Alignment

Order fields largest → smallest to minimize padding.

```go
// ❌ 24 bytes (padding waste)
type User struct {
    IsAdmin bool   // 1 + 7 padding
    ID      int64  // 8
    Age     int8   // 1 + 7 padding
}

// ✅ 16 bytes
type User struct {
    ID      int64  // 8
    IsAdmin bool   // 1
    Age     int8   // 1 + 6 padding
}
```

Use the `fieldalignment` tool to detect suboptimal ordering.

### 7. Prefer `strings`/`bytes` over `regexp`

`regexp` is safe but slow. Use `strings` functions for simple matching. If regex is unavoidable, compile once at package level with `regexp.MustCompile`.

### 8. Escape Analysis — Keep Allocations on the Stack

Don't return pointers to small, short-lived structs. For slices, use the append pattern — pass a destination slice so the caller manages memory.

```go
// ❌ forces heap allocation every call
func (m *IntMap) Convert() []int {
    result := make([]int, 0, len(m.data))
    for _, v := range m.data {
        result = append(result, v)
    }
    return result
}

// ✅ caller controls allocation
func (m *IntMap) Convert(dst []int) []int {
    for _, v := range m.data {
        dst = append(dst, v)
    }
    return dst
}
```

### 9. Concrete Returns over Interface Returns

Accept interfaces, return concrete types. Returning an interface forces a wrapping allocation. (See also `go-style` interface design rules.)

### 10. Atomics and RWMutex for Contention

`sync.Mutex` serializes goroutines. Use `sync/atomic` for counters, `sync.RWMutex` for read-heavy data.

```go
// ❌ mutex for a counter
type Counter struct {
    mu sync.Mutex
    v  int64
}

// ✅ atomic
type Counter struct {
    v atomic.Int64
}
func (c *Counter) Add() { c.v.Add(1) }
```

### 11. `defer` on Hot Paths

Go 1.22+ significantly reduced `defer` overhead. In most code, use `defer` freely (as `go-style` recommends). Only consider manual unlock/close on benchmarked hot paths where profiling shows `defer` as a measurable contributor — this is rare post-1.22.
