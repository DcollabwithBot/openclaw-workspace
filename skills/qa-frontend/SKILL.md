# QA & Frontend Development Skills

## qa-tester.sh
Website testing med Playwright.

**Usage:**
```bash
# Visual/screenshot test
./skills/qa-tester/qa-tester.sh https://example.com visual

# Lighthouse performance
./skills/qa-tester/qa-tester.sh https://example.com lighthouse

# Check broken links
./skills/qa-tester/qa-tester.sh https://example.com links
```

## frontend-scaffold.sh
Scaffold nye frontend projekter.

**Usage:**
```bash
# Next.js + TypeScript + Tailwind
./skills/frontend-dev/frontend-scaffold.sh my-app nextjs

# React + Vite + Tailwind  
./skills/frontend-dev/frontend-scaffold.sh my-app react
```

## Agent Prompts
Brug disse agenter til kodearbejde:
- `/spawn agent=orchestrator task="..."` — CLI tool management, kodning
- `/spawn agent=communicator task="..."` — Dokumentation, PR beskrivelser