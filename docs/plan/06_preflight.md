# Phase 6 — Preflight (Synchronous)

## Goal

The draft → preflight → ready flow. Operators run schema validation plus an optional developer-defined preflight check, see blocking errors or a review screen with informational results, and any argument change invalidates a passed preflight. Synchronous (inline) preflight only — the async variant rides on the job infrastructure in phase 8.

## Prerequisites

Phase 5 complete (draft form).

## Acceptance criteria owned

- AC-DEV-020 — optional preflight check, runs after schema validation, before execution
- AC-DEV-021 — preflight returns blocking errors and non-blocking informational results
- AC-DEV-023 — preflight receives the same argument values perform would (files: honoured fully once phase 7 lands)
- AC-OP-030 — operator can run preflight once arguments are ready
- AC-OP-031 — schema validation errors shown field-level, linked to form fields
- AC-OP-032 — on failure, operator returns to the form, corrects, re-runs
- AC-OP-033 — on pass, review screen shows informational results
- AC-OP-034 — changing any argument after a pass forces preflight re-run

## Deliverables

1. **Developer API on `MoActions::Base`:**

   ```ruby
   def preflight(args, check)
     check.error "No users matched"            if args.user_ids.empty?   # blocking
     check.info  "Will import #{n} users"                                 # non-blocking
     check.warn  "3 duplicate emails will be skipped"                     # non-blocking, styled as warning
   end
   ```

   - `preflight` optional — actions without it pass automatically after schema validation.
   - `check` is a small `MoActions::PreflightCheck` collector; `passed?` = no errors. Serializes to jsonb (`{ errors: [], infos: [], warnings: [] }`) stored on `execution.preflight_results`.
   - An exception raised inside developer preflight code is caught and recorded as a blocking error (with class/message) — a bad preflight must never 500 the dashboard.
2. **`MoActions::PreflightRunner`** — one PORO orchestrating: build `Arguments` from the draft → schema `valid?` → if invalid, transition back to draft with argument errors → else `start_preflight!`, run action's preflight, then `pass_preflight!` or `fail_preflight!` and store results. Runs inline this phase; phase 8 wraps it in a job for `async_preflight` actions.
3. **Controller & UI:**
   - "Run preflight" button on the draft form → `preflights#create`.
   - Schema failure: re-render the form; errors anchored per field (reuse phase 5 error rendering; add anchor links from an error summary at top).
   - Preflight (developer-check) failure: back to form with a prominent blocking-errors panel above it.
   - Pass: **review screen** (`executions#show` in `ready` status): read-only argument summary, info/warning results, and a placeholder disabled "Execute" button (wired in phase 8), plus "Back to edit".
   - "Back to edit" or any `executions#update` while `ready` → transition back to draft (phase 4's model rule already clears `preflight_results`), forcing re-run. Enforce server-side, not just by hiding buttons.
4. **Dummy app:** give one sample action a meaningful preflight (errors + infos + a warning) for tests and manual QA.

## Implementation notes

- Keep the state flow exactly as phase 4 defined: `draft → preflighting → ready` or back to `draft`. Even though sync preflight makes `preflighting` momentary, pass through it so phase 8's async path needs no new states.
- Review screen argument summary should render via definitions (type-aware display), not raw jsonb inspection.

## Out of scope (do not build)

- Async preflight / waiting UI (phase 8: AC-DEV-022, AC-OP-035).
- Execute/confirm (phase 8). File upload gating (phase 7).

## Tests required

- Runner: schema-invalid → draft + errors; check-with-errors → draft + stored blocking results; pass → ready + stored infos/warnings; exception in preflight → draft + error recorded, no raise.
- Action without preflight passes straight to ready.
- Integration: form → preflight fail → correct → preflight pass → review screen shows infos.
- Editing after pass returns execution to draft and clears results (server-side, tested via direct request).

## Exit criteria

- Manual QA: full draft → preflight → review loop in dummy app, both failure and success paths.
- Full suite green. ≤ 1000 lines changed. Committed.
