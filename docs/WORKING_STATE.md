# Working State

## Currently works

- Mountable Rails engine gem (`mo_actions`) with a dummy host app under `test/dummy`.
- Host apps define actions in `app/actions` as subclasses of `MoActions::Base` with a small class-level DSL: `key` (derived from class name, overridable), `display_name` (defaults to humanized key), `description`, `category` (required — reading it unset raises `MoActions::MissingCategory`), and `argument :name, type: :string|:integer|:boolean, required: false, description:`.
- Actions self-register via `MoActions::Base.inherited` into `MoActions::Registry` (`register`, `find`, `all`, `by_category`, `reset!`). The engine's `to_prepare` resets the registry and eager loads `app/actions` so registration works at boot and survives dev code reloading.
- Dashboard split across two controllers:
  - `ActionsController#index` — actions grouped by category; each row has Run → `executions#new` and Executions → `executions#index?action_key=…`, plus an "All executions" link.
  - `ExecutionsController` — `index` (recent-first history, optional `action_key` filter), `show` (detail + progress), `new` (run form for one action), `create` (validate, cast, enqueue, redirect to show).
- Submitted arguments are validated with ActiveModel before enqueue: `required: true` → `validates …, presence: true`; `type: :integer` → `validates …, numericality: { only_integer: true }, allow_blank: true`. Invalid creates re-render `executions/new` (422), keep prior values, create no execution, and do not call `perform`.
- Valid runs cast via `ActiveModel::Type`, persist a `running` `MoActions::Execution`, enqueue `MoActions::RunExecutionJob`, then redirect to `executions#show`. Unknown action keys on new/create return 404.
- `#perform(ctx)` receives a `MoActions::Context` for progress: `ctx.total = n`, `ctx.progress(i)` (clamped to total when set; negatives → 0). Progress is stored on the execution (`progress_total`, `progress_current`).
- The job rebuilds the action from stored arguments, calls `perform`, then marks `succeeded` or `failed` (with `error_message`) on the same record.
- Execution detail shows action name + key, status, progress (`current / total` and percent when total present), performer, arguments, error message (failed only), and timestamps. Running detail offers a Refresh link. Index rows show progress and link to detail. Unregistered action keys fall back to the raw key via `action_display_name`. Unknown ids 404.
- "Run again" on a registered action's detail page links to `executions#new?action_key=…&from_execution=…`. The new form prefills argument fields from the source execution's stored arguments (current DSL keys only). Submit uses the normal create path (new execution → show) and leaves the original record untouched. Unregistered actions have no Run again control; the detail page remains readable.
- Host authentication via `MoActions.configure`: `authenticate_with` (callable or controller-method symbol) runs as a `before_action` on `MoActions::ApplicationController`; unset config rejects with 403. `current_performer` callable is exposed as a helper and stored on executions. Install generator copies a commented initializer and reminds hosts to `mo_actions:install:migrations`. Dummy app uses session-based login at `/login`.
- Dummy `DemoBackfillAction` sleeps between steps in development so a manual reload can observe progress (`active_job` `:async` in dev, `:inline` in test).

## Current model

- Engine table `mo_actions_executions` via installable migrations under `db/migrate`. Dummy/test DB is SQLite (`json` column; PG can use the same migration).
- `MoActions::Execution`: `STATUSES = %w[running succeeded failed]`, optional polymorphic `performer`, `progress_current` (default 0), optional `progress_total`, `recent` scope, `progress_percent`, `action_class` / `action_display_name` (registry lookup with key fallback).
- `MoActions::Base` includes `ActiveModel::Model`. Argument DSL declares Rails validators at definition time. `#execute(performer:)` validates → casts → creates running execution → enqueues job. Hosts implement `#perform(ctx)`.
- `MoActions::Context` wraps an execution for `total=` / `progress`.
- `MoActions::RunExecutionJob` loads the execution, rebuilds the action, runs `perform`, terminalizes status.
- Gem code also lives in `lib/mo_actions/{base,registry,configuration,argument_definition,context,engine}.rb`.
- `ArgumentDefinition#cast` delegates to `ActiveModel::Type.lookup` (string/integer/boolean). Requiredness is stored on the definition and enforced via ActiveModel presence.
- `Registry.find` scans `all` by key rather than keeping a key-indexed hash — avoids stale-key problems when `key` is overridden after `inherited` registration, and is plenty fast for the expected action counts.

