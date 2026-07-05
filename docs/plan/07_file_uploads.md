# Phase 7 — File Uploads

## Goal

File and array-of-file arguments work end to end: ActiveStorage direct upload with per-file progress, non-blocking form editing, remove/replace, retention through validation/preflight failures, and server-side gating of preflight when required uploads are missing or in flight. A pluggable adapter seam lets non-ActiveStorage hosts substitute their own storage.

## Prerequisites

Phase 6 complete (preflight flow).

## Acceptance criteria owned

- AC-DEV-074 — configurable upload behaviour to use host's upload infrastructure
- AC-OP-020 — upload files (incl. large) without blocking the form
- AC-OP-021 — per-upload progress indicator
- AC-OP-022 — cannot proceed to preflight while a required upload is in progress
- AC-OP-023 — cannot proceed to preflight if a required file missing
- AC-OP-024 — files retained through validation/preflight failures
- AC-OP-025 — show name and size of uploaded files
- AC-OP-026 — remove or replace an uploaded file
- AC-OP-027 — array-of-file rows upload independently with own progress
- AC-SYS-030 — files associated with the draft from the moment upload completes
- AC-SYS-031 — server rejects preflight/execute when required uploads incomplete/invalid
- AC-SYS-032 — files retained through preflight failures and form edits

## Deliverables

1. **Storage adapter seam** — `MoActions.config.file_storage` (default `MoActions::FileStorage::ActiveStorage`):
   - Interface: `attach(execution, argument_name, signed_id)`, `remove(execution, argument_name, reference)`, `metadata(reference)` → `{ filename:, byte_size: }`, `resolve(reference)` → object handed to action code (for AS: the blob/attached file).
   - Only the ActiveStorage implementation ships in v1; the seam exists solely because AC-DEV-074 demands it. Do not build a second adapter.
2. **ActiveStorage wiring:**
   - `Execution` gets `has_many_attached :files`; the `arguments` jsonb stores stable references (signed blob ids) under each file argument name — attachment order/mapping lives in jsonb, attachments provide lifecycle.
   - `Types::File.cast` (placeholder from phase 3) now resolves references via the adapter; `Arguments` exposes the resolved file object(s) to preflight/perform, satisfying AC-DEV-023 fully.
   - Required-file validation: reference present AND blob exists/analyzable; a file "in progress" (no completed blob) counts as missing.
3. **Frontend (Stimulus + `@rails/activestorage` direct upload):**
   - `file_upload_controller.js`: direct upload on file select, progress bar from AS events, then swaps in a hidden input with the signed id and renders filename + human size with a remove button. Replace = remove + new upload. Errors (network, oversize) shown inline; input reset.
   - Array-of-file: reuse phase 5's array wrapper; each row hosts its own upload controller instance and progress.
   - Form-level gating: preflight submit button disabled while any upload is in flight (controller tracks in-flight count). This is UX only — the server check is authoritative.
4. **Server-side gating:** `PreflightRunner` (and later execute) rejects when required file references are absent or unresolvable, surfacing field-level errors like other validation failures.
5. **Retention through edits:** hidden signed-id inputs persist on re-render after validation/preflight failure — verify with tests; uploaded blobs must survive any number of form round-trips. (Cleanup of abandoned blobs is phase 14.)
6. **Dummy app:** ActiveStorage installed (local disk service); one sample action gains `:file` and array-of-`:file` arguments; sample preflight reads the file (e.g. counts CSV rows) proving AC-DEV-023.
7. **System test harness** (if deferred from phase 5): JS-driver system tests are now required.

## Implementation notes

- Direct upload endpoint is the host's `/rails/active_storage/direct_uploads` — ensure engine forms point at the main-app route.
- Do not proxy file bytes through engine controllers.
- Human file sizes via `number_to_human_size`.

## Out of scope (do not build)

- Orphaned-blob cleanup (phase 14). Virus scanning, content-type restrictions (not in ACs).
- Second storage adapter.

## Tests required

- Adapter: attach/remove/metadata/resolve against ActiveStorage with a real (test-service) blob.
- `Types::File` + `Arguments`: resolves single and array file arguments; missing/invalid reference → required error.
- Preflight rejection when required file absent (integration, bypassing UI).
- Retention: failed validation re-render keeps signed-id inputs; blob still attached after multiple edit cycles.
- System tests: upload with progress, remove/replace, array rows uploading independently, preflight button disabled mid-upload.

## Exit criteria

- Manual QA: large-file upload stays non-blocking; full draft → upload → preflight (reads file) → review loop works.
- Full suite green. ≤ 1000 lines changed (system-test infra excluded if it pushes over — flag if so). Committed.
