---
name: go-testing
tags: [golang, testing]
description: >
  Go testing standards: table-driven tests, testify/require, sentinel errors,
  mocking, fuzzing, race detection, and test file conventions.
  Use this skill whenever writing, reviewing, or discussing Go tests — including
  unit tests, integration tests, benchmarks, fuzz tests, mocks, or test helpers.
  Also trigger when the user mentions testify, go-cmp, gock, testcontainers,
  or asks "how should I test this" for Go code.
---

# Go Testing

Every piece of logic must be tested.

## Test Libraries

| Library | When to use |
|---------|------------|
| `testify/require` | **Default** — fails fast, clear messages |
| `testify/assert` | Only when the test should continue after a failure |
| `google/go-cmp` | Deep comparisons with custom `cmp.Option`s |
| `gock` | Mock HTTP calls — never hit real endpoints in tests |
| `testcontainers` | Integration tests with external services (databases, queues) |

**Favor `require` over `assert`.** It fails immediately and prevents cascading noise.

## Table-Driven Tests

The default pattern. Use for all new tests.

```go
func TestValidateEmail(t *testing.T) {
    tests := []struct {
        name    string
        email   string
        want    bool
        wantErr string // use sentinel errors when possible (see go-style)
    }{
        {"valid email", "user@example.com", true, ""},
        {"empty email", "", false, "email cannot be empty"},
        {"invalid format", "not-an-email", false, "invalid email format"},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := ValidateEmail(tt.email)
            if tt.wantErr != "" {
                require.ErrorContains(t, err, tt.wantErr)
                return
            }
            require.NoError(t, err)
            require.Equal(t, tt.want, got)
        })
    }
}
```

When testing sentinel errors, use `require.ErrorIs(t, err, ErrNotFound)` instead of string matching.

## Test Helpers and Setup

- Mark helpers with `t.Helper()` — no exceptions. Stack traces point to the calling test.
- Use `t.Cleanup(fn)` for teardown instead of `defer` — it runs even if the test calls `t.Fatal`.
- Arrange-act-assert structure. Every time.

```go
func setupTestDB(t *testing.T) *DB {
    t.Helper()
    db, err := NewDB(":memory:")
    require.NoError(t, err)
    t.Cleanup(func() { db.Close() })
    return db
}
```

## Parallel Tests

Use `t.Parallel()` for independent subtests to speed up suites.

```go
for _, tt := range tests {
    t.Run(tt.name, func(t *testing.T) {
        t.Parallel()
        // ...
    })
}
```

Go 1.22+: loop variable is per-iteration scoped — `tt := tt` capture is no longer needed.

## Mocking

Mock via interfaces. Define mocks in the test file, not production code. Keep them minimal.

```go
type MockEmailSender struct {
    Sent []Email
    Err  error // set to simulate failure
}

func (m *MockEmailSender) Send(to, subject, body string) error {
    if m.Err != nil {
        return m.Err
    }
    m.Sent = append(m.Sent, Email{to, subject, body})
    return nil
}
```

## Fuzzing

Use `testing.F` for input-discovery testing on parsers, validators, and serialization.

```go
func FuzzParseConfig(f *testing.F) {
    f.Add([]byte(`{"key": "value"}`))
    f.Add([]byte(`{}`))

    f.Fuzz(func(t *testing.T, data []byte) {
        cfg, err := ParseConfig(data)
        if err != nil {
            return // invalid input is expected
        }
        // round-trip: marshal back and re-parse
        out, err := cfg.Marshal()
        require.NoError(t, err)
        require.Equal(t, cfg, mustParse(t, out))
    })
}
```

## Test File Conventions

| Type | File Pattern | Notes |
|------|-------------|-------|
| Unit | `*_test.go` | Same package |
| Integration | `*_integration_test.go` | Use `//go:build integration` build tag |

```bash
go test ./...                          # unit tests
go test -tags integration ./...        # integration tests
go test -count=1 ./...                 # bypass test cache
```

## Benchmarks

Write benchmarks for performance-sensitive code. Use `b.Loop()` (Go 1.24+) — prevents dead-code elimination automatically.

```go
func BenchmarkProcessData(b *testing.B) {
    data := generateTestPayload()
    b.ResetTimer()
    b.ReportAllocs()
    for b.Loop() {
        ProcessData(data)
    }
}
```

For `benchstat` comparisons, sync.Pool, and the full optimization workflow, see the `go-performance` skill.

## Race Detector

Always run tests with `-race`. Non-negotiable for goroutines, shared state, or channels.

```bash
go test -race ./...
```

## Skipping Slow Tests

Use `testing.Short()` to gate expensive tests in local dev. CI runs without `-short`.

```go
func TestExpensiveIntegration(t *testing.T) {
    if testing.Short() {
        t.Skip("skipping in short mode")
    }
    // ...
}
```

## Rules

1. **No test, no merge.** Every exported function gets a test. Every bug fix gets a regression test.
2. **`require` over `assert`** unless you explicitly need the test to continue.
3. **`errors.Is` over string matching** — use sentinel errors (see `go-style`).
4. **No real endpoints in tests** — mock HTTP with `gock`, databases with `testcontainers` or in-memory fakes.
5. **`t.Helper()` on every helper** — no exceptions.
6. **`-race` in CI** — always.
7. **Table-driven by default** — flat tests only for genuinely one-off cases.
