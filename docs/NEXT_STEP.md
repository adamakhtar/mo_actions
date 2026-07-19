# Next Step

Status: **ready** (decided, not yet built)

## Goal

Let operators start a new run pre-filled from a past execution ("Run again").

## In scope

- "Run again" control on `executions#show` (and optionally the index row)
- Opens `executions#new` for the same action key with argument fields pre-filled from the past execution's stored arguments
- Creates a **new** execution when submitted (original untouched)
- If the action key is no longer registered → no Run again (or 404), detail page still readable
- Tests: prefill values, submit creates a new record, original unchanged, unregistered action has no control

## Out of scope

- Drafts / edit-before-run persistence before confirm
- Async execution, progress, logs, batching
- File arguments / copying ActiveStorage attachments
- Preflight, authorization rules, retention/cleanup
- Filtered audit tabs

## Done when

- Operators can re-run from a past execution with prior arguments filled in.
- Submitting creates a distinct new execution; the source record is unchanged.
- Full suite green.
