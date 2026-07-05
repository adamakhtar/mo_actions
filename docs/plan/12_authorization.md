# Phase 12 — Per-Action Authorization

## Goal

Developers declare who may run each action; the dashboard shows unauthorized actions as disabled (with an explanation and a visibility toggle); enforcement happens server-side on every mutating request, not just in the UI. No Pundit/CanCan — a simple callable on the action class.

## Prerequisites

Phase 11 complete (controls).

## Acceptance criteria owned

- AC-DEV-060 — per-action authorization rule determining which performers may run it
- AC-DEV-061 — enforced when running, not just when displaying
- AC-OP-003 — unauthorized actions visible but clearly disabled, with explanation
- AC-OP-004 — operator can toggle visibility of unauthorized actions
- AC-SYS-051 — unauthorized users cannot run actions even bypassing the UI

## Deliverables

1. **DSL on `MoActions::Base`:**

   ```ruby
   class RefundOrderAction < MoActions::Base
     authorize { |performer| performer.admin? }
   end
   ```

   - Block receives the performer, returns truthy/falsy. No block = authorized for all authenticated performers (document this default prominently).
   - `Base.authorized?(performer)` wraps it; exceptions inside the block count as unauthorized (and are reported via `Rails.error.report` or logged) — an authorization bug must fail closed.
2. **Enforcement (server-side, the real boundary):** a single guard (controller concern or before_action on the engine's relevant controllers) authorizing on: draft create, draft update, preflight, execute, pause/resume/cancel/retry. Unauthorized → 403 with a plain message. Draft-scoped endpoints keep the phase 5 performer-ownership check too — both must pass.
   - Authorization is checked at request time each time; an operator whose access was revoked mid-draft cannot proceed (an in-flight execution is NOT killed — decide and document that in code comments).
3. **Actions index UX:**
   - Unauthorized actions render greyed out with disabled Run button and short explanation ("You are not authorized to run this action").
   - Toggle ("Show actions I can't run") — default on; persisted in session or a cookie (no DB). Small Stimulus controller or plain form — pick simpler.
4. **Dummy app:** admin flag on `User`, one admin-only sample action, both user types seeded for QA.

## Implementation notes

- Do not build roles, permissions models, or grant UIs — the callable IS the API; hosts bring their own logic.
- Keep the authorization check cheap: it runs per action on the index page. Note in docs that expensive checks are the host's problem to memoize.

## Out of scope (do not build)

- Audit-trail visibility scoping (phase 13, AC-DEV-073/AC-SYS-052).
- Approval workflows (out of scope v1).

## Tests required

- DSL: no block → authorized; block true/false; block raising → unauthorized, error reported.
- Enforcement per endpoint: unauthorized performer gets 403 on create/update/preflight/execute/controls via direct requests (UI bypass).
- Mid-draft revocation: draft created while authorized cannot be executed after authorization changes.
- Index: unauthorized actions disabled with explanation; toggle hides/shows them and persists across requests.

## Exit criteria

- Manual QA as non-admin: see disabled action with explanation, toggle works, direct POST rejected.
- Full suite green. ≤ 1000 lines changed. Committed.
