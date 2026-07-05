# Phase 4 — Execution Data Model

## Goal

The persistence layer: `Execution`, `Batch`, and `LogEntry` models with migrations and the execution state machine. Pure model layer — controllers/UI arrive in phase 5, jobs in phase 8.

## Prerequisites

Phase 3 complete (argument DSL).

## Acceptance criteria owned

- AC-SYS-002 — each execution records performer, started/finished timestamps
- AC-SYS-003 — well-defined states: draft, preflighting, ready, queued, running, paused, succeeded, failed, cancelled

(Groundwork for many later ACs: batches, logs, jsonb arguments.)

## Deliverables

1. **Migrations** (installable into host via `rails mo_actions:install:migrations`; extend the phase 1 install generator to mention this):
   - `mo_actions_executions`: `action_key` (string, indexed), `status` (string, indexed, default "draft"), `performer` (polymorphic, indexed), `arguments` (jsonb on PG / json on SQLite), `preflight_results` (jsonb, for phase 6), `error_message` (text), `progress` (integer 0–100, default 0), `queued_at`, `started_at`, `finished_at`, timestamps.
   - `mo_actions_batches`: `execution` FK, `position` (integer), `status` (string, default "pending"), `progress` (integer, default 0), `error_message`, `checkpoint` (jsonb, for phase 11), `started_at`, `finished_at`, timestamps. Unique index on `[execution_id, position]`.
   - `mo_actions_log_entries`: `execution` FK (indexed), `batch` FK (nullable), `level` (string), `message` (text), `created_at`. No `updated_at` — logs are append-only.
2. **`MoActions::Execution`:**
   - `STATUSES` constant; string enum (`enum :status, ...` with string values) giving predicates and scopes.
   - Explicit transition methods enforcing the legal graph, raising `MoActions::InvalidTransition` otherwise:
     - `start_preflight!` (draft→preflighting), `pass_preflight!` (preflighting→ready), `fail_preflight!` (preflighting→draft),
     - `queue!` (ready→queued, sets `queued_at`), `run!` (queued/paused→running, sets `started_at` first time),
     - `pause!` (running→paused), `succeed!`/`fail!`/`cancel!` (→ terminal, set `finished_at`).
   - `action_class` (registry lookup), `arguments_object` (rebuild `MoActions::Arguments` from stored jsonb), `duration`, `active?` (queued/running/paused), `finished?`.
   - Editing rule enforced at model level: `arguments` writable only in `draft` status (AC-SYS-004 groundwork).
   - Returning to draft (e.g. after failed preflight or argument edit) clears `preflight_results`.
3. **`MoActions::Batch`:** `pending → running → succeeded/failed` (+ `skipped` reserved for cancel in phase 11), same explicit-transition style, `positioned` scope.
4. **`MoActions::LogEntry`:** `LEVELS = %w[debug info warn error]`, level validation, `chronological` scope, `for_batch(batch)` scope.
5. **Fixtures** for all three models covering the interesting states (used heavily in later phases).

## Implementation notes

- Keep transitions dumb: guard + update columns. No callbacks that trigger side effects (broadcasting comes in phase 10 via explicit calls, not model callbacks).
- Statuses are strings in the DB per tech requirements — verify the enum stores strings.
- SQLite (dummy app) doesn't have jsonb; use `json` column type conditionally or plain `json` type which works on both. Note the PG-preferred production guidance in a migration comment.
- `progress` clamped 0–100 at the model.

## Out of scope (do not build)

- Controllers, views, routes for executions (phase 5).
- Jobs (phase 8). Broadcasting (phase 10). Checkpoint APIs (phase 11) — the column exists, nothing reads it yet.
- Retention/cleanup (phase 14).

## Tests required

- Every legal transition; a representative set of illegal transitions raise `InvalidTransition`.
- Timestamps set correctly (`queued_at`, `started_at` only on first run, `finished_at` on terminal).
- Arguments immutable outside draft (update refused/raises).
- `arguments_object` round-trip: build from action + params, save, reload, typed access works.
- Batch position uniqueness; log level validation; scopes.

## Exit criteria

- Migrations run on the dummy app (SQLite) cleanly from scratch.
- Full suite green. ≤ 1000 lines changed. Committed.
