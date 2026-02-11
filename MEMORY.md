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

## Projects
| Project | File | Triggers | Status |
|---------|------|----------|--------|
| OpenClaw Setup | `memory/projects/openclaw-setup.md` | gateway, config, models, providers | Active |

## Decisions
| Period | File |
|--------|------|
| 2026-02 | `memory/decisions/2026-02.md` |

## Preferences
- Language: Danish (casual)
- Channel: WhatsApp primary
- Models: **Claude Sonnet** (default), Opus (on-demand), Kimi K2.5 (fallback/background)
- Cost strategy: Cheap default with scoped fallbacks
- Security: File permissions locked, prompt injection defense enabled
- Backups: Daily at 3 AM UTC

## Setup Milestones (2026-02-11)
✅ Model routing (Sonnet default, Kimi fallbacks)  
✅ Memory search (OpenAI embeddings, hybrid search)  
✅ Heartbeat (Kimi, rotating checks)  
✅ Todoist integration (task visibility)  
✅ GitHub integration (dspammails-rgb bot, DcollabwithBot org)  
✅ Security hardening (permissions, backups, git tracking)  
✅ Agent fleet (6 specialized agents with spawn permissions)

## Drill-Down Rules
1. Always load Active Context files at session start
2. Drill into people/ when conversation mentions a person
3. Drill into projects/ when conversation is about a specific project
4. Max 5 drill-downs at session start
5. Update this index with every detail file change — same commit, no exceptions
