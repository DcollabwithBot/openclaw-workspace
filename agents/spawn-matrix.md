# Spawn Permissions Matrix

Who can spawn whom.

## Current Fleet (4 Agents)

| Agent | ID (Name) | ID (Role) | Role | Spawned By |
|-------|-----------|-----------|------|------------|
| James | `james` | `main` | Main assistant | (root) |
| Rene | `rene` | `orchestrator` | Builder/implementation | main, coordinator |
| Rikke | `rikke` | `communicator` | Communication/writing | main |
| Anders | `anders` | `coordinator` | Planning/PM/analysis | main |

## Agent ID Mappings

Each agent supports BOTH name-based and role-based IDs:

| File | Name ID | Role ID |
|------|---------|---------|
| `james.md` | `james` | `main` |
| `rene.md` | `rene` | `orchestrator` |
| `rikke.md` | `rikke` | `communicator` |
| `anders.md` | `anders` | `coordinator` |

**Example spawns (both work):**
- `sessions_spawn agentId=rene` → Rene
- `sessions_spawn agentId=orchestrator` → Rene
- `sessions_spawn agentId=rikke` → Rikke
- `sessions_spawn agentId=communicator` → Rikke
- `sessions_spawn agentId=anders` → Anders
- `sessions_spawn agentId=coordinator` → Anders

## Matrix

| Spawner ↓ \ Spawnee → | communicator | coordinator | orchestrator |
|-----------------------|:------------:|:-----------:|:------------:|
| **main (James)**      | ✅ | ✅ | ✅ |
| **coordinator (Anders)** | ❌ | ❌ | ✅ |
| **orchestrator (Rene)** | ❌ | ❌ | ❌ |

## Legend
- ✅ **Can spawn**
- ❌ **Cannot spawn**

## Key Rules

1. **Main (James)** can spawn any agent
2. **Coordinator (Anders)** can only spawn orchestrator for execution
3. **Orchestrator (Rene)** cannot spawn other agents (focus on building)

## Typical Flows

### Simple Task
```
main → orchestrator → [EXECUTE] → main
```

### Complex Task
```
main → coordinator (plan) → orchestrator (execute) → [RETURN] → main
```

### Communication Task
```
main → communicator → [EXECUTE] → main
```

---

## Archive

Previous spawn matrix with 11 agents archived at: [agents/archive/spawn-matrix-legacy.md](./archive/spawn-matrix-legacy.md)
