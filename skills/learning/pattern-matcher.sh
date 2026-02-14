#!/bin/bash
# pattern-matcher.sh - Automated pattern learning from memory files
# Scans last 7 days of memory/*.md for failure patterns
# Updates behavior-corrections.json with detected patterns
# Exit 1 if new patterns found (alerts heartbeat)

set -e

WORKSPACE="/root/.openclaw/workspace"
MEMORY_DIR="$WORKSPACE/memory"
CORRECTIONS_FILE="$MEMORY_DIR/behavior-corrections.json"
PATTERNS_FILE="$WORKSPACE/skills/learning/patterns.conf"

# Ensure corrections file exists
if [[ ! -f "$CORRECTIONS_FILE" ]]; then
    echo '{"patterns":[],"lastScan":""}' > "$CORRECTIONS_FILE"
fi

# Define patterns to detect: "regex|target_file|section|description"
# Format: regex pattern | target file to patch | section hint | human description
PATTERNS=(
    "profile.*minimal.*allow.*conflict|AGENTS.md|tool-policies|Profile minimal allow conflicts detected"
    "deployment.*credential|PROJECT.md|requirements|Deployment credential handling needed"
    "sidste.*10%|AGENTS.md|workflows|Danish 'sidste 10%' workflow pattern detected"
)

NEW_PATTERNS_FOUND=0
CURRENT_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Get memory files from last 7 days
find "$MEMORY_DIR" -name "*.md" -mtime -7 -type f | while read -r file; do
    for pattern_def in "${PATTERNS[@]}"; do
        IFS='|' read -r regex target section description <<< "$pattern_def"
        
        # Search for pattern in file (case insensitive)
        if grep -qiE "$regex" "$file" 2>/dev/null; then
            # Check if this pattern already recorded
            if ! grep -q "$description" "$CORRECTIONS_FILE" 2>/dev/null; then
                # Add new pattern to JSON
                tmp=$(mktemp)
                jq --arg desc "$description" \
                   --arg target "$target" \
                   --arg section "$section" \
                   --arg regex "$regex" \
                   --arg file "$file" \
                   --arg found "$(date -r "$file" +"%Y-%m-%d")" \
                   '.patterns += [{"description":$desc,"target":$target,"section":$section,"regex":$regex,"source":$file,"found":$found,"applied":false}]' \
                   "$CORRECTIONS_FILE" > "$tmp" && mv "$tmp" "$CORRECTIONS_FILE"
                
                echo "[LEARN] New pattern detected: $description"
                NEW_PATTERNS_FOUND=1
            fi
        fi
    done
done

# Update lastScan timestamp
tmp=$(mktemp)
jq --arg time "$CURRENT_TIME" '.lastScan = $time' "$CORRECTIONS_FILE" > "$tmp" && mv "$tmp" "$CORRECTIONS_FILE"

# Exit 1 if new patterns found (for heartbeat alerting)
if [[ $NEW_PATTERNS_FOUND -eq 1 ]]; then
    echo "[ALERT] New behavior patterns detected, review behavior-corrections.json"
    exit 1
fi

echo "[OK] Pattern scan complete, no new patterns found"
exit 0
