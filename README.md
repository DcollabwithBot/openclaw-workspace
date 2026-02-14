# OpenClaw Workspace - Danny Lindholm

**Setup Date:** 2026-02-14  
**Architecture:** 4 Agents + 5 Skills  
**Monthly Budget:** $50

---

## Quick Reference

### The 4 Agents

| Agent | Role | Model | When to Use |
|-------|------|-------|-------------|
| **James** | Main/Coordinator | Sonnet 4.5 | Everything - your interface |
| **Rene** | Builder | Sonnet 4.5 | Code, deploy, implement |
| **Rikke** | Communicator | Opus 4.6 | Writing, emails, Instagram |
| **Anders** | Analyst | Sonnet 4.5 | Research, planning, verification |

### The 5 Skills (Free!)

| Skill | Purpose | Usage |
|-------|---------|-------|
| **security** | Security scans, credential check | `./skills/security/security-scan.sh [path]` |
| **vibe-check** | Code quality detector | `./skills/vibe-check/vibe-check.sh [path]` |
| **completeness** | "Last 10%" guardian | `./skills/completeness/check.sh [project]` |
| **research** | Web research workflow | See `skills/research/SKILL.md` |
| **instagram** | Caption guidelines | See `skills/instagram/SKILL.md` |

---

## Key Commands

### Run skill:
```bash
cd /root/.openclaw/workspace/skills/security
./security-scan.sh /path/to/check --level basic
```

### Spawn agent:
```
sessions_spawn({
  agentId: "orchestrator",
  task: "Implement feature X",
  label: "feature-x"
})
```

### Memory:
- Before new task: `/compact`
- After task: Commit to `memory/YYYY-MM-DD.md`

---

## Cost Optimization

- **Heartbeat:** Kimi (NVIDIA, free)
- **Main chat:** Sonnet 4.5 ($3/$15 per M)
- **Writing:** Opus 4.6 ($5/$25 per M) 
- **Skills:** $0 (bash scripts)

**Estimated monthly:** $13-40 (vs $60-100 before migration)

---

## File Structure

```
workspace/
├── AGENTS.md           # Agent configuration
├── SOUL.md            # James' personality
├── USER.md            # Danny's profile
├── HEARTBEAT.md       # Proactive checks
├── MEMORY.md          # Long-term memory index
├── skills/            # 5 skills (bash scripts)
│   ├── security/
│   ├── vibe-check/
│   ├── completeness/
│   ├── research/
│   └── instagram/
├── memory/            # Daily files
└── projects/          # Project folders
```

---

## Workflow Examples

### Deploy new feature:
```
Danny: "Deploy tjekbolig.ai SSO"
James → Rene: Implement
Rene → Security skill: Scan
Rene → Vibe-check skill: Quality check
Rene → Completeness skill: Verify done
Rene: Deploy
James: Report done
```

### Write Instagram post:
```
Danny: "Lav caption til renovering billede"
James → Rikke: Generate caption
Rikke: Follow instagram skill guidelines
```

---

## Security

- API keys in `.env` (gitignored)
- Credential rotation tracked (90 days)
- Tool policies: James only spawns, Rene implements
- Budget limits: $50/month hard cap

---

## Migration History

See `FINAL_SUMMARY.md` for full details of 11→4 agent migration.

---

*Last updated: 2026-02-14*
