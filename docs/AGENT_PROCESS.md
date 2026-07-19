# Agent Process

This project is built in small working slices. Keep the process agile: decide only the next useful step, complete it, then update the project memory.

**Decide** and **build** are separate modes. Do not invent the following slice while implementing the current one. Cursor agents are instructed via `.cursor/rules/agent-process.mdc`; this doc remains the source of truth.

## Modes

| Mode | Trigger phrases (examples) | Output |
| --- | --- | --- |
| **Decide** | "what's next?", "what should we build next?", "decide the next step/slice", "propose next" | Update `docs/NEXT_STEP.md` only (no feature code) |
| **Build** | "build the next feature/step/slice", "implement it", "build it", "continue building" | Implement exactly what `docs/NEXT_STEP.md` already says |

If the user only asks what to build next, **decide** — do not start coding. If they ask to build and no decided next step exists (or it is already done), **stop and decide first** (or ask them to), then wait for an explicit build request unless they clearly asked to do both.

---

## Decide mode

Purpose: pick exactly one next slice and write it down. No implementation PR for product code.

### Before deciding

1. Read this file.
2. Read `docs/PRODUCT_DIRECTION.md`.
3. Read `docs/WORKING_STATE.md`.
4. Read `docs/NEXT_STEP.md` (may be empty, done, or stale).
5. Confirm what is already on `main` (and recently merged PRs/branches) so you do not re-propose shipped work.
6. If needed for scope sharpness, selectively consult:
   - `docs/TECHNICAL_REQUIREMENTS.md`
   - `docs/ACCEPTANCE_CRITERIA.md`

### Decide rules

- Propose the smallest useful next slice that advances product direction from current working state.
- Exactly one goal. Clear in scope / out of scope / done criteria.
- Do not implement the slice.
- Do not prebuild or design far-future infrastructure beyond naming it out of scope.

### After deciding

Update `docs/NEXT_STEP.md` with:

- Goal
- In scope
- Out of scope
- Done when

Optionally note in the PR/summary why this slice (one short paragraph). Leave `WORKING_STATE.md` alone unless a factual correction is required for the decision to make sense.

---

## Build mode

Purpose: implement the already-decided slice in `docs/NEXT_STEP.md`.

### Before starting work

1. Read this file.
2. Read `docs/PRODUCT_DIRECTION.md`.
3. Read `docs/WORKING_STATE.md`.
4. Read `docs/NEXT_STEP.md`.
5. Confirm that next step is still undone on `main`. If it is missing, marked done, or stale vs shipped work → **do not invent a replacement while building**. Switch to decide mode (or tell the user), then stop unless they explicitly asked to decide and build.
6. If the current slice needs more context, selectively consult:
   - `docs/TECHNICAL_REQUIREMENTS.md`
   - `docs/ACCEPTANCE_CRITERIA.md`
7. Do only the current next step unless the user explicitly changes direction.

### Working rules

- Every change should leave the gem in a working state.
- Build the smallest useful slice.
- Prefer simple models first.
- Do not prebuild future-phase infrastructure.
- Keep future capabilities directional until needed.
- If a larger design choice appears, record the decision briefly in `docs/WORKING_STATE.md`.

### Before finishing a build

Update:

1. `docs/WORKING_STATE.md`
   - what works now
   - current implementation shape
   - tests proving it

2. `docs/NEXT_STEP.md`
   - mark the completed slice as done (goal + brief "shipped" note)
   - **do not** invent the following slice here — leave that for decide mode
   - use a clear stub, e.g. status `done` / `awaiting next decision`

3. `docs/PRODUCT_DIRECTION.md`
   - only if product intent changed

### PR expectation (build)

Each build PR should include:

- one working slice
- tests for that slice, when code changes
- docs updated to reflect reality (`WORKING_STATE` + completed `NEXT_STEP`)

---

## Reference material

Always read for either mode:

- `docs/PRODUCT_DIRECTION.md`
- `docs/WORKING_STATE.md`
- `docs/NEXT_STEP.md`

Read only when relevant:

- `docs/TECHNICAL_REQUIREMENTS.md`
- `docs/ACCEPTANCE_CRITERIA.md`
- prior broad implementation branches

The larger docs and prior implementation branches are directional reference material. Use them to preserve product intent, terminology, and edge cases for the current slice. Do not load or implement them wholesale by default.
