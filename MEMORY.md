# MEMORY.md — Index

> Lightweight index. Detail lives in subdirectories. Drill down on demand.
> Max 3k tokens. Archive inactive items.

## Active Context
<!-- 2-3 files always loaded at session start -->
- `memory/context/setup.md` — current setup status & next steps

## People
| Who | File | Triggers | Notes |
|-----|------|----------|-------|
| Owner | `memory/people/owner.md` | user, human, preferences | Danish-speaking, WhatsApp primary |
| Danny | `memory/people/danny.md` | work, tech, family context | Techlead/NetIP, ADHD, 2 børn |

## Projects
| Project | File | Triggers | Status |
|---------|------|----------|--------|
| OpenClaw Setup | `memory/projects/openclaw-setup.md` | gateway, config, models | ✅ Complete |
| Security Baselines | `memory/projects/security-baselines.md` | OIB, Spectre, Intune | Active |

## Decisions
| Period | File |
|--------|------|
| 2026-02 | `memory/decisions/2026-02.md` |

## Preferences
- **Language:** Danish (direkte, ingen omsvøb)
- **Channel:** WhatsApp primary
- **Models:** Claude Sonnet (default), Opus (on-demand), Kimi K2.5 (fallback/background)
- **Cost strategy:** Cheap default with scoped fallbacks
- **Security:** File permissions locked, prompt injection defense enabled
- **Backups:** Daily at 3 AM UTC

## Danny's Profil — Key Facts
- **Navn:** Danny Lindholm, 32 (født 30. maj 1993)
- **Familie:** Kirstine (kone), Sigurd (4), Vilma (6)
- **Job:** Techlead/Seniorkonsulent NetIP (tidligere CTO Infrateam)
- **Bopæl:** 1921-hus på 220kvm + værksted, under renovering
- **Sideprojekter:** Forex trading (ORB strategi), Instagram @SlottetPaaMollegade
- **Personlighed:** Gul med rød/grøn, selvdiagnosticeret ADHD
- **Arbejdsstil:** Trives med variation, går død i ensformige opgaver
- **Kommunikation:** Direkte — "en spade er en spade"
- **Værdier:** Familie først, effektivitet, præcision, økonomisk mindset

## Setup Milestones (2026-02-10 til 2026-02-13)
✅ Model routing (Sonnet default, Kimi fallbacks)  
✅ Memory search (OpenAI embeddings, hybrid search)  
✅ Heartbeat (Kimi, rotating checks)  
✅ Todoist integration (task visibility)  
✅ GitHub integration (dspammails-rgb bot, DcollabwithBot org)  
✅ Security hardening (permissions, backups, git tracking)  
✅ Agent fleet (6+ agents med tool policies)  
✅ Brave Search med quota tracking  
✅ Tool policies per agent (korrekt implementeret med tool groups)

## Kritiske Lærdomme

### Tool Policies — Debug History (2026-02-13)
**Fejl:** `profile: "minimal"` + `allow` giver konflikt  
**Løsning:** Brug kun `allow` med tool groups, ingen profile  
**Tool groups:** `group:sessions`, `group:memory`, `group:fs`, `group:runtime`, `group:ui`  
**Test:** Spawn hver agent efter ændringer for at verificere

### Agent Review Process (2026-02-12)
**Pattern:** Worker agent → Verifier agent → Commit  
**Brugt til:** Spectre A/S vs OIB comparison (763 settings)  
**Resultat:** Fejlfri analyse med kritisk gennemgang

### Format Standardization (2026-02-12)
**Rule:** Check altid eksisterende format før nyt arbejde  
**Eksempel:** Spectre comparison måtte reformateres til ms-baseline format

## Agent Fleet (Feb 2026)
| Agent | Model | Tools | Permissions |
|-------|-------|-------|-------------|
| main | Sonnet 4.5 | sessions, memory, read | Spawning only |
| monitor | Kimi K2.5 | read, memory, web | Status checks |
| researcher | Kimi K2.5 | read, memory, web, image | Research |
| communicator | Opus 4.6 | read, memory, message | Professional writing |
| orchestrator | Sonnet 4.5 | runtime, fs, memory, sessions | CLI tools |
| coordinator | Opus 4.6 | read, memory, web, sessions | Planning |
| verifier | Sonnet 4.5 | read, memory, web | Quality check |

## Today's Key Decisions (2026-02-14)
- 11→4 agent migration complete
- Anti-vibe-slop plan implemented
- Context budget: 10k token max
- Security: API keys never in chat
- Cost: $50/mo hard limit

## Drill-Down Rules
1. Always load Active Context files at session start
2. Drill into people/ when conversation mentions a person
3. Drill into projects/ when conversation is about a specific project
4. Max 5 drill-downs at session start
5. Update this index with every detail file change — same commit, no exceptions
