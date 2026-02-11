#!/bin/bash
# reset-brave-counter.sh - Monthly reset of Brave usage counter
# Run via cron on 1st of each month

USAGE_FILE="/root/.openclaw/workspace/memory/brave-usage.json"
LOG_FILE="/root/.openclaw/workspace/memory/search-usage.log"
CURRENT_MONTH=$(date +%Y-%m)

echo "{
  \"brave\": {
    \"monthlyLimit\": 2000,
    \"warningThreshold\": 1990,
    \"currentMonth\": \"$CURRENT_MONTH\",
    \"requestCount\": 0,
    \"lastUpdated\": \"$(date -Iseconds)Z\"
  }
}" > "$USAGE_FILE"

echo "[$(date -Iseconds)] Monthly reset performed for $CURRENT_MONTH" >> "$LOG_FILE"
echo "Brave counter reset for $CURRENT_MONTH"