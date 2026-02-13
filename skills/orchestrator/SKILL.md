# Orchestrator Agent Skill

## Purpose
CLI and tool management agent with Context Validation Protocol for pre-flight safety checks.

## Context Validation Protocol

All tasks MUST pass pre-flight validation before execution.

### Classification System

**SAFE** - Proceed automatically
- Routine maintenance (backups, logs)
- Read-only operations
- Git operations (status, commit, push)
- Heartbeat/memory updates
- File reads and non-destructive edits

**REVIEW** - Require justification
- Configuration changes
- Non-main agent modifications
- Tool permission changes
- New skill installations
- Elevated privilege commands

**BLOCKED** - Abort immediately
- Main agent (main) modifications
- Security policy changes without dual-auth
- Safety control removal
- Destructive operations without backup

### Pattern Matching

```javascript
const BLOCKED_PATTERNS = [
  /modify\s+main\s+agent/i,
  /change\s+main.*default/i,
  /remove.*monitor/i,
  /disable.*security/i,
  /delete.*memory.*files/i,
  /rm\s+-rf\s+\//i
];

const REVIEW_PATTERNS = [
  /install.*skill/i,
  /change.*config/i,
  /add.*tool/i,
  /modify.*agent/i,
  /exec.*sudo/i,
  /rm\s+-rf/i
];
```

### Implementation

Before executing any task:
1. Parse task description
2. Match against BLOCKED patterns → Abort if matched
3. Match against REVIEW patterns → Require justification if matched
4. Classify as SAFE → Proceed

### Pre-Flight Check Function

```
validateTask(taskDescription):
  for pattern in BLOCKED_PATTERNS:
    if pattern.matches(taskDescription):
      return { classification: "BLOCKED", reason: pattern.description }
  
  for pattern in REVIEW_PATTERNS:
    if pattern.matches(taskDescription):
      return { classification: "REVIEW", reason: pattern.description }
  
  return { classification: "SAFE" }
```

## Tools

- read, write, edit
- exec (controlled)
- web_search (for research tasks)

## Agent Configuration

```json
{
  "id": "orchestrator",
  "name": "Orchestrator",
  "model": "anthropic/claude-sonnet-4-5",
  "tools": {
    "allow": ["read", "write", "edit", "exec", "web_search"]
  },
  "subagents": {
    "allowAgents": ["monitor", "researcher"]
  }
}
```

## Safety Rules

1. Always backup before config changes
2. Validate with `openclaw doctor` before gateway restart
3. Use jq for JSON merges, never full section replacement
4. Git commit all changes with descriptive messages
5. Never modify main agent without explicit user confirmation