## Decisions

- Used `display_name` in the DSL instead of `name` (as older plan docs suggested) to avoid shadowing `Class#name`, which Rails/Zeitwerk rely on.
- Argument DSL uses keyword `type:` (`argument :email, type: :string`) rather than a positional type — reads clearly next to `description:` / `required:`.
- Validation uses Rails' own `validates` / ActiveModel errors (presence + numericality). Raw input is validated first so integer numericality sees `"abc"` before `ActiveModel::Type::Integer` would coerce it to `0`.
- `required:` defaults to `false` so existing optional args stay optional. Dummy `SendInvoiceRemindersAction` marks `days_overdue` required as the example.
- Run UX lives on `executions#new` / `#create` (not the actions index) so validation errors have a dedicated page. Actions index only discovers actions and links out. Create redirects to show so operators land on progress.
- Executions index is the history surface: all actions, recent first, filterable by `action_key`. Filter by unregistered keys still lists matching rows (deleted actions); only new/create require a registered action.
- "Run again" is a link to a prefilled `new` form, not an immediate re-execute. Prefill ignores missing/mismatched `from_execution` ids so a bare `new` still works. Only current argument names are copied (dropped DSL args are skipped; new required args stay blank for the operator to fill).
- Progress v1 assumes a known total at start (`ctx.total =`). No indeterminate UI yet. Percent is derived for display only.
- Minimal async via ActiveJob so the detail page can be reloaded while work runs. No Hotwire / polling / meta-refresh — just a Refresh link while `running`.
- Progress columns shipped as a follow-up installable migration (`AddProgressToMoActionsExecutions`) so hosts that already ran the create migration can pick them up via `mo_actions:install:migrations`.
- Skipped a separate Types hierarchy / Arguments object — definitions + ActiveModel on the action instance are enough.
- No duplicate-key guard yet; `find` returns the first match. Add a guard when it earns its keep.
- Dashboard is closed by default (`authenticate_with` nil → 403). Hosts must opt into access via the callable; rejection shape (redirect vs 403) is host-controlled.
- Polymorphic `performer` on executions — no `performer_class_name` config needed yet; `current_performer` remains the sole host hook.
- Execution statuses are `running` / `succeeded` / `failed`. Did not prebuild draft/queued/paused/cancelled, batches, logs, or transition bang-methods — those wait for slices that need them.
- Failed `perform` is caught in the job, recorded, and surfaced on the detail page (flash alert when the job already finished inline). Unknown action keys on new/create still 404 with no persistence. Validation failures are 422 with no persistence. Missing execution ids 404.
- Stored arguments are the coerced values (string keys), not the raw params.
- Rails 8.1 generated scaffold; gemspec declares `rails >= 7.0`, Ruby `>= 3.1`.

## Tests proving it

Run with `bin/rails test` (green):

- `test/mo_actions/base_test.rb` — key derivation/override, DSL defaults, missing category error, abstract `perform`.
- `test/mo_actions/registry_test.rb` — registration, find, unknown key, `by_category` grouping, reset/rebuild (dev-reload simulation).
- `test/mo_actions/configuration_test.rb` — config defaults, setters, `reset_config!`.
- `test/mo_actions/argument_definition_test.rb` — cast for string/integer/boolean, blank integer → nil, unsupported type error, required flag.
- `test/mo_actions/argument_dsl_test.rb` — declaration order, `#execute` validate/cast/enqueue/perform, progress reporting, redeclare replaces, presence + numericality.
- `test/mo_actions/context_test.rb` — total/progress persistence and clamping.
- `test/mo_actions/execution_test.rb` — validations (including `running`), recent scope, polymorphic performer, display-name fallback, progress_percent.
- `test/integration/dashboard_test.rb` — actions index links; run page forms; create with coerced args; unknown key 404; succeeded/failed persistence; executions index + action_key filter; validation 422 on run page; execution show (progress, running refresh, failed/unregistered, Run again) + 404; Run again prefill + new record + original unchanged; demo backfill progress.
- `test/integration/dashboard_auth_test.rb` — unauthenticated redirect, default 403, session login + create, `current_performer` helper, symbol `authenticate_with`.

## Important constraints

- Every change should leave the gem in a working state.
- Build the smallest useful slice.
- Prefer simple models first.
- Do not prebuild future-phase infrastructure.
- Keep future capabilities directional until needed.
- If a larger design choice appears, record the decision here briefly.
