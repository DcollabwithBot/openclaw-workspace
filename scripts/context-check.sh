#!/bin/bash
# Context Check - Alert if .md files exceed 5k tokens (~20KB)
# Usage: ./context-check.sh
# Exit 0 = OK, Exit 1 = large files found

THRESHOLD_KB=20  # ~5k tokens
WORKSPACE="/root/.openclaw/workspace"
LARGE_FILES=()

while IFS= read -r file; do
  size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
  size_kb=$((size / 1024))
  if [ "$size_kb" -gt "$THRESHOLD_KB" ]; then
    LARGE_FILES+=("$file:${size_kb}")
  fi
done < <(find "$WORKSPACE" -name "*.md" -type f 2>/dev/null)

if [ ${#LARGE_FILES[@]} -eq 0 ]; then
  echo "✅ Context check: All .md files under ${THRESHOLD_KB}KB (~5k tokens)"
  exit 0
else
  echo "⚠️  CONTEXT CHECK ALERT"
  echo "Files exceeding ${THRESHOLD_KB}KB (may impact token usage):"
  for item in "${LARGE_FILES[@]}"; do
    file="${item%:*}"
    kb="${item#*:}"
    echo "  - $file (${kb}KB)"
  done
  echo ""
  echo "💡 Suggestion: Consider splitting large files into sections"
  exit 1
fi
