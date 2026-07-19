# Next Step

## Goal

Put the dashboard behind host-app authentication with a small configuration surface, so the engine is safe to mount in a real app.

## In scope

- `MoActions::Configuration` PORO + `MoActions.configure` / `MoActions.config`
- `authenticate_with` — host-supplied callable run as a `before_action` on the engine's `ApplicationController`; unauthenticated requests rejected (redirect or 403, per the callable)
- `current_performer` — callable receiving the controller, returning the performer record; exposed as a helper
- Install generator (`rails g mo_actions:install`) copying a commented initializer template
- Dummy app wired with a trivial auth scheme to exercise both paths
- Tests: config defaults and setters, unauthenticated rejection, authenticated access, `current_performer` resolution

## Out of scope

- Per-action authorization rules
- Arguments and forms
- Persistence / execution records
- Async execution, progress, logs
- Batching, preflight, audit trail, retention
- Performer model configuration beyond the `current_performer` callable

## Done when

- An unauthenticated request to the dummy app's `/mo_actions` is rejected.
- An authenticated request sees the dashboard and can run an action.
- `MoActions.configure` works from an initializer; defaults are sensible when unset.
- Full suite green.
