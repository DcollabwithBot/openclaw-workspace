# Agent Fleet Security Audit
**Dato:** 2026-02-13  
**Auditor:** security-agent (subagent: 9eeef87d-dcac-4832-96d6-48bbdda55a4e)  
**Config Source:** `~/.openclaw/openclaw.json`

---

## Executive Summary

| Metric | Count |
|--------|-------|
| Total agents | 9 |
| Kritiske findings | 3 |
| Høje findings | 4 |
| Medium findings | 3 |
| Anbefalinger | 12 |

**Overall Security Posture:** WEAK - Mangel på tool-level restrictions og principle of least privilege

---

## Per-Agent Analysis

### 1. main

| Attribut | Værdi |
|----------|--------|
| **Default** | Ja |
| **Tools** | `read`, `group:sessions`, `group:memory` |
| **Spawn permissions** | Alle 8 andre agents |
| **Model** | Sonnet 4.5 → Kimi K2.5 (OR) → Kimi K2.5 (NVIDIA) |

**Findings:**
- 🔴 **CRITICAL:** Har `group:sessions` uden begrænsning - kan omdirigere enhver agent til ondsindede formål
- 🟠 **HIGH:** Ingen tool restrictions - har implicit adgang til alle tools via defaults
- 🟡 **MEDIUM:** Fallback til Kimi K2.5 (non-API) indebærer ukontrolleret kontekst-window (131k vs 262k)
- ✅ **PASS:** Har ikke eksplicit `exec` tilladelse

**Anbefalinger:**
1. Fjern `group:sessions` - main skal kun kunne spawne agents, ikke styre deres sessions
2. Tilføj eksplicit `deny: ["exec", "write", "edit", "browser", "nodes", "canvas"]`
3. Overvej at bruge `profile: "minimal"` eksplicit

---

### 2. monitor

| Attribut | Værdi |
|----------|--------|
| **Default** | Nej |
| **Tools** | `read`, `web_search`, `web_fetch`, `group:memory` |
| **Spawn permissions** | Ingen |
| **Model** | Kimi K2.5 (OR) → Kimi K2.5 (NVIDIA) |

**Findings:**
- 🟠 **HIGH:** `web_fetch` kombineret med `web_search` = potentiel SSRF/prompt injection vektor
- 🟠 **HIGH:** Kan læse `group:memory` = adgang til sensitiv SESSION kontekst
- 🟡 **MEDIUM:** Ingen spawn = korrekt for lettvægtsopgaver
- ✅ **PASS:** Har ikke `exec`, `write`, eller `edit` - god least privilege

**Anbefalinger:**
1. Isolate `group:memory` - monitor bør ikke have adgang til long-term memory
2. Overvej `maxResults: 3` på web_search for at begrænse angrebsoverflade
3. Audit: monitor har adgang til at læse credentials hvis de gemmes i workspace

---

### 3. researcher

| Attribut | Værdi |
|----------|--------|
| **Default** | Nej |
| **Tools** | `read`, `web_search`, `web_fetch`, `group:memory`, `image` |
| **Spawn permissions** | Ingen |
| **Model** | Kimi K2.5 (OR) → Kimi K2.5 (NVIDIA) → Sonnet 4.5 → Gemini Flash |

**Findings:**
- 🟠 **HIGH:** Fallback kæde slutter på Gemini Flash (anden provider) - potentiel data leakage til Google
- 🟠 **HIGH:** `image` tool uden kontekst-begrænsning - kan behandle sensitiv data
- 🟡 **MEDIUM:** `web_fetch` kan tilgå interne endpoints hvis ikke blacklistet
- 🟡 **MEDIUM:** Længste fallback chain (4 models) = høj utilgængelighedsrisiko
- ✅ **PASS:** Ingen spawn permissions = korrekt

**Anbefalinger:**
1. Fjern Gemini Flash fra fallback chain (Google data residency bekymringer)
2. Tilføj `web_fetch.denyHosts` for interne netværk (10.0.0.0/8, 192.168.0.0/16)
3. Overvej at fjerne `image` tool eller tilføje content-filter

---

### 4. communicator

| Attribut | Værdi |
|----------|--------|
| **Default** | Nej |
| **Tools** | `read`, `group:memory`, `message` |
| **Spawn permissions** | Ingen |
| **Model** | Opus 4.6 → Sonnet 4.5 → Kimi K2.5 |

