# Mo Actions — Acceptance Criteria (v1)

This document defines what the gem must deliver for its three audiences: **developers** (action authors and host app integrators), **operators** (dashboard users who run and monitor actions), and the **system** (background behaviour, data integrity, and lifecycle).

It describes outcomes and behaviours, not implementation.

**Related:** [Technical Requirements](./TECHNICAL_REQUIREMENTS.md) — stack, code style, phased delivery.

---

## Scope

**In scope for v1:** defining actions in code, running them via a mounted dashboard, draft → preflight → execute flow, typed arguments (including arrays), file uploads, async execution with batching, progress and logging, pause/resume/cancel, authorization, and execution audit trail. Only supports Rails.

**Out of scope for v1:** composite/struct argument types, dry run mode, auto-retry policies, approval workflows, notifications UI, admin-editable categories.

---

## 1. Developer — Defining Actions

### 1.1 Action registration and discovery

| ID | Acceptance criteria |
| -- | ------------------- |
| AC-DEV-001 | A developer can define an action in Ruby within the host Rails application. |
| AC-DEV-002 | Defined actions are automatically discovered and registered when the application boots. |
| AC-DEV-003 | Each action has a stable identifier, a human-readable name, and a description shown to operators. |
| AC-DEV-004 | Each action belongs to exactly one category. Categories are used to group actions in the dashboard. |
| AC-DEV-005 | A developer can define multiple actions across multiple categories. |

### 1.2 Arguments

| ID | Acceptance criteria |
| -- | ------------------- |
| AC-DEV-010 | A developer can declare arguments on an action with a name, type, description, required/optional flag, and default value. |
| AC-DEV-011 | Supported scalar types: string, integer, decimal, boolean, date, datetime, enum, and file. |
| AC-DEV-012 | Any scalar type can be declared as an array (e.g. array of integers, array of files). |
| AC-DEV-013 | A developer can attach validations to arguments (e.g. presence, numericality, inclusion, custom rules). |
| AC-DEV-014 | Validations on array arguments apply to each element, with optional array-level rules (minimum/maximum items, uniqueness). |
| AC-DEV-015 | Argument definitions are the single source of truth — the dashboard form, validation, and runtime access all derive from the same declaration. |
| AC-DEV-016 | In action code, the developer receives typed, coerced argument values — not raw form data. |

### 1.3 Preflight

| ID | Acceptance criteria |
| -- | ------------------- |
| AC-DEV-020 | A developer can optionally define a preflight check that runs after schema validation and before execution. |
| AC-DEV-021 | Preflight can return blocking errors (prevent execution) and non-blocking informational results (shown to the operator). |
| AC-DEV-022 | A developer can mark preflight as asynchronous for expensive checks; the operator sees a waiting state until results are ready. |
| AC-DEV-023 | Preflight receives the same argument values the perform step would receive, including access to uploaded files. |

### 1.4 Execution, progress, and logging

| ID | Acceptance criteria |
| -- | ------------------- |
| AC-DEV-030 | A developer implements the action's work in a perform method invoked when execution begins. |
| AC-DEV-031 | During perform, the developer can report progress as a percentage. |
| AC-DEV-032 | During perform, the developer can write log entries at different levels (e.g. info, warning, error). |
| AC-DEV-033 | During perform, the developer can log exceptions in a structured way. |
| AC-DEV-034 | During perform, the developer can write progress-style log messages distinct from percentage progress. |
| AC-DEV-035 | The developer can access who triggered the execution (the performer). |
| AC-DEV-036 | Log entries from a single execution appear in one chronological stream, optionally tagged by batch. |

### 1.5 Batching

| ID | Acceptance criteria |
| -- | ------------------- |
| AC-DEV-040 | Every action runs as at least one batch. Single-step actions require no batch configuration. |
| AC-DEV-041 | A developer can configure multi-batch actions with a delay between batches. |
| AC-DEV-042 | A developer can configure multi-batch actions to run only within a specified time window (e.g. 1am–5am). |
| AC-DEV-043 | Progress reported within a batch contributes to an overall execution progress percentage. |
| AC-DEV-044 | A developer can dynamically add batches during execution when the total batch count is not known upfront. |

### 1.6 Pause and resume

| ID | Acceptance criteria |
| -- | ------------------- |
| AC-DEV-050 | A developer can opt in to pause/resume support on an action. |
| AC-DEV-051 | Without additional code, pause takes effect between batches. |
| AC-DEV-052 | With additional code, the developer can check for pause/cancel signals within long-running loops. |
| AC-DEV-053 | The developer can save and restore checkpoint state to support mid-batch resume. |

### 1.7 Authorization

| ID | Acceptance criteria |
| -- | ------------------- |
| AC-DEV-060 | A developer can define an authorization rule per action that determines which performers may run it. |
| AC-DEV-061 | Authorization is enforced when an operator attempts to run an action, not just when displaying it. |

### 1.8 Host app integration

