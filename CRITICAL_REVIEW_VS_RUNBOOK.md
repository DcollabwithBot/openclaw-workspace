# Critical Review: Vores Setup vs OpenClaw Runbook

**Dato:** 2026-02-14 15:35  
**Formål:** Kritisk sammenligning af vores nuværende setup mod community best practices

---

## TL;DR - Hvad gør vi forkert?

| Problem | Vi gør | Runbook anbefaler | Impact |
|---------|--------|-------------------|--------|
| **Over-engineering** | 11 agenter til 1 person | 4-5 agents max, resten skills | Token waste, kompleksitet |
| **Expensive defaults** | Sonnet som default overalt | Cheap defaults, spawn expensive når nødvendigt | Cost, rate limits |
| **Coordinator bloat** | James har exec/write/edit | Coordinator = sessions only, spawn workers | Security risk |
| **Heartbeat complexity** | Mange separate checks | Single rotating heartbeat | Token overhead |
| **Skills security** | Bruger community skills | Build your own first | Security risk ⚠️ |
| **Cross-provider fallback** | Mest Anthropic-only | ALTID cross-provider | Single point of failure |

**Bottom line:** Vi har bygget det flashy setup, ikke det boring reliable setup.

---

## 1. Agent Architecture - Vi har for mange

### Vores setup (11 agenter):
```
main, orchestrator, coordinator, researcher, communicator,
monitor, verifier, reviewer, security, complexity-guardian, webmon
```

**Overlappende ansvar:**
- Coordinator vs Orchestrator - begge planlægger
- Verifier vs Reviewer - begge verificerer
- Monitor vs Webmon - begge overvåger

### Runbook mønster:
```
1 coordinator (cheap, spawner)
+ 3-4 workers (expensive, scoped)
+ skills (ikke agenter)
```

**Runbook quote:**
> "The most common mistake is treating OpenClaw like a single super-intelligent chatbot that should handle everything at once."

**Vi gør det modsatte:** 11 super-intelligente bots der overlapper!

---

## 2. Model Routing - Dyre defaults overalt

### Vores defaults:
```json
"defaults": {
  "model": {
    "primary": "anthropic/claude-sonnet-4-5"
  }
}
```

**Problem:** Alle agenter bruger Sonnet som default. Det er dyrt!

### Runbook anbefaling:
```json
"defaults": {
  "model": {
    "primary": "anthropic/claude-sonnet-4-5",  // OK for main
    "fallbacks": [
      "kimi-coding/k2p5",                      // Cross-provider!
      "synthetic/hf:zai-org/GLM-4.7",
      "openrouter/google/gemini-3-flash-preview"
    ]
  }
}
```

**Men:** Monitor, heartbeat, background tasks skal bruge cheap models!

### Runbook quote:
> "Heartbeats run often but do simple checks. No reason to burn premium models on background plumbing. I've seen tens of thousands of heartbeat tokens cost fractions of a cent on cheap models."

**Vi bruge Kimi (OK) men kun som fallback - vi burde bruge det primært!**

---

## 3. Coordinator Role - James gør for meget

### Vores James (main):
```json
"tools": {
  "allow": [
    "read", "edit", "write", "exec",
    "group:fs", "group:memory",
    "sessions_spawn", "sessions_list"
  ]
}
```

**Problem:** James kan køre kode, skrive filer, execute commands. Det er FORKERT!

### Runbook anbefaling:
```json
"main": {
  "tools": {
    "allow": ["sessions_spawn", "sessions_list", "read", "group:memory"]
  }
}
```

**Coordinator skal IKKE implementere - skal delegere!**

### Runbook quote:
> "What clicked for me was that the main model should be a coordinator, not a worker."

**Vi har gjort James til både coordinator OG worker. Det er derfor jeg nogle gange koder selv i stedet for at spawne Rene!**

---

## 4. Heartbeat - For komplekst

### Vores HEARTBEAT.md:
- 7 separate checks (git_status, proactive_scan, memory_maintenance, ttl_cleanup, cost_tracking, todoist_review, followup)
- Hver har sin egen logik
- State tracking spredt ud

### Runbook anbefaling:
```
Single rotating heartbeat:
1. Read state file
2. Run most overdue check
3. Update timestamp
4. HEARTBEAT_OK if nothing found
```

**Fordel:** Simplere, færre tokens, nemmere at debug.

**Vi har:** Kompleks logik der køres hver gang.

---

## 5. Skills vs Agents - Vores største fejl

### Hvad vi har som agenter der burde være skills:

| Agent | Bør være | Hvorfor |
|-------|----------|---------|
| Monitor (Karl) | Skill | Simple checks, ingen reasoning |
| Webmon (Morten) | Skill | HTTP check script |
| Complexity Guardian (Karen) | AGENTS.md rule | Ikke engang nødvendig |
| Verifier (Peter) | Skill/workflow | Verification != separat agent |

### Runbook quote:
> "I've had better luck building my own [skills] and treating community skills as inspiration rather than drop-ins."

**Vi har IKKE bygget egne skills endnu!** Vi har brugt community skills ukritisk.

