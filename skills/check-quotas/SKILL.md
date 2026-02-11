# Check Quotas Skill

Monitor API quota usage across configured providers.

## Overview

Simple script to check API quota status for all configured providers. Useful for:
- Monitoring spend before running expensive tasks
- Heartbeat integration for quota alerts
- Pre-flight checks before spawning subagents

## Providers Checked

- **OpenRouter** — Usage, limit, remaining, percent used
- **OpenAI** — Key validity check
- **Anthropic** — Key validity check
- **GitHub** — Rate limits (core + search)
- **Todoist** — Key validity check

## Usage

### Run manually:
```bash
~/.openclaw/workspace/skills/check-quotas/check-quotas.sh
```

### Pretty print:
```bash
~/.openclaw/workspace/skills/check-quotas/check-quotas.sh | jq .
```

### Check specific provider:
```bash
# OpenRouter usage percent
~/.openclaw/workspace/skills/check-quotas/check-quotas.sh | jq '.openrouter.percent_used'

# GitHub remaining calls
~/.openclaw/workspace/skills/check-quotas/check-quotas.sh | jq '.github.core_remaining'

# All valid APIs
~/.openclaw/workspace/skills/check-quotas/check-quotas.sh | jq 'del(.checked_at) | to_entries | map(select(.value != "null")) | from_entries'
```

## Output Format

```json
{
  "openrouter": {
    "usage": 45.23,
    "limit": 100.00,
    "remaining": 54.77,
    "percent_used": 45.23
  },
  "openai_api": "valid",
  "anthropic_api": "valid",
  "github": {
    "core_limit": 5000,
    "core_remaining": 4980,
    "core_reset": 1739280000,
    "search_limit": 30,
    "search_remaining": 30
  },
  "todoist": "valid",
  "checked_at": "2026-02-11T11:30:00Z"
}
```

## Heartbeat Integration

Add to HEARTBEAT.md:
```markdown
### 4. Quota Check (every 4 hours)
- Run: `~/.openclaw/workspace/skills/check-quotas/check-quotas.sh`
- Alert if OpenRouter >80% or GitHub <100 remaining
- Last check: read `lastChecks.quotas` from state
```

## Alert Examples

```bash
# Check if OpenRouter >80% used
QUOTAS=$(~/.openclaw/workspace/skills/check-quotas/check-quotas.sh)
USAGE=$(echo "$QUOTAS" | jq '.openrouter.percent_used // 0')
if (( $(echo "$USAGE > 80" | bc -l) )); then
    echo "⚠️ OpenRouter quota at ${USAGE}%"
fi

# Check if GitHub rate limit low
REMAINING=$(echo "$QUOTAS" | jq '.github.core_remaining // 5000')
if [ "$REMAINING" -lt 100 ]; then
    echo "⚠️ GitHub API calls remaining: $REMAINING"
fi
```

## Requirements

- `bash`, `curl`, `jq`
- API keys in `~/.openclaw/credentials/`

## Files

- `check-quotas.sh` — Main script
- `SKILL.md` — This documentation
