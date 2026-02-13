# HEARTBEAT.md - Rotating Proactive Checks

**Instructions:**
This file defines periodic checks. Run the **most overdue check** based on current time vs `lastChecks` in `memory/heartbeat-state.json`, then reply HEARTBEAT_OK.

## State Tracking
Read/update: `memory/heartbeat-state.json`

Format:
```json
{
  "lastChecks": {
    "git_status": 1770800000,
    "proactive_scan": 1770800000,
    "memory_maintenance": 1770800000
  }
}
```

## Rotation Logic
For each heartbeat, calculate overdue time for all checks:
- `overdue = current_time - (last_check + interval)`
- Run the check with highest overdue value (most overdue first)
- Update `lastChecks` after completing a check
- If nothing is overdue, reply HEARTBEAT_OK immediately

## Checks

### 1. Git Status Check (every 24h)
**Interval:** 86400 seconds  
**Purpose:** Ensure config is backed up
- Check if `~/.openclaw` has uncommitted changes
- If changes exist: commit with timestamp + push to origin
- Alert if push fails or remote is unreachable
- Update `lastChecks.git_status`

### 2. Proactive Scanning (every 24h)
**Interval:** 86400 seconds  
**Purpose:** Check for issues needing attention
- Read recent memory files (last 3 days)
- Look for `TODO`, `FIXME`, `ALERT` markers
- Check agent session logs for errors
- Review Todoist for stalled tasks (>48h)
- If issues found: summarize and alert user
- Update `lastChecks.proactive_scan`

### 3. Memory Maintenance (every 48h)
**Interval:** 172800 seconds  
**Purpose:** Clean up and consolidate memory
- Review daily memory files from last 7 days
- Identify significant events worth keeping
- Update MEMORY.md with distilled learnings
- Remove outdated/outdated info from MEMORY.md
- Archive old daily files (>30 days) if needed
- Update `lastChecks.memory_maintenance`

## Quiet Hours
- Late night (23:00-08:00 UTC+1) → only urgent items
- Respect if user is clearly busy

## When to Reach Out vs HEARTBEAT_OK
**Reach out if:**
- Important event/reminder coming up
- Something interesting found
- Git push fails (backup issue)
- Stalled tasks or alerts detected

**HEARTBEAT_OK if:**
- Nothing overdue
- Nothing new since last check
- User is busy/quiet hours
- Just checked <30min ago
