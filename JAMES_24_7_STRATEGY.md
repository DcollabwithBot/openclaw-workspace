# James 24/7 Access Strategy

**Dato:** 2026-02-14
**Formål:** 100% uptime for Danny med primært Sonnet kvalitet

## Model Fallback Strategy

### Primary: Sonnet 4.5 (Anthropic)
- Bruges så længe jeg har tokens
- Højeste kvalitet, hurtigste respons
- Du betaler for dette via API

### Fallback: Kimi K2.5 (NVIDIA - gratis)
- Aktiveres automatisk når Sonnet fejler
- Jeg informerer dig: "[Sonnet limit - bruger Kimi backup]"
- Lavere kvalitet men fuldt funktionel
- Gratis via NVIDIA trial

## Implementation

### Når Sonnet virker:
```
Du: [spørgsmål]
Mig: [svar med Sonnet kvalitet] ✅
```

### Når Sonnet er i limit:
```
Du: [spørgsmål]
Mig: [Sonnet rate limit - skifter til Kimi backup]
Mig: [svar med Kimi kvalitet] ⚠️
```

### Når Sonnet er tilbage:
```
Mig: [Sonnet tilgængelig igen - skifter tilbage] ✅
```

## Baggrunds Agenter (altid Kimi)
- Heartbeat: Kimi (gratis)
- Monitor: Kimi (gratis)
- Research: Kimi (billig)
- Kun når de spawnes specifikt med andre modeller

## Cost Optimization
- Sonnet kun til direkte chat med dig
- Kimi til alt baggrunds arbejde
- Du får besked når jeg skifter
- Ingen overraskelser

## Target: 99% Sonnet, 1% Kimi (kun når nødvendigt)

---
**Danny har 24/7 adgang:**
- Primært høj kvalitet (Sonnet)
- Backup tilgængelig (Kimi)
- Transparent om hvad der bruges
- Ingen nedetid
