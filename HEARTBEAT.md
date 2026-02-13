# HEARTBEAT.md - Rotating Proactive Checks

**Instructions:**
This file defines periodic checks. Run the most overdue check, then reply HEARTBEAT_OK.

## State Tracking
Read/update: `memory/heartbeat-state.json`

Format:
```json
{
  "lastChecks": {
    "status": 1770800000,
    "memory": 1770800000
  }
}
```

## Checks (Rotate Based on Overdue Time)

### 1. Status Check (every 2 hours)
- Check if anything needs immediate attention
- Review recent memory files for pending todos
- Last check: read `lastChecks.status` from state

### 2. Memory Maintenance (every 6 hours)
- Review recent daily memory files
- Identify significant events worth adding to MEMORY.md
- Update MEMORY.md with distilled learnings
- Remove outdated info from MEMORY.md
- Last check: read `lastChecks.memory` from state

### 3. Todoist Reconciliation (every 2 hours)
- Run: `~/.openclaw/workspace/skills/todoist/todoist.sh reconcile`
- Check for stalled tasks (>24h old, not in 🟢 Done)
- Check for tasks in 🟠 Waiting
- Report counts per state (🟡🔵🟠🟣)
- Alert if stalled or waiting tasks found
- Last check: read `lastChecks.todoist` from state

### 4. Brave Search Quota (every 6 hours)
- Run: `~/.openclaw/workspace/skills/check-quotas/check-quotas.sh | jq '.brave_search'`
- Alert if: usage >= 1.950 (97.5%) or near_limit = true
- Auto-switches to Perplexity at 1.990 (99.5%)
- Monthly reset: 1st of month via cron
- Last check: read `lastChecks.brave_quota` from state

### 5. Model Fallback Monitor (every 2 hours)
- Check gateway log for fallback events: `grep -i "fallback\|failover" /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log | tail -20`
- Alert if Anthropic → Kimi fallbacks detected (especially for main/coordinator/communicator)
- Track frequency - single fallback OK, repeated = issue
- Last check: read `lastChecks.fallback_monitor` from state

## Quiet Hours
- Late night (23:00-08:00 UTC+1) → only urgent items
- Respect if user is clearly busy

## When to Reach Out vs HEARTBEAT_OK
**Reach out if:**
- Important event/reminder coming up
- Something interesting found
- >8h since last interaction

**HEARTBEAT_OK if:**
- Nothing new since last check
- User is busy/quiet hours
- Just checked <30min ago
