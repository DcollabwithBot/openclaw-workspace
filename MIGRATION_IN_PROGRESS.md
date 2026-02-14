# Migration In Progress - 11 → 4 Agents + Skills

**Started:** 2026-02-14 15:40 UTC  
**Budget limit:** $50/måned ($1.67/dag)  
**Status:** P0 kritiske fixes i gang

---

## P0 - KRITISKE FIXES (NU)

### 1. Budget Limits
**Action:** Set provider budget limits  
**Status:** ⚠️ MANUAL - Danny skal selv gøre dette

**Anthropic Console:**
- URL: https://console.anthropic.com/settings/limits
- Monthly limit: $50
- Alerts: 50%, 80%

**OpenAI Console:**
- URL: https://platform.openai.com/settings/organization/billing/limits
- Monthly limit: $50
- Alerts: 50%, 80%

**Kan ikke automatiseres** - kræver login til dashboards.

---

### 2. Reducer James' Tools
**Action:** Remove exec, write, edit from main agent  
**Status:** ✅ DONE (commit 28bac30)

**Changes:**
- James tools: read, memory, sessions (coordinator kun)
- Removed: exec, write, edit, group:fs

---

### 3. Fix Communicator Fallback
**Action:** Add cross-provider fallback efter Opus  
**Status:** ✅ DONE (commit 28bac30)

**Changes:**
- Communicator fallback: Kimi (OpenRouter + NVIDIA)
- No longer Sonnet same-provider

---

## P1 - SKILLS (DENNE UGE)

### Skills to Create:
1. ✅ Security skill (Bent's expertise) - commit 1327e9f
   - security-scan.sh (hardcoded secrets, permissions, dangerous patterns)
   - check-credentials.sh (rotation tracking)
2. 🔄 Vibe-check skill (code quality) - IN PROGRESS
3. Completeness skill (last 10%)
4. Research skill (web queries)
5. Instagram skill (content helper)

**Status:** 1/5 complete

---

## P2 - AGENT SIMPLIFICATION (NÆSTE UGE)

Remove 7 agents, keep 4:
- Keep: James, Rene, Rikke, Anders
- Remove: Bent, Mette, Karl, Karen, Peter, Christian, Morten

**Status:** Pending skills creation

---

*Danny approved: "går bare i gang med arbejdet" - 2026-02-14 15:40*
