#!/bin/bash
# auto-patcher.sh - Applies behavior corrections to AGENTS.md
# Reads behavior-corrections.json and applies patches
# Can be run manually or via cron

set -e

WORKSPACE="/root/.openclaw/workspace"
MEMORY_DIR="$WORKSPACE/memory"
CORRECTIONS_FILE="$MEMORY_DIR/behavior-corrections.json"
AGENTS_FILE="$WORKSPACE/AGENTS.md"

echo "[PATCHER] Starting auto-patcher..."

# Check if corrections file exists
if [[ ! -f "$CORRECTIONS_FILE" ]]; then
    echo "[ERROR] behavior-corrections.json not found"
    exit 1
fi

# Check if there are unapplied patterns
UNAPPLIED_COUNT=$(jq '[.patterns[] | select(.applied == false)] | length' "$CORRECTIONS_FILE")

if [[ "$UNAPPLIED_COUNT" -eq 0 ]]; then
    echo "[OK] No unapplied patterns found"
    exit 0
fi

echo "[PATCHER] Found $UNAPPLIED_COUNT unapplied patterns"

# Process each unapplied pattern
jq -c '.patterns[] | select(.applied == false)' "$CORRECTIONS_FILE" | while read -r pattern; do
    DESCRIPTION=$(echo "$pattern" | jq -r '.description')
    TARGET=$(echo "$pattern" | jq -r '.target')
    SECTION=$(echo "$pattern" | jq -r '.section')
    REGEX=$(echo "$pattern" | jq -r '.regex')
    SOURCE=$(echo "$pattern" | jq -r '.source')
    
    echo "[PATCH] Processing: $DESCRIPTION"
    
    # Determine target file path
    if [[ "$TARGET" == "AGENTS.md" ]]; then
        TARGET_FILE="$AGENTS_FILE"
    elif [[ "$TARGET" == "PROJECT.md" ]]; then
        # Find PROJECT.md or use default location
        TARGET_FILE="$WORKSPACE/PROJECT.md"
    else
        TARGET_FILE="$WORKSPACE/$TARGET"
    fi
    
    # Check if target file exists
    if [[ ! -f "$TARGET_FILE" ]]; then
        echo "[WARN] Target file not found: $TARGET_FILE, skipping"
        continue
    fi
    
    # Create patch entry in AGENTS.md if target is AGENTS.md
    if [[ "$TARGET" == "AGENTS.md" ]]; then
        # Add pattern note to the Learning section or create it
        PATCH_NOTE="\n<!-- Auto-learned pattern: $(date +%Y-%m-%d) -->\n- **Pattern**: $DESCRIPTION\n- **Section**: $SECTION\n- **Source**: $SOURCE\n- **Regex**: \`$REGEX\`\n"
        
        # Check if ## Learning section exists
        if grep -q "^## Learning" "$TARGET_FILE"; then
            # Add after ## Learning line
            sed -i "/^## Learning/a\\$PATCH_NOTE" "$TARGET_FILE"
        else
            # Append to end of file
            echo -e "\n## Learning\n\nAuto-detected patterns from memory analysis:\n$PATCH_NOTE" >> "$TARGET_FILE"
        fi
        
        echo "[PATCH] Added pattern note to AGENTS.md"
    fi
    
    # Mark pattern as applied in JSON
    tmp=$(mktemp)
    jq --arg desc "$DESCRIPTION" \
       '(.patterns[] | select(.description == $desc)).applied = true' \
       "$CORRECTIONS_FILE" > "$tmp" && mv "$tmp" "$CORRECTIONS_FILE"
    
    echo "[PATCH] Marked as applied: $DESCRIPTION"
done

# Git commit changes if AGENTS.md was modified
cd "$WORKSPACE"
if git diff --quiet AGENTS.md 2>/dev/null; then
    echo "[OK] No changes to commit"
else
    git add AGENTS.md
    git add memory/behavior-corrections.json
    git commit -m "auto-patch: Apply learned behavior patterns ($(date +%Y-%m-%d))"
    echo "[COMMIT] Changes committed to git"
fi

echo "[PATCHER] Auto-patcher complete"
exit 0
