# Project: OpenClaw Setup

## Timeline
- **2026-02-10**: Initial setup, WhatsApp linked, Kimi K2.5 added (NVIDIA + OpenRouter)

## Configuration
- Gateway: port 18789, bind=lan, password auth
- Providers: Anthropic (token), NVIDIA (API key), OpenRouter (API key)
- WhatsApp: selfChatMode, allowlist with owner number

## Fixes Applied
- Device pairing chicken-and-egg: manually edited paired.json to approve CLI device
- Gateway restart via SIGUSR1 (no systemd available)

## Lessons Learned
- "pairing required" on CLI = check /root/.openclaw/devices/pending.json
- NVIDIA free tier is slow (~37s) — OpenRouter is 6x faster for Kimi K2.5
- `models.mode: "merge"` keeps all providers available alongside defaults
