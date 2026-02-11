#!/bin/bash
# smart-search.sh - Brave search with Perplexity fallback and usage tracking
# Usage: smart-search.sh "query" [count]

QUERY="${1:-}"
COUNT="${2:-5}"
USAGE_FILE="/root/.openclaw/workspace/memory/brave-usage.json"
LOG_FILE="/root/.openclaw/workspace/memory/search-usage.log"

# Check if we need to reset monthly counter
check_monthly_reset() {
    local current_month=$(date +%Y-%m)
    local file_month=$(jq -r '.brave.currentMonth' "$USAGE_FILE" 2>/dev/null || echo "none")
    
    if [[ "$current_month" != "$file_month" ]]; then
        echo "{
  \"brave\": {
    \"monthlyLimit\": 2000,
    \"warningThreshold\": 1990,
    \"currentMonth\": \"$current_month\",
    \"requestCount\": 0,
    \"lastUpdated\": \"$(date -Iseconds)Z\"
  }
}" > "$USAGE_FILE"
        echo "[$(date -Iseconds)] Monthly reset performed for $current_month" >> "$LOG_FILE"
    fi
}

# Get current usage
check_monthly_reset
BRAVE_COUNT=$(jq -r '.brave.requestCount' "$USAGE_FILE")
WARNING_THRESHOLD=$(jq -r '.brave.warningThreshold' "$USAGE_FILE")

# Decide which provider to use
if [[ "$BRAVE_COUNT" -ge "$WARNING_THRESHOLD" ]]; then
    PROVIDER="perplexity"
    echo "[$(date -Iseconds)] Brave quota near limit ($BRAVE_COUNT/$WARNING_THRESHOLD), switching to Perplexity" >> "$LOG_FILE"
else
    PROVIDER="brave"
    # Increment counter
    NEW_COUNT=$((BRAVE_COUNT + 1))
    jq --arg count "$NEW_COUNT" --arg date "$(date -Iseconds)Z" \
       '.brave.requestCount = ($count | tonumber) | .brave.lastUpdated = $date' \
       "$USAGE_FILE" > "${USAGE_FILE}.tmp" && mv "${USAGE_FILE}.tmp" "$USAGE_FILE"
    echo "[$(date -Iseconds)] Brave search #${NEW_COUNT}/2000: $QUERY" >> "$LOG_FILE"
fi

# Output status
OUTPUT=$(cat <<EOF
{
  "provider": "$PROVIDER",
  "brave_remaining": $((2000 - NEW_COUNT)),
  "query": "$QUERY"
}
EOF
)

echo "$OUTPUT"