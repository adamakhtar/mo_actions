# Working State

## Currently works

- Mountable Rails engine gem (`mo_actions`) with a dummy host app under `test/dummy`.
- Host apps define actions in `app/actions` as subclasses of `MoActions::Base` with a small class-level DSL: `key` (derived from class name, overridable), `display_name` (defaults to humanized key), `description`, `category` (required — reading it unset raises `MoActions::MissingCategory`), and `argument :name, type: :string|:integer|:boolean, description:`.
- Actions self-register via `MoActions::Base.inherited` into `MoActions::Registry` (`register`, `find`, `all`, `by_category`, `reset!`). The engine's `to_prepare` resets the registry and eager loads `app/actions` so registration works at boot and survives dev code reloading.
- The engine dashboard (mounted at `/mo_actions` in the dummy app) lists actions grouped by category with name + description. Argument-free actions get a one-click Run button; actions with arguments get a generated form (text/number/checkbox).
- Running an action instantiates it with coerced argument values (available as readers), calls `#perform` synchronously, then redirects with a flash notice. Unknown keys return 404.
- Host authentication via `MoActions.configure`: `authenticate_with` (callable or controller-method symbol) runs as a `before_action` on `MoActions::ApplicationController`; unset config rejects with 403. `current_performer` callable is exposed as a helper. Install generator copies a commented initializer. Dummy app uses session-based login at `/login`.

## Current model

- Everything is in-memory POROs except the dummy app's trivial `User` model for auth: no engine database tables, no persistence, no jobs.
- Gem code lives in `lib/mo_actions/{base,registry,configuration,argument_definition,engine}.rb`; dashboard is one controller (`MoActions::ActionsController`) with `index` and `run`.
- `ArgumentDefinition#cast` does light coercion only (blank/uncastable integers → nil; booleans via `ActiveModel::Type::Boolean`). No requiredness or validation errors yet.
- `Registry.find` scans `all` by key rather than keeping a key-indexed hash — avoids stale-key problems when `key` is overridden after `inherited` registration, and is plenty fast for the expected action counts.

## Decisions

- Used `display_name` in the DSL instead of `name` (as older plan docs suggested) to avoid shadowing `Class#name`, which Rails/Zeitwerk rely on.
- Argument DSL uses keyword `type:` (`argument :email, type: :string`) rather than a positional type — reads clearly next to `description:`.
- Skipped a separate Types hierarchy / Arguments object for this slice — definitions + `cast` on `ArgumentDefinition` and readers on the action instance are enough until validation/persistence need a richer bag.
- No duplicate-key guard yet; `find` returns the first match. Add a guard when it earns its keep (e.g. once keys are persisted).
- Dashboard is closed by default (`authenticate_with` nil → 403). Hosts must opt into access via the callable; rejection shape (redirect vs 403) is host-controlled.
- Deferred `performer_class_name` / performer model config — only the `current_performer` callable for now. Add a class-name setting when persistence needs it.
- Rails 8.1 generated scaffold; gemspec declares `rails >= 7.0`, Ruby `>= 3.1`.

## Tests proving it

Run with `bin/rails test` (green):

- `test/mo_actions/base_test.rb` — key derivation/override, DSL defaults, missing category error, abstract `perform`.
- `test/mo_actions/registry_test.rb` — registration, find, unknown key, `by_category` grouping, reset/rebuild (dev-reload simulation).
- `test/mo_actions/configuration_test.rb` — config defaults, setters, `reset_config!`.
- `test/mo_actions/argument_definition_test.rb` — cast for string/integer/boolean, blank integer → nil, unsupported type error.
- `test/mo_actions/argument_dsl_test.rb` — declaration order, instance readers, redeclare replaces.
- `test/integration/dashboard_test.rb` — authenticated index; arg form fields; one-click Run for arg-free actions; POST with args reaches `perform` coerced; unknown action 404s.
- `test/integration/dashboard_auth_test.rb` — unauthenticated redirect, default 403, session login + run, `current_performer` helper, symbol `authenticate_with`.

## Important constraints

- Every change should leave the gem in a working state.
- Build the smallest useful slice.
- Prefer simple models first.
- Do not prebuild future-phase infrastructure.
- Keep future capabilities directional until needed.
- If a larger design choice appears, record the decision here briefly.
