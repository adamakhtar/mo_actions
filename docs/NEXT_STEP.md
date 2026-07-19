# Next Step

Status: **ready** (decided, not yet built)

## Deferred

- **Run again** (prefill from a past execution) — postponed; pick up in a later decide.

## Goal

Action authors can declare a completion total when work starts and report current progress during `perform`; that progress is persisted on the execution so a dashboard operator can see it by reloading the page (no Hotwire).

## Why this shape

Today an `Execution` is only created after `perform` finishes, so there is nothing to update mid-run and nowhere for a reload to look. This slice creates the record up front (with a non-terminal status), runs work in the background, and writes progress onto that record as the action goes.

## In scope

- Execution columns for progress, e.g. `progress_total` and `progress_current` (integers; percent derived for display)
- Statuses needed for an in-flight run (at least `running`, plus existing `succeeded` / `failed`)
- Create the execution **before** work starts; persist progress updates during `perform`
- Author API on a small context (or equivalent) passed into `perform`, roughly:
  - set total at start (`ctx.total = n` / `ctx.progress_total(n)`)
  - record current (`ctx.progress(i)` → updates `progress_current`, clamped to total)
- Minimal async path so create/confirm returns, redirects to `executions#show`, and a later reload shows updated progress (ActiveJob; host adapter)
- Dashboard: show progress on detail (and optionally index for running rows); **manual reload only** — no Turbo Streams / polling / meta-refresh required
- Dummy action that advances progress slowly enough to demo a reload
- Tests: total + current persisted; clamp/bounds; success/failure still terminal; show renders progress; unregistered-action detail still works

## Out of scope

- Hotwire / Turbo Stream live updates
- Structured logging / log stream UI
- Multi-batch, delays, windows
- Pause / resume / cancel / retry
- Drafts, preflight, authorization rules
- Run again
- File arguments

## Done when

- An action author can set a completion total and update current progress during `perform`.
- Progress is saved on the execution record and visible on the detail page after a manual reload while (or after) the run.
- Full suite green.
