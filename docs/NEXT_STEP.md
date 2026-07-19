# Next Step

Status: **done** / awaiting next decision

## Shipped

Let operators start a new run pre-filled from a past execution ("Run again").

- "Run again" on `executions#show` when the action is still registered
- Opens `executions#new` with `from_execution` and argument fields pre-filled
- Submit creates a new execution; the source record is unchanged
- Unregistered action keys: detail stays readable, no Run again control
