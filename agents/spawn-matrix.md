# Spawn Permissions Matrix

Who can spawn whom.

## Matrix

| Spawner ↓ \ Spawnee → | monitor | researcher | communicator | reviewer | coordinator | orchestrator | verifier | security | complexity-guardian |
|-----------------------|:-------:|:----------:|:------------:|:--------:|:-----------:|:------------:|:--------:|:--------:|:-------------------:|
| **main (James)**      | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| **coordinator (Anders)** | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | ✅ | ✅ |
| **orchestrator (Rene)** | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ |

## Legend

- ✅ **Can spawn**
- ❌ **Cannot spawn**

## Key Rules

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

## Typical Flows

### Simple Task
```
main → orchestrator → [EXECUTE]
```

### Complex Task
```
main → coordinator (plan) → orchestrator (execute) → [RETURN] → main
```

### With Verification
```
main → orchestrator → [EXECUTE] → main → verifier (review) → [DONE]
```

### Research Task
```
main → coordinator → researcher → [RETURN] → coordinator → [RETURN] → main
```
