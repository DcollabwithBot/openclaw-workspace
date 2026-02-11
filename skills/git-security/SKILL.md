# Git Security Skill

Sikkerhedsscanning af Git repos for secrets, credentials og API keys før commit/push.

## Quick Start

```bash
# Pre-commit hook (automatisk)
~/.openclaw/workspace/skills/git-security/scripts/install-hooks.sh

# Manuelt scan
~/.openclaw/workspace/skills/git-security/scripts/scan.sh

# Pre-push check
~/.openclaw/workspace/skills/git-security/scripts/pre-push.sh
```

## Installation

### 1. Installer hooks i et repo:
```bash
cd /path/to/repo
~/.openclaw/workspace/skills/git-security/scripts/install-hooks.sh
```

### 2. Eller globalt for alle nye repos:
```bash
~/.openclaw/workspace/skills/git-security/scripts/install-hooks.sh --global
```

## Kommandoer

| Kommando | Beskrivelse |
|----------|-------------|
| `scan` | Scanner for secrets i aktuelle repo |
| `scan /path/to/repo` | Scanner specifikt repo |
| `pre-commit` | Køres automatisk før hver commit |
| `pre-push` | Køres automatisk før hver push |
| `install-hooks` | Installerer hooks i repo |
| `check-staged` | Tjekker kun staged files |

## Detekterer

- 🔑 API keys (OpenAI, AWS, Azure, etc.)
- 🪙 Tokens (Bearer, JWT, GitHub PAT)
- 🔐 Private keys (SSH, RSA, EC)
- 📁 .env filer
- 🎭 Passwords i kode
- 🚫 Credentials paths

## Ignorer falske positiver

Tilføj til `.gitsecurityignore`:
```
# Hele filer
src/config/example.env

# Specifikke linjer (via kommentar i koden)
const API_KEY = "test-key-123"; // gitsecurity:ignore
```

## Agent

Spawn security agent til detaljeret review:
```bash
# Scan og få rapport
~/.openclaw/workspace/skills/git-security/scripts/scan.sh --report

# Eller spawn agent
sessions_spawn "Git security scan of /path/to/repo"
```
