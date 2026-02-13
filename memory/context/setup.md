# Active Context: Setup

## Current State
- Fresh OpenClaw install (2026-02-10) on Linux Proxmox VE (x64)
- Gateway: port 18789, bind=lan, auth=password
- WhatsApp: linked to +4530627684, working
- BOOTSTRAP.md still exists — intro conversation not done yet

## Models Configured (updated 2026-02-11)
- **Claude Sonnet 4.5** — default primary (alias "Sonnet"), cheaper than Opus
- **Claude Opus 4.6** — on-demand only (alias "Opus"), use via /model
- **Kimi K2.5 (OpenRouter)** — alias "Kimi K2.5", fallback #1, subagents default
- **Kimi K2.5 (NVIDIA)** — alias "Kimi NVIDIA", fallback #2 (free but slow)

## Model Routing Strategy
- Main session: Sonnet (default) → Kimi OpenRouter → Kimi NVIDIA
- Subagents: Kimi K2.5 (OpenRouter) — cheap background work
- Opus: available on-demand for heavy reasoning tasks

## Config from Runbook (applied 2026-02-10)
- **Context Pruning**: cache-ttl, 6h TTL, keep last 3 assistant messages
- **Compaction**: memory flush at 40k tokens → memory/YYYY-MM-DD.md
- **Log Redaction**: redactSensitive = "tools"
- **File Permissions**: locked down (~/.openclaw 700, config 600)

## Known Issues
- ~~Memory search plugin unavailable~~ ✅ Fixed (OpenAI API key configured 2026-02-11)
- No systemd user services (container env) — gateway runs in foreground
- CLI device pairing was manually fixed (edited paired.json directly)
- Gateway bound to "lan" (0.0.0.0) — runbook recommends "loopback", but we need LAN access

## Runbook Implementation Status (2026-02-11)
- [x] Model routing (Sonnet default, Kimi fallbacks, Opus on-demand) ✅
- [x] Memory search (OpenAI text-embedding-3-small, hybrid search) ✅
- [x] Session memory indexing (experimental) ✅
- [x] Heartbeat (Kimi K2.5, every 30min, rotating checks) ✅
- [x] Internal hooks (command-logger, boot-md, session-memory) ✅
- [x] Named agents — **All 6 complete** ✅
  - monitor, researcher, communicator, orchestrator, coordinator + main
- [x] Context pruning & compaction ✅
- [x] Concurrency limits ✅
- [x] Latency optimization (block streaming, debouncing, thinking off) ✅
- [x] Todoist task tracking (visibility into agent work) ✅
- [x] GitHub integration (dspammails-rgb bot, DcollabwithBot org) ✅
- [x] Security hardening (permissions, audit, git tracking, backups) ✅
- [x] Quota monitoring skill ✅

## Next Steps
- [x] Complete bootstrap conversation (name, identity, vibe) ✅

## Post-Reddit Research Todo (2026-02-13)

### Høj Prioritet
- [ ] **Git-track ~/.openclaw config** - Setup git repo i ~/.openclaw for rollback
- [ ] **Rotating heartbeat** - Erstat fixed 30min med "most overdue" rotation
- [ ] **Audit USER.md** - Omskriv til "profile + contract" format (ikke dagbog)

### Medium Prioritet
- [ ] **Tilføj Gemini Flash 3** - Som fallback efter Kimi K2.5 (via OpenRouter)
- [ ] **Tilføj GLM-5** - Som yderligere billig model at teste (via OpenRouter)
- [ ] **Discord integration** - Research Discord som erstatning/supplement til webchat
- [ ] **Telegram integration** - Research Telegram vs Discord, vælg den bedste

### Lav Prioritet
- [ ] **Test sandbox/container isolation** - Verify Proxmox container actually isolates agent

## Security Hardening Backlog (2026-02-13)
- [x] **Explicit tool policies per agent** - ✅ Implementeret korrekt med tool groups
- [x] **Model fallback observability** - ✅ Tilføjet til HEARTBEAT.md
- [x] **Worker→Verifier pattern** - ✅ Verifier agent tilføjet
- [ ] **Test sandbox/container isolation** - Verify Proxmox container actually isolates agent (escape testing)
