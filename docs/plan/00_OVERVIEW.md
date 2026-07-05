# Mo Actions — Execution Plan Overview

This directory is the build plan for the `mo_actions` gem. It is written to be executed by an LLM agent, one phase at a time.

## How to use this plan (instructions for the executing agent)

1. Read this file, then read [`../TECHNICAL_REQUIREMENTS.md`](../TECHNICAL_REQUIREMENTS.md) in full before starting any phase. Do NOT read [`../ACCEPTANCE_CRITERIA.md`](../ACCEPTANCE_CRITERIA.md) in full — instead, look up only the AC IDs your phase file lists under "Acceptance criteria owned". The AC doc is the authoritative wording; the phase file's one-line summaries are for orientation only.
2. Work on exactly ONE phase file per session. Do not read ahead into later phase files — they may tempt you into premature abstraction.
3. Each phase file is self-contained: goal, deliverables, implementation notes, out-of-scope guardrails, required tests, and exit criteria.
4. Do not start phase N+1 until phase N's exit criteria are all met and the full test suite passes.
5. Each phase must stay under ~1000 changed lines (code + tests + views + migrations). If you cannot, stop and flag it — do not silently split or expand scope.
6. One phase = one commit (or one small commit series). Commit messages must explain WHY (business objective), not just what, and note anything deliberately avoided.
7. When acceptance criteria and this plan conflict: acceptance criteria wins on *what*, technical requirements wins on *how*, this plan wins on *when* (sequencing).

## What we are building

A mountable Rails engine gem (`mo_actions`) that lets developers define admin/operational "actions" in Ruby (with typed arguments, preflight checks, batched background execution, pause/resume/cancel) and lets operators run and monitor them through a bundled Hotwire dashboard with a full audit trail.

## Domain model (target end state)

| Object | Kind | Purpose |
| ------ | ---- | ------- |
| `MoActions::Base` | PORO (host app subclasses) | Action definition: key, name, description, category, argument DSL, `preflight`, `perform`, `authorize` |
| `MoActions::Registry` | Singleton | Boot-time discovery and lookup of action classes by key |
| `MoActions::Arguments` | PORO | Typed, coerced argument values handed to `preflight`/`perform` |
| `MoActions::Execution` | AR model, `mo_actions_executions` | One run: status state machine, performer (polymorphic), `arguments` jsonb, timestamps |
| `MoActions::Batch` | AR model, `mo_actions_batches` | One sequential unit of work within an execution: position, status, progress, timestamps |
| `MoActions::LogEntry` | AR model, `mo_actions_log_entries` | Persisted log line: level, message, optional batch tag |
| `MoActions::RunBatchJob` | ActiveJob | Runs one batch, chains the next (with delay / time window) |
| `MoActions::PreflightJob` | ActiveJob | Runs async preflight checks |
| `MoActions::ExecutionBroadcaster` | PORO | Single place for Turbo Stream broadcasts |
| `MoActions::Configuration` | PORO | `MoActions.configure` block: performer model, auth hooks, retention, timezone, upload adapter |

Execution states: `draft → preflighting → ready → queued → running → paused → succeeded / failed / cancelled`. String statuses, transitions as explicit bang methods on `Execution` (e.g. `queue!`, `succeed!`).

## Non-negotiable conventions (digest — full detail in TECHNICAL_REQUIREMENTS.md)

- Ruby 3.1+, Rails 7.0+, Rails engine with Zeitwerk. Tables prefixed `mo_actions_`.
- ActiveJob (adapter-agnostic), ActiveStorage direct upload, Turbo Streams via ActionCable, Stimulus. No React/Redis/Sidekiq-specific code/webpack/authz gems.
- Minitest, not RSpec. Prefer fixtures. Test via a dummy host app under `test/dummy`.
- Basecamp style: expressive over clever, YAGNI, vanilla Rails, no service-object ceremony, comments explain why not what.
- Status values are strings. No feature flags — phases gate scope.

## Phase index

Phases are strictly sequential. Each file lists the acceptance criteria (AC IDs) it must satisfy.

