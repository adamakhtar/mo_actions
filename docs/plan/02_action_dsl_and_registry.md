# Phase 2 — Action Definition & Discovery

## Goal

Developers can define action classes in the host app; the gem discovers and registers them at boot, grouped by category. No arguments, no execution yet — just identity and discovery.

## Prerequisites

Phase 1 complete (engine skeleton, dummy app, config, tests green).

## Acceptance criteria owned

- AC-DEV-001 — define an action in Ruby within the host app
- AC-DEV-002 — actions auto-discovered and registered at boot
- AC-DEV-003 — stable identifier, human-readable name, description
- AC-DEV-004 — each action belongs to exactly one category
- AC-DEV-005 — multiple actions across multiple categories

## Deliverables

1. **`MoActions::Base`** — PORO superclass for host actions:
   - Class-level DSL: `name "Import Users"`, `description "..."`, `category :billing`.
   - `key` derived from class name (`ImportUsersAction` → `"import_users"`), overridable via `key "custom_key"`. Keys are snake_case strings and must be unique.
   - Sensible defaults: name humanized from key; description optional but recommended; category required (raise a clear error at registration if missing).
2. **`MoActions::Registry`** — module-level singleton:
   - `register(klass)`, `find(key)` (raises `MoActions::ActionNotFound`), `all`, `by_category` (ordered hash of category → actions sorted by name).
   - Duplicate key registration raises with a clear message naming both classes.
3. **Discovery at boot:**
   - Convention: host actions live in `app/actions/**/*_action.rb` (autoloaded by the host's Zeitwerk).
   - `MoActions::Base.inherited` hook registers subclasses; engine `to_prepare` block eager-loads the actions directory so registration happens on boot AND survives code reloading in development (registry must be reset and rebuilt on reload — this is the tricky part; test it).
4. **Categories** — plain value: symbol/string on the action plus a small `MoActions::Category` value object only if needed for label/sorting. Categories are defined in code only (no DB, no admin UI).
5. **Dummy app fixtures:** 3–4 sample actions across 2 categories (e.g. `ImportUsersAction`, `SendInvoiceRemindersAction` in `:billing`; `PurgeStaleSessionsAction` in `:maintenance`). These become the seed actions used by every later phase's tests and manual QA.
6. **Dashboard root updated:** replace phase 1 placeholder with a read-only list of registered actions grouped by category, showing name + description. (Full index UX with run buttons is phase 5 — keep this minimal.)

## Implementation notes

- No metaprogramming beyond the `inherited` hook and simple class-attribute DSL macros. Everything must be greppable.
- Store DSL values in class instance variables with reader/writer macro methods — avoid `class_attribute` inheritance surprises unless needed.
- Do not build an "action versioning" or "enabled/disabled" concept.

## Out of scope (do not build)

- Argument DSL (phase 3). Preflight/perform methods (phases 6/8) — `Base` should not even declare them yet.
- Authorization DSL (phase 12).
- Any persistence.

## Tests required

- Defining a subclass registers it; `Registry.find("import_users")` returns it.
- Key derivation and override; duplicate key raises.
- Missing category raises at registration with actionable message.
- `by_category` grouping/ordering.
- Dev-reload simulation: re-registering after `Registry.reset!` works cleanly.
- Dashboard root shows grouped actions (controller/integration test).

## Exit criteria

- Dummy app boots with sample actions visible at `/mo_actions`, grouped by category.
- Full suite green. ≤ 1000 lines changed. Committed.
