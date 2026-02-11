# Todoist Task Tracking

Make agent work visible through Todoist with state management, labels, and detailed progress tracking.

## Overview

This skill provides full task visibility for long-running agent work using Todoist sections for state management:
- **🟡 Queue** — Backlog, ready to start
- **🔵 In Progress** — Currently working on
- **🟠 Waiting** — Blocked, waiting for input
- **🟣 Review** — Ready for review
- **🟢 Done** — Completed

## Setup

**Single project:** `OpenClaw Tasks` (auto-creates with sections)

**API token:** `~/.openclaw/credentials/todoist` (chmod 600)

## Tools

### `todoist_create_task`
Create a new task in the queue.

**Parameters:**
- `title` (required): Task title
- `description` (optional): Task details
- `labels` (optional): JSON array of label names `["urgent", "research"]`

**Example:**
```
todoist_create_task(
  title="Research competitor pricing",
  description="Compare top 3 competitors' pricing models",
  labels='["research", "priority"]'
)
```

### `todoist_start_task`
Move task to "In Progress" and log start time.

**Parameters:**
- `task_id` (required)

**Example:**
```
todoist_start_task(task_id="7654321098")
```

### `todoist_set_waiting`
Mark task as blocked/waiting with reason.

**Parameters:**
- `task_id` (required)
- `reason` (optional): Why it's blocked

**Example:**
```
todoist_set_waiting(
  task_id="7654321098",
  reason="Need API key for service X"
)
```

### `todoist_set_review`
Move task to "Review" for user feedback.

**Parameters:**
- `task_id` (required)

### `todoist_complete_task`
Mark task as done with completion summary.

**Parameters:**
- `task_id` (required)
- `summary` (optional): What was accomplished

**Example:**
```
todoist_complete_task(
  task_id="7654321098",
  summary="Found 3 pricing tiers: Basic $9, Pro $29, Enterprise custom"
)
```

### `todoist_add_comment`
Add progress update with categorization.

**Parameters:**
- `task_id` (required)
- `comment` (required): Update text
- `type` (optional): `progress`, `blocker`, `decision`, `info`, `update` (default)

**Example:**
```
todoist_add_comment(
  task_id="7654321098",
  comment="Completed data collection from 5 sources",
  type="progress"
)

# Blocker discovered
todoist_add_comment(
  task_id="7654321098",
  comment="Rate limited by API, need to wait 1 hour",
  type="blocker"
)

# Key decision made
todoist_add_comment(
  task_id="7654321098",
  comment="Using Stripe over PayPal for better API",
  type="decision"
)
```

### `todoist_add_label`
Add a label to an existing task.

**Parameters:**
- `task_id` (required)
- `label` (required): Label name (auto-creates if missing)

**Example:**
```
todoist_add_label(task_id="7654321098", label="urgent")
```

### `todoist_list_by_state`
List tasks in a specific state.

**Parameters:**
- `state` (optional): `queue`, `progress`, `waiting`, `review`, `done`, `all` (default)

**Example:**
```
# What's in progress?
todoist_list_by_state("progress")

# What's blocked?
todoist_list_by_state("waiting")

# Everything
todoist_list_by_state("all")
```

### `todoist_list_all`
List all tasks in the project.

### `todoist_get_task_details`
Get task + all comments for full context.

**Parameters:**
- `task_id` (required)

### `todoist_reconcile`
Health check for stalled tasks.

**Returns:**
- `status`: "ok" or "alert"
- `active`: Count of active tasks
- `waiting`: Count of waiting tasks  
- `stalled`: Count of tasks >24h old
- `stalled_tasks`: Details of stalled tasks

## Workflow Example

**Track a research task:**
```
# 1. Create with context
task_id = todoist_create_task(
  title="Research pricing models",
  description="Compare 5 SaaS pricing strategies for our product",
  labels='["research", "competitor-analysis"]'
)

# 2. Start work (moves to 🔵 In Progress)
todoist_start_task(task_id=task_id)

# 3. Log progress as you go
todoist_add_comment(
  task_id=task_id,
  comment="Found 3 models so far: freemium, tiered, usage-based",
  type="progress"
)

# 4. Hit a blocker (moves to 🟠 Waiting)
todoist_set_waiting(
  task_id=task_id,
  reason="Need access to competitor pricing page"
)

# User provides access...

# 5. Resume work (back to 🔵 In Progress)
todoist_start_task(task_id=task_id)

todoist_add_comment(
  task_id=task_id,
  comment="Access granted, continuing with analysis",
  type="info"
)

# 6. Ready for review (moves to 🟣 Review)
todoist_set_review(task_id=task_id)

# User reviews...

# 7. Complete with summary (moves to 🟢 Done)
todoist_complete_task(
  task_id=task_id,
  summary="Recommend tiered pricing: Starter $19, Growth $49, Scale $99"
)
```

## State Management

| State | Section | When to Use |
|-------|---------|-------------|
| Queue | 🟡 Queue | Backlog, not started yet |
| Progress | 🔵 In Progress | Currently working on it |
| Waiting | 🟠 Waiting | Blocked, needs user input |
| Review | 🟣 Review | Done, needs user approval |
| Done | 🟢 Done | Completed, closed |

## Labels

Use labels to categorize tasks:
- `urgent` — High priority
- `research` — Information gathering
- `coding` — Implementation work
- `bug` — Bug fixes
- `meeting` — Requires meeting/discussion
- `waiting-external` — Blocked on third party

Labels are auto-created on first use.

## Comments

Comments include:
- Timestamp
- Emoji prefix based on type
- Full message

**Comment types:**
- 📈 Progress — Step completion
- 🚧 Blocker — Issues encountered
- 🎯 Decision — Key choices made
- ℹ️ Info — General updates
- 💬 Update — Default updates
- 🤖 Auto — System messages (task created, started, etc.)

## Reconciliation

Heartbeat checks every 2 hours:
- Tasks >24h old flagged as stalled
- Waiting tasks reported
- Alerts if action needed

## Implementation

See `todoist.sh` for bash implementation using Todoist REST API v2.

## Security

- API token stored in `~/.openclaw/credentials/todoist` (chmod 600)
- Not committed to git
- Logs sanitized (no token exposure)