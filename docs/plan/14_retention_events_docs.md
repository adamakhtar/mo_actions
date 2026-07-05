# Phase 14 — Retention, Lifecycle Events & Documentation

## Goal

Close out v1: automatic cleanup of expired drafts, old executions, and orphaned files; lifecycle events hosts can subscribe to for notifications; and the documentation required by the definition of done.

## Prerequisites

Phase 13 complete (audit trail).

## Acceptance criteria owned

- AC-DEV-076 — configurable retention periods for drafts and completed executions
- AC-DEV-078 — subscribe to lifecycle events (succeeded, failed, …)
- AC-OP-016 — abandoned drafts eventually cleaned up automatically
- AC-SYS-033 — orphaned files from abandoned/expired drafts cleaned up
- AC-SYS-034 — files on completed executions retained for a configurable period, then cleaned
- AC-SYS-040 — drafts expire after a configurable period
- AC-SYS-041 — completed executions/logs retained for a configurable period before cleanup

Plus: definition-of-done item 3 (documentation).

## Deliverables

1. **Retention config:**

   ```ruby
   MoActions.configure do |c|
     c.draft_retention     = 7.days    # drafts older than this are destroyed
     c.execution_retention = 90.days   # terminal executions older than finished_at + this are destroyed
     c.file_retention      = 30.days   # attachments on terminal executions purged after this (≤ execution_retention)
   end
   ```

2. **`MoActions::CleanupJob`** (one job, three passes — split only if it reads badly):
   - Expired drafts: destroy (dependent-destroys batches/logs; ActiveStorage purges attachments → covers AC-SYS-033 for expired drafts; manual abandon in phase 5 already destroys, so its attachments purge too — verify with a test).
   - File retention: purge attachments on terminal executions past `file_retention`; execution record and logs remain (audit trail intact, files gone). Detail page renders gracefully with purged files ("file removed per retention policy").
   - Execution retention: destroy terminal executions past `execution_retention` with logs and remaining attachments.
   - Batched deletes (`in_batches`/`find_each`) — retention sweeps must not lock tables on big hosts. Idempotent and safe to run at any frequency; host schedules it via their own recurring-job mechanism (document in initializer template, consistent with phase 11's reaper — mention both in docs).
3. **Lifecycle events via `ActiveSupport::Notifications`:**
   - Instrument at transition call sites (same explicit spots that broadcast): `execution.queued.mo_actions`, `.started`, `.paused`, `.resumed`, `.succeeded`, `.failed`, `.cancelled`, plus `batch.failed.mo_actions`. Payload: `execution_id`, `action_key`, performer gid, `error_message` where relevant.
   - Convenience subscriber API: `MoActions.on(:execution_failed) { |execution| ... }` wrapping the ActiveSupport plumbing (re-fetches the record for the block).
   - Document the notification-wiring pattern (e.g. Slack on failure) in the README — the gem ships no notification UI (out of scope v1).
4. **Documentation** (definition of done #3):
   - `README.md`: what/why, installation (gemfile, install generator, migrations, mount, initializer walkthrough), quick-start action example, links to guides.
   - `docs/guides/action_authoring.md`: full DSL reference — arguments/types/validations, preflight, perform/perform_batch, batching options, pause/checkpoints, authorization, testing actions without the queue (the `Runner` story from phase 8).
   - `docs/guides/operator_guide.md`: dashboard walkthrough — browse, draft, upload, preflight, execute, monitor, control, audit, run again.
   - Host integration notes: auth hookup, performer config, execution scope, realtime config, scheduling `CleanupJob` + `ReapStuckExecutionsJob`, job-adapter requirements (`wait_until` support), timezone.
5. **Final sweep:** run the whole acceptance criteria document against the dummy app; fix any small gaps found (flag anything larger rather than exceeding the phase budget). Verify definition-of-done item 2 end-to-end: fresh install → define action → mount → full cycle.

## Implementation notes

- Retention math from `finished_at` (terminal) / `updated_at` or `created_at` (drafts — pick one, comment why).
- `file_retention > execution_retention` is a config error — validate at configure time with a clear message.

## Out of scope (do not build)

- A scheduler (cron/recurring) dependency. Notification UI. Log export.

## Tests required

- Cleanup: expired vs fresh drafts; file purge honours `file_retention` while keeping record/logs; execution destroy honours `execution_retention`; job idempotent (run twice, no error); attachments actually purged (blob gone).
- Detail page with purged files renders the placeholder.
- Events: each transition emits its event with correct payload; `MoActions.on(:execution_failed)` fires with the execution.
- Config validation: `file_retention > execution_retention` raises.

## Exit criteria

- All ACs verified against the dummy app (final sweep above).
- README + guides complete enough for a new host to install and author an action unaided.
- Full suite green. ≤ 1000 lines changed. Committed. **v1 done.**
