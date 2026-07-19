# Next Step

## Goal

Reject invalid argument input before `perform` runs, and show field errors on the generated run form.

## In scope

- Requiredness on the argument DSL (`argument :name, type: :string, required: true` or equivalent small API)
- Validate/coerce submitted params in the dashboard `run` action before instantiating/`perform`
- On failure: no execution record, re-render the index (or a minimal run form) with per-field errors and prior values
- Clear errors for blank required values and obviously bad casts (e.g. non-integer for `:integer`)
- Tests for required blank, bad cast, successful path still creates an execution

## Out of scope

- Drafts / edit-before-run flow
- Async execution, progress, logs, batching
- Preflight, authorization rules, audit export, retention/cleanup
- Execution detail / show page, re-run from a past execution
- Composite/array/file argument types

## Done when

- Invalid runs do not call `perform` and do not create an `Execution`.
- The operator sees which fields failed and why.
- Valid runs still succeed and persist as today.
- Full suite green.
