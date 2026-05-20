---
name: go-style
tags: [golang, style]
description: >
  Go coding conventions, error handling, interface design, and idiomatic
  patterns. Use when writing, reviewing, refactoring, or discussing Go code.
  Fires alongside coding-style — do not repeat cross-language rules.
---

# Go Coding Style

Cross-language principles (never-nesting, naming, restraint) live in `coding-style`. This file covers Go-specific idioms only.

## Never Nesting — Go Idiom

Guard clauses with early return. `continue` in loops. This is the Go spelling of the universal rule.

```go
// ✅
func checkA(str string) bool {
    if str == "" {
        return false
    }
    for _, char := range str {
        if char == ' ' || char == '\t' || char == '\n' {
            continue
        }
        if char == 'A' || char == 'a' {
            return true
        }
    }
    return false
}
```

## Error Handling

Handle all errors. Wrap with context using `%w`. No naked returns.

```go
// ✅ wrap with context
if err := repo.SaveUser(ctx, user); err != nil {
    return fmt.Errorf("save user %s: %w", user.ID, err)
}

// ❌ context lost
if err := repo.SaveUser(ctx, user); err != nil {
    return err
}
```

Sentinel errors for known conditions. Custom types when callers need structured data.

```go
var (
    ErrNotFound     = errors.New("resource not found")
    ErrUnauthorized = errors.New("unauthorized")
)

// check with errors.Is / errors.As — never string matching
```

Acceptable exception: best-effort cleanup with explicit discard.

```go
_ = writer.Close()
```

## Zero-Value Design

Types must be usable at zero value. No constructor-required initialization.

```go
// ✅ zero value works
type Counter struct {
    mu    sync.Mutex
    count int
}

// ❌ nil map panic
type BadCounter struct {
    counts map[string]int
}
```

## Interface Design

- Accept interfaces, return structs.
- Single-method interfaces preferred. Compose when needed.
- Define interfaces at the consumer, not the implementor.

```go
// consumer owns the interface
package service

type UserStore interface {
    GetUser(id string) (*User, error)
}

type Service struct {
    store UserStore
}
```

## Functional Options

Use for constructors with optional configuration.

```go
type Option func(*Server)

func WithTimeout(d time.Duration) Option {
    return func(s *Server) { s.timeout = d }
}

func NewServer(addr string, opts ...Option) *Server {
    s := &Server{addr: addr, timeout: 30 * time.Second}
    for _, opt := range opts {
        opt(s)
    }
    return s
}
```

## Package Organization

- Short, lowercase names — no underscores.
- `internal/` for packages not intended for external import.
- Avoid package-level mutable state — use dependency injection.

## Quick Reference

- `context.Context` as first parameter
- `defer` for cleanup
- Unexported by default; export only what the API requires
- Run `golangci-lint` on all code — unlinted code isn't ready
- Validate inputs at boundaries — strong types over `interface{}`
- Never log secrets
- Follow [Effective Go](https://go.dev/doc/effective_go)
