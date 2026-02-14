#!/bin/bash
# pattern-matcher.sh - Scans memory files for failure patterns and updates behavior-corrections.json
# Usage: ./pattern-matcher.sh
# Exit codes: 0=OK (no new patterns), 1=new patterns found (triggers auto-patcher)

set -e

WORKSPACE="/root/.openclaw/workspace"
MEMORY_DIR="$WORKSPACE/memory"
JSON_FILE="$MEMORY_DIR/behavior-corrections.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ensure JSON file exists
if [[ ! -f "$JSON_FILE" ]]; then
    echo '{"patterns":[],"lastScan":""}' > "$JSON_FILE"
fi

# Get current timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Find memory files from last 7 days
echo "Scanning memory files..."
FOUND_PATTERNS=0
NEW_PATTERNS_JSON=""

# Get list of recent memory files (last 7 days)
MEMORY_FILES=$(find "$MEMORY_DIR" -name "*.md" -type f -mtime -7 2>/dev/null | sort)

if [[ -z "$MEMORY_FILES" ]]; then
    echo "No recent memory files found"
    # Update lastScan timestamp even if no files
    jq --arg ts "$TIMESTAMP" '.lastScan = $ts' "$JSON_FILE" > "$JSON_FILE.tmp" && mv "$JSON_FILE.tmp" "$JSON_FILE"
    exit 0
fi

# Pattern 1: Tool policy conflicts (profile/minimal + allow conflicts)
echo "Checking for tool policy conflicts..."
TOOL_CONFLICTS=$(echo "$MEMORY_FILES" | xargs grep -h -E "(profile.*minimal.*allow|allow.*profile.*minimal|tool.*policy.*conflict)" 2>/dev/null | head -5)
if [[ -n "$TOOL_CONFLICTS" ]]; then
    echo "  Found tool policy conflict pattern"
    FOUND_PATTERNS=1
    PATTERN_ID="tool-policy-conflict-$(date +%s)"
    # Extract context around the match
    CONTEXT=$(echo "$MEMORY_FILES" | xargs grep -h -B1 -A1 -E "profile.*minimal" 2>/dev/null | head -10 | tr '\n' ' ' | sed 's/"/\\"/g')
    NEW_PATTERNS_JSON="$NEW_PATTERNS_JSON{\"id\":\"$PATTERN_ID\",\"type\":\"tool-policy-conflict\",\"description\":\"Tool policy profile/allow conflict detected\",\"context\":\"$CONTEXT\",\"timestamp\":\"$TIMESTAMP\",\"autoFix\":true},"
fi

# Pattern 2: Deployment credential issues  
echo "Checking for deployment credential issues..."
CRED_ISSUES=$(echo "$MEMORY_FILES" | xargs grep -h -E "(deployment.*credential|credential.*missing|nordicway.*cred)" -i 2>/dev/null | head -5)
if [[ -n "$CRED_ISSUES" ]]; then
    echo "  Found deployment credential pattern"
    FOUND_PATTERNS=1
    PATTERN_ID="cred-issue-$(date +%s)"
    CONTEXT=$(echo "$MEMORY_FILES" | xargs grep -h -B1 -A1 -E "deployment.*credential|nordicway" -i 2>/dev/null | head -10 | tr '\n' ' ' | sed 's/"/\\"/g')
    NEW_PATTERNS_JSON="$NEW_PATTERNS_JSON{\"id\":\"$PATTERN_ID\",\"type\":\"deployment-credential\",\"description\":\"Deployment credential management issue\",\"context\":\"$CONTEXT\",\"timestamp\":\"$TIMESTAMP\",\"autoFix\":true},"
fi

