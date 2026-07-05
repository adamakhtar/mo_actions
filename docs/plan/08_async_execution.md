# Phase 8 — Async Execution, Perform API & Logging

## Goal

The heart of the gem: confirmed executions run in the background via ActiveJob. Developers get the `perform` API — typed args, performer access, progress reporting, structured logging. Every action runs as one batch by default (multi-batch orchestration is phase 9). Async preflight also lands here, reusing the same job plumbing.

## Prerequisites

Phase 7 complete (file uploads).

## Acceptance criteria owned

- AC-DEV-022 — preflight can be marked async; operator sees waiting state
- AC-DEV-030 — work implemented in a `perform` method
- AC-DEV-031 — report progress as a percentage
- AC-DEV-032 — log entries at levels (info, warning, error)
- AC-DEV-033 — structured exception logging
- AC-DEV-034 — progress-style log messages distinct from percentage progress
- AC-DEV-035 — access to the performer
- AC-DEV-036 — single chronological log stream, optionally batch-tagged
- AC-DEV-040 — every action runs as at least one batch; single-step needs no batch config
- AC-DEV-077 — works with host's job adapter (no adapter-specific code)
- AC-DEV-079 — actions testable without the job queue
- AC-OP-035 — waiting state for expensive (async) preflight
- AC-OP-040 — explicit confirm before execution
- AC-OP-041 — arguments locked on confirm
- AC-OP-042 — redirect to execution detail on begin
- AC-SYS-001 — async execution, operator not blocked
- AC-SYS-004 — arguments immutable once execution begins
- AC-SYS-021 — logs persisted, available after completion
- AC-SYS-022 — logs associated with execution, optionally batch
- AC-SYS-061 — concurrent executions of same action
- AC-SYS-062 — re-run always creates a new execution record

## Deliverables

1. **Developer API — `perform` with a context object:**

   ```ruby
   def perform(args, ctx)
     ctx.log :info, "Starting import"          # persisted LogEntry
     ctx.performer                              # who triggered it
     users.each_with_index do |u, i|
       import(u)
       ctx.progress (i + 1) * 100 / users.size  # percentage
       ctx.log_progress "Imported #{u.email}"   # progress-style message (info-level, tagged progress)
     end
   rescue SomeError => e
     ctx.log_exception e                        # class, message, first N backtrace lines
     raise
   end
   ```

   - `MoActions::Context` wraps the execution + current batch: `log(level, msg)`, `log_progress(msg)`, `log_exception(e)`, `progress(pct)` (clamps, writes batch progress), `performer`, `execution`.
   - Log writes go through the model from phase 4; batch tag set automatically from current batch.
2. **`MoActions::Runner`** — PORO running one batch inline (no job): loads action, builds `Arguments` from stored jsonb, builds `Context`, calls `perform`, handles transitions (`run!` → `succeed!`, or on exception: log_exception, `fail!` with `error_message`). This is the unit developers use in tests (AC-DEV-079) — document it in the class comment.
3. **`MoActions::RunBatchJob < ActiveJob::Base`** — thin: find execution/batch, delegate to `Runner`. No retries (`retry_on` nothing; manual retry is phase 11). Queue name configurable via `MoActions.config.queue_name` (default `:default`).
4. **One implicit batch:** confirming an execution creates batch 1 automatically. `perform(args, ctx)` is the single-batch API; actions never mention batches unless multi-batch (phase 9).
5. **Confirm → execute flow:**
   - Review screen's Execute button (placeholder from phase 6) → confirmation (`data-turbo-confirm` or a confirm page — pick simpler) → `executions#execute`: guards status `ready`, `queue!`, create batch, enqueue `RunBatchJob`, redirect to `executions#show`.
   - Immutability: already enforced at model (phase 4); add a controller guard test proving arguments can't change post-confirm even via crafted request.
6. **Execution detail page (static v1)** — `executions#show` for non-draft statuses: status badge, performer, timestamps, progress bar, argument summary, chronological log list. Manual-refresh only; Turbo Stream liveness is phase 10. Failed executions show `error_message` prominently (groundwork for AC-OP-079).
7. **Async preflight:** `async_preflight!` DSL flag on `Base`; when set, `preflights#create` enqueues `MoActions::PreflightJob` (wrapping phase 6's `PreflightRunner`) and the UI shows a "Preflight running…" waiting state on the draft (meta-refresh or Turbo-frame polling acceptable until phase 10 upgrades it live).
8. **Dummy app:** a sample action with sleeps/logging for manual QA; dummy uses the `:async` ActiveJob adapter in development, `:test` adapter in tests.

## Implementation notes

- Everything through ActiveJob's portable API — `perform_later`, `set(wait:)` (phase 9). Nothing adapter-specific.
- `Runner` must be robust to actions raising anything, including `Exception`-adjacent errors in serialization — the execution must always end in a terminal or resumable state.
- Concurrency (AC-SYS-061/062): no uniqueness constraints on active executions per action; "run" always creates a new record. Add an explicit test.

## Out of scope (do not build)

- Multi-batch, delays, windows, dynamic batches (phase 9).
- Live streaming UI (phase 10). Pause/cancel/retry (phase 11).
- Lifecycle notifications (phase 14).

## Tests required

- `Runner`: success path (transitions, progress, logs persisted), failure path (exception → failed + structured log + error_message), performer access.
- Job: enqueued on execute; `perform_enqueued_jobs` drives execution to succeeded.
- Confirm flow integration: ready → execute → queued → (drain jobs) → succeeded, redirect correct; execute rejected from non-ready statuses; argument update rejected post-confirm.
- Async preflight: flagged action enqueues job, draft shows waiting state, results appear after drain.
- Two concurrent executions of one action both complete independently.
- Direct `Runner` usage without any job — the developer-testing story.

## Exit criteria

- Manual QA: full draft → preflight → confirm → watch (refresh) → succeeded/failed in dummy app.
- Full suite green. ≤ 1000 lines changed. Committed.
