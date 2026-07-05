# Phase 1 — Engine Skeleton & Host Integration

## Goal

A working, testable Rails engine gem that a host app can install, configure, and mount, with dashboard authentication in place. No actions, no models yet — just the chassis everything else bolts onto.

## Prerequisites

None. This is the first phase. Read `00_OVERVIEW.md` first.

## Acceptance criteria owned

- AC-DEV-070 — mountable dashboard engine at a configurable path
- AC-DEV-071 — configurable performer model (default: host's user model)
- AC-DEV-072 — integrate with host app authentication; unauthenticated users blocked
- AC-SYS-050 — unauthorized users cannot access the dashboard

## Deliverables

1. **Gem scaffold** generated with `rails plugin new mo_actions --mountable --skip-javascript` (adjust flags as needed), cleaned up:
   - `mo_actions.gemspec`: `rails >= 7.0`, Ruby `>= 3.1`, metadata. No runtime deps beyond rails.
   - Zeitwerk-friendly layout: `lib/mo_actions.rb`, `lib/mo_actions/engine.rb`, `lib/mo_actions/version.rb`.
   - `MoActions::Engine < ::Rails::Engine` with `isolate_namespace MoActions`.
2. **Dummy host app** under `test/dummy`:
   - Minimal Rails 7 app, SQLite, a trivial `User` model (id, name) to act as performer.
   - Engine mounted at `/mo_actions` in dummy routes.
3. **Configuration** — `MoActions::Configuration` PORO + `MoActions.configure` / `MoActions.config`:
   - `performer_class_name` (string, default `"User"`).
   - `authenticate_with` — a callable or symbol resolved against the engine's ApplicationController; hosts typically supply a lambda run as a `before_action` (e.g. `->(controller) { controller.redirect_to "/login" unless ... }`).
   - `current_performer` — callable receiving the controller, returning the performer record.
   - Leave slots empty for later phases (retention, timezone, upload adapter) — do NOT add them yet (YAGNI).
   - Install generator (`rails g mo_actions:install`) that copies an initializer template. Migrations come in phase 4; the generator will be extended then.
4. **Engine base controller** — `MoActions::ApplicationController`:
   - Runs the configured authentication check as a `before_action`; unauthenticated requests are rejected (redirect or 403 per host callable).
   - `current_performer` helper method exposed to views.
5. **Placeholder dashboard root** — one controller + view ("Mo Actions" heading) proving mount, layout, and auth work. Minimal engine layout with vanilla CSS stylesheet stub served via asset pipeline (no webpack/esbuild).
6. **Test harness** — Minitest wired to the dummy app (`test/test_helper.rb`), CI-runnable via `bin/test` or `rails test`.

## Implementation notes

- Follow the naming conventions table in TECHNICAL_REQUIREMENTS.md §2 exactly.
- Keep the initializer template heavily commented — it doubles as configuration documentation.
- Turbo/Stimulus setup: include `turbo-rails` and `stimulus-rails` as gem dependencies now (they're needed from phase 5), using importmap within the engine layout. Keep JS zero-build.

## Out of scope (do not build)

- Any models, migrations, or database tables.
- Action definition DSL, registry.
- Authorization rules per action (phase 12) — this phase is authentication only.
- Polling fallback, ActionCable setup.

## Tests required

- Engine mounts and root path renders for an authenticated performer.
- Unauthenticated request is rejected (whatever the configured callable does).
- `MoActions.configure` sets and exposes config values; defaults are correct.
- `current_performer` resolves via the configured callable.

## Exit criteria

- `cd test/dummy && rails s` serves the dashboard placeholder at `/mo_actions` behind auth.
- Full test suite green. ≤ 1000 lines changed.
- Committed with a message explaining the chassis decisions (importmap, isolate_namespace, config surface).
