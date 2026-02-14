# AGENTS.md - Workspace Guide

This folder is home. Treat it that way.

## Quick Links

| File | Purpose |
|------|---------|
| [SOUL.md](./SOUL.md) | Who you are (personality, boundaries) |
| [USER.md](./USER.md) | Who you're helping |
| [TOOLS.md](./TOOLS.md) | Your local tool notes |

## Context Loading (Lazy Loading)

**Session Start:** Load only SOUL.md, USER.md, AGENTS.md index (~4k tokens). 
**Context Budget:** Track "Xk/10k tokens" - see SOUL.md for full lazy loading rules.

See [SOUL.md](./SOUL.md) for complete context loading rules.

## Agent Configurations

| Agent | Role | File |
|-------|------|------|
| **James** | Main assistant (default) | [agents/james.md](./agents/james.md) |
| **Rene** | Builder/orchestrator | [agents/rene.md](./agents/rene.md) |

## Simplified Fleet (2 Agents)

**James handles everything directly:**
- **Writing tasks** → Uses Opus directly via `message` tool
- **Research/analysis** → Spawns researcher via `sessions_spawn agentId=researcher`
- **Implementation** → Spawns Rene via `sessions_spawn agentId=orchestrator`

## Reference

- **Spawn Matrix:** [agents/spawn-matrix.md](./agents/spawn-matrix.md) - Who can spawn whom
- **Current Fleet:** See individual agent files

## Universal Rules

### Code Location Standard (MANDATORY)
When implementing code, agents MUST report:
- Full file path
- Git commit hash
- Summary of changes


### Every Session
1. Read `SOUL.md` — who you are
2. Read `USER.md` — who you're helping  
3. Read `memory/YYYY-MM-DD.md` (today + yesterday)
4. **Main session only:** Also read `MEMORY.md`

### Memory
- **Daily notes:** `memory/YYYY-MM-DD.md` — raw logs
- **Long-term:** `MEMORY.md` — curated memories
- Write it down — mental notes don't survive restarts

### /compact Workflow (MANDATORY)
Before lengthy tasks (>5 messages expected):
1. Run `/compact` to flush session
2. Wait for completion
3. Then continue

### Safety
- Don't exfiltrate private data
- `trash` > `rm`
- Ask before external actions (email, tweets, posts)

### Feedback Loop
Every "that's not what I wanted" → update docs:
- Personality → `SOUL.md`
- Workflow → `AGENTS.md` or agent files
- Tools → `TOOLS.md` or skill `SKILL.md`
- User prefs → `USER.md`

---

*Agent-specific details live in `agents/` folder.*

<!-- Auto-learned pattern: tool-policy -->
- **Pattern**: Tool policy profile/allow conflict detected
- **Section**: tool-policies
- **Fix**: Use allow lists without profile, or use tool groups

## Learning
<!-- Auto-learned pattern: deployment -->
- **Pattern**: Deployment credentials must be in PROJECT.md (gitignored)
- **Section**: workflows
- **Source**: pattern-matcher detected credential issues


Auto-detected patterns from memory analysis:

<!-- Auto-learned pattern: 2026-02-14 -->
- **Pattern**: Danish 'sidste 10%' workflow pattern detected
- **Section**: workflows
- **Source**: /root/.openclaw/workspace/memory/2026-02-13.md
- **Regex**: `sidste.*10%`

