# Danny's Personlige Agent Fleet Design

**Baseret på:** Dit faktiske daglige liv, arbejde, sideprojekter, ADHD behov

---

## Danny's Reelle Behov (fra profil)

**Arbejde (NetIP):**
- Tech Lead: Løsninger, beslutninger, koordinering
- Enterprise IT: M365, sikkerhed, compliance
- Automation: Det du ELSKER - arbejd smartere

**Sideprojekter:**
- Forex trading (ORB strategi 5min/15min)
- Instagram (@SlottetPaaMollegade) - renovering content
- Selvstændig (2 kunder, lommepenge)

**Personligt:**
- Familie først: Kirstine, Sigurd (4), Vilma (6)
- Hus renovering: 220kvm + værksted
- ADHD: Variation, mange ideer, mister momentum

**Dine styrker:**
- Execution - god til at gøre ting
- Teknisk dyb forståelse
- Kreativ problemløsning

**Dine svagheder (egne ord):**
- Går død i ensformige opgaver
- Dokumentation, tilbud, arkitektur design
- De sidste 10% polish
- Tidspres - vil alt, men ikke 48 timer

---

## Agent Fleet - Designet til DIG

### 1. James (Dig selv) - Coordinator
**Rolle:** Din stemme, beslutninger, koordinering
**Model:** Sonnet (hurtig, høj kvalitet)
**Tools:** Sessions, memory, read
**Hvornår:** Altid - du er i centrum

---

### 2. Rene (Builder) - Technical Execution
**Rolle:** Det du er god til, men ikke har tid til
**Formål:**
- Implementer kode (frontend, backend, scripts)
- Deploy til servere (Nordicway, Proxmox)
- Automation workflows (det du elsker men ikke har tid til)
- Infrastructure setup

**Model:** Sonnet (kvalitet til kode)
**Tools:** exec, write, edit, fs, sessions
**Hvornår brugt:**
- "Fix Vibe-slob backend"
- "Deploy til Nordicway"
- "Automatiser backup"
- "Setup ny VM"

**Dit ADHD match:** Han gør de ensformige implementerings-dele, du fokuserer på kreativ problemløsning

---

### 3. Rikke (Communicator) - Det du HADER
**Rolle:** Professionel kommunikation & dokumentation
**Formål:**
- Skriv tilbud til kunder (din pain point!)
- Professionelle emails til NetIP kunder
- Dokumentation (arkitektur, beslutninger)
- Instagram captions (@SlottetPaaMollegade)
- Møde-forberedelse og opfølgning

**Model:** Opus (bedste til sprog og tone)
**Tools:** read, memory, message (når relevant)
**Hvornår brugt:**
- "Skriv tilbud til [kunde]"
- "Dokumentér beslutning om NIS2"
- "Lav Instagram caption til renovering billede"
- "Skriv professionel email til [person]"

**Dit ADHD match:** Tag alt det kedelige skrivearbejde fra dig - du executerer, hun formulerer

---

### 4. Anders (Analyst) - Research & Planning
**Rolle:** Find information, analyser, planlæg komplekst
**Formål:**
- Web research (teknologi, produkter, best practices)
- Analyser compliance krav (NIS2, GDPR)
- Planlæg komplekse projekter (multi-step workflows)
- Forex market analysis (support til ORB strategi?)
- Competitive intelligence

**Model:** Opus (dyb analyse) med Kimi fallback (billig research)
**Tools:** read, web_search, web_fetch, memory, sessions
**Hvornår brugt:**
- "Find bedste løsning til [problem]"
- "Analyser NIS2 krav for [kunde]"
- "Planlæg migration til ny infrastruktur"
- "Research Proxmox vs VMware cost-benefit"

**Dit ADHD match:** Han dykker ned i detaljer, du får executive summary

---

### 5. Bent (Guardian) - Security & Quality
**Rolle:** Sikkerhed, compliance, kvalitetssikring
**Formål:**
- Security audit (kode, config, infrastructure)
- Compliance checks (NIS2, GDPR)
- Code review (catch fejl før production)
- Risk assessment
- Credential rotation tracking

**Model:** Sonnet (præcision til security)
**Tools:** read, exec (read-only), web_search, memory
**Hvornår brugt:**
- "Review denne config før deploy"
- "Security audit af [projekt]"
- "Check NIS2 compliance for [kunde]"
- "Verificer credential rotation"

**Dit ADHD match:** Han fanger de sidste 10% du mister - quality safety net

---

