# Smart Search Skill

Smart web search with automatic provider fallback and quota tracking.

## Problem Solved

- Brave Search: 2.000 requests/måned (gratis)
- Perplexity via OpenRouter: betalt, men altid tilgængelig
- Automatisk skift når Brave nærmer sig grænsen (1.990 requests)
- Månedlig reset af tæller

## Usage

```bash
# Via skill script
~/.openclaw/workspace/skills/smart-search/smart-search.sh "din søgning" 5

# Direct tool use ( tracked )
# web_search tool automatically uses this logic
```

## Tracking

- Usage file: `memory/brave-usage.json`
- Log file: `memory/search-usage.log`
- Monthly reset: 1st of each month via cron

## Fallback Logic

| Brave Usage | Action |
|-------------|--------|
| < 1.990 | Use Brave Search |
| >= 1.990 | Switch to Perplexity |
| New month | Reset counter, use Brave |

## Files

- `smart-search.sh` - Main script with tracking logic
- `reset-brave-counter.sh` - Monthly reset cron job

## Configuration

No config needed - reads from:
- `BRAVE_API_KEY` (environment)
- `OPENROUTER_API_KEY` (already configured)

## Cost

- Brave: $0 (2.000/måned)
- Perplexity via OpenRouter: ~$0.005-0.02 per search