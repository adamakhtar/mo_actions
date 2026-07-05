# Phase 5 — Dashboard: Browse Actions & Draft Executions

## Goal

Operators can browse actions, start a draft execution, fill in a dynamically rendered argument form (including array arguments), save values while editing, and abandon the draft. Ends at the form — preflight is phase 6.

## Prerequisites

Phase 4 complete (models).

## Acceptance criteria owned

- AC-OP-001 — view all registered actions grouped by category
- AC-OP-002 — each action shows name and description
- AC-OP-010 — starting an action creates a draft execution
- AC-OP-011 — form rendered dynamically from argument definitions
- AC-OP-012 — each argument shows description/help text
- AC-OP-013 — array arguments: dynamic list with add, remove, reorder
- AC-OP-014 — operator can save scalar values while continuing to edit
- AC-OP-015 — operator can abandon a draft

## Deliverables

1. **Routes & controllers** (engine-namespaced):
   - `actions#index` — replaces phase 2 stub: category-grouped cards/list, name + description, "Run" button per action.
   - `executions#create` — POST with `action_key`; creates a draft `Execution` for `current_performer`, redirects to edit.
   - `executions#edit` / `executions#update` — the draft form. Update coerces params through `MoActions::Arguments`, persists `to_h` to the draft, re-renders with field-level errors when invalid but ALWAYS saves the raw-but-castable values (operators must not lose work).
   - `executions#destroy` — abandon: destroys draft (only in draft status), redirects to actions index with notice.
2. **Dynamic form renderer:**
   - One partial per type family: text/string, number (integer/decimal), checkbox (boolean), date, datetime-local, select (enum), file placeholder (disabled input with "file uploads arrive in phase 7" — acceptable interim), plus an array wrapper partial.
   - Dispatch via a small view helper mapping `ArgumentDefinition#type` → partial. No `render "types/#{type}"` string interpolation without an allowlist.
   - Each field: label, description as help text, inline field errors, `required` marking.
3. **Array field Stimulus controller** (`array_field_controller.js`):
   - Renders existing elements as rows; add row (from a `<template>`), remove row, reorder (up/down buttons are fine — no drag-and-drop dependency).
   - Inputs named `execution[arguments][user_ids][]` so Rails params arrive as arrays; empty submissions handled (hidden empty-array marker input).
4. **Save-while-editing:** the form submits normally (Turbo drive) and re-renders edit on validation errors; a "Save draft" button persists current values without demanding validity (only castability). Validation completeness is enforced at preflight (phase 6), not here.
5. **Layout polish:** engine layout gets simple, clean vanilla CSS (header, category sections, form styles, error styles). Modern and unfussy; no CSS framework.

## Implementation notes

- Drafts belong to `current_performer`; scope `executions#edit/update/destroy` to the performer's own drafts.
- Reuse `MoActions::Arguments` for everything — no separate form object unless controller logic exceeds ~15 lines.
- Keep Stimulus controllers dependency-free and small; register via importmap set up in phase 1.

## Out of scope (do not build)

- Preflight button behaviour (phase 6) — render the button disabled or omit it.
- File uploads (phase 7). Execution list/detail pages (phases 10/13).
- Draft expiry cleanup (phase 14) — abandoning is manual-only for now.
- Authorization-based disabling of actions (phase 12) — all actions runnable by any authenticated performer for now.

## Tests required

- Integration: full flow — index → create draft → edit → update with valid values → values persisted typed; update with invalid values → field errors shown AND castable values retained.
- Array params: add/remove/reorder round-trip through params to persisted array.
- Abandon destroys draft; cannot destroy non-draft execution.
- Draft scoping: performer B cannot edit performer A's draft.
- System test (optional but preferred) exercising the Stimulus array controller with a JS driver; if the harness cost is too high this phase, cover params-level behaviour in integration tests and add the system test harness in phase 7 where JS testing becomes unavoidable.

## Exit criteria

- Manual QA in dummy app: browse, start draft, fill rich form (arrays included), save, abandon.
- Full suite green. ≤ 1000 lines changed. Committed.
