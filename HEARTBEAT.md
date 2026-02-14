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
    "memory_maintenance": 1770800000,
    "ttl_cleanup": 1770800000,
    "cost_tracking": 1770800000
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
- **Compaction-safety:** Ensure critical info exists in both MEMORY.md AND recent daily files
- Update `lastChecks.memory_maintenance`

### 4. TTL Cleanup (every 24h)
**Interval:** 86400 seconds  
**Purpose:** Archive or delete old memory files
- Find files in `memory/` matching `YYYY-MM-DD.md` pattern
- If file age > 30 days:
  - Extract year-month: `YYYY-MM`
  - Create `memory/archive/YYYY-MM/` if not exists
  - Move file to archive directory
- Update `lastChecks.ttl_cleanup`

### 5. Cost Tracking (every 24h)
**Interval:** 86400 seconds  
**Purpose:** Aggregate and report usage costs
- Read `memory/costs/YYYY-MM.csv` for current month
- Sum tokens and costs
- If new day: append to daily file summary
- Alert if monthly cost exceeds threshold (configurable)
- Update `lastChecks.cost_tracking`

### 6. Todoist Review (every 12h)
**Interval:** 43200 seconds  
**Purpose:** Proactive task management

**Check Steps:**
1. Fetch active tasks via Todoist API
2. Identify actionable items:
   - Overdue tasks → alert immediately
   - Due today → include in summary
   - Stalled >48h → flag for review
   - Quick wins (<1h) → suggest starting

**Alert Thresholds:**
- 🔴 Overdue tasks → immediate alert
- 🟡 3+ tasks due today → summarize
- 🟢 All clear → HEARTBEAT_OK

**Output:**
- If actionable: "Du har X overdue, Y due i dag: [list]"
- Else: HEARTBEAT_OK
- Update `lastChecks.todoist_review`

## Session End Protocol
When a session ends (before replying final message):
1. Identify important events from the session
2. Append summary to `memory/YYYY-MM-DD.md`:
   ```markdown
   ## [HH:MM] Session Summary
   - Events: [list key events]
   - Decisions: [any decisions made]
   - Outcomes: [results/completions]
   ```
3. If critical info learned: also queue for MEMORY.md update

## Quiet Hours
- Late night (23:00-08:00 UTC+1) → only urgent items
- Respect if user is clearly busy

## When to Reach Out vs HEARTBEAT_OK
**Reach out if:**
- Important event/reminder coming up
- Something interesting found
- Git push fails (backup issue)
- Stalled tasks or alerts detected
- Cost threshold exceeded

**HEARTBEAT_OK if:**
- Nothing overdue
- Nothing new since last check
- User is busy/quiet hours
- Just checked <30min ago

### 7. Follow-Up Check (every 12h)
**Interval:** 43200 seconds
**Purpose:** Proaktiv follow-up på Danny

**Check:**
- Har jeg blockers uden svar >24h?
- Er der stalled Danny-tasks >48h?
- Nærmer sig deadlines (<24h) uden aktion?
- Mangler jeg spawn-adgang til nye agenter/skills?

**Alert:**
- 🔴 Blocker uden svar → "Danny, jeg har blocker: [beskrivelse]"
- 🟡 Deadline nærmer sig → "Husker du [task] due [dato]?"
- 🟢 OK → HEARTBEAT_OK

**Update:** `lastChecks.followup`
