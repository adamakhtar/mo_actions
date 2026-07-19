# Agent Process

This project is built in small working slices. Keep the process agile: decide only the next useful step, complete it, then update the project memory.

Cursor agents are instructed to follow this file automatically via `.cursor/rules/agent-process.mdc` whenever the user asks for the next feature/step/slice. This doc remains the source of truth for the process.

## Before starting work

1. Read this file.
2. Read `docs/PRODUCT_DIRECTION.md`.
3. Read `docs/WORKING_STATE.md`.
4. Read `docs/NEXT_STEP.md`.
5. Confirm the suggested next step is still undone on `main` (and not already shipped on another merged branch). If `NEXT_STEP.md` is stale, correct it before coding.
6. If the current slice needs more context, selectively consult:
   - `docs/TECHNICAL_REQUIREMENTS.md`
   - `docs/ACCEPTANCE_CRITERIA.md`
7. Do only the current next step unless the user explicitly changes direction.

## Reference material

Always read:

- `docs/PRODUCT_DIRECTION.md`
- `docs/WORKING_STATE.md`
- `docs/NEXT_STEP.md`

Read only when relevant:

- `docs/TECHNICAL_REQUIREMENTS.md`
- `docs/ACCEPTANCE_CRITERIA.md`
- prior broad implementation branches

The larger docs and prior implementation branches are directional reference material. Use them to preserve product intent, terminology, and edge cases for the current slice. Do not load or implement them wholesale by default.

## Working rules

- Every change should leave the gem in a working state.
- Build the smallest useful slice.
- Prefer simple models first.
- Do not prebuild future-phase infrastructure.
- Keep future capabilities directional until needed.
- If a larger design choice appears, record the decision briefly in `docs/WORKING_STATE.md`.

## Before finishing

Update:

1. `docs/WORKING_STATE.md`
   - what works now
   - current implementation shape
   - tests proving it

2. `docs/NEXT_STEP.md`
   - exactly one suggested next slice
   - in scope and out of scope
   - done criteria

3. `docs/PRODUCT_DIRECTION.md`
   - only if product intent changed

## PR expectation

Each PR should include:

- one working slice
- tests for that slice, when code changes
- docs updated to reflect reality
