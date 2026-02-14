# Agent Learning System
**Purpose:** Automatic adaptation and improvement over time
**Updated:** 2026-02-14

---

## Current Learning (Passive)

**What works now:**
- Agents read files each session (SOUL.md, USER.md, MEMORY.md)
- Daily memory files capture events
- Memory search finds relevant context
- But: NO structured learning loop

**What's missing:**
- Automated pattern recognition
- Cross-agent knowledge sharing
- Feedback integration
- Performance tracking

---

## Proposed Learning System

### 1. Daily Learning Loop (Heartbeat)

**Every 24h (via Heartbeat):**

```bash
# Automated by cron/heartbeat - NO LLM cost

1. Review yesterday's memory/YYYY-MM-DD.md
2. Extract patterns:
   - What worked well? → Update best practices
   - What failed? → Update failure prevention
   - New preferences? → Update USER.md
   - Repeated mistakes? → Flag for attention

3. Update agent files:
   - If James made mistakes → Update SYSTEM_PROMPT.md
   - If Rene had issues → Update agents/rene.md
   - If workflow broke → Update AGENTS.md

4. Cross-agent sync:
   - If Rene learned something → Notify Anders
   - If Anders found better way → Share with Rene
   - Common knowledge → Update shared skills/
```

### 2. Feedback Integration

**After every task completion:**

Danny rates/says: "Good" / "Not quite" / "Wrong"

**Automatic actions:**
- "Good" → Log to "what works" memory
- "Not quite" → Update instructions, try again
- "Wrong" → Create failure note, update prevention rules

**Implementation:**
```markdown
# In memory/YYYY-MM-DD.md auto-appended:
## [HH:MM] Task Feedback
- Task: [description]
- Agent: [name]
- Feedback: [good/not quite/wrong]
- Learning: [what to change]
- Updated: [which file was changed]
```

### 3. Agent-to-Agent Learning

**Weekly sync (every Monday):**

```
Each agent shares:
1. "This week I learned..."
2. "This pattern worked..."
3. "Avoid this mistake..."
4. "New preference from Danny..."

Shared in: memory/agent-learning/week-06.md
All agents read this at week start
```

### 4. Performance Tracking

**Metrics tracked automatically:**

| Metric | Track | Action if Bad |
|--------|-------|---------------|
| Task completion rate | % completed vs promised | Review promises |
| Danny satisfaction | Feedback scores | Update approach |
| Cost per task | $ spent / task | Optimize model choice |
| Time to complete | Actual vs estimated | Better estimation |
| Context efficiency | Tokens used / task | Optimize loading |

**Weekly report:**
```
Week 06 Performance:
- Tasks: 12 completed, 2 pending
- Success rate: 92%
- Avg cost: $0.45/task
- Danny feedback: 8 good, 1 not quite
- Issues: 2 (context bloat, slow response)

Recommendations:
1. Use Kimi more for research (save $0.30/task)
2. Load smaller context chunks
3. Set stricter time limits
```

### 5. Automated Improvement

**When patterns detected:**

```
Pattern: "Danny always asks for bullet lists"
Action: Update SOUL.md format preference

Pattern: "Rene timeout on complex deploys"
Action: Add progress updates, break into steps

Pattern: "Anders research too detailed"
Action: Add "summarize in 3 bullets" rule
```

**Implementation:**
- Kimi K2.5 analyzes patterns (cheap)
- Updates relevant files automatically
- Danny reviews changes (approval workflow)

---

## Implementation Timeline

### Week 1: Foundation
- [ ] Add "Learning Check" to HEARTBEAT.md
- [ ] Create memory/agent-learning/ folder
- [ ] Setup feedback logging

### Week 2: Tracking
- [ ] Implement performance metrics
- [ ] Create weekly report template
- [ ] Test agent-to-agent sync

### Week 3: Automation
- [ ] Automated pattern detection
- [ ] Auto-update low-risk files
- [ ] Danny approval for major changes

### Week 4: Polish
- [ ] Refine based on first month
- [ ] Document learnings
- [ ] Optimize for cost

---

## Key Principles

1. **Learning ≠ More Work for Danny**
   - Automated detection
   - Proactive updates
   - Danny only approves/changes

2. **Cross-Agent Knowledge**
   - If one learns, all learn
   - Shared best practices
   - No silos

3. **Continuous Improvement**
   - Small daily improvements
   - Weekly pattern recognition
   - Monthly major reviews

4. **Cost-Conscious**
   - Use Kimi for pattern detection
   - Batch learning (not real-time)
   - Focus on high-impact changes

---

## Example: Learning in Action

**Day 1:** Danny asks for bullet list → I provide it → "Good"

**Day 2:** Danny asks again for bullets → I provide → "Good"

**Day 3:** Pattern detected (2x bullets = preference)
→ Auto-update SOUL.md: "Format: Bullet lists preferred"

**Day 4:** I start using bullets proactively
→ Danny: "Perfect, you know me"

**Week 1 Review:**
- Pattern: Danny likes bullets
- Action: Added to SOUL.md
- Result: Faster responses, better fit

---

## Questions for Danny

1. Should I auto-update files or wait for approval?
2. How often? Daily learning vs weekly batch?
3. What level of change can I make without asking?
4. Should all agents learn from each other or keep separate?

---

*This system ensures we get better every day without Danny having to manually teach us.*
