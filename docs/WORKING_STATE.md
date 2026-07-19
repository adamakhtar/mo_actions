# Working State

## Currently works

- Mountable Rails engine gem (`mo_actions`) with a dummy host app under `test/dummy`.
- Host apps define actions in `app/actions` as subclasses of `MoActions::Base` with a small class-level DSL: `key` (derived from class name, overridable), `display_name` (defaults to humanized key), `description`, `category` (required — reading it unset raises `MoActions::MissingCategory`), and `argument :name, type: :string|:integer|:boolean, required: false, description:`.
- Actions self-register via `MoActions::Base.inherited` into `MoActions::Registry` (`register`, `find`, `all`, `by_category`, `reset!`). The engine's `to_prepare` resets the registry and eager loads `app/actions` so registration works at boot and survives dev code reloading.
- Dashboard split across two controllers:
  - `ActionsController#index` — actions grouped by category; each row has Run → `executions#new` and Executions → `executions#index?action_key=…`, plus an "All executions" link.
  - `ExecutionsController` — `index` (recent-first history, optional `action_key` filter), `new` (run form for one action), `create` (validate, cast, perform, persist).
- Submitted arguments are validated with ActiveModel before `perform`: `required: true` → `validates …, presence: true`; `type: :integer` → `validates …, numericality: { only_integer: true }, allow_blank: true`. Invalid creates re-render `executions/new` (422), keep prior values, create no execution, and do not call `perform`.
- Valid runs cast via `ActiveModel::Type`, call `#perform` synchronously, persist a `MoActions::Execution`, then redirect to the executions index (filtered to that action) with flash notice/alert. Unknown action keys on new/create return 404.
- Each successful/failed run persists `MoActions::Execution` (action key, coerced arguments as json, polymorphic performer when present, `succeeded`/`failed` status, optional `error_message`).
- Host authentication via `MoActions.configure`: `authenticate_with` (callable or controller-method symbol) runs as a `before_action` on `MoActions::ApplicationController`; unset config rejects with 403. `current_performer` callable is exposed as a helper and stored on executions. Install generator copies a commented initializer and reminds hosts to `mo_actions:install:migrations`. Dummy app uses session-based login at `/login`.

## Current model

- Engine table `mo_actions_executions` via installable migration under `db/migrate`. Dummy/test DB is SQLite (`json` column; PG can use the same migration).
- `MoActions::Execution` is a thin AR model: `STATUSES = %w[succeeded failed]`, optional polymorphic `performer`, `recent` scope, `action_display_name` (registry lookup with key fallback).
- `MoActions::Base` includes `ActiveModel::Model`. Argument DSL declares Rails validators at definition time. Instances keep raw submitted values until `#execute` (validates → casts → `#perform` → persists `Execution`). Perform failures are recorded as failed executions inside `#execute`; invalid input returns false with no record.
- Gem code also lives in `lib/mo_actions/{base,registry,configuration,argument_definition,engine}.rb`.
- `ArgumentDefinition#cast` delegates to `ActiveModel::Type.lookup` (string/integer/boolean). Requiredness is stored on the definition and enforced via ActiveModel presence.
- `Registry.find` scans `all` by key rather than keeping a key-indexed hash — avoids stale-key problems when `key` is overridden after `inherited` registration, and is plenty fast for the expected action counts.

## Decisions

- Used `display_name` in the DSL instead of `name` (as older plan docs suggested) to avoid shadowing `Class#name`, which Rails/Zeitwerk rely on.
- Argument DSL uses keyword `type:` (`argument :email, type: :string`) rather than a positional type — reads clearly next to `description:` / `required:`.
- Validation uses Rails' own `validates` / ActiveModel errors (presence + numericality). Raw input is validated first so integer numericality sees `"abc"` before `ActiveModel::Type::Integer` would coerce it to `0`. Public entry point is `#execute(performer:)` (returns false if invalid); hosts implement `#perform` with already-cast readers. The controller does not create executions.
- `required:` defaults to `false` so existing optional args stay optional. Dummy `SendInvoiceRemindersAction` marks `days_overdue` required as the example.
- Run UX lives on `executions#new` / `#create` (not the actions index) so validation errors have a dedicated page. Actions index only discovers actions and links out.
- Executions index is the history surface: all actions, recent first, filterable by `action_key`. Filter by unregistered keys still lists matching rows (deleted actions); only new/create require a registered action.
- Skipped a separate Types hierarchy / Arguments object — definitions + ActiveModel on the action instance are enough.
- No duplicate-key guard yet; `find` returns the first match. Add a guard when it earns its keep.
- Dashboard is closed by default (`authenticate_with` nil → 403). Hosts must opt into access via the callable; rejection shape (redirect vs 403) is host-controlled.
- Polymorphic `performer` on executions — no `performer_class_name` config needed yet; `current_performer` remains the sole host hook.
- Execution statuses are only `succeeded`/`failed` for sync runs. Did not prebuild draft/queued/running/paused/cancelled, batches, logs, or transition bang-methods — those wait for slices that need them.
- Failed `perform` is caught, recorded, and surfaced as a flash alert (not a 500). Unknown action keys on new/create still 404 with no persistence. Validation failures are 422 with no persistence.
- Stored arguments are the coerced values (string keys), not the raw params.
- Rails 8.1 generated scaffold; gemspec declares `rails >= 7.0`, Ruby `>= 3.1`.

## Tests proving it

Run with `bin/rails test` (green):

- `test/mo_actions/base_test.rb` — key derivation/override, DSL defaults, missing category error, abstract `perform`.
- `test/mo_actions/registry_test.rb` — registration, find, unknown key, `by_category` grouping, reset/rebuild (dev-reload simulation).
- `test/mo_actions/configuration_test.rb` — config defaults, setters, `reset_config!`.
- `test/mo_actions/argument_definition_test.rb` — cast for string/integer/boolean, blank integer → nil, unsupported type error, required flag.
- `test/mo_actions/argument_dsl_test.rb` — declaration order, `#execute` validate/cast/perform, redeclare replaces, presence + numericality.
- `test/mo_actions/execution_test.rb` — validations, recent scope, polymorphic performer, display-name fallback.
- `test/integration/dashboard_test.rb` — actions index links; run page forms; create with coerced args; unknown key 404; succeeded/failed persistence; executions index + action_key filter; validation 422 on run page.
- `test/integration/dashboard_auth_test.rb` — unauthenticated redirect, default 403, session login + create, `current_performer` helper, symbol `authenticate_with`.

## Important constraints

- Every change should leave the gem in a working state.
- Build the smallest useful slice.
- Prefer simple models first.
- Do not prebuild future-phase infrastructure.
- Keep future capabilities directional until needed.
- If a larger design choice appears, record the decision here briefly.
