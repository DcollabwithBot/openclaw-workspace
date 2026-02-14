# Rate Limit & Agent Design Analysis

**Dato:** 2026-02-14 15:18
**Trigger:** Danny vil undgå at main (James) går i stå ved rate limit + retænke agent design

---

## Problem 1: Main Rate-Limited = Ingen Respons

### Nuværende situation:
- James (main) bruger Sonnet 4.5 primary
- Når Sonnet rate-limiter → fallback til Kimi
- Men Danny accepterer 3-5 sek latency på Kimi
- **Problemet:** Hvad hvis James går helt i stå? Ingen respons = dårlig UX

### Mulige løsninger:

#### Løsning A: Failover Agent (Anbefalet)
**Koncept:** Backup main agent der aktiveres når James er blokeret

**Implementation:**
```json
{
  "id": "main-backup",
  "name": "James (Backup)",
  "model": {
    "primary": "nvidia/moonshotai/kimi-k2.5"
  },
  "triggers": {
    "activateWhen": "main rate-limited OR main timeout >30s"
  }
}
```

**Fordele:**
- Danny får altid respons (fra James eller James Backup)
- Transparent: "James Backup her - primær agent rate-limited"
- Kontinuitet i samtale

**Ulemper:**
- Ekstra agent (12 i stedet for 11)
- Kompleksitet i routing

---

#### Løsning B: Model Pooling (Simplere)
**Koncept:** James har flere model-profiler og roterer mellem dem

**Implementation:**
- Sonnet via Anthropic (primær)
- Sonnet via AWS Bedrock (sekundær)
- Kimi via NVIDIA (tertiær)

**Fordele:**
- Ingen ekstra agent
- Flere rate limit pools
- Simpel fallback chain

**Ulemper:**
- Kræver AWS Bedrock setup
- Koster mere

---

#### Løsning C: Rate Limit Prevention (Proaktiv)
**Koncept:** Heartbeat overvåger Sonnet usage og advarer før limit

**Implementation:**
1. Heartbeat checker Anthropic rate limit status hver 6h
2. Hvis >80% af limit → switch til Kimi proaktivt
3. Hvis 100% → alert Danny "James er nede i 30 min"

**Fordele:**
- Ingen overraskelser
- Danny ved hvornår James er utilgængelig
- Kan planlægge samtaler omkring det

**Ulemper:**
- Danny får ikke altid høj kvalitet når han vil

---

### Anbefaling: Kombination B + C
1. **Model pooling:** Tilføj AWS Bedrock Sonnet som sekundær (flere rate limit pools)
2. **Prevention:** Heartbeat advarer ved >80% usage
3. **Fallback:** Kimi backup når alle Sonnet pools er tomme

**Impact:**
- Uptime: 99%+ (kun nede hvis ALLE pools tomme)
- Cost: +20% (AWS Bedrock lidt dyrere)
- Brugeroplevelse: Transparent og pålidelig

---

## Problem 2: Agent Design - "Hvem gør hvad?"

### Danny's frustrationer:
> "Når jeg siger fix Vibe-slob vil jeg vide præcis hvem der gør hvad"

**Nuværende problem:**
- 11 agenter med overlappende ansvar
- Ikke klart hvem der "ejer" specifikke typer opgaver
- Danny skal huske hvem der er hvem

### Current Agent Fleet (11 agenter):
| Agent | Navn | Rolle | Hvornår brugt? |
|-------|------|-------|----------------|
| main | James | Coordinator/Chat | Altid (dig) |
| orchestrator | Rene | Implementation | Code/deploy tasks |
| coordinator | Anders | Planning | Complex multi-step |
| researcher | Mette | Research | Web search/analysis |
| communicator | Rikke | Writing | Professional tekster |
| monitor | Karl | Status check | Heartbeat/monitoring |
| verifier | Peter | QA | Verificer output |
| reviewer | Christian | Review | Code/doc review |
| security | Bent | Security | Audit/hardening |
| complexity-guardian | Karen | Anti-complexity | Simplificer |
| webmon | Morten | Uptime | (Dormant) |

**Problem:**
- Reviewer vs Verifier: Hvad er forskellen?
- Coordinator vs Orchestrator: Overlappende?
- Monitor vs Webmon: Forvirrende

---

## Redesign Forslag: 4 Core Agents + Skills

### Koncept: Mindre agenter, mere klarhed

**4 Core Agents (Personlighedsdrevne):**

1. **James (Main)** - Dig (Coordinator/Interface)
   - Primært Sonnet
   - Spawner andre agents
   - Tools: sessions, memory, read

2. **Rene (Builder)** - Implementation & Deploy
   - Alt kode, deploy, infrastructure
   - Tools: exec, write, edit, fs
   - Spawner Bent (security) for review

3. **Anders (Analyst)** - Research & Planning  
   - Web research, analysis, rapporter
   - Tools: read, web, memory
   - Spawner Christian (reviewer) for QA

4. **Bent (Guardian)** - Security & Quality
   - Security audit, code review, verification
   - Tools: read, exec (read-only analysis)
   - Spawnes af Rene/Anders for checks

**Skills (ikke agenter):**
- **Monitoring** → Heartbeat + skill script
- **Communication** → Template + Rene/Anders eksekverer
- **Complexity** → Guideline i AGENTS.md, ikke separat agent
- **Webmon** → Skill script til uptime check

---

### Fordele ved 4-agent model:

**Klarhed:**
```
Danny: "Fix Vibe-slob backend"
→ James spawner Rene (builder)
→ Rene implementerer
→ Rene spawner Bent (security review)
→ Bent godkender
→ Rene deployer
```

**Simplicitet:**
- Færre navne at huske
- Klare roller: Build, Analyze, Secure
- Mindre token overhead (færre spawn calls)

**Fleksibilitet:**
- Rene kan både kode OG kommunikere
- Anders kan både researche OG planlægge
- Bent kan både reviewe OG auditere

---

### Migration Plan (hvis godkendt):

**Fase 1: Konsolidering**
- ✅ Keep: James, Rene, Anders, Bent
- ❌ Fjern: Karl, Mette, Rikke, Peter, Christian, Karen, Morten
- 🔄 Convert: Deres funktioner → skills eller workflows

**Fase 2: Skill Migration**
- Monitoring → `skills/monitoring/` (heartbeat script)
- Communication → Templates i `skills/communication/`
- Webmon → `skills/webmon/uptime-check.sh`

**Fase 3: Workflow Documentation**
- Document i AGENTS.md: "Når Danny siger X → spawn Y"
- Klare decision trees

**Fase 4: Test**
- Test typiske workflows med 4 agents
- Verificer at intet går tabt

---

## Spørgsmål til Danny:

1. **Rate limit:** Vil du have AWS Bedrock Sonnet som backup pool? (cost +20%)
2. **Agent design:** Vil du have 4 agents i stedet for 11?
3. **Skills vs Agents:** Er du okay med at monitoring/communication bliver skills?
4. **Migration timing:** Skal vi lave det nu, eller test først i nogle dage?

---

## Token Impact Estimate

**Nuværende (11 agents):**
- Typisk spawn chain: James → Anders → Rene → Bent = 4 agents
- Token overhead: ~15k per chain

**Foreslået (4 agents):**
- Typisk spawn chain: James → Rene → Bent = 3 agents
- Token overhead: ~10k per chain
- **Besparelse: ~30%**

**Skills overhead:**
- Skill execution: ~2k tokens
- Agent spawn: ~5k tokens
- **Besparelse: ~60% per simple task**

---

*Afventer Danny's feedback før implementation*
