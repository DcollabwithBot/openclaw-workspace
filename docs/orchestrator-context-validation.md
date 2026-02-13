# Orchestrator Context Validation Protocol

## Purpose
Pre-flight validation for all orchestrator tasks to ensure safety and appropriate escalation.

## Classification Levels

### SAFE
- Routine maintenance tasks
- Read-only operations
- File backups and logging
- Git operations (status, commit, push)
- Heartbeat updates
- Memory file management

### REVIEW
- Configuration changes (requires justification)
- Agent modifications (non-main)
- Tool permission changes
- New skill installations
- External command execution with elevated privileges

### BLOCKED
- Main agent (main) modification attempts
- System-level destructive operations without backup
- Security policy changes without dual authorization
- Removal of safety controls or monitoring

## Validation Procedure

1. Parse incoming task description for pattern keywords
2. Match against classification database
3. Return classification with required action:
   - SAFE: Proceed with task
   - REVIEW: Provide justification before proceeding
   - BLOCKED: Abort and notify user

## Pattern Keywords

### BLOCKED Patterns
- "modify main agent"
- "change main.*default"
- "remove.*monitor"
- "disable.*security"
- "delete.*memory.*files"

### REVIEW Patterns
- "install.*skill"
- "change.*config"
- "add.*tool"
- "modify.*agent"
- "exec.*sudo"
- "rm -rf"

## Implementation

This protocol must be applied before any orchestrator task execution.
