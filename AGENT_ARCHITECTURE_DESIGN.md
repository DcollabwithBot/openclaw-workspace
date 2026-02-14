# Agent Architecture Design - Security Review (Bent)

**Dato:** 2026-02-14  
**Udført af:** Bent (Security Agent)  
**Status:** ✅ Config ændringer implementeret

---

## 🎯 Problem Løst

**Før:** Default model var Kimi K2.5 → main og de fleste agenter brugte Kimi  
**Efter:** Default er nu Sonnet 4.5 → main bruger Anthropic som ønsket

---

## 📋 Agent Model Matrix (Endelig)

| Agent | Primary | Fallback | Use Case | Omkostning |
|-------|---------|----------|----------|------------|
| **main** | Sonnet 4.5 | Kimi | Chat, coordination | Medium |
| **orchestrator** | Sonnet 4.5 | Kimi | Implementation | Medium |
| **coordinator** | Opus 4.6 | Sonnet | Complex planning | High |
| **communicator** | Opus 4.6 | Sonnet | Kommunikation (sprog) | High |
| **researcher** | Kimi | Gemini | Research (billigt) | Free |
| **monitor** | Kimi | - | Status checks | Free |
| **security** | Sonnet 4.5 | Opus | Security review | Medium |
| **reviewer** | Sonnet 4.5 | Opus | Code review | Medium |
| **verifier** | Sonnet 4.5 | Kimi | Verification | Medium |
| **complexity-guardian** | Kimi | - | Triage | Free |
| **webmon** | Kimi | - | Uptime monitoring | Free |

---

## 🔧 Konfiguration Ændringer

### 1. Default Model (linje ~65)
```json
"model": {
  "primary": "anthropic/claude-sonnet-4-5",
  "fallbacks": [
    "openrouter/moonshotai/kimi-k2.5",
    "nvidia/moonshotai/kimi-k2.5"
  ]
}
```

### 2. Main Agent Override (linje ~119)
```json
{
  "id": "main",
  "default": true,
  "model": {
    "primary": "anthropic/claude-sonnet-4-5",
    "fallbacks": [
      "openrouter/moonshotai/kimi-k2.5",
      "nvidia/moonshotai/kimi-k2.5"
    ]
  },
  // ... resten
}
```

---

## 🔄 Failover Strategi

**Hvad betyder "failover"?**
- Hvis primary model fejler (rate limit, cooldown, nede) → automatisk skift til fallback
- Hvis fallback også fejler → næste i kæden
- Sidste fallback er altid Kimi via NVIDIA (gratis)

**Eksempel rækkefølge for main:**
1. `anthropic/claude-sonnet-4-5` (primary)
2. `openrouter/moonshotai/kimi-k2.5` (fallback 1)
3. `nvidia/moonshotai/kimi-k2.5` (fallback 2 - gratis)

---

## 💓 Heartbeat Model Status Check

**Danny spurgte:** "Skal heartbeat tjekke om vi er blocked?"

**Svar:** Ja, det anbefales. Heartbeat kan:
1. Tjekke om Anthropic er i cooldown
2. Logge hvilken model der faktisk bruges
3. Advisere hvis vi er på fallback i længere tid

**Nuværende heartbeat config:**
```json
"heartbeat": {
  "every": "30m",
  "model": "openrouter/moonshotai/kimi-k2.5",
  "target": "last",
  "prompt": "Read HEARTBEAT.md if it exists..."
}
```

**Anbefaling:** Overvej at tilføje model status check til HEARTBEAT.md eller oprette en monitor agent der tjekker API status.

---

## 💰 Estimeret Omkostningsprofil

| Model | Brug | Est. Cost |
|-------|------|-----------|
| Sonnet 4.5 | ~60% af kald | $0.50/MTok |
| Opus 4.6 | ~10% af kald | $3.00/MTok |
| Kimi (OpenRouter) | ~20% af kald | $0.45/MTok |
| Kimi (NVIDIA) | ~10% af kald | Gratis |

**Bemærk:** Kimi via NVIDIA er helt gratis (NVIDIA API key er allerede konfigureret).

---

## ✅ Checklist

- [x] Default ændret fra Kimi til Sonnet 4.5
- [x] Main agent har explicit Sonnet 4.5 override
- [x] Researcher beholder Kimi (billig research)
- [x] Monitor beholder Kimi (billige checks)
- [x] Coordinator fastholder Opus 4.6 (komplekse opgaver)
- [x] Communicator fastholder Opus 4.6 (godt sprog)
- [x] Failover kæde: Sonnet → Kimi (OR) → Kimi (NVIDIA)
- [ ] Heartbeat model status check (kan tilføjes senere)

---

## 📁 Relevante Files

- `/root/.openclaw/openclaw.json` - Konfiguration ændret
- `/root/.openclaw/workspace/memory/2026-02-14.md` - Dokumentation
- `/root/.openclaw/workspace/AGENT_ARCHITECTURE_DESIGN.md` - Denne fil

---

## 🚀 Næste Skridt

1. **Test:** Start en ny session og verificér at main bruger Sonnet 4.5
2. **Monitor:** Hold øje med omkostninger de første par dage
3. **Heartbeat:** Overvej at tilføje model status check
4. **Dokumentér:** Opdater AGENTS.md hvis nye agenter tilføjes

---

*Designet af Bent (Security) for Danny*  
*Godkendes af Danny før endelig implementering*