# Pattern 3: Danish workflow patterns (sidste 10%)
echo "Checking for Danish workflow patterns..."
DANISH_PATTERN=$(echo "$MEMORY_FILES" | xargs grep -h -E "sidste.*10%|popcorn.*hjerne" -i 2>/dev/null | head -3)
if [[ -n "$DANISH_PATTERN" ]]; then
    echo "  Found Danish workflow pattern"
    FOUND_PATTERNS=1
    PATTERN_ID="danish-workflow-$(date +%s)"
    CONTEXT=$(echo "$DANISH_PATTERN" | head -3 | tr '\n' ' ' | sed 's/"/\\"/g')
    NEW_PATTERNS_JSON="$NEW_PATTERNS_JSON{\"id\":\"$PATTERN_ID\",\"type\":\"danish-workflow\",\"description\":\"Danish workflow pattern (sidste 10%)\",\"context\":\"$CONTEXT\",\"timestamp\":\"$TIMESTAMP\",\"autoFix\":false},"
fi

# Pattern 4: Context handling errors (where is the code?)
echo "Checking for context handling errors..."
CONTEXT_ERRORS=$(echo "$MEMORY_FILES" | xargs grep -h -E "(hvor.*koden|where.*code|context.*handling.*error|code.*location)" -i 2>/dev/null | head -5)
if [[ -n "$CONTEXT_ERRORS" ]]; then
    echo "  Found context handling error pattern"
    FOUND_PATTERNS=1
    PATTERN_ID="context-error-$(date +%s)"
    CONTEXT=$(echo "$MEMORY_FILES" | xargs grep -h -B1 -A2 -E "kode-lokalitet|code.*location" -i 2>/dev/null | head -15 | tr '\n' ' ' | sed 's/"/\\"/g')
    NEW_PATTERNS_JSON="$NEW_PATTERNS_JSON{\"id\":\"$PATTERN_ID\",\"type\":\"context-handling\",\"description\":\"Code location/context reporting issue\",\"context\":\"$CONTEXT\",\"timestamp\":\"$TIMESTAMP\",\"autoFix\":true},"
fi

# Pattern 5: Rate limit / fallback issues
echo "Checking for rate limit patterns..."
RATE_LIMITS=$(echo "$MEMORY_FILES" | xargs grep -h -E "(rate.*limit|fallback|timeout|kimi.*fejlede)" -i 2>/dev/null | head -5)
if [[ -n "$RATE_LIMITS" ]]; then
    echo "  Found rate limit pattern"
    FOUND_PATTERNS=1
    PATTERN_ID="rate-limit-$(date +%s)"
    CONTEXT=$(echo "$RATE_LIMITS" | head -3 | tr '\n' ' ' | sed 's/"/\\"/g')
    NEW_PATTERNS_JSON="$NEW_PATTERNS_JSON{\"id\":\"$PATTERN_ID\",\"type\":\"rate-limit\",\"description\":\"Rate limiting or fallback issue\",\"context\":\"$CONTEXT\",\"timestamp\":\"$TIMESTAMP\",\"autoFix\":false},"
fi

# Update JSON file with new patterns and timestamp
if [[ $FOUND_PATTERNS -eq 1 ]]; then
    echo "Updating behavior-corrections.json..."
    # Remove trailing comma and wrap in array
    NEW_PATTERNS_JSON="[${NEW_PATTERNS_JSON%,}]"
    
    # Use jq to merge new patterns
    jq --argjson newPatterns "$NEW_PATTERNS_JSON" --arg ts "$TIMESTAMP" \
       '.patterns += $newPatterns | .lastScan = $ts' "$JSON_FILE" > "$JSON_FILE.tmp" && mv "$JSON_FILE.tmp" "$JSON_FILE"
    
    echo "Found $FOUND_PATTERNS new pattern(s). JSON updated."
    echo "Run auto-patcher.sh to apply fixes."
    exit 1
else
    echo "No new patterns found."
    # Just update timestamp
    jq --arg ts "$TIMESTAMP" '.lastScan = $ts' "$JSON_FILE" > "$JSON_FILE.tmp" && mv "$JSON_FILE.tmp" "$JSON_FILE"
    exit 0
fi
