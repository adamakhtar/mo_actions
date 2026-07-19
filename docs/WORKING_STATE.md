# Working State

## Currently works

- Mountable Rails engine gem (`mo_actions`) with a dummy host app under `test/dummy`.
- Host apps define actions in `app/actions` as subclasses of `MoActions::Base` with a small class-level DSL: `key` (derived from class name, overridable), `display_name` (defaults to humanized key), `description`, `category` (required — reading it unset raises `MoActions::MissingCategory`), and `argument :name, type: :string|:integer|:boolean, required: false, description:`.
- Actions self-register via `MoActions::Base.inherited` into `MoActions::Registry` (`register`, `find`, `all`, `by_category`, `reset!`). The engine's `to_prepare` resets the registry and eager loads `app/actions` so registration works at boot and survives dev code reloading.
- The engine dashboard (mounted at `/mo_actions` in the dummy app) lists actions grouped by category with name + description. Argument-free actions get a one-click Run button; actions with arguments get a generated form (text/number/checkbox) with required markers and inline field errors after failed validation.
- Submitted arguments are validated with ActiveModel before `perform`: `required: true` → `validates …, presence: true`; `type: :integer` → `validates …, numericality: { only_integer: true }, allow_blank: true`. Invalid runs re-render the index (422), keep prior values, create no execution, and do not call `perform`.
- Valid runs cast via `ActiveModel::Type`, call `#perform` synchronously, then redirect with a flash notice (or alert on failure). Unknown keys return 404 and create no record.
- Each successful/failed dashboard run persists a `MoActions::Execution` (action key, coerced arguments as json, polymorphic performer when present, `succeeded`/`failed` status, optional `error_message`). The index shows the 20 most recent executions below the action list.
- Host authentication via `MoActions.configure`: `authenticate_with` (callable or controller-method symbol) runs as a `before_action` on `MoActions::ApplicationController`; unset config rejects with 403. `current_performer` callable is exposed as a helper and stored on executions. Install generator copies a commented initializer and reminds hosts to `mo_actions:install:migrations`. Dummy app uses session-based login at `/login`.

## Current model

- Engine table `mo_actions_executions` via installable migration under `db/migrate`. Dummy/test DB is SQLite (`json` column; PG can use the same migration).
- `MoActions::Execution` is a thin AR model: `STATUSES = %w[succeeded failed]`, optional polymorphic `performer`, `recent` scope, `action_display_name` (registry lookup with key fallback).
- `MoActions::Base` includes `ActiveModel::Model`. Argument DSL declares Rails validators at definition time. Instances keep raw submitted values until `cast_arguments!` (called only after `valid?`).
- Gem code also lives in `lib/mo_actions/{base,registry,configuration,argument_definition,engine}.rb`; dashboard is one controller (`MoActions::ActionsController`) with `index` and `run`.
- `ArgumentDefinition#cast` delegates to `ActiveModel::Type.lookup` (string/integer/boolean). Requiredness is stored on the definition and enforced via ActiveModel presence, not custom validation code.
- `Registry.find` scans `all` by key rather than keeping a key-indexed hash — avoids stale-key problems when `key` is overridden after `inherited` registration, and is plenty fast for the expected action counts.

## Decisions

- Used `display_name` in the DSL instead of `name` (as older plan docs suggested) to avoid shadowing `Class#name`, which Rails/Zeitwerk rely on.
- Argument DSL uses keyword `type:` (`argument :email, type: :string`) rather than a positional type — reads clearly next to `description:` / `required:`.
- Validation uses Rails' own `validates` / ActiveModel errors (presence + numericality). Raw input is validated first so integer numericality sees `"abc"` before `ActiveModel::Type::Integer` would coerce it to `0`.
- `required:` defaults to `false` so existing optional args stay optional. Dummy `SendInvoiceRemindersAction` marks `days_overdue` required as the example.
- Skipped a separate Types hierarchy / Arguments object — definitions + ActiveModel on the action instance are enough.
- No duplicate-key guard yet; `find` returns the first match. Add a guard when it earns its keep.
- Dashboard is closed by default (`authenticate_with` nil → 403). Hosts must opt into access via the callable; rejection shape (redirect vs 403) is host-controlled.
- Polymorphic `performer` on executions — no `performer_class_name` config needed yet; `current_performer` remains the sole host hook.
- Execution statuses are only `succeeded`/`failed` for sync runs. Did not prebuild draft/queued/running/paused/cancelled, batches, logs, or transition bang-methods — those wait for slices that need them.
- Failed `perform` is caught, recorded, and surfaced as a flash alert (not a 500). Unknown action keys still 404 with no persistence. Validation failures are 422 with no persistence.
- Stored arguments are the coerced values (string keys), not the raw params.
- Rails 8.1 generated scaffold; gemspec declares `rails >= 7.0`, Ruby `>= 3.1`.

## Tests proving it

Run with `bin/rails test` (green):

- `test/mo_actions/base_test.rb` — key derivation/override, DSL defaults, missing category error, abstract `perform`.
- `test/mo_actions/registry_test.rb` — registration, find, unknown key, `by_category` grouping, reset/rebuild (dev-reload simulation).
- `test/mo_actions/configuration_test.rb` — config defaults, setters, `reset_config!`.
- `test/mo_actions/argument_definition_test.rb` — cast for string/integer/boolean, blank integer → nil, unsupported type error, required flag.
- `test/mo_actions/argument_dsl_test.rb` — declaration order, raw then cast, `argument_values`, redeclare replaces, presence + numericality.
- `test/mo_actions/execution_test.rb` — validations, recent scope, polymorphic performer, display-name fallback.
- `test/integration/dashboard_test.rb` — authenticated index; arg form fields; one-click Run; POST with args reaches `perform` coerced; unknown action 404s with no record; succeeded/failed execution persistence; recent executions list; blank required + bad integer → 422, field errors, no execution.
- `test/integration/dashboard_auth_test.rb` — unauthenticated redirect, default 403, session login + run, `current_performer` helper, symbol `authenticate_with`.

## Important constraints

- Every change should leave the gem in a working state.
- Build the smallest useful slice.
- Prefer simple models first.
- Do not prebuild future-phase infrastructure.
- Keep future capabilities directional until needed.
- If a larger design choice appears, record the decision here briefly.
