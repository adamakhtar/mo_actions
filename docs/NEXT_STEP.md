# Next Step

## Goal

Add a read-only execution detail page so operators can open a past run and see its full recorded context.

## In scope

- `ExecutionsController#show` + route
- Detail view: action name/key, status, performer, arguments, error message (when failed), timestamps
- Link each row on the executions index to its detail page
- Graceful render when the action key is no longer registered (show raw key)
- Tests for show content (succeeded and failed) and unknown id → 404

## Out of scope

- Drafts / edit-before-run flow
- Async execution, progress, logs, batching
- Filtered audit tabs (Succeeded/Failed/Active), re-run from a past execution
- Preflight, authorization rules, retention/cleanup
- New argument types

## Done when

- Operators can open a past execution from the executions index and see its recorded fields.
- Missing executions 404.
- Full suite green.
