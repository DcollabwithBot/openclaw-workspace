# Spawn Permissions Matrix (Legacy - 11 Agents)

**Status:** ARCHIVED - Replaced by simplified 4-agent matrix

This is the legacy spawn matrix with 11 agents. Kept for reference.

---

## Legacy Matrix (11 Agents)

| Spawner ↓ \ Spawnee → | monitor | researcher | communicator | reviewer | coordinator | orchestrator | verifier | security | complexity-guardian |
|-----------------------|:-------:|:----------:|:------------:|:--------:|:-----------:|:------------:|:--------:|:--------:|:-------------------:|
| **main (James)**      | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| **coordinator (Anders)** | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | ✅ | ✅ |
| **orchestrator (Rene)** | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ |

## Legend

- ✅ **Can spawn**
- ❌ **Cannot spawn**

## Key Rules (Legacy)

1. **Verifier (Peter) — MAIN ONLY**
   - Only `main` (James) can spawn verifier
   - Separation of duties principle
   - Verifier reviews work before final delivery

2. **Coordinator cannot spawn:**
   - Other coordinators (avoid recursion)
   - Verifier (reserved for main)

3. **Orchestrator cannot spawn:**
   - Coordinator (Rene reports to Anders, not reverse)
   - Orchestrator (no self-spawn)
   - Verifier (reserved for main)
   - Complexity-guardian (coordinator role)

## Archived Agents

These agents have been moved to skills or merged:
- monitor → monitoring skill
- researcher → research skill
- reviewer → Anders workflow
- verifier → Anders workflow
- security → security skill
- complexity-guardian → vibe-check skill

---
*Archived: 2026-02-14*
*See: spawn-matrix.md for current 4-agent matrix*