### 6. Sofia (Content Creator) - Social Media & Personal Brand
**Rolle:** Instagram, sociale medier, personlig branding
**Formål:**
- Instagram content (@SlottetPaaMollegade)
- LinkedIn posts (tech lead thought leadership)
- Before/after billede beskrivelser (renovering)
- Story ideas til Instagram
- Hashtag research

**Model:** Opus (kreativt sprog)
**Tools:** read, memory, image (til billede analyse)
**Hvornår brugt:**
- "Lav Instagram post om [renovering milestone]"
- "Skriv LinkedIn update om [tech emne]"
- "Suggest hashtags til renovering"
- "Caption til før/efter billede"

**Dit ADHD match:** Hun holder din Instagram aktiv uden at du bruger tid på det

---

## Agent Fleet Oversigt

| Agent | Rolle | Primær brug | Model | Din pain point |
|-------|-------|-------------|-------|----------------|
| **James** | Coordinator | Altid (dig) | Sonnet | - |
| **Rene** | Builder | Implementation/deploy | Sonnet | Ensformigt kodning |
| **Rikke** | Communicator | Tilbud/emails/docs | Opus | Dokumentation (HADER) |
| **Anders** | Analyst | Research/planning | Opus → Kimi | Dyb research tid |
| **Bent** | Guardian | Security/review | Sonnet | De sidste 10% |
| **Sofia** | Content | Instagram/social | Opus | Social media tid |

**6 agenter total** (ikke 4 - du har brug for 6 baseret på dit liv)

---

## Workflow Eksempler (Dit Daglige Liv)

### Arbejde: Kunde tilbud
```
Du → James: "Lav tilbud til [kunde] på M365 migration"
James → Anders: Research pricing & scope
Anders → Rikke: Skriv professionelt tilbud
Rikke → Bent: Review for compliance/sikkerhed
Bent → Du: Klar til godkendelse
```

### Sideprojekt: Instagram post
```
Du → James: "Lav Instagram post om køkken før/efter"
James → Sofia: Analyser billede + skriv caption
Sofia → Du: "Her er 3 caption forslag + hashtags"
```

### Tech: Deploy ny feature
```
Du → James: "Deploy tjekbolig.ai SSO til Nordicway"
James → Rene: Implementer + deploy
Rene → Bent: Security review
Bent → Rene: Godkendt
Rene → Du: "Deployed + verified"
```

### Privat: Forex trading support (eksperimentel)
```
Du → James: "US Open om 10 min - hvad siger markedet?"
James → Anders: Check EURUSD/GBPUSD sentiment
Anders → Du: "Sentiment bullish, gap up expected"
(Du tager beslutning baseret på ORB strategi)
```

---

## Skills (Ikke Agenter)

**Monitoring** → Heartbeat script
**Webmon** → Uptime check skill
**Backup** → Cron skill
**Git** → Automation skill

---

## Cost Estimate (Per Måned)

**High usage scenario:**
- James (Sonnet): ~1M tokens = $3-15
- Rene (Sonnet): ~2M tokens = $6-30  
- Rikke (Opus): ~500k tokens = $3-15
- Anders (Opus → Kimi): ~1M tokens = $1.50-7.50 (gratis Kimi)
- Bent (Sonnet): ~500k tokens = $1.50-7.50
- Sofia (Opus): ~300k tokens = $1.80-9

**Total: ~$17-84/måned** (afhængig af brug)

**Vs nuværende ChatGPT Plus: $20/md** (som du dropper)

---

## Migration Plan

**Fase 1: Core (i dag)**
- ✅ Keep: James, Rene, Bent
- ✅ Merge: Anders (coordinator + researcher)
- ✅ Keep: Rikke (critical - du hader skrivearbejde!)

**Fase 2: Content (næste uge)**
- ➕ Add: Sofia (Instagram support)
- Test workflow med renovering posts

**Fase 3: Cleanup**
- ❌ Remove: Karl, Mette, Peter, Christian, Karen, Morten
- Convert til skills hvor relevant

**Fase 4: Optimize**
- Fine-tune models per agent
- Cost tracking per agent
- Usage analytics

---

## Spørgsmål til dig:

1. **6 agenter** (James, Rene, Rikke, Anders, Bent, Sofia) eller bare de 5 uden Sofia?
2. **Sofia (Content):** Er Instagram support værdifuldt nok til dedikeret agent?
3. **Forex support:** Skal Anders have adgang til finance data sources?
4. **Andet jeg har overset** i dit daglige liv?

---

*Designet specifikt til Danny's behov - ikke generisk agent fleet*
