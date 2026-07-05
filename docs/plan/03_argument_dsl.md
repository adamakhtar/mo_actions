# Phase 3 — Typed Argument DSL

## Goal

Actions declare typed arguments (scalars and arrays) with validations, defaults, and descriptions. Raw input (string-keyed hashes, as a form would submit) is coerced into typed values, validated, and exposed through a single `Arguments` object. This is pure Ruby — no UI, no persistence.

The argument definitions built here are **the single source of truth**: phase 5 renders forms from them, phase 6 validates against them, phase 8 hands coerced values to `perform`.

## Prerequisites

Phase 2 complete (action DSL + registry).

## Acceptance criteria owned

- AC-DEV-010 — declare arguments with name, type, description, required/optional, default
- AC-DEV-011 — scalar types: string, integer, decimal, boolean, date, datetime, enum, file
- AC-DEV-012 — any scalar type can be an array
- AC-DEV-013 — validations (presence, numericality, inclusion, custom)
- AC-DEV-014 — array validations apply per element + array-level rules (min/max items, uniqueness)
- AC-DEV-015 — argument definitions are the single source of truth
- AC-DEV-016 — action code receives typed, coerced values

## Deliverables

1. **DSL on `MoActions::Base`:**

   ```ruby
   class ImportUsersAction < MoActions::Base
     category :billing

     argument :source, :enum, values: %w[csv api], default: "csv", description: "Where to pull users from"
     argument :batch_size, :integer, default: 100, validates: { numericality: { greater_than: 0 } }
     argument :notify, :boolean, default: false
     argument :user_ids, :integer, array: true, required: true,
              array_validates: { min_items: 1, max_items: 500, unique: true }
     argument :mapping_file, :file, required: false
   end
   ```

   - `required:` defaults to true when no default is given, false otherwise — pick one rule, document it in the DSL code, and stick to it.
   - `argument_definitions` returns ordered `MoActions::ArgumentDefinition` value objects (name, type, array?, required?, default, description, validation options).
2. **Type system** — `MoActions::Types` with one small class per type (`Types::String`, `Types::Integer`, `Types::Decimal`, `Types::Boolean`, `Types::Date`, `Types::Datetime`, `Types::Enum`, `Types::File`), each implementing `cast(raw)`:
   - Use `ActiveModel::Type` under the hood where it fits (boolean "1"/"0", date parsing); wrap rather than reinvent.
   - Uncastable input (e.g. `"abc"` for integer) records a type error on that argument rather than raising.
   - `Types::File` in this phase: a passthrough placeholder that stores an opaque reference (e.g. a signed id string). Real ActiveStorage wiring is phase 7. Design `cast` so phase 7 only swaps internals.
   - Enum requires `values:`; casting validates inclusion automatically.
3. **`MoActions::Arguments`** — built via `Arguments.build(action_class, raw_hash)`:
   - Coerces every raw value per its definition; applies defaults for missing keys.
   - `valid?` / `errors` — an `ActiveModel::Errors`-compatible object so form helpers and field-level messages work later. Runs: requiredness, type-cast errors, declared validations (map `validates:` options to ActiveModel validators on a dynamic-but-greppable validator), custom rules via `validate :method_name` or lambda.
   - Array handling: casts each element, applies element validations per element (errors indexed, e.g. `user_ids[2]`), then array-level rules (`min_items`, `max_items`, `unique`).
   - Read access: `args[:batch_size]`, plus method access `args.batch_size` via `respond_to_missing?`-backed method_missing kept tiny, or generated readers — prefer generated readers (greppable).
   - `to_h` returns a JSON-serializable hash (jsonb-ready for phase 4).

## Implementation notes

- This phase is the gem's core value — take care with error message quality. Every validation failure must say which argument, which element (for arrays), and why.
- No composite/struct types, no nested arrays, no conditional arguments (out of scope v1).
- Keep `Arguments` under ~150 lines by delegating casting to the type classes.

## Out of scope (do not build)

- Form rendering (phase 5). Persistence (phase 4). Real file upload (phase 7).
- Cross-argument validations (YAGNI until a phase demands it).

## Tests required (this phase is test-heavy — that's expected)

- Each scalar type: happy-path cast, uncastable input → error, nil handling, default application.
- Enum inclusion; boolean edge cases ("1", "true", "0", "", nil).
- Arrays: element coercion, per-element validation with indexed errors, min/max items, uniqueness, empty array vs missing.
- Required vs optional vs default interaction.
- Custom validation rules.
- `to_h` round-trips through JSON.
- Update one dummy action to use a rich argument set (used in later phases).

## Exit criteria

- `Arguments.build(ImportUsersAction, params).valid?` works end-to-end in a console.
- Full suite green. ≤ 1000 lines changed. Committed.
