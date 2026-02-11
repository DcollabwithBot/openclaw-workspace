# Todoist Task Tracking

Make agent work visible through Todoist. Track what's in progress, what's blocked, and what's done.

## Overview

This skill provides task visibility for long-running agent work. Instead of digging through logs, glance at Todoist to see:
- What's currently in progress
- What's waiting for human input
- What's stuck/stalled
- What's been completed

## Setup

**Projects created:**
- `OpenClaw - Queue` (backlog)
- `OpenClaw - Active` (in progress)
- Assigned tasks = blocked on human

**API token:** `~/.openclaw/credentials/todoist`

## Tools

### `todoist_create_task`
Create a new task in the queue.

**Parameters:**
- `title` (required): Task title
- `description` (optional): Task details
- `project` (optional): "queue" or "active" (default: queue)

**Example:**
```
todoist_create_task(
  title="Research competitor pricing",
  description="Compare top 3 competitors"
)
```

### `todoist_move_to_active`
Start work on a task (move from queue to active).

**Parameters:**
- `task_id` (required): Task ID

**Example:**
```
todoist_move_to_active(task_id="7654321098")
```

### `todoist_assign_to_user`
Mark task as blocked on human input.

**Parameters:**
- `task_id` (required): Task ID
- `reason` (required): Why it's blocked

**Example:**
```
todoist_assign_to_user(
  task_id="7654321098",
  reason="Need API key for service X"
)
```

### `todoist_complete_task`
Mark task as done.

**Parameters:**
- `task_id` (required): Task ID

**Example:**
```
todoist_complete_task(task_id="7654321098")
```

### `todoist_add_comment`
Add progress update to task.

**Parameters:**
- `task_id` (required): Task ID
- `comment` (required): Update text

**Example:**
```
todoist_add_comment(
  task_id="7654321098",
  comment="Completed step 1/3: data collection"
)
```

### `todoist_list_active`
List all active tasks.

**Returns:** JSON array of active tasks

### `todoist_list_assigned`
List all tasks assigned to user (blocked).

**Returns:** JSON array of assigned tasks

### `todoist_reconcile`
Check for stalled or blocked tasks.

**Returns:** Summary of task health

## Workflow

**Starting work:**
1. Create task in queue
2. Move to active when starting
3. Add comments as progress updates
4. Complete when done

**When blocked:**
1. Assign to user with reason
2. Wait for user input
3. Unassign and continue when unblocked

**Reconciliation (heartbeat):**
- Runs every 30 minutes
- Checks for tasks stuck >24h
- Reports blocked/stalled tasks
- Returns HEARTBEAT_OK if healthy

## Usage Examples

**Track a research task:**
```
# Create
task_id = todoist_create_task(
  title="Research pricing models",
  description="Compare 5 SaaS pricing strategies"
)

# Start work
todoist_move_to_active(task_id=task_id)

# Progress update
todoist_add_comment(
  task_id=task_id,
  comment="Found 3 models so far"
)

# Complete
todoist_complete_task(task_id=task_id)
```

**Handle blocking:**
```
# Hit a blocker
todoist_assign_to_user(
  task_id=task_id,
  reason="Need access to analytics dashboard"
)

# User provides access
todoist_add_comment(
  task_id=task_id,
  comment="Access granted, continuing"
)
todoist_complete_task(task_id=task_id)
```

## Implementation

See `todoist.sh` for bash implementation using Todoist REST API v2.

## Notes

- Tasks auto-create projects on first use
- API token must be valid Todoist token
- Rate limits: ~450 requests/15min (handled gracefully)
- Reconciliation runs via heartbeat (configurable)
