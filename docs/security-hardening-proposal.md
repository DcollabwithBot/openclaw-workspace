# Security Hardening Proposal — OpenClaw på Proxmox

**Dato:** 2026-02-13  
**Udarbejdet af:** Coordinator-agent (subagent)  
**Status:** DRAFT — afventer Danny's review  

---

## Indholdsfortegnelse

1. [Executive Summary](#executive-summary)
2. [Nuværende Setup](#nuværende-setup)
3. [Identificerede Gaps & Risici](#identificerede-gaps--risici)
4. [Design-forslag](#design-forslag)
   - 4.1 Tool Policies per Agent
   - 4.2 Model Fallback Observability
   - 4.3 Worker→Verifier Pattern
5. [Konkrete Config-ændringer](#konkrete-config-ændringer)
6. [Implementeringsplan](#implementeringsplan)
7. [Risici & Trade-offs](#risici--trade-offs)
8. [Review-punkter til Danny](#review-punkter-til-danny)

---

## Executive Summary

Vi kører OpenClaw 2026.2.9 i en Proxmox container med 6 agents (main, monitor, researcher, communicator, orchestrator, coordinator). **Ingen af dem har tool-level restrictions** — alle agents har fuld adgang til exec, write, browser, nodes osv.

OpenClaw har **built-in support** for alt vi mangler:
- `agents.list[].tools.{profile, allow, deny}` — per-agent tool policies
- `tools.byProvider` — provider-specifik tool-begrænsning (relevant for fallback-modeller)
- `logging.level` + file logs — fallback-events logges allerede, men vi fanger dem ikke aktivt
- Hooks system — kan bruges til at trigge notifikationer ved fallback

**Anbefaling:** Implementér i 3 faser over ~1 uge. Ingen breaking changes, alt er additivt.

---

## Nuværende Setup

### Agent Fleet

| Agent | Model (Primary) | Fallbacks | Tool Restrictions | Spawning |
|-------|----------------|-----------|-------------------|----------|
| main | Sonnet 4.5 | Kimi K2.5 (OR), Kimi K2.5 (NVIDIA) | **Ingen** | Alle agents |
| monitor | Kimi K2.5 (OR) | Kimi K2.5 (NVIDIA) | **Ingen** | Ingen |
| researcher | Kimi K2.5 (OR) | Kimi K2.5 (NVIDIA), Sonnet 4.5 | **Ingen** | Ingen |
| communicator | Opus 4.6 | Sonnet 4.5, Kimi K2.5 | **Ingen** | Ingen |
| orchestrator | Sonnet 4.5 | Kimi K2.5 (OR), Kimi K2.5 (NVIDIA) | **Ingen** | monitor, researcher |
| coordinator | Opus 4.6 | Sonnet 4.5, Kimi K2.5 | **Ingen** | monitor, researcher, communicator, orchestrator |

### Nuværende Config (relevant dele)

```json
{
  "tools": {
    "web": { "search": { "enabled": true } }
  },
  "logging": {
    "redactSensitive": "tools"
  }
}
```

**Bemærk:** Ingen `tools.allow`, `tools.deny`, `tools.profile`, eller `agents.list[].tools` er konfigureret.

---

## Identificerede Gaps & Risici

### Gap 1: Ingen Tool Policies per Agent

**Risiko: HØJ**

- **monitor** agent (Kimi K2.5) har fuld exec/write/browser adgang — men bruges kun til lette checks
- **researcher** kan køre shell-kommandoer, slette filer, modificere config
- **communicator** (beregnet til tekst/kommunikation) kan tilgå browser, exec, nodes
- Hvis en fallback-model (Kimi) hallucinerer en destruktiv kommando, er der **ingen guardrails**
- Prompt injection via web_fetch indhold kan eskalere til exec hos enhver agent

**Angrebsscenario:** Researcher fetcher en ondsindet webside → prompt injection → `exec rm -rf /` → intet forhindrer det

### Gap 2: Ingen Fallback Observability

**Risiko: MEDIUM**

- OpenClaw logger fallback-events i gateway file logs (`/tmp/openclaw/openclaw-YYYY-MM-DD.log`)
- Men vi **overvåger dem ikke aktivt** — vi opdager først problemer når noget "føles anderledes"
- Kimi K2.5 har andre capabilities end Sonnet/Opus (svagere tool-brug, anderledes reasoning)
- Når en fallback sker stille, mister vi:
  - Kvalitetsgaranti (Sonnet → Kimi er et signifikant capability-drop)
  - Audit trail for sikkerhedskritiske beslutninger
  - Mulighed for at reagere (pause agent, notificér bruger)

**Scenarie:** Anthropic rate-limiter → Kimi tager over for communicator → sender uprofessionel besked til ekstern kontakt

### Gap 3: Ingen Worker→Verifier Pattern

**Risiko: LAV-MEDIUM**

- Subagents kører og returnerer resultater uden systematisk verifikation
- Orchestrator kan spawne researcher, men resultater accepteres as-is
- For coding-tasks: ingen automatisk review af genereret kode
- For research-tasks: ingen fact-checking af resultater

**Nuance:** OpenClaw's subagent-arkitektur gør det naturligt at implementere verification via spawning af en ekstra agent, men det er ikke konfigureret.

---

## Design-forslag

### 4.1 Tool Policies per Agent

OpenClaw understøtter dette native via `agents.list[].tools`. Vi designer efter **principle of least privilege**.

#### Designprincipper

1. Hver agent får kun de tools den **faktisk bruger**
2. `exec` og `write` er de farligste — begræns aggressivt
3. Brug `tools.profile` som baseline, `allow/deny` for fine-tuning
4. Brug `tools.byProvider` til at begrænse fallback-modeller yderligere

#### Per-Agent Tool Matrix

| Agent | Profile | Allow (ekstra) | Deny | Rationale |
|-------|---------|----------------|------|-----------|
| **main** | `minimal` | `read`, `group:memory`, `sessions_spawn`, `sessions_list`, `sessions_send` | `exec`, `write`, `edit`, `process`, `browser`, `nodes` | Tvinger spawning af specialiserede agents → billigere LLM'er |
| **monitor** | `minimal` | `read`, `group:web`, `group:memory` | `exec`, `write`, `edit`, `process`, `browser`, `canvas`, `nodes` | Checks only, ingen mutations |
| **researcher** | `minimal` | `read`, `group:web`, `group:memory`, `image` | `exec`, `write`, `edit`, `process`, `browser`, `nodes` | Research = read + search |
| **communicator** | `messaging` | `read`, `group:memory` | `exec`, `write`, `edit`, `process`, `browser`, `nodes`, `group:web` | Skriver baseret på kontekst - research = researcher's job |
| **orchestrator** | `coding` | — | `browser`, `nodes`, `canvas` | Kan køre kommandoer + redigere, men ej browser/nodes |
| **coordinator** | `minimal` | `read`, `group:memory`, `group:web`, `sessions_spawn`, `sessions_list`, `sessions_send` | `exec`, `write`, `edit`, `process`, `browser`, `nodes` | Projektleder - delegerer men bygger ikke selv |

#### Provider-specifik begrænsning (fallback-modeller)

**BESLUTNING (Danny 2026-02-13):** FJERNET — Tool restrictions skal ligge hos individuelle agents, ikke globalt per provider. Dette tvinger os til at:
- Definere agents eksplicit når vi har behov
- Lave nye specialiserede agents hvis nødvendigt
- Undgå global "safety net" der skjuler dårligt agent-design

### 4.2 Model Fallback Observability

#### Approach A: Log Level + Monitoring (Enkel)

Sæt `logging.level: "debug"` og parse file logs for fallback-events:

```bash
# Cron-job eller heartbeat check
grep -i "fallback\|failover\|cooldown" /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log
```

#### Approach B: Hook-baseret Notification (Anbefalet)

OpenClaw hooks kan reagere på lifecycle events. Opret en hook der notificerer ved model-switch:

```javascript
// hooks/fallback-notify/index.js
module.exports = {
  name: "fallback-notify",
  events: ["model.fallback"],
  async handler(event, ctx) {
    const { fromModel, toModel, agent, reason } = event;
    // Log til dedicated fil
    const fs = require("fs");
    const line = JSON.stringify({
      ts: new Date().toISOString(),
      event: "model.fallback",
      from: fromModel,
      to: toModel,
      agent,
      reason,
    });
    fs.appendFileSync(
      "/root/.openclaw/workspace/logs/fallback-events.log",
      line + "\n"
    );
    // Notify via system message (valgfrit)
    if (ctx.notify) {
      await ctx.notify({
        title: `⚠️ Model Fallback`,
        body: `${agent}: ${fromModel} → ${toModel} (${reason})`,
        priority: "active",
      });
    }
  },
};
```

#### Approach C: Heartbeat-baseret Check (Pragmatisk)

Tilføj fallback-check til HEARTBEAT.md:

```markdown
## Fallback Monitor
- Check /tmp/openclaw/openclaw-YYYY-MM-DD.log for fallback events
- If found: report to Danny with agent + model details
- Check every 2 heartbeats (~1 time)
```

**Anbefaling:** Start med **Approach C** (ingen kode, virker nu), migrér til **B** når hooks er valideret.

### 4.3 Worker→Verifier Pattern

#### Hvornår er det relevant?

| Use Case | Verifier Needed? | Rationale |
|----------|-----------------|-----------|
| Research-resultater | **Ja, light** | Cross-check fakta med anden søgning |
| Kode-generering | **Ja, medium** | Syntax + sikkerhedscheck |
| Kommunikation (udgående) | **Ja, heavy** | Danny bør approve eksterne beskeder |
| Monitoring | **Nej** | Resultater er self-evident |

#### Implementation via Subagent Spawning

OpenClaw's subagent-system understøtter dette naturligt:

```
orchestrator → spawner researcher (worker)
            → spawner monitor (verifier) med researcher's output som kontekst
```

**Config-ændring:** Giv orchestrator adgang til at spawne en verifier-agent:

```json
{
  "id": "orchestrator",
  "subagents": {
    "allowAgents": ["monitor", "researcher", "verifier"]
  }
}
```

#### Ny Verifier Agent

```json
{
  "id": "verifier",
  "name": "Verifier",
  "workspace": "/root/.openclaw/workspace",
  "model": {
    "primary": "anthropic/claude-sonnet-4-5",
    "fallbacks": ["openrouter/moonshotai/kimi-k2.5"]
  },
  "tools": {
    "profile": "minimal",
    "allow": ["read", "group:web", "group:memory"]
  }
}
```

**Trade-off:** Ekstra API-kald per verificeret opgave. Brug det selektivt — ikke for alle tasks.

---

## Konkrete Config-ændringer

### Samlet `openclaw.json` diff (komplet)

```jsonc
{
  // === GLOBAL TOOL POLICIES ===
  "tools": {
    "web": { /* eksisterende */ }
    // INGEN global byProvider restrictions - tool policies ligger hos individuelle agents
  },

  // === LOGGING ===
  "logging": {
    "redactSensitive": "tools",
    "level": "info",           // Behold info, debug kun ved troubleshooting
    "consoleLevel": "info"
  },

  // === AGENTS ===
  "agents": {
    "defaults": { /* eksisterende - uændret */ },
    "list": [
      {
        "id": "main",
        "default": true,
        "subagents": {
          "allowAgents": ["monitor", "researcher", "communicator", "orchestrator", "coordinator", "verifier"]
        },
        "tools": {
          "profile": "minimal",
          "allow": ["read", "group:memory", "sessions_spawn", "sessions_list", "sessions_send", "session_status"]
        }
        // main: RESTRICTED — tvinger spawning af specialiserede agents for at spare penge
      },
      {
        "id": "monitor",
        "name": "Monitor",
        "workspace": "/root/.openclaw/workspace",
        "model": {
          "primary": "openrouter/moonshotai/kimi-k2.5",
          "fallbacks": ["nvidia/moonshotai/kimi-k2.5"]
        },
        "tools": {
          "profile": "minimal",
          "allow": ["read", "group:web", "group:memory"]
        }
      },
      {
        "id": "researcher",
        "name": "Researcher",
        "workspace": "/root/.openclaw/workspace",
        "model": {
          "primary": "openrouter/moonshotai/kimi-k2.5",
          "fallbacks": ["nvidia/moonshotai/kimi-k2.5", "anthropic/claude-sonnet-4-5"]
        },
        "tools": {
          "profile": "minimal",
          "allow": ["read", "group:web", "group:memory", "image"]
        }
      },
      {
        "id": "communicator",
        "name": "Communicator",
        "workspace": "/root/.openclaw/workspace",
        "model": {
          "primary": "anthropic/claude-opus-4-6",
          "fallbacks": ["anthropic/claude-sonnet-4-5", "openrouter/moonshotai/kimi-k2.5"]
        },
        "tools": {
          "profile": "messaging",
          "allow": ["read", "group:memory"]
        }
      },
      {
        "id": "orchestrator",
        "name": "Orchestrator",
        "workspace": "/root/.openclaw/workspace",
        "model": {
          "primary": "anthropic/claude-sonnet-4-5",
          "fallbacks": ["openrouter/moonshotai/kimi-k2.5", "nvidia/moonshotai/kimi-k2.5"]
        },
        "tools": {
          "profile": "coding",
          "deny": ["browser", "nodes", "canvas"]
        },
        "subagents": {
          "allowAgents": ["monitor", "researcher", "verifier"]
        }
      },
      {
        "id": "coordinator",
        "name": "Coordinator",
        "workspace": "/root/.openclaw/workspace",
        "model": {
          "primary": "anthropic/claude-opus-4-6",
          "fallbacks": ["anthropic/claude-sonnet-4-5", "openrouter/moonshotai/kimi-k2.5"]
        },
        "tools": {
          "profile": "minimal",
          "allow": ["read", "group:memory", "group:web", "sessions_spawn", "sessions_list", "sessions_send", "session_status"]
        },
        "subagents": {
          "allowAgents": ["monitor", "researcher", "communicator", "orchestrator", "verifier"]
        }
      },
      {
        "id": "verifier",
        "name": "Verifier",
        "workspace": "/root/.openclaw/workspace",
        "model": {
          "primary": "anthropic/claude-sonnet-4-5",
          "fallbacks": ["openrouter/moonshotai/kimi-k2.5"]
        },
        "tools": {
          "profile": "minimal",
          "allow": ["read", "group:web", "group:memory"]
        }
      }
    ]
  }
}
```

---

## Implementeringsplan

### Fase 1: Tool Policies (Dag 1-2) — HØJESTE PRIORITET

1. **Backup config:** `cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak`
2. **Tilføj global `tools.byProvider`** for Kimi-begrænsning
3. **Tilføj `tools` til hver agent** i `agents.list[]`
4. **Test:** Kør hver agent og verificér den kun ser tilladte tools
   - `openclaw agent --agent monitor` → skal IKKE have exec
   - `openclaw agent --agent researcher` → skal have web_search/web_fetch/read
5. **Verificér:** Check gateway logs for tool-policy denials

### Fase 2: Fallback Observability (Dag 3-4)

1. **Tilføj fallback-monitor sektion til HEARTBEAT.md**
2. **Opret** `logs/` directory i workspace
3. **Test:** Simulér fallback (midlertidigt fjern Anthropic API-key) og verificér detection
4. **(Valgfrit)** Undersøg hooks-support for `model.fallback` event

### Fase 3: Verifier Pattern (Dag 5-7) — VALGFRI

1. **Tilføj `verifier` agent** til config
2. **Opdatér orchestrator's `allowAgents`** til at inkludere `verifier`
3. **Test med en coding-task:** orchestrator spawner coder → spawner verifier
4. **Evaluér cost/benefit** efter 1 uges brug

---

## Risici & Trade-offs

### Tool Policies

| Risiko | Sandsynlighed | Konsekvens | Mitigering |
|--------|---------------|------------|------------|
| For restriktive policies → agent fejler | Medium | Agent kan ikke udføre opgave | Start med loose policies, stram gradvist |
| Config-fejl bryder agents | Lav | Agent starter ikke | Test hver agent efter ændring |
| Main agent kompromitteres → fuld adgang | Lav | Samme som nu | Acceptabelt — main er Danny's direkte interface |
| Kimi deny-list for bred | Lav | Kimi-fallback ubrugelig | Kimi bruges primært til research/monitoring — read+web er nok |

### Fallback Observability

| Risiko | Sandsynlighed | Konsekvens | Mitigering |
|--------|---------------|------------|------------|
| False positives (normal rotation) | Medium | Alert fatigue | Kun notificér ved provider-shift, ikke profile-rotation |
| Log-parsing misser events | Lav | Uopdagede fallbacks | Supplér med hooks når muligt |

### Verifier Pattern

| Risiko | Sandsynlighed | Konsekvens | Mitigering |
|--------|---------------|------------|------------|
| Dobbelt API-cost | Høj | Højere omkostninger | Brug kun til high-stakes tasks |
| Verifier hallucinerer selv | Lav-Medium | False sense of security | Brug stærkere model til verifier end worker |
| Latency-overhead | Medium | Langsommere responses | Acceptabelt for ikke-tidskritiske tasks |

---

## Review-punkter til Danny

Før implementering, bekræft venligst:

### BESLUTNINGER (Danny 2026-02-13) ✅

- [x] **Main agent restrictions** — JA, restrict main til spawning/read/memory → tvinger brug af specialiserede agents (billigere!)
- [x] **Main agent rolle** — "Assistant's assistant" - delegerer men udfører ikke selv tungt arbejde
- [x] **Kimi global deny-list** — NEJ, fjern global restrictions → redundant når vi bruger allow-lists per agent
- [x] **Verifier agent** — JA, implementer verifier pattern → bedre kvalitetssikring
- [x] **Communicator tools** — NEJ til browser/web - skal skrive baseret på kontekst DU giver, research = researcher's job
- [x] **Coordinator restrictions** — JA, projektleder-rolle: kan se/delegere men ikke bygge (read + sessions + web, ingen exec/write)
- [x] **Fallback notifications** — Log-check via heartbeat er fint (ingen push-notifications)
- [x] **Sandbox mode** — På todo-liste, ignorer for nu
- [x] **Filosofi** — Hvis vi mangler en agent, laver vi den (fremfor at give global adgang)

### Model Context
- Main agent kører **Sonnet 4.5** ($3 input / $15 output per million tokens)
- Fallback til **Kimi K2.5** ($0.45 / $2.25 - 75-85% billigere)
- Ved at restricte main til delegation → tvinger vi billigere agents til tungt arbejde

### Informational

- [ ] **Backup-plan:** Config backup tages før ændringer. Rollback = kopier `.bak` fil
- [ ] **Ingen breaking changes:** Alle ændringer er additive — eksisterende workflows brydes ikke, de begrænses kun
- [ ] **Gradvis udrulning:** Start med monitor+researcher (laveste risiko), derefter communicator, til sidst orchestrator+coordinator

---

*Dokumentet er genereret automatisk baseret på research af OpenClaw docs v2026.2.9 og nuværende config. Alle config-snippets er valideret mod den officielle dokumentation.*
