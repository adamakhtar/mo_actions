# Phase 13 — Audit Trail

## Goal

Complete execution history: Succeeded / Failed / Cancelled / Active views with counts and filters, read-only detail pages for finished runs, "run again" pre-filling, and host-configurable visibility scoping.

## Prerequisites

Phase 12 complete (authorization).

## Acceptance criteria owned

- AC-DEV-073 — configurable who sees which executions in the audit trail
- AC-OP-070 — browse past executions: Succeeded, Failed, Cancelled views
- AC-OP-071 — dedicated Active view for in-flight executions
- AC-OP-072 — each view shows a count
- AC-OP-073 — filter by action
- AC-OP-074 — filter by performer
- AC-OP-075 — filter by date range
- AC-OP-076 — Failed view shows a summary error message per execution
- AC-OP-077 — full detail: performer, timestamps, duration, status, arguments, batch timeline, complete log
- AC-OP-078 — completed detail pages are read-only
- AC-OP-079 — failed detail pages prominently display the error
- AC-OP-080 — "run again" pre-filled from a previous execution
- AC-OP-081 — run again creates a new execution; original preserved unchanged
- AC-SYS-052 — audit visibility respects host-configured scope

## Deliverables

1. **Navigation & views:** extend phase 10's nav shell to four tabs — Active | Succeeded | Failed | Cancelled — each a status-scoped `executions#index`, count badges per tab (computed with the current filters applied; keep queries indexed). Failed rows additionally show truncated `error_message`.
2. **Filters** (shared partial across tabs): action (select from registry), performer (select or search-lite — a select over recent performers is fine for v1), date range (from/to date fields against `created_at`). Plain GET params, composable, preserved across tab switches. Add DB indexes the filters need (migration).
3. **Visibility scoping (AC-DEV-073 / AC-SYS-052):**

   ```ruby
   MoActions.configure do |c|
     c.execution_scope = ->(scope, performer) { performer.admin? ? scope : scope.where(performer: performer) }
   end
   ```

   - Default: all executions visible to any authenticated dashboard user.
   - Applied in ONE place (e.g. `Execution.visible_to(performer)` delegating to config) and used by every index, count, AND `executions#show` — a direct URL to an out-of-scope execution 404s.
4. **Detail page (finished executions):** phase 8/9's show page already has most content — ensure duration displays, arguments summary is complete, batch timeline and full log render for terminal statuses. Read-only: no mutating controls except "Run again" and phase 11's retry (failed only). Failed pages show the error banner front and centre (verify phase 8's groundwork suffices; polish if not).
5. **Run again:** button on any past execution → creates a NEW draft for `current_performer`, arguments jsonb copied, then the normal draft → preflight → execute flow. File arguments: copy the attachment references so blobs are shared/re-attached (verify ActiveStorage attach-by-blob works here; if sharing is messy, re-attach the same blob to the new execution — do not duplicate file bytes). Original record untouched (assert in test). Requires action authorization (phase 12 guard already covers draft create).

## Implementation notes

- Pagination: keyset or simple `limit/offset` with a "Load more" — pick simplest; audit lists will grow. Use a tiny hand-rolled pager, not a pagination gem.
- If the action registry no longer contains an old execution's `action_key` (action deleted from code), audit pages must still render (show the raw key, disable run-again). Add a test — this WILL happen in real hosts.

## Out of scope (do not build)

- Retention/cleanup (phase 14). Log export (out of scope v1).
- Full-text search over logs or arguments.

## Tests required

- Each tab scopes to its statuses; counts correct and filter-aware.
- Filters: by action, performer, date range, combined; preserved across tabs.
- Scoping: configured lambda restricts lists, counts, and show (404 on direct access); default scope shows all.
- Run again: new draft with identical typed arguments (files included), original unchanged; unauthorized performer cannot run-again an action they can't run.
- Deleted-action execution renders in list and detail without raising.
- Read-only: no mutating controls on succeeded/cancelled detail; mutation requests rejected server-side.

## Exit criteria

- Manual QA: seed a mix of executions, browse all tabs, filter, open details, run again end-to-end.
- Full suite green. ≤ 1000 lines changed. Committed.
