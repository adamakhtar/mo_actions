# Next Step

## Goal

Add a read-only execution detail page so operators can open a past run and see its full recorded context.

## In scope

- `ActionsController#show` (or a thin `ExecutionsController#show`) + route for one execution
- Detail view: action name/key, status, performer, arguments, error message (when failed), timestamps
- Link each row on the recent-executions list to its detail page
- Graceful render when the action key is no longer registered (show raw key via existing `action_display_name`)
- Tests for show content (succeeded and failed) and unknown id → 404

## Out of scope

- Drafts / edit-before-run flow
- Async execution, progress, logs, batching
- Filtered audit tabs, re-run from a past execution
- Preflight, authorization rules, retention/cleanup
- New argument types or richer validations

## Done when

- Operators can open a past execution from the index and see its recorded fields.
- Missing executions 404.
- Full suite green.
