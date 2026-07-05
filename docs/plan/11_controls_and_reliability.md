# Phase 11 — Pause / Resume / Cancel / Retry & Reliability

## Goal

Operators can control in-flight executions: cancel queued/running work, pause and resume actions that opt in (between batches by default, mid-batch with checkpoints), and manually retry a failed batch. Dead workers no longer strand executions in "running".

## Prerequisites

Phase 10 complete (live monitoring).

## Acceptance criteria owned

- AC-DEV-050 — opt in to pause/resume per action
- AC-DEV-051 — without extra code, pause takes effect between batches
- AC-DEV-052 — with extra code, check pause/cancel signals inside loops
- AC-DEV-053 — save/restore checkpoint state for mid-batch resume
- AC-OP-060 — cancel a queued or running execution (when supported)
- AC-OP-061 — pause a running execution (when the action supports it)
- AC-OP-062 — resume a paused execution
- AC-OP-063 — controls only shown when meaningful
- AC-SYS-005 — failed batch fails the execution unless manually retried
- AC-SYS-006 — manually retry a failed batch from the dashboard
- AC-SYS-060 — dead worker doesn't leave execution stuck in "running"

## Deliverables

1. **Signalling model:** `pause_requested_at` / `cancel_requested_at` columns on `Execution` (migration). Requesting is instant and safe from the dashboard; the running job observes signals at safe points. Statuses only change when the signal is honoured.
2. **DSL & developer API:**
   - `pausable!` flag on `Base` (pause/resume only for opted-in actions; cancel available to all).
   - Between-batch honouring (free for developers): phase 9's chaining checks signals before enqueueing the next batch — pause → `pause!` (remaining batches pending); cancel → `cancel!` (remaining batches `skipped`).
   - In-loop honouring (`ctx.check_signals!`): raises `MoActions::Cancelled` or `MoActions::Paused` control-flow exceptions that `Runner` catches to transition cleanly. Also `ctx.cancelled?`/`ctx.pause_requested?` for manual handling.
   - Checkpoints: `ctx.save_checkpoint(hash)` persists to the batch's `checkpoint` jsonb (column exists since phase 4); `ctx.checkpoint` reads it. Mid-batch pause keeps the batch `running`→ back to `pending`-with-checkpoint (pick one representation, document it); resume re-runs that batch and the action uses `ctx.checkpoint` to skip completed work.
   - Queued (not started) cancel: guard at job start — if cancel requested, transition and exit without performing.
3. **Resume:** `executions#resume` → `run!`-adjacent transition, clear `pause_requested_at`, enqueue `RunBatchJob` for the first non-completed batch (delay/window rules still apply).
4. **Manual batch retry (AC-SYS-005/006):** on a failed execution's detail page, "Retry failed batch" resets the failed batch (keep the failure in the log; clear batch `error_message`, status → pending), transitions execution `failed → queued` (extend the phase 4 state machine — this is the one new edge), enqueues from that batch. Chaining then continues normally.
5. **Dashboard controls:** pause/resume/cancel/retry buttons in the detail header, each rendered only when meaningful (state predicates on `Execution`: `cancellable?`, `pausable_now?`, `resumable?`, `retryable?`); "Pause requested…" interim indicator; buttons update live via phase 10 broadcasts. Server-side guards mirror every UI rule.
6. **Stuck-execution detection (AC-SYS-060):** `ctx` heartbeats a `heartbeat_at` column (migration) every progress/log write, throttled (e.g. ≥ every 30s). `MoActions::ReapStuckExecutionsJob` marks executions `running` with stale heartbeats (config `stuck_after`, default 15.minutes) as failed with an explanatory error message and log entry. Host schedules it via their own cron/recurring-job tooling — document in the initializer template; do not add a scheduler dependency.
7. **Dummy app:** pausable sample action with checkpointed loop for QA.

## Implementation notes

- Signals are read from the DB at check points — no Redis, no adapter-specific cancellation.
- Control-flow exceptions (`Paused`/`Cancelled`) must be rescued precisely in `Runner` — never swallowed by the generic failure handler.
- Be deliberate about race conditions (signal lands as batch finishes): decide the winner, comment the invariant, test it. Use row locks (`with_lock`) where transitions race.

## Out of scope (do not build)

- Auto-retry policies (explicitly out of scope v1). Concurrent execution limits.
- Job-adapter-level kill/abort — cooperative cancellation only.

## Tests required

- Between-batch: pause and cancel signals honoured at chain point; batch/execution statuses and `skipped` correct.
- In-loop: `check_signals!` raises; `Runner` transitions cleanly mid-batch; checkpoint saved and restored across pause → resume.
- Cancel while queued: job exits without performing.
- Resume re-enqueues correct batch, honours delay/window.
- Retry: failed → queued → (drain) → succeeded; retry only from failed; audit log retains original failure.
- Reaper: stale-heartbeat running execution → failed with message; fresh heartbeat untouched.
- Controls visibility: predicates per status matrix; server rejects meaningless requests (e.g. pause on succeeded) with sensible response.
- Non-pausable action: no pause control, pause request rejected; cancel still works.

## Exit criteria

- Manual QA: pause mid-run, watch it take effect, resume, cancel another, retry a failed batch — all from the dashboard.
- Full suite green. ≤ 1000 lines changed. Committed.