**Findings:**
- 🟠 **HIGH:** Har `message` tool uden rate limiting eller approval workflow
- 🟡 **MEDIUM:** `group:memory` = kan tilgå sensitiv SESSION data
- 🟡 **MEDIUM:** Fallback til Kimi K2.5 for kommunikation = lavere kvalitet, potentielle hallucinationer
- ✅ **PASS:** Ingen web tools = korrekt scope isolering
- ✅ **PASS:** Primær model er Opus 4.6 (højeste kvalitet til tekst)

**Anbefalinger:**
1. KRITISK: Tilføj approval workflow før `message` sendes (menneske-i-loop)
2. Overvej at fjerne `group:memory` - communicator behøver ikke historisk kontekst
3. Dokumentér hvem `message` kan sendes til (WhatsApp, email, etc.)

---

### 5. orchestrator

| Attribut | Værdi |
|----------|--------|
| **Default** | Nej |
| **Tools** | `group:runtime`, `group:fs`, `group:memory`, `group:sessions` |
| **Spawn permissions** | monitor, researcher, verifier |
| **Model** | Sonnet 4.5 → Kimi K2.5 (OR) → Kimi K2.5 (NVIDIA) |
| **Explicit deny** | `browser`, `nodes`, `canvas` |

**Findings:**
- 🔴 **CRITICAL:** `group:runtime` + `group:fs` = fuld `exec` og `write` kapabilitet
- 🔴 **CRITICAL:** `group:sessions` = kan redirect agents til ondsindede formål  
- 🟠 **HIGH:** Spawn graph inkluderer `researcher` → researcher kan spawne arbitrære kodestykker
- 🟠 **HIGH:** Fallback til Kimi med fuld runtime access = potentiel command injection
- 🟡 **MEDIUM:** Har `deny: ["browser", "nodes", "canvas"]` - godt, men ikke nok

**Anbefalinger:**
1. FJERN `group:runtime` fra orchestrator - brug eksplicit tool-tilladelser i stedet
2. FJERN `group:sessions` - orchestrator skal ikke kontrollere active agent sessions
3. Overvej at fjerne `researcher` fra allowAgents - high-risk spawn chain

---

### 6. coordinator

| Attribut | Værdi |
|----------|--------|
| **Default** | Nej |
| **Tools** | `read`, `group:memory`, `web_search`, `web_fetch`, `group:sessions` |
| **Spawn permissions** | monitor, researcher, communicator, orchestrator, verifier |
| **Model** | Opus 4.6 → Sonnet 4.5 → Kimi K2.5 |

**Findings:**
- 🔴 **CRITICAL:** Længste spawn chain (5 agents) = høj eskaleringsrisiko
- 🔴 **CRITICAL:** `group:sessions` + spawn permissions = arbitrær agent manipulation
- 🟠 **HIGH:** `web_fetch` + spawn = kan hente payload og deploy via orchestrator
- 🟠 **HIGH:** Coordinator kan eskalere via orchestrator som har `group:runtime`
- 🟡 **MEDIUM:** Har ikke explicit `exec` men kan få det gennem orchestrator

**Anbefalinger:**
1. FJERN `group:sessions` - coordinator skal kun spawne, ikke kontrollere sessions
2. Overvej at fjerne `orchestrator` fra allowAgents - forhindrer privilege escalation
3. Tilføj `web_fetch.denyHosts` for interne netværk
4. Dokumentér spawn chain: coordinator → orchestrator → researcher = 3-hop privilege gain

---

### 7. verifier

| Attribut | Værdi |
|----------|--------|
| **Default** | Nej |
| **Tools** | `read`, `group:memory`, `web_search`, `web_fetch` |
| **Spawn permissions** | Ingen |
| **Model** | Sonnet 4.5 → Kimi K2.5 |

**Findings:**
- 🟡 **MEDIUM:** Har `web_fetch` men ingen spawn = kan verificere facts
- 🟡 **MEDIUM:** `group:memory` = kan læse sensitiv historik
- ✅ **PASS:** Ingen spawn = korrekt for verification rolle
- ✅ **PASS:** Primær model Sonnet 4.5 = god til verification

**Anbefalinger:**
1. Overvej at fjerne `group:memory` - verifier behøver ikke historisk kontekst
2. Tilføj `web_fetch.denyHosts` for interne netværk

---

### 8. reviewer