---

## 6. Security - Vi mangler baselines

### Vores setup:
✅ Tool policies per agent (god!)  
✅ Prompt injection defense dokumenteret  
❌ Ingen cost controls på provider level  
❌ Ingen credential rotation tracking (vi har dokumenteret det, men ikke implementeret)  
❌ Ingen hard limits på API usage  

### Runbook anbefaler:

**Provider Dashboard Limits:**
```
Anthropic: $500/dag med alerts ved 50%, 80%
OpenAI: $500/dag med alerts ved 50%, 80%
```

**Vi har IKKE sat dette op!** Vi kan brænde $1000+ uden at få alert.

### Runbook quote:
> "I've seen people hit $200+ in a weekend by leaving things uncapped."

**Danny vil ikke være den person!**

---

## 7. Cross-Provider Fallbacks - Kritisk manglende

### Vores fallback chains:
```json
"primary": "anthropic/claude-sonnet-4-5",
"fallbacks": [
  "openrouter/moonshotai/kimi-k2.5",  // ✅ Cross-provider
  "nvidia/moonshotai/kimi-k2.5"        // ✅ Cross-provider
]
```

**Det er faktisk OK!** Men vi mangler det for alle agenter.

**Nogle agenter har kun Anthropic:**
```json
"communicator": {
  "primary": "anthropic/claude-opus-4-6",
  "fallbacks": [
    "anthropic/claude-sonnet-4-5",  // ❌ Samme provider!
    "openrouter/moonshotai/kimi-k2.5"
  ]
}
```

### Runbook critical warning:
> "Claude subscriptions: Rate limits reset every 5 hours or weekly. When you hit the limit, ALL Claude models are unavailable (Opus, Sonnet, Haiku)."

**Hvis vi rammer Claude limit, mister vi både Opus OG Sonnet!**

---

## 8. Cost Tracking - Mangler implementation

### Vores dokumentation:
- ✅ `memory/costs/2026-02.csv` eksisterer
- ✅ Cost tracking i HEARTBEAT.md dokumenteret
- ❌ Ingen aktiv cost aggregation
- ❌ Ingen budget alerts

### Runbook:
> "I use two coding subscriptions at about $20 each. On top of that, API usage runs about $5-$10 per month split between OpenRouter and OpenAI. Most months I land around $45-$50 total."

**Vores estimat:** $17-84/måned (hvis vi fortsætter nuværende setup)

**Med simplificering:** Kunne være $20-40/måned

---

## 9. Token-Heavy Patterns Vi Bruger

### Spawning overhead:
**Typisk flow:**
```
Danny → James → Anders → Rene → Bent = 4 agents
Token overhead: ~15k per chain
```

**Hvis Bent var skill:**
```
Danny → James → Rene (inkl. security skill) = 2 agents
Token overhead: ~8k per chain
Besparelse: ~47%
```

### Memory search:
**Vi bruger:**
```
memory_search + memory_get (semantic + retrieval)
```

**Det er OK!** Men vi har ikke optimeret query patterns.

### Context bloat:
**Vores workspace filer:**
```
AGENTS.md: 14k tokens
SOUL.md: 1k tokens
USER.md: 3k tokens
TOOLS.md: 1k tokens
HEARTBEAT.md: 2k tokens
MEMORY.md: 5k tokens
```

**Total context load ved session start: ~26k tokens**

**Runbook recommendation:** Keep context under 10k, use memory_search for detail.

---

## 10. Hvad vi gør GODT (bevare)

✅ **Tool policies per agent** - Vi har implementeret dette korrekt  
✅ **Git tracking** - Alt er versioneret  
✅ **Memory structure** - Daily files + MEMORY.md index  
✅ **Cross-provider fallbacks** - Vi har Kimi som backup  
✅ **Prompt injection defense** - Dokumenteret i AGENTS.md  
✅ **Security mindset** - Bent's security reviews  

**Disse ting skal vi IKKE ændre - de er på linje med runbook.**

---

## 11. Hvad skal ændres FØRST (prioriteret)

### P0 (Kritisk - gør i dag):
1. **Set provider budget limits**
   - Anthropic dashboard: $500/dag, alerts 50%/80%
   - OpenAI dashboard: $500/dag, alerts 50%/80%
   - **Impact:** Undgå $1000 surprise bills

2. **Reducer main agent tools**
   - James: KUN sessions + read + memory
   - INGEN exec/write/edit
   - **Impact:** Tvinger proper delegation

3. **Fix communicator fallback**
   - Tilføj cross-provider efter Opus
   - **Impact:** Ingen deadlock ved Claude limit

### P1 (Høj - gør denne uge):
4. **Simplificer til 4-5 agenter**
   - Keep: James, Rene, Rikke, Anders
   - Convert to skills: Bent, Karl, Morten, Karen
   - Merge: Peter → Rene workflow, Christian → Anders workflow
   - **Impact:** ~50% token reduction

5. **Cheap model defaults**
   - Heartbeat: Kimi NVIDIA (gratis)
   - Background tasks: Kimi/Gemini nano
   - **Impact:** ~70% heartbeat cost reduction

