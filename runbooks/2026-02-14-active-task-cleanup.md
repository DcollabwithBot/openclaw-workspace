# Runbook: ACTIVE-TASK.md + Agent Cleanup
**Date:** 2026-02-14  
**Objective:** Implement working memory file + Archive 7 deprecated agents (11 → 4)  
**Parallel Tasks:** 2 (can be executed in sequence or parallel)  
**Estimated Time:** 30-45 minutes

---

## Overview

This runbook covers two related tasks:
1. **Task 1:** Implement ACTIVE-TASK.md working memory pattern
2. **Task 2:** Archive deprecated agent configs (cleanup)

These tasks are designed to work together - Task 2 serves as a real-world test of the ACTIVE-TASK.md template created in Task 1.

---

# TASK 1: ACTIVE-TASK.md Implementation

## Objective
Implement Reddit best-practice working memory file for long-running tasks.

## Why ACTIVE-TASK.md?
- **Problem:** Sessions lose context after /compact or restart
- **Solution:** Persistent working memory file agents read/write
- **Pattern:** Based on r/ClaudeAI best practices for agent workflows

## Step-by-Step Implementation

### Step 1.1: Create ACTIVE-TASK.md Template

**File:** `/root/.openclaw/workspace/ACTIVE-TASK.md`

```markdown
# Active Task Working Memory
**Created:** [AUTO-FILLED]  
**Last Updated:** [AUTO-FILLED]  
**Status:** 🟡 In Progress

---

## Current Task
<!-- One-line description of what we're doing right now -->
[BRIEF DESCRIPTION]

## Context
<!-- Why this task? What triggered it? -->
- Trigger: 
- Priority: 
- Estimated effort: 

---

## Progress Checklist
<!-- Break down into atomic steps -->
- [ ] Step 1: 
- [ ] Step 2: 
- [ ] Step 3: 
- [ ] Step 4: 
- [ ] Final validation

---

## Blockers & Dependencies
<!-- What's blocking progress? -->
| Blocker | Status | Owner | Resolution |
|---------|--------|-------|------------|
| None    | ✅     | -     | -          |

---

## Decisions Made
<!-- Key decisions that affect the approach -->
- Decision 1: 
- Decision 2: 

---

## Next Steps
<!-- What happens next in this task -->
1. 
2. 
3. 

---

## Completion Criteria
<!-- How do we know this is done? -->
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

---

## Notes & Scratchpad
<!-- Free-form notes, observations, temporary storage -->
```

### Step 1.2: Document Usage in AGENTS.md

**File:** `/root/.openclaw/workspace/AGENTS.md`

Add new section:

```markdown
## Working Memory (ACTIVE-TASK.md)

For tasks spanning multiple sessions or requiring /compact:

1. **Create** ACTIVE-TASK.md at task start
2. **Update** progress after each significant step
3. **Check** ACTIVE-TASK.md on session resume
4. **Archive** to `tasks/archive/` when complete

### Template Location
- Template: Copy from ACTIVE-TASK.md (when empty)
- Archive: `tasks/archive/YYYY-MM-DD-task-name.md`

### When to Use
- Tasks > 5 messages
- Tasks requiring /compact
- Multi-session work
- Complex dependencies
```

### Step 1.3: Validation

- [ ] File created at `/root/.openclaw/workspace/ACTIVE-TASK.md`
- [ ] Template includes all sections
- [ ] AGENTS.md updated with usage docs
- [ ] Formatting renders correctly

---

# TASK 2: Agent Cleanup (11 → 4)

## Objective
Archive 7 deprecated agent configs while preserving history.

## Current State Analysis

### KEEP (4 new agents):
| Agent | File | Role |
|-------|------|------|
| James | `james.md` | Main assistant |
| Rene | `rene.md` | Builder/orchestrator |
| Rikke | `rikke.md` | Communicator |
| Anders | `anders.md` | Coordinator |

### ARCHIVE (7 old agents):
| Agent | File | Reason |
|-------|------|--------|
| communicator.md | Old Rikke role | Replaced by rikke.md |
| coordinator.md | Old Anders role | Replaced by anders.md |
| frontend-tester.md | Deprecated | Merged into Rene |
| git-guard.md | Deprecated | Merged into Rene |
| monitor.md | Deprecated | Functionality moved |
| researcher.md | Deprecated | Spawning deprecated |
| orchestrator.md | OLD Rene | Replaced by rene.md |

## Step-by-Step Cleanup