| Attribut | Værdi |
|----------|--------|
| **Default** | Nej |
| **Tools** | `read`, `group:memory`, `web_search`, `web_fetch` |
| **Spawn permissions** | Ingen |
| **Model** | Sonnet 4.5 → Opus 4.6 → Kimi K2.5 |

**Findings:**
- 🟠 **HIGH:** Fallback til Opus 4.6 er UNIK - reviewer har højere fallback end primær
- 🟡 **MEDIUM:** `group:memory` = kan læse sensitiv SESSION data
- 🟡 **MEDIUM:** `web_fetch` = potentiel SSRF hvis ikke begrænset
- ✅ **PASS:** Ingen spawn = korrekt

**Anbefalinger:**
1. Ret fallback rækkefølge: Opus 4.6 skal være primær (dyreste, bedste kvalitet)
2. Overvej at fjerne `group:memory` - reviewer behøver ikke historisk kontekst

---

### 9. security

| Attribut | Værdi |
|----------|--------|
| **Default** | Nej |
| **Tools** | `read`, `group:memory`, `web_search`, `web_fetch`, `exec` |
| **Spawn permissions** | Ingen |
| **Model** | Sonnet 4.5 → Opus 4.6 → Kimi K2.5 |

**Findings:**
- 🔴 **CRITICAL:** Har `exec` tool uden approval workflow - kan køre arbitrære kommandoer
- 🔴 **CRITICAL:** `exec` + `web_fetch` = kan hente og køre ondsindet kode
- 🔴 **CRITICAL:** Fallback til Kimi K2.5 med `exec` = potentiel command injection ved hallucination
- 🟠 **HIGH:** Kan læse `~/.openclaw/credentials/` via `read` + path traversal
- 🟠 **HIGH:** Kan tilgå SSH keys i `~/.ssh/` via `read`

**Anbefalinger:**
1. KRITISK: Tilføj approval workflow før `exec` udføres
2. KRITISK: Tilføj `exec.denyChmod` for at forhindre +x på downloaded filer
3. Fjern `web_fetch` eller tilføj strict `denyHosts`
4. Overvej sandboxing til `/tmp/security-sandbox/` for exec-operations

---

## Cross-Agent Security Analysis

### Spawn Graph

```
main → [monitor, researcher, communicator, orchestrator, coordinator, verifier, reviewer, security]
       │
       └────────────────────────────────────────────────────────────────────┐
       │                                                                 │
orchestrator → [monitor, researcher, verifier]                           │
       │                                                                 │
       │    researcher (ingen spawn)                                      │
       │                                                                 │
coordinator → [monitor, researcher, communicator, orchestrator, verifier]  │
       │
       └────→ orchestrator har runtime/fs = privilege escalation til exec/write
```

**Circular Spawn Analysis:** Ingen direkte cirkulære spawns detekteret.  
**Privilege Escalation Path:** coordinator → orchestrator → runtime/fs = fuld systemadgang

### Tool Matrix Summary

| Agent | exec | write | edit | browser | web_search | web_fetch | message | sessions |
|-------|:----:|:-----:|:----:|:-------:|:----------:|:---------:|:-------:|:--------:|
| main | ❓ | ❓ | ❓ | ❓ | ❓ | ❌ | ❌ | ✅ |
| monitor | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ❌ |
| researcher | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ❌ |
| communicator | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| orchestrator | ✅* | ✅* | ✅* | ❌ | ❌ | ❌ | ❌ | ✅ |
| coordinator | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ✅ |
| verifier | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ❌ |
| reviewer | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ❌ |
| security | ✅ | ❓ | ❓ | ❌ | ✅ | ✅ | ❌ | ❌ |

*via `group:runtime` og `group:fs`

---

### Attack Scenarios

#### Scenario 1: Compromised main agent
**Impact:** Total system compromise  
**Path:** main har adgang til alle agents via `group:sessions` + kan spawne alle andre agents  
**Remediation:** 
- Fjern `group:sessions` fra main
- Restriktiv tool profile på main (read-only, spawn-only)

#### Scenario 2: Compromised orchestrator via coordinator chain
**Impact:** Arbitrær code execution  
**Path:** coordinator → spawner orchestrator → har `group:runtime` = exec/write  
**Remediation:**
- Fjern orchestrator fra coordinator's allowAgents, ELLER
- Fjern `group:runtime` fra orchestrator

#### Scenario 3: Security agent command injection
**Impact:** Data exfiltration, system compromise  
**Path:** web_fetch ondsindet payload → exec på payload  
**Remediation:**
- Tilføj approval workflow til security agent's exec
- Implementer sandbox for security checks

