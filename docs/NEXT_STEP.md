# Next Step

## Goal

Persist a simple execution record for each dashboard run so operators can see what ran, with which arguments, and by whom.

## In scope

- Engine migration + `MoActions::Execution` model (action key, performer reference, arguments jsonb/json, status, timestamps)
- Create a record when the dashboard runs an action (sync `perform` still; mark succeeded/failed around the call)
- Index list of recent executions on the dashboard (below the action list is fine)
- Capture `current_performer` when present (polymorphic or type+id; keep it small)
- Tests for record creation on run, failure status when `perform` raises, and index rendering

## Out of scope

- Argument validation (required/typed errors, blocking invalid runs)
- Drafts / edit-before-run flow
- Async execution, progress, logs, batching
- Preflight, authorization rules, audit export, retention/cleanup
- Re-run from a past execution

## Done when

- Running an action from the dashboard creates an execution record with key, arguments, performer, and success/failure status.
- The dashboard shows recent executions.
- Full suite green.