| # | File | Title | Delivers |
| - | ---- | ----- | -------- |
| 1 | `01_engine_skeleton.md` | Engine skeleton & host integration | Gem scaffold, engine, dummy app, config, mounting, dashboard auth |
| 2 | `02_action_dsl_and_registry.md` | Action definition & discovery | `MoActions::Base`, categories, boot-time registry |
| 3 | `03_argument_dsl.md` | Typed arguments | Scalar + array types, coercion, validations |
| 4 | `04_execution_models.md` | Execution data model | `Execution`, `Batch`, `LogEntry` models, migrations, state machine |
| 5 | `05_dashboard_drafts.md` | Dashboard: browse & draft | Action index, dynamic argument form, save/abandon drafts |
| 6 | `06_preflight.md` | Preflight (synchronous) | Schema validation, blocking/info results, review screen |
| 7 | `07_file_uploads.md` | File uploads | Direct upload, progress, remove/replace, array-of-files, preflight gating |
| 8 | `08_async_execution.md` | Async execution & logging | Confirm → queue → run, perform API, progress %, log stream, async preflight |
| 9 | `09_batching.md` | Multi-batch scheduling | Delays, time windows, dynamic batches, overall progress |
| 10 | `10_live_monitoring.md` | Live monitoring UI | Active list, live detail page via Turbo Streams, log filtering |
| 11 | `11_controls_and_reliability.md` | Pause / resume / cancel / retry | Checkpoints, batch retry, stuck-execution detection |
| 12 | `12_authorization.md` | Authorization | Per-action `authorize`, enforcement, disabled UI states |
| 13 | `13_audit_trail.md` | Audit trail | Succeeded/Failed/Cancelled/Active views, filters, run again |
| 14 | `14_retention_events_docs.md` | Retention, lifecycle events, docs | Cleanup jobs, ActiveSupport::Notifications, README/docs |

## Acceptance criteria coverage map

Every AC is owned by exactly one phase (the phase where it becomes fully satisfied; earlier phases may lay groundwork).

| Phase | AC IDs |
| ----- | ------ |
| 1 | AC-DEV-070, AC-DEV-071, AC-DEV-072, AC-SYS-050 |
| 2 | AC-DEV-001, AC-DEV-002, AC-DEV-003, AC-DEV-004, AC-DEV-005 |
| 3 | AC-DEV-010, AC-DEV-011, AC-DEV-012, AC-DEV-013, AC-DEV-014, AC-DEV-015, AC-DEV-016 |
| 4 | AC-SYS-002, AC-SYS-003 |
| 5 | AC-OP-001, AC-OP-002, AC-OP-010, AC-OP-011, AC-OP-012, AC-OP-013, AC-OP-014, AC-OP-015 |
| 6 | AC-DEV-020, AC-DEV-021, AC-DEV-023, AC-OP-030, AC-OP-031, AC-OP-032, AC-OP-033, AC-OP-034 |
| 7 | AC-DEV-074, AC-OP-020, AC-OP-021, AC-OP-022, AC-OP-023, AC-OP-024, AC-OP-025, AC-OP-026, AC-OP-027, AC-SYS-030, AC-SYS-031, AC-SYS-032 |
| 8 | AC-DEV-022, AC-DEV-030, AC-DEV-031, AC-DEV-032, AC-DEV-033, AC-DEV-034, AC-DEV-035, AC-DEV-036, AC-DEV-040, AC-DEV-077, AC-DEV-079, AC-OP-035, AC-OP-040, AC-OP-041, AC-OP-042, AC-SYS-001, AC-SYS-004, AC-SYS-021, AC-SYS-022, AC-SYS-061, AC-SYS-062 |
| 9 | AC-DEV-041, AC-DEV-042, AC-DEV-043, AC-DEV-044, AC-DEV-075, AC-SYS-010, AC-SYS-011, AC-SYS-012, AC-SYS-013, AC-SYS-020 |
| 10 | AC-OP-050, AC-OP-051, AC-OP-052, AC-OP-053, AC-OP-054, AC-SYS-053 |
| 11 | AC-DEV-050, AC-DEV-051, AC-DEV-052, AC-DEV-053, AC-OP-060, AC-OP-061, AC-OP-062, AC-OP-063, AC-SYS-005, AC-SYS-006, AC-SYS-060 |
| 12 | AC-DEV-060, AC-DEV-061, AC-OP-003, AC-OP-004, AC-SYS-051 |
| 13 | AC-DEV-073, AC-OP-070, AC-OP-071, AC-OP-072, AC-OP-073, AC-OP-074, AC-OP-075, AC-OP-076, AC-OP-077, AC-OP-078, AC-OP-079, AC-OP-080, AC-OP-081, AC-SYS-052 |
| 14 | AC-DEV-076, AC-DEV-078, AC-OP-016, AC-SYS-033, AC-SYS-034, AC-SYS-040, AC-SYS-041 |

## Definition of done (whole project)

1. All AC-DEV, AC-OP, AC-SYS criteria met (see map above).
2. The dummy app can install the gem, define an action with arguments, mount the dashboard, and complete a full draft → preflight → execute → audit cycle.
3. Documentation covers developer setup, action authoring, and operator usage (phase 14).
