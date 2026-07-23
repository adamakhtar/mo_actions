# Next Step

Status: **done** / awaiting next decision

## Shipped

Action authors can report progress during `perform`; operators see it on the execution detail page by reloading.

- Execution created as `running` before work starts (`progress_current` / `progress_total`)
- `MoActions::Context` in `#perform(ctx)`: `ctx.total=` / `ctx.progress(n)`
- `MoActions::RunExecutionJob` runs work via ActiveJob; lands succeeded/failed
- Create redirects to `executions#show`; Refresh link while running (no Hotwire)
- Run again still prefills `new` and creates a new execution on submit
