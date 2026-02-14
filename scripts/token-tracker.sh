#!/bin/bash
# Track current session token usage
# Usage: bash scripts/token-tracker.sh [SESSION_KEY]

SESSION_KEY="${1:-agent:main:main}"
echo "Checking token usage for session: $SESSION_KEY"
echo "=========================================="

# Get session status and extract token info
STATUS_OUTPUT=$(openclaw sessions status "$SESSION_KEY" 2>&1)

if [ $? -ne 0 ]; then
    echo "Error: Cannot read session status"
    echo "Output: $STATUS_OUTPUT"
    exit 1
fi

# Extract token information
echo "$STATUS_OUTPUT" | grep -E "(Tokens|Model|Age)" || echo "No token data found"

# Show context percentage for quick reference
echo ""
echo "Context Thresholds:"
echo "  🟢 < 5k tokens: Safe"
echo "  🟡 5-7k tokens: Monitor"
echo "  🟠 7-8k tokens: Consider /compact"
echo "  🔴 > 8k tokens: FORCE /compact NOW"