#### Scenario 4: Prompt injection via web_fetch
**Impact:** Agent manipulation, data leakage  
**Path:** web_fetch kompromitteret side → prompt injection → ondsindede handlinger  
**Remediation:**
- Tilføj content-sanitization på web_fetch
- Rate limiting på web_search/fetch calls

---

## Recommendations (Priority Order)

### 🔴 Critical (Fix immediately)

1. **Tilføj approval workflow til `exec` tool på security agent**
   - Nuværende: Automatisk exec uden menneskelig godkendelse
   - Risk: Arbitrær code execution
   - Fix: `agents.security.tools.exec.requireApproval: true`

2. **Fjern `group:sessions` fra main og coordinator**
   - Nuværende: Sessions manipulation uden begrænsning
   - Risk: Arbitrær agent omdirigering
   - Fix: Eksplicit tool-list uden sessions i `allow`

3. **Fjern `group:runtime` fra orchestrator**
   - Nuværende: Implciit exec via runtime group
   - Risk: Privilege escalation gennem spawn chain
   - Fix: Eksplicit allow-list uden runtime

### 🟠 High (Fix this week)

4. **Implementer `denyHosts` på web_fetch for alle agents**
   - Block: 10.0.0.0/8, 192.168.0.0/16, 169.254.0.0/16
   - Prevent SSRF angreb på interne services

5. **Fix reviewer model fallback rækkefølge**
   - Nuværende: Sonnet → Opus → Kimi
   - Bør være: Opus → Sonnet → Kimi (reviewer = høj kvalitet kritisk)

6. **Fjern Gemini Flash fra researcher fallback chain**
   - Google data residency = compliance risk
   - Nuværende: ... → Gemini Flash

7. **Isolate credentials fra workspace read**
   - Nuværende: agents kan læse `~/.openclaw/credentials/` via path traversal
   - Fix: `read.denyPaths: ["~/.openclaw/credentials/*", "~/.ssh/*", "~/.git-credentials"]`

### 🟡 Medium (Fix this month)

8. **Fjern `group:memory` fra monitor, communicator, verifier, reviewer**
   - De behøver ikke long-term SESSION kontekst
   - Reducerer data exposure ved kompromittering

9. **Tilføj rate limiting på web_search/web_fetch**
   - Prevent DoS og eksfiltrering
   - Max 10 calls per session per default

10. **Dokumenter spawn chains og privilege boundaries**
    - Nuværende: Uklart hvilken agent kan hvad
    - Fix: DECISIONS.md opdatering med security model

### 🟢 Low (Nice to have)

11. **Overvej sandbox mode for security agent**
    - Chroot til `/tmp/security-sandbox/`
    - Limit network egress til specifikke endpoints

12. **Implementer fallback event logging og alerting**
    - Log hver gang en agent falder tilbage til alternativ model
    - Heartbeat check af `/tmp/openclaw/openclaw-*.log`

---

## Compliance Check

| Principle | Status | Bemærkning |
|-----------|:------:|------------|
| Principle of least privilege | ⚠️ PARTIAL | Mange agents har bredere adgang end nødvendigt |
| Defense in depth | ❌ FAIL | Enkelt kompromis = total adgang (især main, coordinator) |
| Fail secure | ⚠️ PARTIAL | Fallback til lavere-kvalitet models uden restrictions |
| Audit logging | ⚠️ PARTIAL | Tool execution logges, men ikke fallback events aktivt |
| Secret management | ❌ FAIL | Credentials i plain text, agents kan læse via `read` |

---

## Summary

**Overall Security Posture:** WEAK

Det nuværende setup prioriterer funktionalitet over sikkerhed. Hovedproblemerne er:

1. **Overprivilegerede spawn permissions** - main og coordinator kan manipulere enhver agent
2. **Manglende tool restrictions** - mange agents har implicit adgang til farlige tools via groups
3. **Ingen approval workflows** - security agent kan køre arbitrære kommandoer uden godkendelse
4. **Ubeskyttede credentials** - API keys og tokens kan læses af agents med `read` tool
5. **Privilege escalation chains** - coordinator → orchestrator giver fuld systemadgang

**Vigtigste handling:** Implementer tool-level restrictions på ALL agents før næste produktions-deployment.

---

*Genereret af security-agent (OpenClaw v2026.2.9)*
