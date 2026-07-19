# Next Step

## Goal

Add a typed argument DSL on actions so operators can supply inputs before a run (still synchronous, still no persistence).

## In scope

- Argument declaration on `MoActions::Base` (e.g. `argument :email, type: :string`)
- A small set of scalar types (`string`, `integer`, `boolean` — expand only if a dummy action needs more)
- Generated run form on the dashboard for actions that declare arguments
- Passing submitted params into the action instance before `#perform` (light coercion to the declared type is fine)
- Tests for DSL, form rendering, and runs that receive the submitted values

## Out of scope

- Validation of required/typed args (required flags, flash errors, blocking invalid runs) — do later
- File uploads / ActiveStorage
- Persistence / execution records / drafts
- Async execution, progress, logs
- Per-action authorization rules
- Batching, preflight, audit trail, retention
- Nested/composite argument types

## Done when

- An action with arguments shows a form; submitting values runs `perform` with those values available on the instance.
- Argument-free actions keep the existing one-click Run behavior.
- Full suite green.
