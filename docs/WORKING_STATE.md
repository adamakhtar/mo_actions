# Working State

## Currently works

- Mountable Rails engine gem (`mo_actions`) with a dummy host app under `test/dummy`.
- Host apps define actions in `app/actions` as subclasses of `MoActions::Base` with a small class-level DSL: `key` (derived from class name, overridable), `display_name` (defaults to humanized key), `description`, `category` (required — reading it unset raises `MoActions::MissingCategory`).
- Actions self-register via `MoActions::Base.inherited` into `MoActions::Registry` (`register`, `find`, `all`, `by_category`, `reset!`). The engine's `to_prepare` resets the registry and eager loads `app/actions` so registration works at boot and survives dev code reloading.
- The engine dashboard (mounted at `/mo_actions` in the dummy app) lists actions grouped by category with name + description, and a Run button per action.
- Running an action instantiates it and calls `#perform` synchronously, then redirects with a flash notice. Unknown keys return 404.

## Current model

- Everything is in-memory POROs: no database tables, no persistence, no jobs.
- Gem code lives in `lib/mo_actions/{base,registry,engine}.rb`; dashboard is one controller (`MoActions::ActionsController`) with `index` and `run`.
- `Registry.find` scans `all` by key rather than keeping a key-indexed hash — avoids stale-key problems when `key` is overridden after `inherited` registration, and is plenty fast for the expected action counts.

## Decisions

- Used `display_name` in the DSL instead of `name` (as older plan docs suggested) to avoid shadowing `Class#name`, which Rails/Zeitwerk rely on.
- No duplicate-key guard yet; `find` returns the first match. Add a guard when it earns its keep (e.g. once keys are persisted).
- Rails 8.1 generated scaffold; gemspec declares `rails >= 7.0`, Ruby `>= 3.1`.

## Tests proving it

Run with `bin/rails test` (17 runs, green):

- `test/mo_actions/base_test.rb` — key derivation/override, DSL defaults, missing category error, abstract `perform`.
- `test/mo_actions/registry_test.rb` — registration, find, unknown key, `by_category` grouping, reset/rebuild (dev-reload simulation).
- `test/integration/dashboard_test.rb` — index lists actions grouped by category with run buttons; POST run invokes `perform` and flashes; unknown action 404s.

## Important constraints

- Every change should leave the gem in a working state.
- Build the smallest useful slice.
- Prefer simple models first.
- Do not prebuild future-phase infrastructure.
- Keep future capabilities directional until needed.
- If a larger design choice appears, record the decision here briefly.
