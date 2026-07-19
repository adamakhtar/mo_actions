# Next Step

## Goal

Add a typed argument DSL on actions so operators can supply inputs before a run (still synchronous, still no persistence).

## In scope

- Argument declaration on `MoActions::Base` (e.g. `argument :email, type: :string, required: true`)
- A small set of scalar types (`string`, `integer`, `boolean` — expand only if a dummy action needs more)
- Generated run form on the dashboard for actions that declare arguments
- Passing submitted params into the action instance before `#perform`
- Validation of required/typed args with clear flash errors (no run on failure)
- Tests for DSL, coercion/validation, form rendering, and rejected/accepted runs

## Out of scope

- File uploads / ActiveStorage
- Persistence / execution records / drafts
- Async execution, progress, logs
- Per-action authorization rules
- Batching, preflight, audit trail, retention
- Nested/composite argument types

## Done when

- An action with arguments shows a form; submitting valid values runs `perform` with those values available on the instance.
- Invalid or missing required arguments do not run the action and show an error.
- Argument-free actions keep the existing one-click Run behavior.
- Full suite green.
