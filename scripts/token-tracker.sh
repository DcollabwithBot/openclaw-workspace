#!/bin/bash
# Token Tracker - Calculate daily/weekly usage from cost CSV
# Usage: ./token-tracker.sh
# Exit 0 = under limit, Exit 1 = approaching $50 limit

COSTS_DIR="/root/.openclaw/workspace/memory/costs"
LIMIT=50.00
WARNING_THRESHOLD=40.00

# Get current month CSV
CURRENT_MONTH=$(date +%Y-%m)
CSV_FILE="$COSTS_DIR/${CURRENT_MONTH}.csv"

if [ ! -f "$CSV_FILE" ]; then
  echo "No cost data for $CURRENT_MONTH"
  exit 0
fi

# Calculate totals using awk
totals=$(awk -F',' 'NR>1 {
  tokens_in += $4
  tokens_out += $5
  cost += $6
} END {
  printf "%.0f|%.0f|%.4f", tokens_in, tokens_out, cost
}' "$CSV_FILE")

TOKENS_IN=$(echo "$totals" | cut -d'|' -f1)
TOKENS_OUT=$(echo "$totals" | cut -d'|' -f2)
COST=$(echo "$totals" | cut -d'|' -f3)

# Weekly calculation (last 7 days)
WEEK_AGO=$(date -d '7 days ago' +%Y-%m-%d 2>/dev/null || date -v-7d +%Y-%m-%d)
weekly_cost=$(awk -F',' -v cutoff="$WEEK_AGO" 'NR>1 && substr($1,1,10) >= cutoff {
  cost += $6
} END { printf "%.4f", cost }' "$CSV_FILE")

# Today
today=$(date +%Y-%m-%d)
daily_cost=$(awk -F',' -v d="$today" 'NR>1 && substr($1,1,10) == d {
  cost += $6
} END { printf "%.4f", cost }' "$CSV_FILE")

echo "════════════════════════════════════════"
echo "         TOKEN USAGE SUMMARY"
echo "════════════════════════════════════════"
echo "Period: $CURRENT_MONTH"
echo "────────────────────────────────────────"
echo "Daily (today):   \$${daily_cost}"
echo "Weekly (7d):     \$${weekly_cost}"
echo "Monthly:         \$${COST}"
echo "────────────────────────────────────────"
echo "Tokens In:       ${TOKENS_IN}"
echo "Tokens Out:      ${TOKENS_OUT}"
echo "Combined:        $((TOKENS_IN + TOKENS_OUT))"
echo "────────────────────────────────────────"

# Check limit
if awk "BEGIN {exit !($COST >= $LIMIT)}"; then
  echo "🚨 ALERT: Monthly cost exceeds \$${LIMIT}!"
  exit 1
elif awk "BEGIN {exit !($COST >= $WARNING_THRESHOLD)}"; then
  echo "⚠️  WARNING: Approaching \$${LIMIT} limit (${COST})"
  exit 1
else
  echo "✅ Under budget: \$${COST} / \$${LIMIT}"
  exit 0
fi