| ID | Acceptance criteria |
| -- | ------------------- |
| AC-DEV-070 | A developer can mount the dashboard engine at a configurable path within the host Rails application. |
| AC-DEV-071 | A developer can configure which model represents the performer (defaulting to the host app's user model). |
| AC-DEV-072 | A developer can integrate the dashboard with the host app's authentication (unauthenticated users cannot access it). |
| AC-DEV-073 | A developer can configure who can see which executions in the audit trail. |
| AC-DEV-074 | A developer can configure file upload behaviour to use the host app's existing upload infrastructure. |
| AC-DEV-075 | A developer can configure timezone used for batch scheduling windows. |
| AC-DEV-076 | A developer can configure retention periods for drafts and completed executions. |
| AC-DEV-077 | The gem works with the host app's existing background job infrastructure without requiring a specific job adapter. |
| AC-DEV-078 | A developer can subscribe to lifecycle events (e.g. execution succeeded, execution failed) to wire up notifications in the host app. |
| AC-DEV-079 | A developer can test actions without going through the job queue. |

---

## 2. Operator — Running and Monitoring Actions

### 2.1 Discovering actions

| ID | Acceptance criteria |
| -- | ------------------- |
| AC-OP-001 | An operator can view all registered actions grouped by category. |
| AC-OP-002 | Each action displays its name and description so the operator understands what it does before running it. |
| AC-OP-003 | Actions the operator is not authorized to run are visible but clearly disabled, with an explanation. |
| AC-OP-004 | An operator can toggle visibility of unauthorized actions on or off. |

### 2.2 Draft — supplying arguments

| ID | Acceptance criteria |
| -- | ------------------- |
| AC-OP-010 | An operator can start running an action, which creates a draft execution. |
| AC-OP-011 | The dashboard renders a form dynamically from the action's argument definitions. |
| AC-OP-012 | Each argument shows its description/help text. |
| AC-OP-013 | Array arguments render as a dynamic list where the operator can add, remove, and reorder entries. |
| AC-OP-014 | The operator can save scalar argument values while continuing to edit the form. |
| AC-OP-015 | The operator can abandon a draft execution. |
| AC-OP-016 | Abandoned drafts are eventually cleaned up automatically. |

### 2.3 File uploads

| ID | Acceptance criteria |
| -- | ------------------- |
| AC-OP-020 | An operator can upload file arguments, including large files, without blocking the rest of the form. |
| AC-OP-021 | Each file upload shows a progress indicator. |
| AC-OP-022 | An operator cannot proceed to preflight while a required file upload is still in progress. |
| AC-OP-023 | An operator cannot proceed to preflight if a required file has not been uploaded. |
| AC-OP-024 | If validation or preflight fails, previously uploaded files remain attached — the operator does not need to re-upload them. |
| AC-OP-025 | An operator can see the name and size of uploaded files. |
| AC-OP-026 | An operator can remove or replace an uploaded file. |
| AC-OP-027 | For array-of-file arguments, each row uploads independently with its own progress. |

### 2.4 Preflight

| ID | Acceptance criteria |
| -- | ------------------- |
| AC-OP-030 | An operator can run a preflight check once arguments (including files) are ready. |
| AC-OP-031 | Schema validation errors are shown with field-level messages linked to the relevant form fields. |
| AC-OP-032 | If preflight fails, the operator returns to the argument form to make corrections and can re-run preflight. |
| AC-OP-033 | If preflight passes, the operator sees a review screen with informational results (e.g. row counts, warnings). |
| AC-OP-034 | If the operator changes any argument after a successful preflight, they must re-run preflight before executing. |
| AC-OP-035 | For expensive preflight checks, the operator sees a clear waiting/in-progress state. |

### 2.5 Execute

| ID | Acceptance criteria |
| -- | ------------------- |
| AC-OP-040 | After successful preflight, the operator must explicitly confirm before execution begins. |
| AC-OP-041 | Once confirmed, arguments are locked — they cannot be changed for that execution. |
| AC-OP-042 | The operator is redirected to the execution detail view once execution begins. |

### 2.6 Monitoring active executions

| ID | Acceptance criteria |
| -- | ------------------- |
| AC-OP-050 | An operator can view all currently active executions (queued, running, paused) in one place. |
| AC-OP-051 | The active executions list shows action name, performer, status, progress, and start time. |
| AC-OP-052 | An operator can open an execution to see live progress, batch status, and a streaming log. |
| AC-OP-053 | Progress and log updates appear on the execution detail page without requiring a manual refresh. |
| AC-OP-054 | An operator can filter the log by batch. |

### 2.7 Controlling executions

| ID | Acceptance criteria |
| -- | ------------------- |
| AC-OP-060 | An operator can cancel a queued or running execution (when supported). |
| AC-OP-061 | An operator can pause a running execution (when the action supports it). |
| AC-OP-062 | An operator can resume a paused execution. |
| AC-OP-063 | Cancel and pause controls are only available when meaningful (e.g. not on already-finished executions). |

### 2.8 Audit trail

| ID | Acceptance criteria |
| -- | ------------------- |
| AC-OP-070 | An operator can browse past executions in separate views: Succeeded, Failed, and Cancelled. |
| AC-OP-071 | An operator can browse all active (in-flight) executions in a dedicated Active view. |
| AC-OP-072 | Each audit view shows a count of matching executions. |
| AC-OP-073 | An operator can filter executions by action. |
| AC-OP-074 | An operator can filter executions by performer. |
| AC-OP-075 | An operator can filter executions by date range. |
| AC-OP-076 | The Failed view shows a summary error message for each execution to aid triage. |
| AC-OP-077 | An operator can open any past execution to view its full detail: performer, timestamps, duration, status, arguments used, batch timeline, and complete log. |
| AC-OP-078 | Completed execution detail pages are read-only. |
| AC-OP-079 | Failed execution detail pages prominently display the error. |
| AC-OP-080 | An operator can start a new run pre-filled with the arguments from a previous execution ("run again"). |
| AC-OP-081 | "Run again" creates a new execution — the original audit record is preserved unchanged. |

---

## 3. System — Background Behaviour and Integrity

### 3.1 Execution lifecycle

| ID | Acceptance criteria |
| -- | ------------------- |
| AC-SYS-001 | Actions execute asynchronously in the background — the operator is not blocked waiting for completion. |
| AC-SYS-002 | Each execution records who performed it and when it started and finished. |
| AC-SYS-003 | Each execution transitions through well-defined states (draft, preflighting, ready, queued, running, paused, succeeded, failed, cancelled). |
| AC-SYS-004 | Arguments are immutable once execution begins. |
| AC-SYS-005 | A failed batch causes the execution to fail unless manually retried. |
| AC-SYS-006 | An operator can manually retry a failed batch from the dashboard. |

### 3.2 Batching and scheduling

| ID | Acceptance criteria |
| -- | ------------------- |
| AC-SYS-010 | Batches within an execution run sequentially (one at a time). |
| AC-SYS-011 | Configured delays between batches are honoured. |
| AC-SYS-012 | Configured time windows are honoured — batches outside the window wait until the window opens. |
| AC-SYS-013 | Each batch records its own status, timestamps, and progress. |

### 3.3 Progress and logging

| ID | Acceptance criteria |
| -- | ------------------- |
| AC-SYS-020 | Overall execution progress reflects completed batches and current batch progress. |
| AC-SYS-021 | Log entries are persisted and available after execution completes. |
| AC-SYS-022 | Log entries are associated with their execution and optionally tagged with a batch. |

### 3.4 File lifecycle

| ID | Acceptance criteria |
| -- | ------------------- |
| AC-SYS-030 | Uploaded files are associated with the draft execution from the moment upload completes. |
| AC-SYS-031 | The system rejects preflight and execute requests if required file uploads are incomplete or invalid. |
| AC-SYS-032 | Uploaded files are retained through preflight failures and form edits. |
| AC-SYS-033 | Orphaned files from abandoned or expired drafts are cleaned up. |
| AC-SYS-034 | Files attached to completed executions are retained for a configurable period, then cleaned up. |

### 3.5 Data retention

| ID | Acceptance criteria |
| -- | ------------------- |
| AC-SYS-040 | Draft executions that are not completed expire after a configurable period. |
| AC-SYS-041 | Completed execution records and logs are retained for a configurable period before cleanup. |

### 3.6 Security and authorization

| ID | Acceptance criteria |
| -- | ------------------- |
| AC-SYS-050 | Unauthorized users cannot access the dashboard. |
| AC-SYS-051 | Unauthorized users cannot run actions, even by bypassing the UI. |
| AC-SYS-052 | Execution visibility in the audit trail respects the host app's configured scope. |
| AC-SYS-053 | Log output displayed in the dashboard is safe from injection attacks. |

### 3.7 Reliability

| ID | Acceptance criteria |
| -- | ------------------- |
| AC-SYS-060 | If a background worker dies mid-execution, the execution does not remain stuck in "running" indefinitely. |
| AC-SYS-061 | Multiple executions of the same action can run concurrently. |
| AC-SYS-062 | Re-running an action always creates a new, independent execution record. |

---

## 4. Explicitly out of scope (v1)

The following are acknowledged requirements for future versions but are **not** acceptance criteria for v1:

| Feature | Notes |
| ------- | ----- |
| Composite/struct argument types | Array of named field groups (e.g. column mappings) |
| Dry run mode | Preview what would happen without making changes |
| Automatic retry on failure | Manual batch retry only in v1 |
| Concurrent execution limits | Per-action throttling |
| In-dashboard notifications | Host app wires via lifecycle events |
| Approval workflows | Second-user sign-off before execution |
| Admin-editable categories | Categories defined in code only |
| Export log as file | CSV/JSON download |
| API-only mode (no bundled UI) | Engine UI is the v1 delivery |

---

## 5. Definition of done (v1 release)

The gem is v1-complete when:

1. All **AC-DEV**, **AC-OP**, and **AC-SYS** criteria above are met.
2. A host application can install the gem, define at least one action with arguments, mount the dashboard, and complete a full draft → preflight → execute → audit cycle.
3. Documentation covers developer setup, action authoring, and operator usage.
