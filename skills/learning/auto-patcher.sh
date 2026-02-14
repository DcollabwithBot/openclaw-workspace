#!/bin/bash
# auto-patcher.sh - Reads behavior-corrections.json and applies patches to AGENTS.md
# Usage: ./auto-patcher.sh
# Exit codes: 0=OK (patches applied or none needed), 1=error

set -e

WORKSPACE="/root/.openclaw/workspace"
MEMORY_DIR="$WORKSPACE/memory"
AGENTS_MD="$WORKSPACE/AGENTS.md"
JSON_FILE="$MEMORY_DIR/behavior-corrections.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Auto-Patcher ==="
echo "Reading from: $JSON_FILE"
echo "Patching: $AGENTS_MD"

# Check files exist
if [[ ! -f "$JSON_FILE" ]]; then
    echo "ERROR: behavior-corrections.json not found"
    exit 1
fi

if [[ ! -f "$AGENTS_MD" ]]; then
    echo "ERROR: AGENTS.md not found"
    exit 1
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "ERROR: jq is required but not installed"
    exit 1
fi

# Get patterns with autoFix=true that haven't been applied
PATTERNS=$(jq -c '.patterns[] | select(.autoFix == true and (.applied // false) == false)' "$JSON_FILE" 2>/dev/null || echo "")

if [[ -z "$PATTERNS" ]]; then
    echo "No pending auto-fix patterns found."
    exit 0
fi

echo "Found patterns to process..."
APPLIED_COUNT=0

# Process each pattern
while IFS= read -r pattern; do
    [[ -z "$pattern" ]] && continue
    
    PATTERN_ID=$(echo "$pattern" | jq -r '.id')
    PATTERN_TYPE=$(echo "$pattern" | jq -r '.type')
    DESCRIPTION=$(echo "$pattern" | jq -r '.description')
    
    echo "Processing: $PATTERN_ID ($PATTERN_TYPE)"
    
    case "$PATTERN_TYPE" in
        "tool-policy-conflict")
            echo "  -> Patching tool policy section..."
            # Check if Auto-learned section exists
            if ! grep -q "<!-- Auto-learned pattern: tool-policy" "$AGENTS_MD"; then
                # Add a new Auto-learned pattern section before ## Learning
                if grep -q "^## Learning" "$AGENTS_MD"; then
                    sed -i '/^## Learning/i\
<!-- Auto-learned pattern: tool-policy -->\
- **Pattern**: Tool policy profile/allow conflict detected\
- **Section**: tool-policies\
- **Fix**: Use allow lists without profile, or use tool groups\
' "$AGENTS_MD"
                    echo "  -> Added tool-policy pattern to AGENTS.md"
                    APPLIED_COUNT=$((APPLIED_COUNT + 1))
                fi
            fi
            ;;
            
        "deployment-credential")
            echo "  -> Patching PROJECT.md requirements..."
            # Check if deployment pattern exists
            if ! grep -q "<!-- Auto-learned pattern: deployment" "$AGENTS.md" 2>/dev/null || true; then
                # Add to Learning section
                if grep -q "^## Learning" "$AGENTS_MD"; then
                    sed -i '/^## Learning/a\
<!-- Auto-learned pattern: deployment -->\
- **Pattern**: Deployment credentials must be in PROJECT.md (gitignored)\
- **Section**: workflows\
- **Source**: pattern-matcher detected credential issues\
' "$AGENTS_MD"
                    echo "  -> Added deployment credential pattern to AGENTS.md"
                    APPLIED_COUNT=$((APPLIED_COUNT + 1))
                fi
            fi
            ;;
            
        "context-handling")
            echo "  -> Patching code location requirements..."
            # Check if context pattern exists
            if ! grep -q "Kode-Lokalitetsstandard" "$AGENTS_MD"; then
                # Add after first ## Universal Rules or similar
                if grep -q "^## Universal Rules" "$AGENTS_MD"; then
                    sed -i '/^## Universal Rules/a\
\
### Code Location Standard (MANDATORY)\
When implementing code, agents MUST report:\
- Full file path\
- Git commit hash\
- Summary of changes\
' "$AGENTS_MD"
                    echo "  -> Added code location standard to AGENTS.md"
                    APPLIED_COUNT=$((APPLIED_COUNT + 1))
                fi
            fi
            ;;
            
        "danish-workflow")
            echo "  -> Skipping Danish workflow (manual review required)"
            ;;
            
        "rate-limit")
            echo "  -> Skipping rate limit (manual review required)"
            ;;
            
        *)
            echo "  -> Unknown pattern type: $PATTERN_TYPE"
            ;;
    esac
    
    # Mark as applied in JSON
    jq --arg id "$PATTERN_ID" '(.patterns[] | select(.id == $id) | .applied) = true' "$JSON_FILE" > "$JSON_FILE.tmp" && mv "$JSON_FILE.tmp" "$JSON_FILE"
    
done <<< "$PATTERNS"

# Git operations
echo ""
echo "=== Git Operations ==="
cd "$WORKSPACE"

# Check if there are changes
if git diff --quiet HEAD -- "$AGENTS_MD" 2>/dev/null; then
    echo "No changes to AGENTS.md"
else
    echo "Changes detected, committing..."
    
    # Configure git if needed
    git config user.email "agent@openclaw.local" 2>/dev/null || true
    git config user.name "Auto-Patcher" 2>/dev/null || true
    
    # Add and commit
    git add "$AGENTS_MD"
    git add "$JSON_FILE"
    
    COMMIT_MSG="auto: Apply learned patterns from memory analysis

Applied patterns:
- Tool policy conflicts
- Deployment credential requirements  
- Code location standards

Auto-generated by: auto-patcher.sh"

    git commit -m "$COMMIT_MSG" || echo "Commit failed or nothing to commit"
    
    # Push to master
    echo "Pushing to master..."
    git push origin master || echo "Push failed - may need manual intervention"
    
    echo "Git operations complete."
fi

echo ""
echo "=== Summary ==="
echo "Patterns applied: $APPLIED_COUNT"
echo "Auto-patcher complete."

exit 0
