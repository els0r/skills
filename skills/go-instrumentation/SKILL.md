---
name: go-instrumentation
tags: [golang, observability]
description: >
  Observability principles for Go services: structured logging,
  distributed tracing, metrics, context propagation, and HTTP service
  bootstrap. Library-agnostic — the code examples use
  github.com/els0r/telemetry as a concrete reference implementation,
  but the patterns apply equally to slog + OpenTelemetry, zap,
  zerolog, or any equivalent stack. Use this skill whenever writing
  or reviewing Go code that involves logging, tracing, metrics,
  observability, middleware, or service bootstrap — even if the user
  doesn't explicitly mention "instrumentation." Also trigger when the
  user discusses context propagation, span creation, request latency,
  or error tracking.
---

# Go Instrumentation

Universal patterns for instrumenting Go services. The code examples
use `github.com/els0r/telemetry` as a concrete reference
implementation; substitute the equivalent calls in your chosen stack
(slog + OpenTelemetry, zap, zerolog, ...). Pick a library, then don't
reinvent it.

## What to wire up

| Concern | Pattern | Reference impl (`els0r/telemetry`) |
|---------|---------|------------------------------------|
| Context labels | Request-scoped metadata attached to ctx (user_id, request_id) | `telemetry.WithLabels(ctx, ...)` |
| Logging | Logger that pulls labels from context automatically | `logging.FromContext(ctx)` |
| Tracing | Span helper that also emits structured logs | `spanlogging.Start()` |
| HTTP middleware | One-call middleware registration for the router | `obsgin.RegisterObservability(router, ...)` |

**Labels vs span attributes:** Labels propagate through the entire request context (correlation). Span attributes are local to a single operation (e.g., `order_id` on a processing span).

## Structured Logging

Always use structured key-value logging. Never concatenate strings.

```go
logger := logging.FromContext(ctx)
logger.Infow("user created",
    "user_id", user.ID,
    "email", user.Email,
)

// ❌ logger.Info("User " + user.Email + " created with ID " + user.ID)
```

Use consistent, lowercase, snake_case keys:

| Key | Usage |
|-----|-------|
| `user_id` | User identifier |
| `request_id` | Request correlation ID |
| `company_id` | Tenant/company identifier |
| `duration_ms` | Operation duration in milliseconds |
| `error` | Error value |

### Log Levels

| Level | When |
|-------|------|
| `Debug` | Detailed flow for local dev — never in prod hot paths |
| `Info` | Normal operations worth recording (service started, job completed) |
| `Warn` | Degraded but recoverable (retry succeeded, fallback used) |
| `Error` | Failed operation that needs attention — always include the `error` key |

**Log or return, not both.** If you return an error to the caller, don't also log it — the caller decides. Log only at the point where the error is handled (not propagated).

## Tracing

Use `spanlogging.Start()` (or your library's equivalent span helper) for operations involving downstream systems or complex logic. Don't trace trivial functions.

```go
func ProcessOrder(ctx context.Context, orderID string) error {
    ctx, span := spanlogging.Start(ctx, "order.Process")
    defer span.End()

    span.SetAttributes(attribute.String("order_id", orderID))

    if err := validate(ctx, orderID); err != nil {
        span.RecordError(err)
        return fmt.Errorf("validate order %s: %w", orderID, err)
    }
    // ...
    return nil
}
```

- Keep span names consistent: `package.Function` or `service/operation`.
- Use `span.RecordError(err)` before returning errors — it attaches the error to the trace.

## HTTP Service Bootstrap

Every Go HTTP service should wire observability from the start. The example below uses `els0r/telemetry` + Gin; the structure (init observability, register middleware, start the server) is identical for any stack.

```go
func main() {
    ctx := context.Background()

    flags := pflag.NewFlagSet("service", pflag.ExitOnError)
    obs.RegisterFlags(flags)
    flags.Parse(os.Args[1:])

    shutdown, err := obs.InitFromFlags(ctx)
    if err != nil {
        panic(err)
    }
    defer shutdown()

    router := gin.New()
    obsgin.RegisterObservability(router,
        true,  // logging middleware
        true,  // tracing middleware
        true,  // metrics middleware
        true,  // recovery middleware
        false, // verbose request body logging (disable in prod)
    )

    router.GET("/health", func(c *gin.Context) {
        c.JSON(200, gin.H{"status": "healthy"})
    })

    router.Run(":8080")
}
```

## Profiling

For pprof endpoints and production profiling, see the `go-performance` skill.

## Rules

1. **Never build custom instrumentation** when your library provides it.
2. **Always use middleware** for HTTP instrumentation — don't instrument routes individually.
3. **Never log secrets** (passwords, tokens, API keys) — not even at debug level.
4. **Always pass `context.Context`** through the call chain so labels and trace IDs propagate.
5. **Set timeouts on all external calls** — a missing timeout is a future outage.
6. **Log or return errors, not both** — duplicated error logs obscure the actual call chain.

```go
// ✅ context with timeout
ctx, cancel := context.WithTimeout(ctx, 30*time.Second)
defer cancel()
resp, err := client.Do(req.WithContext(ctx))

// ❌ no timeout — future outage
resp, err := http.Get(url)
```
