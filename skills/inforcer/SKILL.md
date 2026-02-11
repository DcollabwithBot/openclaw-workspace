# Inforcer Skill

Hent data fra Inforcer API (Microsoft 365 policy management for MSPs).

## Quick Start

```bash
# Hent alle tenants
~/.openclaw/workspace/skills/inforcer/scripts/inforcer.sh tenants

# Hent politikker for en tenant
~/.openclaw/workspace/skills/inforcer/scripts/inforcer.sh policies <tenant-id>

# Hent compliance status
~/.openclaw/workspace/skills/inforcer/scripts/inforcer.sh compliance <tenant-id>

# Hent backup status
~/.openclaw/workspace/skills/inforcer/scripts/inforcer.sh backups <tenant-id>

# Hent alerts
~/.openclaw/workspace/skills/inforcer/scripts/inforcer.sh alerts
```

## Installation

1. Gem API nøgle i `~/.openclaw/credentials/inforcer-token`:
```bash
echo "4422a7187e5942558cb8b4abc9c231d4" > ~/.openclaw/credentials/inforcer-token
chmod 600 ~/.openclaw/credentials/inforcer-token
```

## Commands

| Command | Beskrivelse |
|---------|-------------|
| `tenants` | List alle tilsluttede M365 tenants |
| `policies <tenant-id>` | Hent politikker for specifik tenant |
| `compliance <tenant-id>` | Hent compliance status |
| `backups <tenant-id>` | Hent backup konfiguration og status |
| `alerts` | Hent aktive alerts/notifikationer |
| `audit <tenant-id>` | Hent audit log |
| `status` | API health check |

## API Reference

Base URL: `https://api.inforcer.com/v1` (eller tilpas med `INFORCER_API_URL` env var)
Authentication: Bearer token i header

Se `references/` for detaljeret API dokumentation.

**Bemærk:** API endpoint skal måske opdateres når Inforcer dokumentationen er tilgængelig. 
Kørs `inforcer.sh status` for at teste forbindelsen.
