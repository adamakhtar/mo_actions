# Phase 9 — Multi-Batch Execution & Scheduling

## Goal

Actions can split work into sequential batches with configurable delays and time windows, add batches dynamically mid-run, and overall execution progress aggregates batch progress. Builds directly on phase 8's single-batch runner.

## Prerequisites

Phase 8 complete (async execution).

## Acceptance criteria owned

- AC-DEV-041 — multi-batch with delay between batches
- AC-DEV-042 — batches only within a time window (e.g. 1am–5am)
- AC-DEV-043 — batch progress contributes to overall execution progress
- AC-DEV-044 — dynamically add batches during execution
- AC-DEV-075 — configurable timezone for scheduling windows
- AC-SYS-010 — batches run sequentially
- AC-SYS-011 — delays honoured
- AC-SYS-012 — time windows honoured (wait until window opens)
- AC-SYS-013 — each batch records status, timestamps, progress
- AC-SYS-020 — overall progress = completed batches + current batch progress

## Deliverables

1. **Batch DSL on `MoActions::Base`:**

   ```ruby
   class BackfillInvoicesAction < MoActions::Base
     batches delay: 5.minutes, window: "01:00".."05:00"

     def plan_batches(args, planner)      # optional; absent = single batch
       args.account_ids.each_slice(100) { |ids| planner.add(account_ids: ids) }
     end

     def perform_batch(args, ctx)
       ctx.batch_params[:account_ids]     # payload from planner
       ...
     end
   end
   ```

   - `plan_batches` runs at execute-time (replacing phase 8's implicit single batch) and creates `Batch` rows with a `params` payload (add a `params` json column to `mo_actions_batches` — small migration).
   - Single-batch actions keep using `perform`; multi-batch actions implement `perform_batch`. Defining both is an error at registration. (Internally `perform` is just the one-batch case — keep the wiring simple.)
   - Dynamic batches: `ctx.add_batch(**params)` appends a pending batch at the end during a run (AC-DEV-044).
2. **Sequential chaining in `Runner`/`RunBatchJob`:** on batch success, find the next pending batch; if none, `succeed!` the execution; otherwise enqueue the next `RunBatchJob` honouring:
   - **Delay:** `RunBatchJob.set(wait: delay).perform_later(...)`.
   - **Window:** `MoActions::TimeWindow` value object — parses `"HH:MM".."HH:MM"`, handles overnight ranges (`"23:00".."04:00"`), computes `next_opening(from:)` in `MoActions.config.timezone` (default `Time.zone` / host default; add the config knob). Outside window → `set(wait_until: next_opening)`. Delay and window compose: apply delay, then push to window opening if the delayed time falls outside.
   - Batch failure → execution `fail!` (manual retry is phase 11); remaining batches stay `pending`.
3. **Overall progress:** `Execution#recalculate_progress!` = (fully completed batches + current batch fraction) / total known batches, recalculated on batch progress writes and on dynamic batch addition (progress may legitimately drop when batches are added — document this in a comment).
4. **UI updates (still static/refresh-based):** execution detail gains a batch timeline section — each batch's position, status, progress, timestamps, and scheduled-for time when waiting on delay/window ("Next batch at 01:00"). Log entries render their batch tag; log filter-by-batch UI defers to phase 10.
5. **Dummy app:** one multi-batch sample action with delay + window + dynamic batches for QA.

## Implementation notes

- Chaining, not looping: each job enqueues its successor. Never hold a worker across a delay/window.
- All window math through the configured timezone — test DST boundaries at least once and overnight windows thoroughly. Use `travel_to` liberally.
- `wait_until` relies on the host adapter supporting scheduled jobs — every serious adapter does; note it in docs (phase 14), don't code around it.

## Out of scope (do not build)

- Pause/resume/cancel between batches (phase 11) — but chaining should check status before enqueueing the next batch in a way phase 11 can extend.
- Live UI updates (phase 10). Concurrent-batch execution (never — v1 is sequential only).

## Tests required

- Planner: N batches created with params; single-batch actions unaffected; both `perform` and `perform_batch` defined → registration error.
- Chaining: batches run strictly sequentially through the test adapter; last success → execution succeeded; mid-batch failure → execution failed, later batches still pending.
- Delay: next job scheduled `wait:` delay (assert enqueued_at).
- Window: inside window runs now; outside schedules at next opening; overnight window; delay+window composition; timezone respected.
- Dynamic: `ctx.add_batch` mid-run appends and executes; progress recalculates.
- Progress aggregation across completed/current/pending batches.

## Exit criteria

- Manual QA: multi-batch action visibly steps through batches with a delay in dummy app.
- Full suite green. ≤ 1000 lines changed. Committed.
