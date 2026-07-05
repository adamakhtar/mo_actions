# Phase 10 — Live Monitoring UI

## Goal

Operators watch executions in real time: an Active executions list and a live execution detail page (progress, batch timeline, streaming log) updated via Turbo Streams over ActionCable — no manual refresh. Log rendering is injection-safe.

## Prerequisites

Phase 9 complete (batching).

## Acceptance criteria owned

- AC-OP-050 — view all active executions (queued, running, paused) in one place
- AC-OP-051 — active list shows action name, performer, status, progress, start time
- AC-OP-052 — open an execution: live progress, batch status, streaming log
- AC-OP-053 — progress/log updates appear without manual refresh
- AC-OP-054 — filter the log by batch
- AC-SYS-053 — log output safe from injection

## Deliverables

1. **`MoActions::ExecutionBroadcaster`** — the single place for broadcasts (per tech requirements):
   - `execution_updated(execution)` → replaces status badge + progress bar + batch timeline frames on the detail page, and the execution's row on the active list.
   - `log_entry_created(entry)` → appends to the detail page log stream.
   - Called explicitly from `Runner`/`Context`/transition call sites — NOT from model callbacks. Throttle progress broadcasts (e.g. only on integer-percent change) so hot loops don't flood the cable.
   - Uses `Turbo::StreamsChannel.broadcast_*` with engine partials; streams named per-execution plus one for the active list.
2. **Active executions list** — `executions#index` scoped `active` (queued/running/paused): table of action name, performer, status badge, progress bar, started/queued time; each row a Turbo-Stream target; subscribes to the active-list stream. Row appears on queue, updates live, disappears (or restyles) on terminal state. Becomes the "Active" tab of phase 13's audit navigation — build the nav shell now with one tab.
3. **Live detail page:** phase 8's static show page gains `turbo_stream_from`; progress bar, status, batch timeline, and log update live. Waiting-on-window/delay state ("Next batch at 01:00") updates when the next batch starts. Also upgrade phase 8's async-preflight waiting state from polling to a stream broadcast.
4. **Log filtering by batch** — server-rendered filter (select of batches → reloads log frame filtered via `LogEntry.for_batch`). Keep live-append consistent with an active filter: simplest correct approach is data-batch-id attributes + a tiny Stimulus controller hiding non-matching appended rows.
5. **Injection safety:** log messages and error messages must render as plain text (default ERB escaping — verify nothing uses `raw`/`html_safe` on user-or-action-supplied strings, including inside broadcast partials). Add a test with a `<script>` payload in a log message.
6. **Polling fallback (config only):** `MoActions.config.realtime = :action_cable` (default) or `:polling`; polling mode swaps `turbo_stream_from` for a refresh-interval Turbo frame. Implement minimally — the AC list doesn't demand it, tech requirements name it as configurable-not-default. If it threatens the line budget, cut it and note the deferral in the commit message.

## Implementation notes

- Dummy app needs ActionCable configured (async adapter is fine in dev/test).
- Broadcast partials must be shared with the non-stream page render — one source of truth per component (`_progress.html.erb`, `_status_badge.html.erb`, `_batch_timeline.html.erb`, `_log_entry.html.erb`).
- Broadcasting from background jobs requires the cable to work outside request context — verify in dummy app with the async job adapter.

## Out of scope (do not build)

- Pause/cancel/resume buttons (phase 11) — leave space in the detail header.
- Audit views beyond the Active tab (phase 13).
- Per-performer stream authorization subtleties beyond dashboard auth (visibility scoping is phase 13).

## Tests required

- Broadcaster: correct streams/targets invoked on execution update and log append (assert via `assert_broadcasts` / capturing Turbo Stream broadcasts).
- Runner integration: driving an execution emits broadcasts at transitions and progress changes; progress throttling works.
- Active list: shows only active statuses; row content correct.
- Log filter: batch-filtered requests return only tagged entries.
- XSS: `<script>` in log message renders escaped (both full page and broadcast partial paths).
- System test: detail page updates live while a job runs (drive jobs inline, assert DOM changes without page reload).

## Exit criteria

- Manual QA: open a running multi-batch execution in dummy app, watch progress/batches/log update live; second browser tab on Active list updates too.
- Full suite green. ≤ 1000 lines changed. Committed.
