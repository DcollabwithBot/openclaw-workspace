# Anti-Vibe-Slop Plan: Context Optimization

**Date:** 2026-02-14
**Goal:** Eliminate token waste, prevent future bloat
**Target:** <10k tokens context load, 80% automation without LLM

---

## Current State Analysis

### Context Bloat (Token Counts)
| File | Current | Target | Reduction |
|------|---------|--------|-----------|
| AGENTS.md | ~14k | <5k | 64% |
| MEMORY.md | ~5k | <3k | 40% |
| SOUL.md | ~1k | <1k | 0% (OK) |
| USER.md | ~3k | <2k | 33% |
| **TOTAL** | **~23k** | **<11k** | **52%** |

### Problems Identified
1. AGENTS.md loads everything (should be indexed)
2. MEMORY.md not using search (full load)
3. No context pruning strategy
4. Heartbeat underutilized (could do more)
5. Skills vs Agents not optimally balanced

---

## Phase 1: File Structure Reorganization (Week 1)

### 1.1 AGENTS.md → Split into Index + Sections
**Current:** Single 14k file loaded every session
**Target:** Index file (1k) + load only relevant section

**New Structure:**
```
AGENTS.md (index - 1k tokens)
├── agents/james.md (2k)
├── agents/rene.md (2k)
├── agents/rikke.md (1k)
├── agents/anders.md (2k)
└── agents/spawn-matrix.md (1k)
```

**Implementation:**
- James (main) only loads AGENTS.md index
- Spawns agent → that agent loads its own file
- Saves 10k+ tokens per session

### 1.2 MEMORY.md → True Index
**Current:** 5k curated memories
**Target:** Index (500 tokens) + use memory_search

**New Structure:**
```
MEMORY.md (index only)
- Links to: memory/people/danny.md
- Links to: memory/projects/tjekbolig-ai.md
- Links to: memory/decisions/2026-02.md
- etc.
```

---

## Phase 2: Context Loading Optimization (Week 1-2)

### 2.1 Lazy Loading Strategy
**Rule:** Never load full files, only what's needed

**Implementation:**
```
Instead of: read("AGENTS.md")
Do: memory_search("agent spawn permissions")
Then: read("agents/spawn-matrix.md") (only 1k)
```

### 2.2 Session-Based Context Pruning
**Current:** Load everything at start
**Target:** Load incrementally as needed

**Rules:**
1. Start session: Load SOUL.md + USER.md only (~4k)
2. When spawning: Load relevant agent file (~2k)
3. When searching memory: Use memory_search (~500 tokens)
4. Total per action: <7k instead of 23k

---

## Phase 3: Automation Without LLM (Week 2)

### 3.1 Move to Heartbeat/Cron
**Current:** LLM-based checks
**Target:** Bash/Python scripts

| Task | Current | New | Savings |
|------|---------|-----|---------|
| Secret detection | Rene (LLM) | Regex script | $0.10 → $0 |
| Memory summary | Rene (LLM) | Kimi (cheap) | $0.05 → $0.01 |
| Git backup | Manual/LLM | Cron script | $0 → $0 |
| Cost tracking | Manual | CSV script | $0 → $0 |

### 3.2 New Heartbeat Checks
```
1. Secret scan (regex, $0)
2. Context size check (warn if >10k)
3. Token usage tracking (CSV)
4. File size monitoring
```

---

## Phase 4: Prevention Rules (Ongoing)

### 4.1 File Size Limits
**Hard limits:**
- Any .md file: Max 5k tokens
- Any skill script: Max 200 lines
- AGENTS.md sections: Max 2k each

**Enforcement:**
- Pre-commit hook: Reject if file >5k tokens
- Heartbeat: Daily check, alert if exceeded
- CI/CD: Block commits with large files

### 4.2 Context Budget per Session
**Rule:** James must track and report:
```
"Context load: 7.2k/10k tokens (72%)"
```

**Alert at:**
- 80%: Warning
- 90%: Force /compact
- 100%: Refuse new tasks until compact

### 4.3 Documentation Standards
**Rule:** If you can't explain it in 100 words, split it

**Templates:**
- AGENTS.md section: Bullet points, not paragraphs
- Skill docs: Usage first, theory optional
- Memory files: YYYY-MM-DD format only

---

## Phase 5: Verification & Monitoring

### 5.1 Weekly Audit (Heartbeat)
```bash
# Every Monday 09:00
1. Measure all .md file sizes
2. Calculate avg context load
3. Report: "Context efficiency: X%"
4. Flag files >5k tokens
```

### 5.2 Monthly Review
- Review MEMORY.md (remove outdated)
- Archive old memory files (>30 days)
- Check for bloat creep
- Update AGENTS.md index

---

## Implementation Timeline

### Week 1: Structure
- [ ] Split AGENTS.md into sections
- [ ] Convert MEMORY.md to index
- [ ] Update SOUL.md with context rules
- [ ] Test new loading strategy

### Week 2: Automation
- [ ] Move secret detection to bash script
- [ ] Implement context budget tracking
- [ ] Setup file size monitoring
- [ ] Create pre-commit hooks

### Week 3: Optimization
- [ ] Prune existing files >5k
- [ ] Archive old memory files
- [ ] Optimize skill scripts
- [ ] Document new standards

### Week 4: Verification
- [ ] Measure context load improvement
- [ ] Verify cost savings
- [ ] Test all workflows
- [ ] Update AGENTS.md with lessons

---

## Prevention: Never Again

### Rule 1: Context Budget
**"If it doesn't fit in 10k, it doesn't ship"**
- James tracks context per session
- Hard limit at 10k tokens
- Force /compact at 8k

### Rule 2: File Size Limits
**"5k tokens max per file"**
- Enforced by pre-commit hook
- Heartbeat daily check
- CI/CD blocking

### Rule 3: Lazy Loading
**"Load only what's needed, when needed"**
- Index files, not monoliths
- memory_search > read full file
- Agent-specific files, not shared

### Rule 4: Automation ≠ LLM
**"If bash can do it, bash should do it"**
- Skills for deterministic tasks
- Agents for reasoning only
- Heartbeat for periodic checks

---

## Success Metrics

| Metric | Before | After | Target |
|--------|--------|-------|--------|
| Context load | 23k tokens | TBD | <11k (52% reduction) |
| File count >5k | 3 files | TBD | 0 files |
| LLM-based automation | 80% | TBD | <20% |
| Monthly cost | $31-100 | TBD | $13-40 |
| Session startup | 5s | TBD | <2s |

---

## References

- OpenClaw Runbook: "Keep context under 10k"
- Reddit Post 1: "Specific instructions in small files"
- Reddit Post 2: "/compact before tasks"
- Anders Report: "58% token reduction possible"

---

*This plan prevents the "vibe-slop" trap of ever-growing context.*
