# DECISIONS.md - Active Decisions Affecting Behavior

> This file contains active decisions that shape how the agent operates.
> Update this file when making decisions that affect workflow, preferences, or behavior.

## Decision Log

### 2026-02-12: Model Routing Strategy
**Decision:** Use Sonnet 4.5 as default, Kimi for background, Opus on-demand

**Rationale:** 
- Sonnet provides good quality at 5-10x cheaper than Opus
- Kimi ($0.45/$2.25 per M) handles routine work
- Opus ($15/$75 per M) reserved for heavy reasoning only

**Impact:** 
- Main session: Sonnet (default) → Kimi (fallback) → Opus (on-demand via `/model`)
- Subagents: Kimi K2.5 for cheap background work
- Use `/model Opus` explicitly when heavy reasoning needed

### 2026-02-12: Agent Fleet Structure
**Decision:** Six specialized agents with specific spawn permissions

**Agents:**
| Agent | Model | Purpose | Can Spawn |
|-------|-------|---------|-----------|
| main | Sonnet 4.5 | General purpose | All |
| monitor | Kimi K2.5 | Lightweight checks | No |
| researcher | Kimi K2.5 | Web research | No |
| communicator | Opus 4.6 | Professional writing | No |
| orchestrator | Sonnet 4.5 | CLI/tool management | monitor, researcher |
| coordinator | Opus 4.6 | Complex planning | monitor, researcher, communicator, orchestrator |

**Rationale:** Cost-effective specialization - cheap agents for simple tasks, expensive for critical

### 2026-02-12: External Skills Security
**Decision:** Never use `npx skills add` from community repo

**Workflow:**
1. Create skills in `workspace/skills/` (self-made)
2. Git-track all skills
3. If external skill needed: `git clone` specific author repo
4. Scan with `git-security/scripts/scan.sh`
5. Manual review before installation

**Rationale:** Community repo compromised (Feb 2026) - 100+ malicious skills using namespace squatting

### 2026-02-12: Heartbeat Strategy
**Decision:** Heartbeat uses Kimi K2.5 with rotating checks, not cron for batching

**Pattern:**
- Uses heartbeat for: Multiple checks that can batch together
- Uses cron for: Exact timing, one-shot reminders, isolated tasks

**Rationale:** Heartbeat provides conversational context; cron provides precision

### 2026-02-12: Memory Structure
**Decision:** Daily files + curated MEMORY.md + skills notes

**Structure:**
- `memory/YYYY-MM-DD.md` - Raw daily logs
- `MEMORY.md` - Curated long-term (main sessions only)
- `AGENTS.md` - Agent behavior rules
- `USER.md` - Human profile
- Skills/TOOLS.md - Tool-specific notes

**Rationale:** Raw logs for debugging, curated for continuity, skills for tool docs

### 2026-02-12: Communication Style
**Decision:** Danish, casual/direct, no filler words

**Preferences:**
- Language: Dansk (casual)
- Channel: WhatsApp primary
- Style: Direct, precise, value-focused
- No: "Great question!" / "I'd be happy to help!" fluff
- Yes: Actions over words

**Rationale:** Matches user's preference for efficiency and directness

## How to Add Decisions

When a pattern emerges or a choice affects behavior:

1. **Describe the decision** - What was decided?
2. **Explain rationale** - Why this choice?
3. **Document impact** - How does it change behavior?
4. **Update this file** - Don't just remember, write it down

## Decision Review

**Frequency:** Review monthly during heartbeat maintenance  
**Process:** Remove outdated decisions, update changed ones, add new patterns

## Active vs Archived

- **Active:** Currently affecting behavior
- **Outdated:** No longer relevant - move to `memory/decisions/YYYY-MM.md`

---

*Update this file whenever making decisions that shape how the agent operates.*