### Step 2.1: Create Archive Directory

```bash
mkdir -p /root/.openclaw/workspace/agents/archive
```

### Step 2.2: Archive Old Agents

**CRITICAL:** Move (don't copy) to preserve git history.

```bash
cd /root/.openclaw/workspace/agents/

# Move all deprecated agents
mv communicator.md archive/
mv coordinator.md archive/
mv frontend-tester.md archive/
mv git-guard.md archive/
mv monitor.md archive/
mv researcher.md archive/
mv orchestrator.md archive/
```

**Verify:**
```bash
ls -la /root/.openclaw/workspace/agents/
# Should show: anders.md, james.md, rene.md, rikke.md, spawn-matrix.md, archive/

ls -la /root/.openclaw/workspace/agents/archive/
# Should show: 7 .md files
```

### Step 2.3: Update AGENTS.md Index

**Current AGENTS.md shows:**
- James
- Rene

**Update to show all 4:**

```markdown
## Agent Configurations

| Agent | Role | File |
|-------|------|------|
| **James** | Main assistant (default) | [agents/james.md](./agents/james.md) |
| **Rene** | Builder/orchestrator | [agents/rene.md](./agents/rene.md) |
| **Rikke** | Communicator | [agents/rikke.md](./agents/rikke.md) |
| **Anders** | Coordinator | [agents/anders.md](./agents/anders.md) |

## Simplified Fleet (4 Agents)

**James handles everything directly:**
- **Writing tasks** → Uses Opus directly
- **Communication** → Spawns Rikke via `sessions_spawn agentId=communicator`
- **Coordination** → Spawns Anders via `sessions_spawn agentId=coordinator`
- **Implementation** → Spawns Rene via `sessions_spawn agentId=orchestrator`

## Archived Agents

Deprecated agents moved to [agents/archive/](./agents/archive/):
- Old communicator, coordinator, orchestrator configs
- Deprecated: frontend-tester, git-guard, monitor, researcher
```

### Step 2.4: Update Spawn Matrix

**File:** `/root/.openclaw/workspace/agents/spawn-matrix.md`

#### Agent ID Mappings

Each agent supports BOTH name-based and role-based IDs:

| File | Name ID | Role ID |
|------|---------|---------|
| `james.md` | `james` | `main` |
| `rene.md` | `rene` | `orchestrator` |
| `rikke.md` | `rikke` | `communicator` |
| `anders.md` | `anders` | `coordinator` |

**Example spawns (both work):**
- `sessions_spawn agentId=rene` → Rene
- `sessions_spawn agentId=orchestrator` → Rene
- `sessions_spawn agentId=rikke` → Rikke
- `sessions_spawn agentId=communicator` → Rikke

**Current matrix has:** monitor, researcher, communicator, reviewer, coordinator, orchestrator, verifier, security, complexity-guardian

**New simplified matrix (4 agents):**

```markdown
# Spawn Permissions Matrix

Who can spawn whom.

## Current Fleet (4 Agents)

| Agent | ID | Role | Spawned By |
|-------|-----|------|------------|
| James | `main` | Main assistant | (root) |
| Rikke | `communicator` | Communication | main |
| Anders | `coordinator` | Coordination | main |
| Rene | `orchestrator` | Implementation | main, coordinator |

## Matrix

| Spawner ↓ \ Spawnee → | communicator | coordinator | orchestrator |
|-----------------------|:------------:|:-----------:|:------------:|
| **main (James)**      | ✅ | ✅ | ✅ |
| **coordinator (Anders)** | ❌ | ❌ | ✅ |
| **orchestrator (Rene)** | ❌ | ❌ | ❌ |

## Legend
- ✅ **Can spawn**
- ❌ **Cannot spawn**

## Key Rules

1. **Main (James)** can spawn any agent
2. **Coordinator (Anders)** can only spawn orchestrator for execution
3. **Orchestrator (Rene)** cannot spawn other agents (focus on building)

## Typical Flows

### Simple Task
```
main → orchestrator → [EXECUTE] → main
```

### Complex Task
```
main → coordinator (plan) → orchestrator (execute) → [RETURN] → main
```

### Communication Task
```
main → communicator → [EXECUTE] → main
```

---

## Archive

Previous spawn matrix with 11 agents archived at: [agents/archive/spawn-matrix-legacy.md](./archive/spawn-matrix-legacy.md)
```

**Also create:** `/root/.openclaw/workspace/agents/archive/spawn-matrix-legacy.md` (copy of current before changes)

### Step 2.5: Smoke Tests

**CRITICAL:** Test BEFORE git commit

```bash
# Test 1: Rene via role ID
openclaw sessions spawn agentId=orchestrator
# Expected: Spawns Rene

# Test 2: Rene via name ID
openclaw sessions spawn agentId=rene
# Expected: Spawns Rene

# Test 3: Rikke via role ID
openclaw sessions spawn agentId=communicator
# Expected: Spawns Rikke

# Test 4: Rikke via name ID
openclaw sessions spawn agentId=rikke
# Expected: Spawns Rikke

# Test 5: Anders via role ID
openclaw sessions spawn agentId=coordinator
# Expected: Spawns Anders

# Test 6: Anders via name ID
openclaw sessions spawn agentId=anders
# Expected: Spawns Anders

# Test 7: Deprecated agent - should fail gracefully
openclaw sessions spawn agentId=monitor
# Expected: Error "Agent not found" or similar

# Test 8: Another deprecated agent
openclaw sessions spawn agentId=researcher
# Expected: Error "Agent not found"
```

**Document results** in ACTIVE-TASK.md under "Progress Checklist"

### Step 2.6: Git Commit

```bash
cd /root/.openclaw/workspace

# Stage changes
git add AGENTS.md
git add agents/spawn-matrix.md
git add agents/archive/

# Commit with descriptive message
git commit -m "refactor: Archive 7 deprecated agents (11→4 simplification)

- Archive old configs: communicator, coordinator, frontend-tester,
  git-guard, monitor, researcher, orchestrator (old)
- Keep: james, rene, rikke, anders
- Update AGENTS.md index with 4-agent fleet
- Update spawn-matrix.md with simplified permissions
- Add spawn-matrix-legacy.md to archive for reference

BREAKING CHANGE: Old agent IDs no longer spawnable"

# Push
git push origin main
```

### Step 2.7: Update Memory

**File:** `/root/.openclaw/workspace/memory/2026-02-14.md`

Add section:

```markdown
## Completed: Agent Fleet Simplification (11→4)

**Time:** [TIMESTAMP]
**Commit:** [COMMIT_HASH]

### Changes
- Archived 7 deprecated agent configs to `agents/archive/`
- Updated AGENTS.md with 4-agent fleet documentation
- Updated spawn-matrix.md with simplified permissions

### New Fleet
| Agent | Role | Spawn ID |
|-------|------|----------|
| James | Main | `main` |
| Rene | Builder | `orchestrator` |
| Rikke | Communicator | `communicator` |
| Anders | Coordinator | `coordinator` |

### Smoke Test Results
- ✅ `spawn agentId=orchestrator` → Rene
- ✅ `spawn agentId=communicator` → Rikke
- ✅ `spawn agentId=coordinator` → Anders
- ✅ Deprecated agents fail gracefully
```

---

# SUCCESS METRICS

## Task 1 (ACTIVE-TASK.md)
- [ ] ACTIVE-TASK.md exists at `/root/.openclaw/workspace/ACTIVE-TASK.md`
- [ ] Template has all required sections
- [ ] AGENTS.md documents usage pattern
- [ ] Template was used for Task 2 (dogfooding)

## Task 2 (Agent Cleanup)
- [ ] `agents/archive/` directory exists
- [ ] 7 files archived (not deleted):
  - [ ] communicator.md
  - [ ] coordinator.md
  - [ ] frontend-tester.md
  - [ ] git-guard.md
  - [ ] monitor.md
  - [ ] researcher.md
  - [ ] orchestrator.md (old)
- [ ] AGENTS.md shows only 4 agents
- [ ] Spawn-matrix.md updated
- [ ] Legacy spawn-matrix archived
- [ ] Smoke tests passed
- [ ] Git commit pushed
- [ ] Memory updated

---

# ROLLBACK PLAN

If something breaks:

```bash
cd /root/.openclaw/workspace

# Revert git changes
git reset --hard HEAD~1

# Or restore specific files from archive
cp agents/archive/AGENTNAME.md agents/
```

---

# POST-COMPLETION NOTES

<!-- Fill in after execution -->

**Actual time taken:** ___ minutes  
**Issues encountered:**  
**Adjustments made:**  
**Lessons learned:**  

---

*Runbook created: 2026-02-14*  
*Reviewed by: [PENDING]*  
*Executed by: [PENDING]*
