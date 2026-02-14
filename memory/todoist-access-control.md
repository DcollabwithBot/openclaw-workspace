# Todoist API Access Control

**Dato:** 2026-02-14
**Agent:** orchestrator (subagent)

## API Token
- **Location:** `/root/.openclaw/.env`
- **Key:** `TODOIST_API_KEY`
- **Status:** ✅ Tilføjet og verificeret

## Access Matrix

| Agent | Rolle | Todoist Adgang | Begrundelse |
|-------|-------|----------------|-------------|
| main (James) | Default assistant | ✅ | Owner - alle operationer |
| coordinator (Anders) | PM/Planlægning | ✅ | Opretter tasks, planlægger |
| orchestrator (Rene) | Udviklingsopgaver | ✅ | Implementerer fra tasks |
| monitor (Morten) | Lightweight checks | ❌ | Kun uptime monitoring |
| researcher | Web research | ❌ | Ingen PM funktion |
| communicator | Professional writing | ❌ | Ingen task management |
| verifier (Peter) | Review/QA | ❌ | Kun review, ikke planning |
| security (Bent) | Security tasks | ❌ | Fokus på sikkerhed |

## Oprettede Tasks

1. **ID: `6g2PV3M39vRHC95f`**
   - P1: Tilføj expiry metadata til MEMORY.md
   - Labels: @backlog, @quick-win, @memory-improvement
   - Due: 2026-02-14

2. **ID: `6g2PV3P7hjWJX6Wf`**
   - P2: Implementer "proposal → review → merge" workflow
   - Labels: @backlog, @security, @memory-improvement
   - Due: 2026-02-28

3. **ID: `6g2PV3Q86P6xc3Xf`**
   - P2: Research Mem0 self-hosted
   - Labels: @backlog, @research, @memory-improvement
   - Due: 2026-03-01

## Test Result
- API Connection: ✅ OK
- Project: OpenClaw Tasks (6fxmgmw8MGgWmxw7)
- Tasks Created: 3/3 ✅
