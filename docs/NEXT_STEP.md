# Next Step

## Goal

Build the smallest working slice: define actions, list them in a dashboard, and run one synchronously.

## In scope

- Rails engine skeleton
- Minimal action base class
- Action registry
- Dashboard list of registered actions
- Run button or form
- Synchronous invocation of the selected action
- Test coverage for listing and invocation

## Out of scope

- Authorization
- Arguments
- Persistence
- Async execution
- Progress
- Logs
- Batching
- Preflight or confirmation flows
- Audit trail
- Retention

## Done when

- The dummy app defines at least one action.
- Visiting the mounted engine dashboard lists the action.
- Starting the action invokes its `perform` method.
- Tests prove the working slice.