6. **Single rotating heartbeat**
   - Merge 7 checks → 1 rotating pattern
   - **Impact:** Simplere, fewer tokens

### P2 (Medium - gør næste uge):
7. **Build security skill**
   - Bent's expertise → `/workspace/skills/security/`
   - Callable fra Rene/Anders
   - **Impact:** Reusable, cheaper

8. **Optimize context loading**
   - Reducer workspace file sizes
   - Use memory_search mere
   - **Impact:** Faster session starts

9. **Cost tracking automation**
   - Active daily aggregation
   - Weekly reports til Danny
   - **Impact:** Synlighed

---

## 12. Migration Plan

### Fase 1: Safety (i dag)
```
[ ] Set Anthropic budget limit ($500/dag)
[ ] Set OpenAI budget limit ($500/dag)
[ ] Enable email alerts (50%, 80%)
[ ] Document current monthly spend
```

### Fase 2: Core Fixes (i dag)
```
[ ] Reducer James tools (kun sessions + read + memory)
[ ] Fix communicator cross-provider fallback
[ ] Test spawning workflow efter changes
```

### Fase 3: Simplification (denne uge)
```
[ ] Design 4 core agents (James, Rene, Rikke, Anders)
[ ] Convert Bent → security skill
[ ] Convert Karl → monitoring skill
[ ] Merge Peter → Rene workflow
[ ] Merge Christian → Anders workflow
[ ] Delete: Karen, Morten
```

### Fase 4: Optimization (næste uge)
```
[ ] Single rotating heartbeat
[ ] Cheap model defaults for background
[ ] Context size optimization
[ ] Cost tracking automation
```

---

## 13. Lessons Learned fra Runbook

### Vigtigste takeaways:

**1. Boring > Flashy**
> "OpenClaw gets useful when you stop expecting magic and start expecting a tool that needs tuning."

**Vi har jagtet flashy (11 agenter, alle features) i stedet for boring reliable.**

**2. Coordinator ≠ Worker**
> "What clicked for me was that the main model should be a coordinator, not a worker."

**James skal spawne, ikke implementere.**

**3. Cheap defaults, expensive on-demand**
> "Strong models work best when they're scoped. Pin them to specific agents and call them when you actually need them."

**Vi bruger Sonnet everywhere - det er spild.**

**4. Cross-provider always**
> "When you hit the [Claude] limit, ALL Claude models are unavailable."

**Single provider = single point of failure.**

**5. Build skills, don't collect agents**
> "I've had better luck building my own [skills]."

**Vi har samlet agenter som Pokemon. Dårlig strategi.**

---

## 14. Konkrete Token Besparelser

### Nuværende monthly estimate:
```
Spawn overhead: 15k tokens/chain × 50 chains/md = 750k tokens
Heartbeat: 2k tokens/check × 30 days × 7 checks = 420k tokens
Context loading: 26k tokens × 100 sessions = 2.6M tokens
Agent coordination: 500k tokens
---
Total: ~4.3M tokens/md
Cost estimate: $60-100/md
```

### Efter optimization:
```
Spawn overhead: 8k tokens/chain × 50 chains/md = 400k tokens (-47%)
Heartbeat: 1k tokens/check × 30 days = 30k tokens (-93%)
Context loading: 10k tokens × 100 sessions = 1M tokens (-62%)
Agent coordination: 200k tokens (-60%)
---
Total: ~1.6M tokens/md (-63%)
Cost estimate: $20-40/md (-50-60%)
```

**ROI:** ~$40/md savings = $480/år

---

## 15. Spørgsmål til Danny

**Budget limits (kritisk):**
1. Skal jeg sætte $500/dag limits på Anthropic + OpenAI dashboards nu?
2. Eller vil du have lavere limits? ($100/dag? $200/dag?)

**Agent simplification:**
1. Er du OK med at gå fra 11 → 4 agenter denne uge?
2. Eller vil du teste gradvist over 2-3 uger?

**Skills:**
1. Skal jeg bygge security skill som det første? (Bent's expertise)
2. Eller monitoring skill først? (Karl's job)

**Timing:**
1. Skal vi vente på Anders' (coordinator) komplette analyse?
2. Eller starter vi safety fixes (budget limits) nu?

---

## 16. Final Vurdering

**Vores setup score: 6/10**

**Hvad vi gør godt:**
- Git tracking ✅
- Memory structure ✅
- Tool policies ✅
- Security mindset ✅

**Hvad vi gør dårligt:**
- For mange agenter (11 vs 4) ❌
- Dyre defaults (Sonnet everywhere) ❌
- Coordinator gør for meget (James har exec) ❌
- Ingen budget limits (kan brænde $1000) ❌
- Kompleks heartbeat (7 checks) ❌

**Runbook författare ville sige:**
> "You've built the YouTube thumbnail setup, not the Tuesday afternoon setup."

**Det er sandt. Vi skal gå fra flashy til boring reliable.**

---

*Klar til at implementere ændringer når du godkender prioriteterne.*
