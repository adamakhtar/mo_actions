# Mo Actions — Technical Requirements

Guidance for implementing the gem. Defines stack, code style, phased delivery, and conventions.

**Related documents:**

- [Acceptance Criteria](./ACCEPTANCE_CRITERIA.md) — what to build (outcomes)
- Technical plan (architecture, domain model) — `.cursor/plans/mo_actions_gem_plan_9fea4a12.plan.md`

When in doubt, acceptance criteria wins on _what_; this document wins on _how_.

---

## 1. Stack

### Required

| Layer           | Choice                              | Notes                                                         |
| --------------- | ----------------------------------- | ------------------------------------------------------------- |
| Ruby            | 3.1+                                | Match Rails 7 minimum                                         |
| Rails           | 7.0+                                | Host app dependency; gem declares `rails >= 7.0`              |
| Background jobs | **ActiveJob**                       | Adapter-agnostic — Solid Queue, Good Job, Sidekiq via adapter |
| Frontend        | **Hotwire** (Turbo + Stimulus)      | No React, Vue, or SPA framework                               |
| CSS             | Vanilla / minimal engine stylesheet | No Tailwind in gem v1 unless host app provides it via layout  |
| Database        | PostgreSQL preferred                | jsonb for `arguments`; SQLite acceptable for gem specs        |
| File uploads    | **ActiveStorage** direct upload     | Default; pluggable adapter for non-AS host apps               |
| Real-time       | **Turbo Streams** via ActionCable   | Polling fallback configurable, not default                    |
| Testing         | **Minitest**                        | Rails default; not RSpec                                      |

### Use Rails defaults — do not introduce alternatives unless necessary

- ActiveJob, not custom job runners
- ActiveRecord, not ROM/Sequel
- ActiveStorage, not Shrine/CarrierWave (in gem code)
- ActiveSupport::Notifications for instrumentation hooks
- Engine (`rails engine`), not a plain Rack app
- Zeitwerk autoloading
- Fixtures or factory-minimal setup in tests — prefer fixtures for engine models

### Explicit non-dependencies (v1)

No Sidekiq-specific code. No Redis requirement. No webpack/esbuild in gem. No GraphQL. No authorization gem (Pundit/CanCan) — roll a simple `authorize` callable on the action class.

---

## 2. Code style

### Philosophy: Basecamp / 37signals

Write code for **humans first**, machines second.

- **Expressive over clever.** Prefer a method named `ready_for_preflight?` over a nested ternary.
- **YAGNI.** Do not build composite argument types, dry run, or retry policies until a phase explicitly calls for them.
- **Simple is best.** The smallest change that satisfies the current phase's acceptance criteria.
- **Vanilla Rails.** If Rails already does it, use that — don't wrap it unnecessarily.
- **Concise files.** A 400-line model is a smell — extract only when it aids readability, not preemptively.
- **Comments explain why, not what.** Only non-obvious business rules and invariants.
- **No metaprogramming magic** beyond what the argument DSL reasonably needs. If a macro is hard to grep, reconsider.

### Naming

| Thing              | Convention                          | Example                          |
| ------------------ | ----------------------------------- | -------------------------------- |
| Gem module         | `MoActions`                         |                                  |
| Tables             | `mo_actions_*` prefix               | `mo_actions_executions`          |
| Models             | `MoActions::Execution`              | Namespaced under engine          |
| Jobs               | `MoActions::RunBatchJob`            | Suffix `Job`                     |
| Actions (host app) | `<Verb><Noun>Action`                | `ImportUsersAction`              |
| Action keys        | `snake_case` string                 | `"import_users"`                 |
| Status values      | String enum via `enum` or constants | `status: "running"` not integers |

### Patterns to prefer

- Plain Ruby objects for value types (`MoActions::Arguments`, `MoActions::Types::File`)
- `ActiveSupport::CurrentAttributes` for request-scoped performer if needed
- State transitions as explicit methods on `Execution` (`execution.queue!`, `execution.succeed!`) — not scattered string assignment
- Broadcasts in one place (e.g. `MoActions::ExecutionBroadcaster`)
- Configuration via `MoActions.configure { |c| ... }` block in initializer

### Patterns to avoid

- Concern proliferation — max 1–2 concerns per model, only if genuinely shared
- Service object ceremony (`MoActions::Executions::CreateService`) unless logic exceeds ~15 lines in controller
- Callback chains that obscure flow — prefer explicit calls from jobs/controllers
- Premature abstraction (adapter pattern beyond file uploads until second use case exists)
- Feature flags for unfinished work — use phases instead

### Committing work

- commit messages will be used by LLM's and humans to understand the code.
- state why code has changed in addition to what changed - e.g. business objectives etc
- state anything important that can't be discerned by just reading the code
- also state what we avoided and why (important top level details only)

---

## 3. Phased delivery

**Rule:** Each phase targets **≤ 1000 lines changed** (including tests, views, migrations). One phase = one reviewable PR.

Phases are sequential — do not start phase N+1 until phase N tests pass and acceptance criteria listed for that phase are met.
