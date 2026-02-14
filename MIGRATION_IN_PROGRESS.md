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

### Skills Created: ✅ ALL DONE
1. ✅ Security skill (commit 1327e9f) - Bent's expertise as bash
2. ✅ Vibe-check skill (commit 2b2c32b) - Code quality detector  
3. ✅ Completeness skill (commit e35e20f) - "Last 10%" guardian
4. ✅ Research skill (commit 4a02471) - Workflow documentation
5. ✅ Instagram skill (commit 4a02471) - Caption guidelines

**Status:** 5/5 complete ✅

**Total savings:** ~$0 per execution (no LLM usage for automated checks)
**Replaced agents:** Bent, Karl, Karen, Mette (functionality preserved as skills)

---

## P2 - AGENT SIMPLIFICATION (I GANG - 2026-02-14 16:22)

**Target:** 11 agenter → 4 core agents

### Agents Being Removed (7):
1. ❌ monitor (Karl) → heartbeat skill
2. ❌ researcher (Mette) → research skill
3. ❌ verifier (Peter) → Anders workflow
4. ❌ reviewer (Christian) → Anders workflow
5. ❌ security (Bent) → security skill
6. ❌ complexity-guardian (Karen) → vibe-check skill
7. ❌ webmon (Morten) → dormant/unused

### Agents Kept (4):
1. ✅ main (James) - Coordinator
2. ✅ orchestrator (Rene) - Builder
3. ✅ communicator (Rikke) - Writer
4. ✅ coordinator (Anders) - Analyst

**Status:** 🔄 IN PROGRESS
- Rene updating openclaw.json
- Spawn permissions being updated
- /compact workflow being added to AGENTS.md

---

*Danny approved: "går bare i gang med arbejdet" - 2026-02-14 15:40*
